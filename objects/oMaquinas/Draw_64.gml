// Interface fixa na tela: dica da máquina embaixo do mouse e painel de informação da NASA
if (!instance_exists(oDia)) exit;
var _gw = display_get_gui_width();
var _painel  = make_color_rgb(24, 27, 34);
var _borda   = make_color_rgb(150, 155, 165);
var _amarelo = make_color_rgb(255, 230, 120);
var _verde   = make_color_rgb(140, 235, 140);

// --- Dica: nome, o que faz e quanto custa ---
if (hover != undefined && !global.ui_bloqueada) {
    var _def  = hover.def;
    var _nome = tr("maq_" + _def.chave + "_nome");
    var _acao = "", _cor_acao = _verde;
    var _custo = tr("maq_custo_um");   // todo clique numa máquina custa 1 raio
    var _cor_custo = (global.raios <= 0) ? cor_ruim : c_white;

    if (hover.quebrada) {
        _acao = tr("maq_quebrada");
        _cor_acao = cor_ruim;
        _custo = tr("maq_reparo", materiais_texto(_def.reparo));
        _cor_custo = estoque_tem(_def.reparo) ? c_white : cor_ruim;
    } else {
        switch (_def.tipo) {
            case "nasa":        _acao = tr("maq_console_acao"); _custo = tr("maq_custo_gratis"); break;
            case "laboratorio": _acao = tr("maq_laboratorio_acao", LAB_CUSTO_REGOLITO) + " (" + tr("lab_escudo") + ")"; break;
            case "clima":       _acao = tr("maq_antena_acao"); break;
            case "expedicao":   _acao = tr("maq_porta_acao"); _custo = tr("maq_custo_expedicao"); break;
            case "estoque":     _acao = tr("maq_estoque_acao"); _custo = materiais_texto(global.estoque); if (_custo == "") _custo = tr("maq_estoque_vazio"); _cor_custo = c_white; break;
            default:
                _acao = maquina_efeito_texto(_def.efeito);
                var _b = maquina_efeito_bloqueio(_def.efeito);
                if (_b == "cheio") { _acao = tr("maq_cheio"); _cor_acao = cor_ruim; }
                if (_b == "falta") { _acao = tr("maq_falta_status"); _cor_acao = cor_ruim; }
        }
    }

    var _s = 2;
    var _larg = max(oDia.texto_largura(_nome, _s), oDia.texto_largura(_acao, _s), oDia.texto_largura(_custo, _s)) + 24;
    var _alt  = 3 * 10 * _s + 12;
    var _m  = mouse_gui();
    var _x1 = clamp(_m[0] + 18, 8, _gw - _larg - 8);
    var _y1 = clamp(_m[1] + 18, 8, display_get_gui_height() - _alt - 8);

    draw_set_color(_painel);
    draw_rectangle(_x1, _y1, _x1 + _larg, _y1 + _alt, false);
    draw_set_color(hover.quebrada ? cor_ruim : _borda);
    draw_rectangle(_x1, _y1, _x1 + _larg, _y1 + _alt, true);
    oDia.texto(_x1 + 12, _y1 + 8,           _nome,  _s, _amarelo,   fa_left, fa_top);
    oDia.texto(_x1 + 12, _y1 + 8 + 10 * _s, _acao,  _s, _cor_acao,  fa_left, fa_top);
    oDia.texto(_x1 + 12, _y1 + 8 + 20 * _s, _custo, _s, _cor_custo, fa_left, fa_top);
}

// --- Painel de informação (console da NASA e laboratório): no alto da tela ---
if (nasa_tempo > 0 && nasa_texto != "") {
    var _a = min(1, nasa_tempo / 30);
    var _s = 3;
    var _larg_max = 900;
    var _corpo = oDia.texto_quebrar(nasa_texto, _s, _larg_max);
    var _alt = 7 * 2 + 16 + oDia.texto_altura(_corpo, _s, 4) + 32;
    var _x1 = (_gw - _larg_max) / 2 - 24;
    var _y1 = floor((display_get_gui_height() - _alt) / 2);   // no centro da tela
    nasa_painel_y = _y1;                                      // o Step usa para o clique no X

    draw_set_alpha(0.92 * _a);
    draw_set_color(_painel);
    draw_rectangle(_x1, _y1, _x1 + _larg_max + 48, _y1 + _alt, false);
    draw_set_alpha(_a);
    draw_set_color(_amarelo);
    draw_rectangle(_x1, _y1, _x1 + _larg_max + 48, _y1 + _alt, true);
    oDia.texto(_x1 + 24, _y1 + 14, nasa_titulo, 2, _amarelo, fa_left, fa_top, _a);
    oDia.texto(_x1 + 24, _y1 + 14 + 7 * 2 + 16, _corpo, _s, c_white, fa_left, fa_top, _a, false, 4);

    // X para fechar (o clique é tratado no Step)
    var _fx = _x1 + _larg_max + 48 - 30;
    draw_set_color(_painel);
    draw_rectangle(_fx, _y1 + 8, _fx + 22, _y1 + 30, false);
    draw_set_color(_amarelo);
    draw_rectangle(_fx, _y1 + 8, _fx + 22, _y1 + 30, true);
    oDia.texto(_fx + 11, _y1 + 19, "X", 2, c_white, fa_center, fa_middle, _a);
}
draw_set_alpha(1);
draw_set_color(c_white);
