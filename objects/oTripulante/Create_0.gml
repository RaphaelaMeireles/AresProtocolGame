// =====================================================================
// oTripulante - um astronauta vivendo na base
// =====================================================================
// Criado pelo oTripulacao a partir dos personagens da camada "Personagens".
// (x, y) = os pés do personagem. Anda pela grade de scr_mapa (não atravessa paredes nem móveis),
// usa as máquinas, conversa com os outros, dorme na cama, sai em expedições
// e mostra balões de emoção.
//
// Estados: "parado" (pensando no que fazer), "andando", "usando" (numa máquina),
//          "conversando", "expedicao" (indo até a porta para sair), "fora" (em expedição)

if (!variable_instance_exists(id, "nome"))   nome = "?";
if (!variable_instance_exists(id, "escala")) escala = 1;   // tamanho do desenho na room (como no editor)

caminho      = path_add();
estado       = "parado";
espera       = irandom_range(30, 120);       // frames até decidir o próximo passo
vel          = 0.55 + random(0.25);          // cada um anda num ritmo
alvo_maquina = undefined;
icone_uso    = "";                           // balão mostrado ao usar a máquina
parceiro     = noone;
cooldown_conversa = irandom_range(180, 420);
travado      = 0;                            // frames sem sair do lugar enquanto anda
portal_alvo    = noone;                      // oPortal até onde está indo (para passar a outro módulo)
destino_final  = undefined;                  // [x, y] de verdade, do outro lado do portal
indo_expedicao = false;                      // está indo até o airlock por outro módulo

w = sprite_get_width(sprite_index) * escala;
h = sprite_get_height(sprite_index) * escala;

// Animação de caminhada: 4 quadros gerados a partir do desenho (scr_animacao)
spr_andar = tripulante_frames_andar(sprite_index);
passo     = 0;          // avança enquanto anda; o quadro é floor(passo) mod 4
anim      = random(100);
andando   = false;
virado    = choose(-1, 1);
x_ant     = x;
y_ant     = y;
pulo      = 0;          // pulinho ao falar numa conversa
alpha_corpo = 1;        // some/aparece na porta da expedição

// Balão de emoção
emocao       = "";
emocao_tempo = 0;
emocao_pop   = 0;

dia_visto = global.dia;

/// Mostra um balão por um tempo (frames)
falar = function(_icone, _frames) {
    emocao = _icone;
    emocao_tempo = _frames;
    emocao_pop = 0;
    if (estado == "conversando") pulo = 3;
};

/// Vai até um ponto da base pelo caminho livre. Devolve false se não houver caminho.
ir_para = function(_x, _y) {
    if (global.mapa == undefined) return false;
    // Se por algum motivo está fora do chão (ex.: começou num tubo), volta para o chão mais perto
    if (mapa_regiao(x, y) == 0) { var _c = mapa_ponto_livre_perto(x, y); x = _c[0]; y = _c[1]; }
    var _p = mapa_ponto_livre_perto(_x, _y);
    portal_alvo = noone;
    destino_final = undefined;

    // Mesmo módulo: vai direto
    if (mp_grid_path(global.mapa.grade, caminho, x, y, _p[0], _p[1], true)) {
        path_start(caminho, vel, path_action_stop, true);
        estado = "andando";
        travado = 0;
        return true;
    }
    // Outro módulo: vai até o portal da passagem; do outro lado continua até o destino
    var _portal = mapa_portal_rumo(x, y, _p[0], _p[1]);
    if (_portal != noone && mp_grid_path(global.mapa.grade, caminho, x, y, _portal.x, _portal.y, true)) {
        portal_alvo = _portal;
        destino_final = _p;
        path_start(caminho, vel, path_action_stop, true);
        estado = "andando";
        travado = 0;
        return true;
    }
    return false;
};

