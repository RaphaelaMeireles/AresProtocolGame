if (!instance_exists(oDia)) exit;
var _gw = display_get_gui_width(), _gh = display_get_gui_height();
var _painel  = make_color_rgb(24, 27, 34);
var _borda   = make_color_rgb(150, 155, 165);
var _amarelo = make_color_rgb(255, 230, 120);
var _verde   = make_color_rgb(120, 220, 120);
var _suave   = make_color_rgb(150, 155, 165);

// ===================================================================== card da missão
card_rect = undefined;   // preenchido abaixo quando o card ou o botão "!" aparecem
// Minimizado: só um botão preto com "!" no canto (igual ao do Stardew Valley). Clique abre a missão.
if (aberta && minimizada && global.fim_missao == "" && !global.ui_bloqueada) {
    var _bx = _gw - 48, _by = 96;
    draw_set_alpha(0.9); draw_set_color(make_color_rgb(8, 8, 10)); draw_rectangle(_bx, _by, _bx + 36, _by + 36, false);
    draw_set_alpha(1);   draw_set_color(_borda);  draw_rectangle(_bx, _by, _bx + 36, _by + 36, true);
    oDia.texto(_bx + 18, _by + 18, "!", 3, _amarelo, fa_center, fa_middle);
    card_rect = [_bx, _by, _bx + 36, _by + 36];
}

// Aberto: MISSÕES -> sobreviver 10 sols -> estoque (um material por linha) -> dica da expedição
if (aberta && !minimizada && global.fim_missao == "" && !global.ui_bloqueada) {
    var _w = 300;
    var _x1 = _gw - _w - 12, _y1 = 96;
    var _x = _x1 + 18;
    var _larg_txt = _w - 36;

    // Ordem do estoque no card (poeira por último)
    var _ordem = ["regolito", "ferro", "silicio", "magnesio", "poeira"];

    // Dica da expedição (ou onde está quem saiu)
    var _txt_exp = tr("obj_exp_livre");
    if (instance_exists(oExpedicao) && oExpedicao.missao != undefined) {
        var _mi = oExpedicao.missao;
        _txt_exp = tr("obj_exp_fora", instance_exists(_mi.tripulante) ? _mi.tripulante.nome : "?",
                      tr("exp_" + _mi.destino.id + "_nome"), _mi.dia_volta);
    }
    _txt_exp = oDia.texto_quebrar(_txt_exp, 2, _larg_txt);

    // Altura calculada antes, para o painel caber tudo
    var _alt = 18 + 14 + 26          // título
             + 20 + 14 + 26          // sobreviver + barra
             + (array_length(global.objetivos) - 1) * 40   // outras missões (cada uma com barra)
             + 22 + array_length(_ordem) * 28 + 18   // estoque
             + oDia.texto_altura(_txt_exp, 2, 4) + 18;

    draw_set_alpha(0.9); draw_set_color(make_color_rgb(8, 8, 10)); draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _alt, false);
    draw_set_alpha(1);   draw_set_color(_borda);  draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _alt, true);

    var _y = _y1 + 18;
    oDia.texto(_x1 + _w / 2, _y, tr("obj_titulo"), 2, _amarelo, fa_center, fa_top);

    // Botão [-] à direita do título: minimiza o card no botão "!"
    var _mx1 = _x1 + _w - 34, _my1 = _y1 + 10;
    draw_set_color(make_color_rgb(8, 8, 10)); draw_rectangle(_mx1, _my1, _mx1 + 24, _my1 + 24, false);
    draw_set_color(_borda);                   draw_rectangle(_mx1, _my1, _mx1 + 24, _my1 + 24, true);
    oDia.texto(_mx1 + 12, _my1 + 12, "-", 2, c_white, fa_center, fa_middle);
    _y += 14 + 26;

    // Sobreviver 10 sols
    var _p = objetivo_progresso(global.objetivos[0]);
    var _ok = (_p[0] >= _p[1]);
    oDia.texto(_x, _y, tr("obj_sobreviver"), 2, _ok ? _verde : c_white, fa_left, fa_top);
    oDia.texto(_x + _larg_txt, _y, string(_p[0]) + "/" + string(_p[1]), 2, _suave, fa_right, fa_top);
    var _bar_y = _y + 20;
    draw_set_color(make_color_rgb(50, 54, 62));
    draw_rectangle(_x, _bar_y, _x + _larg_txt, _bar_y + 6, false);
    draw_set_color(_ok ? _verde : _amarelo);
    draw_rectangle(_x, _bar_y, _x + _larg_txt * clamp(_p[0] / _p[1], 0, 1), _bar_y + 6, false);
    _y += 40;

    // Outras missões: amostras, ferro, silício, magnésio e máquinas funcionando
    for (var o = 1; o < array_length(global.objetivos); o++) {
        var _obj = global.objetivos[o];
        var _po = objetivo_progresso(_obj);
        var _feito = (_po[0] >= _po[1]);
        oDia.texto(_x, _y, tr("obj_" + _obj.id), 2, _feito ? _verde : c_white, fa_left, fa_top);
        oDia.texto(_x + _larg_txt, _y, string(_po[0]) + "/" + string(_po[1]), 2, _feito ? _verde : _suave, fa_right, fa_top);
        var _bo = _y + 20;
        draw_set_color(make_color_rgb(50, 54, 62));
        draw_rectangle(_x, _bo, _x + _larg_txt, _bo + 6, false);
        draw_set_color(_feito ? _verde : _amarelo);
        draw_rectangle(_x, _bo, _x + _larg_txt * clamp(_po[0] / _po[1], 0, 1), _bo + 6, false);
        _y += 40;
    }
    _y += 20;

    // Estoque: ícone, nome e quantidade
    oDia.texto(_x, _y, tr("obj_estoque"), 2, _amarelo, fa_left, fa_top);
    _y += 22;
    gpu_set_texfilter(false);
    for (var i = 0; i < array_length(_ordem); i++) {
        var _mat = _ordem[i];
        draw_sprite_ext(emocao_sprite(global.materiais_icone[$ _mat]), 0, _x, _y, 3, 3, 0, c_white, 1);
        oDia.texto(_x + 30, _y + 3, tr("mat_" + _mat), 2, c_white, fa_left, fa_top);
        oDia.texto(_x + _larg_txt, _y + 3, string(global.estoque[$ _mat]), 2, c_white, fa_right, fa_top);
        _y += 28;
    }
    _y += 18;

    // Dica da expedição
    oDia.texto(_x, _y, _txt_exp, 2, _suave, fa_left, fa_top, 1, false, 4);

    card_rect = [_x1, _y1, _x1 + _w, _y1 + _alt];
}

