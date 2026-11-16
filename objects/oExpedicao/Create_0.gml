// =====================================================================
// oExpedicao - expedições pela Cratera Jezero (clique na porta de saída do airlock)
// =====================================================================
// Criado pelo oGameManager.
// 1) Clique na porta blindada -> abre a janela de expedição com os destinos (scr_expedicao).
// 2) O jogador escolhe o destino e clica em "Go!": gasta 2 raios e o astronauta mais perto
//    vai até a porta, sai, e o rover sai dirigindo.
// 3) Ele fica fora 1 ou 2 dias. Na noite em que volta, o resultado é sorteado
//    (sucesso, parcial ou fracasso) e os materiais vão para o estoque (scr_recursos).
// 4) Quando o dia começa, aparece o relatório da expedição.

depth = -11000;   // janela por cima do oDia

aberta      = false;   // janela de escolha aberta
escolhido   = 0;       // índice do destino escolhido
missao      = undefined;   // expedição em andamento: { tripulante, destino, dia_volta }
relatorio   = undefined;   // resultado para mostrar quando o dia começar
poeira_rover = [];         // nuvenzinhas de poeira atrás do rover

// --- Layout da janela (coordenadas da GUI, 1280 x 720) ---
jan_w = 1000; jan_h = 600;
jan_x1 = (1280 - jan_w) / 2; jan_y1 = (720 - jan_h) / 2;
jan_x2 = jan_x1 + jan_w;     jan_y2 = jan_y1 + jan_h;
linha_y0 = jan_y1 + 110;     // primeira linha da lista de destinos
linha_h  = 62;
bot_w = 200; bot_h = 50;
bot_ir     = [jan_x2 - 40 - bot_w, jan_y2 - 30 - bot_h, jan_x2 - 40, jan_y2 - 30];
bot_voltar = [jan_x2 - 60 - 2 * bot_w, jan_y2 - 30 - bot_h, jan_x2 - 60 - bot_w, jan_y2 - 30];
bot_ok     = [640 - 100, 0, 640 + 100, 0];   // posição vertical calculada ao desenhar o relatório

// --- Rover (sprite sRover na camada Moveis): sai e volta junto com a expedição ---
rover_el = -1;
var _lay = layer_get_id("Moveis");
if (_lay != -1) {
    var _els = layer_get_all_elements(_lay);
    for (var i = 0; i < array_length(_els); i++) {
        if (layer_get_element_type(_els[i]) == layerelementtype_sprite && sprite_get_name(layer_sprite_get_sprite(_els[i])) == "sRover") {
            rover_el = _els[i];
            break;
        }
    }
}
rover_casa = (rover_el != -1) ? layer_sprite_get_x(rover_el) : 0;   // onde o rover estaciona
rover_x    = rover_casa;
rover_w    = (rover_el != -1) ? sprite_get_width(layer_sprite_get_sprite(rover_el)) : 0;
rover_y0   = (rover_el != -1) ? layer_sprite_get_y(rover_el) : 0;   // altura no chão (a rampa levanta)

/// Astronauta disponível mais perto da porta (precisa ficar pelo menos 1 na base)
tripulante_disponivel = function(_px, _py) {
    var _melhor = noone, _dist = infinity, _na_base = 0;
    with (oTripulante) {
        if (estado == "fora" || estado == "expedicao") continue;
        _na_base += 1;
        var _d = point_distance(x, y, _px, _py);
        if (_d < _dist) { _dist = _d; _melhor = id; }
    }
    return (_na_base >= 2) ? _melhor : noone;
};

/// Abre a janela de expedição (clique na porta)
abrir = function() {
    if (missao != undefined || aberta) return;
    expedicao_destinos_do_dia();   // lugares de hoje (mudam a cada dia)
    escolhido = 0;
    aberta = true;
    global.ui_bloqueada = true;
};

fechar = function() {
    aberta = false;
    global.ui_bloqueada = false;
};

/// Manda o astronauta para o destino escolhido
partir = function() {
    var _porta = maquina_por_tipo("expedicao");
    var _dest = global.destinos[escolhido];
    var _custo = expedicao_custo(_dest);
    if (_porta == undefined || global.raios < _custo) return false;   // precisa ter os pontos do risco
    var _t = tripulante_disponivel(_porta.uso_x, _porta.uso_y);
    if (_t == noone) return false;

    global.raios -= _custo;
    missao = { tripulante: _t, destino: _dest, dia_volta: global.dia + _dest.dias };
    global.expedicao_enviada_dia = global.dia;   // amanhã aparece um imprevisto da expedição
    _t.sair_expedicao(_porta.uso_x, _porta.uso_y);
    fechar();
    return true;
};

/// Chamado pelo oDia na troca de dia (tela preta): o astronauta volta se for o dia
nova_noite = function(_dia_novo) {
    if (missao == undefined || _dia_novo < missao.dia_volta || relatorio != undefined) return;
    // O resultado é sorteado agora, mas o tripulante só volta (e os recursos só entram no estoque)
    // depois dos imprevistos do dia: primeiro o evento da expedição, depois o relatório da volta.
    var _t = missao.tripulante;
    relatorio = { nome: instance_exists(_t) ? _t.nome : "?", destino: missao.destino,
                  res: expedicao_resolver(missao.destino), aplicado: false };
};

/// O tripulante volta pela porta e o que ele trouxe entra no estoque (quando o relatório aparece)
voltar_agora = function() {
    var _res = relatorio.res;
    var _mats = variable_struct_get_names(_res.coleta);
    for (var i = 0; i < array_length(_mats); i++) estoque_adicionar(_mats[i], _res.coleta[$ _mats[i]]);
    if (_res.ferido) global.vida = max(0, global.vida - 1);

    if (missao != undefined) {
        var _t = missao.tripulante;
        var _porta = maquina_por_tipo("expedicao");
        if (instance_exists(_t) && _porta != undefined) {
            _t.voltar_expedicao(_porta.uso_x, _porta.uso_y, _res.resultado == "sucesso" ? "feliz" : (_res.ferido ? "triste" : "interrogacao"));
        }
    }
    missao = undefined;
    relatorio.aplicado = true;
};

relatorio_visivel = false;   // o relatório da volta está na tela (calculado no Step, usado no Draw)