/// Chegou no portal: some, aparece no portal do outro módulo e segue até o destino
atravessar_portal = function() {
    var _saida = portal_alvo.par;
    portal_alvo.brilho = 1;
    _saida.brilho = 1;
    x = _saida.x; y = _saida.y;
    x_ant = x; y_ant = y;
    portal_alvo = noone;
    var _dest = destino_final;
    destino_final = undefined;
    if (_dest == undefined || !ir_para(_dest[0], _dest[1])) { alvo_maquina = undefined; indo_expedicao = false; parar(); }
};

/// Vai até uma máquina e usa (ou conserta) quando chegar
ir_usar = function(_m, _icone) {
    if (estado == "fora" || estado == "expedicao") return;
    alvo_maquina = _m;
    icone_uso = _icone;
    if (!ir_para(_m.uso_x, _m.uso_y)) alvo_maquina = undefined;
};

/// Para e fica pensando um pouco
parar = function() {
    path_end();
    portal_alvo = noone;
    destino_final = undefined;
    indo_expedicao = false;
    estado = "parado";
    espera = irandom_range(40, 180);
};

/// Expedição: vai até a porta e sai da base
sair_expedicao = function(_px, _py) {
    alvo_maquina = undefined;
    parceiro = noone;
    falar("estrela", 120);
    if (mp_grid_path(global.mapa.grade, caminho, x, y, _px, _py, true)) {
        path_start(caminho, vel * 1.3, path_action_stop, true);
        estado = "expedicao";
        return;
    }
    // Está em outro módulo: passa pelos portais até o airlock
    if (ir_para(_px, _py)) { indo_expedicao = true; return; }
    x = _px; y = _py;
    estado = "expedicao";
};

/// Volta da expedição: aparece na porta e mostra como foi
voltar_expedicao = function(_px, _py, _icone) {
    x = _px; y = _py; x_ant = x; y_ant = y;
    visible = true;
    alpha_corpo = 0;
    estado = "parado";
    espera = 60;
    dia_visto = global.dia + 1;   // volta na troca de dia: mostra o balão da expedição, não o do evento
    falar(_icone, 300);
};

/// Status da base que está baixo (2 ou menos) e mais urgente, ou "" se está tudo bem
necessidade = function() {
    var _nomes = ["vida", "comida", "energia", "escudo"];
    var _pior = "", _valor = 3;
    for (var i = 0; i < array_length(_nomes); i++) {
        var _v = variable_global_get(_nomes[i]);
        if (_v < _valor) { _valor = _v; _pior = _nomes[i]; }
    }
    return _pior;
};

/// Emoção que combina com como a base está
emocao_do_humor = function() {
    if (global.vida <= 1)    return "triste";
    if (global.comida <= 1)  return "fome";
    if (global.energia <= 1) return "exclamacao";
    if (maquinas_quebradas() > 0 && random(1) < 0.4) return "ferramenta";
    return choose("feliz", "musica", "coracao", "feliz", "estrela");
};

/// Escolhe o que fazer agora
decidir = function() {
    var _r = random(1);
    var _nec = necessidade();
    if (_nec != "" && _r < 0.5) {
        // Algo está faltando: vai até a máquina que ajuda (e mostra que está preocupado)
        var _m = maquina_por_necessidade(_nec);
        if (_m != undefined) {
            ir_usar(_m, _m.def.icone);
            if (estado == "andando") { falar(_nec == "comida" ? "fome" : (_nec == "vida" ? "triste" : "exclamacao"), 90); return; }
        }
    }
    if (_r < 0.35) {
        var _m = maquina_por_necessidade("");
        if (_m != undefined) { ir_usar(_m, _m.def.icone); if (estado == "andando") return; }
    }
    if (_r < 0.85) {
        var _p = mapa_ponto_aleatorio();
        if (ir_para(_p[0], _p[1])) return;
    }
    // Fica onde está e expressa o humor
    falar(emocao_do_humor(), 120);
    espera = irandom_range(90, 200);
};
