// =====================================================================
// oMaquinas - clique do jogador nas máquinas da base
// =====================================================================
// Criado pelo oGameManager, depois da grade de caminhada. Usa as regras de scr_maquinas.
// - Mouse em cima: a máquina brilha e aparece o nome, o que ela faz e o custo.
// - Clique:
//     máquina quebrada  -> conserta (gasta materiais do estoque + 1 raio)
//     status            -> +1 vida/energia/comida (se o status já está cheio, não gasta nada)
//     console (nasa)    -> mostra a previsão real da NASA para Marte
//     laboratório       -> transforma regolito em ferro, silício ou magnésio
//     porta (expedição) -> abre a janela de expedição (oExpedicao)
//     estoque           -> só mostra o que tem guardado
//   O astronauta mais perto vai até a máquina usar (ou consertar).

depth = -14000;
maquinas_listar();

hover      = undefined;   // máquina embaixo do mouse
popups     = [];          // textos que sobem da máquina depois do clique
fumacas    = [];          // fumaça saindo das máquinas quebradas
nasa_texto = "";          // painel de informação da NASA (console e laboratório)
nasa_titulo = "";
nasa_tempo = 0;
nasa_painel_y = 70;       // topo do painel na tela (centralizado ao desenhar)
card_missao_era_aberto = false;   // o card de missão estava aberto antes do painel? (volta ao fechar)
nasa_aberto_antes = false;        // o painel estava aberto no frame anterior

var _vermelho = make_color_rgb(255, 110, 100);
var _verde    = make_color_rgb(140, 235, 140);
cor_ruim = _vermelho;
cor_boa  = _verde;

/// Texto que sobe da máquina e some
popup = function(_m, _texto, _cor) {
    if (_texto == "") return;
    array_push(popups, { x: (_m.x1 + _m.x2) / 2, y: _m.y1, texto: _texto, cor: _cor, t: 0 });
};

/// Mostra o painel de informação no alto da tela
informar = function(_titulo, _texto) {
    nasa_titulo = _titulo;
    nasa_texto = _texto;
    nasa_tempo = 999999;   // fica aberto até o X (ou até a troca de dia, que fecha tudo)
};

/// Clicar numa máquina custa 1 raio. Devolve false (e avisa) se não há raios.
gastar_clique = function(_m) {
    if (global.raios <= 0) { popup(_m, tr("maq_sem_raios"), cor_ruim); return false; }
    gastar_raios(CLIQUE_CUSTO_RAIOS);
    return true;
};

/// Gasta raios: se tiver menos que o custo, usa o que tiver e zera (regra do console)
gastar_raios = function(_custo) {
    global.raios = max(0, global.raios - _custo);
};

/// O astronauta mais perto (na base e sem estar conversando) vai até a máquina
chamar_tripulante = function(_m, _icone) {
    var _melhor = noone, _dist = infinity;
    with (oTripulante) {
        if (estado == "fora" || estado == "expedicao" || estado == "conversando") continue;
        var _d = point_distance(x, y, _m.uso_x, _m.uso_y);
        if (_d < _dist) { _dist = _d; _melhor = id; }
    }
    if (_melhor != noone) _melhor.ir_usar(_m, _icone);
};

/// Clique do jogador na máquina
usar = function(_m) {
    var _def = _m.def;
    if (_def.tipo == "decoracao") return;

    // A porta abre a janela de expedição (a saída gasta os raios da expedição)
    if (_def.tipo == "expedicao") {
        if (instance_exists(oExpedicao)) {
            if (global.dia < global.expedicao_bloqueada_ate) popup(_m, tr("exp_bloqueada"), cor_ruim);
            else if (oExpedicao.missao != undefined) popup(_m, tr("exp_ja_fora"), cor_ruim);
            else if (global.raios <= 0) popup(_m, tr("maq_sem_raios"), cor_ruim);
            else oExpedicao.abrir();   // a janela fica aberta (o dia espera) até mandar alguém ou cancelar
        }
        return;
    }
    // O estoque só mostra o que tem guardado (sem custo)
    if (_def.tipo == "estoque") return;

    if (global.raios <= 0) { popup(_m, tr("maq_sem_raios"), cor_ruim); return; }

    // Quebrada: o clique conserta, se houver material
    if (_m.quebrada) {
        if (!estoque_tem(_def.reparo)) { popup(_m, tr("maq_falta_material"), cor_ruim); return; }
        estoque_gastar(_def.reparo);
        gastar_clique(_m);
        _m.quebrada = false;
        popup(_m, tr("maq_consertada"), cor_boa);
        chamar_tripulante(_m, "ferramenta");
        return;
    }

    switch (_def.tipo) {
        case "nasa":
            // Consultar o Mission Control não gasta pontos de ação
            // Clima real de Marte (InSight) do dia de hoje
            // O card de missão recolhe enquanto o painel está aberto (e volta como estava ao fechar)
            if (nasa_tempo <= 0 && instance_exists(oObjetivos)) {
                card_missao_era_aberto = !oObjetivos.minimizada;
                oObjetivos.minimizada = true;
            }
            informar(tr("nasa_clima_titulo"), clima_registro_aleatorio_texto());
            chamar_tripulante(_m, _def.icone);
            break;

        case "laboratorio":
            // Reforça o escudo: 1 regolito + 1 ponto de ação = +1 Escudo
            if (global.escudo >= global.escudo_max) { popup(_m, tr("maq_escudo_cheio"), cor_ruim); return; }
            if (global.estoque.regolito < LAB_CUSTO_REGOLITO) { popup(_m, tr("lab_falta", LAB_CUSTO_REGOLITO), cor_ruim); return; }
            gastar_clique(_m);
            estoque_gastar({ regolito: LAB_CUSTO_REGOLITO });
            global.escudo = min(global.escudo_max, global.escudo + 1);
            popup(_m, tr("lab_escudo"), cor_boa);
            chamar_tripulante(_m, global.materiais_icone.regolito);
            break;

        case "clima":
            // Estação meteorológica: único lugar que mostra o clima de Marte e a previsão
            gastar_clique(_m);
            if (instance_exists(oDia)) oDia.painel_clima = true;
            break;

        default:   // "status"
            var _bloqueio = maquina_efeito_bloqueio(_def.efeito);
            if (_bloqueio == "cheio") { popup(_m, tr("maq_cheio"), cor_ruim); return; }
            if (_bloqueio == "falta") { popup(_m, tr("maq_falta_status"), cor_ruim); return; }
            var _ef = clima_ajustar_efeito(_def);
            gastar_clique(_m);
            gastar_raios(clima_extra_maquina(_def));   // ventania: o reator de fissão custa 1 ponto a mais
            maquina_aplicar_efeito(_ef);
            popup(_m, maquina_efeito_texto(_ef), cor_boa);
            chamar_tripulante(_m, _def.icone);
    }
};