// ===================================================================== tela final
if (global.fim_missao != "") {
    var _venceu = (global.fim_missao == "vitoria");
    var _w = 820, _h = 560;
    var _x1 = (_gw - _w) / 2, _y1 = (_gh - _h) / 2;
    draw_set_alpha(0.75); draw_set_color(c_black); draw_rectangle(0, 0, _gw, _gh, false); draw_set_alpha(1);
    draw_set_color(_painel); draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, false);
    draw_set_color(_venceu ? _amarelo : make_color_rgb(255, 110, 100));
    draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, true);
    draw_rectangle(_x1 + 4, _y1 + 4, _x1 + _w - 4, _y1 + _h - 4, true);

    oDia.texto(_gw / 2, _y1 + 30, tr(_venceu ? "fim_vitoria" : "fim_derrota"), 5, _venceu ? _amarelo : make_color_rgb(255, 110, 100), fa_center, fa_top);
    var _chave_sub = _venceu ? "fim_vitoria_texto" : ("fim_motivo_" + global.motivo_derrota);
    var _sub = oDia.texto_quebrar(tr(_chave_sub, global.dia), 2, _w - 80);
    oDia.texto(_gw / 2, _y1 + 84, _sub, 2, c_white, fa_center, fa_top, 1, false, 4);

    // Estrelas (ícone da estrela ampliado; apagadas ficam escuras)
    var _estrelas = missao_estrelas();
    for (var s = 0; s < 3; s++) {
        gpu_set_texfilter(false);
        draw_sprite_ext(emocao_sprite("estrela"), 0, _gw / 2 - 100 + s * 70, _y1 + 140, 7, 7, 0,
                        (s < _estrelas) ? c_white : make_color_rgb(60, 60, 70), 1);
    }

    // Lista dos objetivos
    var _y = _y1 + 210;
    for (var i = 0; i < array_length(global.objetivos); i++) {
        var _o = global.objetivos[i];
        var _p = objetivo_progresso(_o);
        var _ok = (_p[0] >= _p[1]);
        oDia.texto(_x1 + 80, _y, (_ok ? "+ " : "- ") + tr("obj_" + _o.id), 3, _ok ? _verde : _suave, fa_left, fa_top);
        oDia.texto(_x1 + _w - 80, _y, string(_p[0]) + "/" + string(_p[1]), 3, _ok ? _verde : _suave, fa_right, fa_top);
        _y += 36;
    }

    // Botão jogar de novo
    bot_denovo = [_gw / 2 - 140, _y1 + _h - 80, _gw / 2 + 140, _y1 + _h - 28];
    var _m = mouse_gui();
    var _hover = point_in_rectangle(_m[0], _m[1], bot_denovo[0], bot_denovo[1], bot_denovo[2], bot_denovo[3]);
    draw_set_color(_hover ? make_color_rgb(80, 85, 95) : make_color_rgb(50, 54, 62));
    draw_rectangle(bot_denovo[0], bot_denovo[1], bot_denovo[2], bot_denovo[3], false);
    draw_set_color(_hover ? _amarelo : _borda);
    draw_rectangle(bot_denovo[0], bot_denovo[1], bot_denovo[2], bot_denovo[3], true);
    oDia.texto(_gw / 2, (bot_denovo[1] + bot_denovo[3]) / 2 + 1, tr("fim_denovo"), 3, c_white, fa_center, fa_middle);
}
draw_set_alpha(1);
draw_set_color(c_white);
