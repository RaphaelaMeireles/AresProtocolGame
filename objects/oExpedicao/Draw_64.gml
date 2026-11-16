// Janela de expedição e relatório da volta (fonte de pixel do oDia)
if (!instance_exists(oDia)) exit;
var _gw = display_get_gui_width(), _gh = display_get_gui_height();
var _painel  = make_color_rgb(24, 27, 34);
var _borda   = make_color_rgb(150, 155, 165);
var _amarelo = make_color_rgb(255, 230, 120);
var _suave   = make_color_rgb(150, 155, 165);
var _m = mouse_gui();

/// Desenha um botão e devolve se o mouse está em cima
var _botao = function(_r, _texto, _cor_texto, _m) {
    var _hover = point_in_rectangle(_m[0], _m[1], _r[0], _r[1], _r[2], _r[3]);
    draw_set_color(_hover ? make_color_rgb(80, 85, 95) : make_color_rgb(50, 54, 62));
    draw_rectangle(_r[0], _r[1], _r[2], _r[3], false);
    draw_set_color(_hover ? make_color_rgb(255, 230, 120) : make_color_rgb(150, 155, 165));
    draw_rectangle(_r[0], _r[1], _r[2], _r[3], true);
    oDia.texto((_r[0] + _r[2]) / 2, (_r[1] + _r[3]) / 2 + 1, _texto, 3, _cor_texto, fa_center, fa_middle);
};

/// Ícones dos materiais com quantidade ("2-3"), em linha; devolve a largura usada
var _icones = function(_x, _y, _coleta) {
    var _px = _x;
    for (var i = 0; i < array_length(global.materiais); i++) {
        var _mat = global.materiais[i];
        var _v = _coleta[$ _mat];
        if (_v == undefined) continue;
        var _txt = is_array(_v) ? ((_v[0] == _v[1]) ? string(_v[0]) : string(_v[0]) + "-" + string(_v[1])) : string(_v);
        if (is_array(_v) && _v[1] <= 0) continue;
        gpu_set_texfilter(false);
        draw_sprite_ext(emocao_sprite(global.materiais_icone[$ _mat]), 0, _px, _y, 3, 3, 0, c_white, 1);
        oDia.texto(_px + 26, _y + 3, _txt, 2, c_white, fa_left, fa_top);
        _px += 26 + oDia.texto_largura(_txt, 2) + 18;
    }
    return _px - _x;
};

// ===================================================================== janela de escolha
if (aberta) {
    draw_set_alpha(0.6); draw_set_color(c_black); draw_rectangle(0, 0, _gw, _gh, false); draw_set_alpha(1);
    draw_set_color(_painel); draw_rectangle(jan_x1, jan_y1, jan_x2, jan_y2, false);
    draw_set_color(_borda);  draw_rectangle(jan_x1, jan_y1, jan_x2, jan_y2, true);
    draw_rectangle(jan_x1 + 4, jan_y1 + 4, jan_x2 - 4, jan_y2 - 4, true);

    oDia.texto((jan_x1 + jan_x2) / 2, jan_y1 + 28, tr("exp_titulo"), 5, _amarelo, fa_center, fa_top);
    oDia.texto((jan_x1 + jan_x2) / 2, jan_y1 + 72, tr("exp_subtitulo"), 2, _suave, fa_center, fa_top);

    // Lista de destinos
    for (var i = 0; i < array_length(global.destinos); i++) {
        var _d = global.destinos[i];
        var _y1 = linha_y0 + i * linha_h;
        var _sel = (i == escolhido);
        var _hover = point_in_rectangle(_m[0], _m[1], jan_x1 + 40, _y1, jan_x2 - 40, _y1 + linha_h - 8);
        draw_set_color(_sel ? make_color_rgb(70, 62, 40) : (_hover ? make_color_rgb(44, 48, 58) : make_color_rgb(34, 37, 46)));
        draw_rectangle(jan_x1 + 40, _y1, jan_x2 - 40, _y1 + linha_h - 8, false);
        if (_sel) { draw_set_color(_amarelo); draw_rectangle(jan_x1 + 40, _y1, jan_x2 - 40, _y1 + linha_h - 8, true); }

        oDia.texto(jan_x1 + 60, _y1 + 10, tr("exp_" + _d.id + "_nome"), 3, _sel ? _amarelo : c_white, fa_left, fa_top);
        // dias e risco
        var _nv = global.expedicao_niveis[$ _d.nivel];
        var _cor_risco = make_color_rgb(_nv.cor[0], _nv.cor[1], _nv.cor[2]);
        oDia.texto(jan_x1 + 60, _y1 + 36, (_d.dias == 1) ? tr("exp_dias_um") : tr("exp_dias", _d.dias), 2, _suave, fa_left, fa_top);
        oDia.texto(jan_x1 + 200, _y1 + 36, tr(_nv.texto), 2, _cor_risco, fa_left, fa_top);
        // custo em pontos de ação (pelo risco)
        oDia.texto(jan_x1 + 350, _y1 + 36, tr("exp_custo_curto", _nv.custo), 2, _amarelo, fa_left, fa_top);
        // o que pode trazer
        _icones(jan_x1 + 560, _y1 + 16, _d.coleta);
    }

    // Explicação do destino escolhido (para crianças)
    var _d = global.destinos[escolhido];
    var _y_desc = linha_y0 + array_length(global.destinos) * linha_h + 6;
    var _desc = oDia.texto_quebrar(tr("exp_" + _d.id + "_texto"), 2, jan_w - 80);
    oDia.texto(jan_x1 + 40, _y_desc, _desc, 2, c_white, fa_left, fa_top, 1, false, 4);
    // Fonte dos dados dos lugares (missão Mars 2020 / Perseverance da NASA)
    var _fonte_exp = oDia.texto_quebrar(tr("exp_fonte"), 2, jan_w - 80);
    oDia.texto(jan_x1 + 40, _y_desc + oDia.texto_altura(_desc, 2, 4) + 12, _fonte_exp, 2, _suave, fa_left, fa_top, 1, false, 4);

    // Quem vai e botões
    var _porta = maquina_por_tipo("expedicao");
    var _t = (_porta != undefined) ? tripulante_disponivel(_porta.uso_x, _porta.uso_y) : noone;
    var _custo_sel = expedicao_custo(_d);
    var _pode = (_t != noone && global.raios >= _custo_sel);
    var _info = (_t == noone) ? tr("exp_sem_tripulante") : ((global.raios < _custo_sel) ? tr("maq_sem_raios") : tr("exp_quem_vai", _t.nome));
    oDia.texto(jan_x1 + 40, bot_ir[1] + 16, _info, 2, _pode ? _amarelo : make_color_rgb(255, 110, 100), fa_left, fa_top);
    _botao(bot_voltar, tr("exp_cancelar"), c_white, _m);
    _botao(bot_ir, tr("exp_ir"), _pode ? make_color_rgb(140, 235, 140) : _suave, _m);
}

// ===================================================================== relatório da volta
if (relatorio != undefined && relatorio_visivel) {
    var _r = relatorio.res;
    var _w = 760, _h = 330;
    var _x1 = (_gw - _w) / 2, _y1 = (_gh - _h) / 2;
    draw_set_alpha(0.6); draw_set_color(c_black); draw_rectangle(0, 0, _gw, _gh, false); draw_set_alpha(1);
    draw_set_color(_painel); draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, false);
    draw_set_color(_borda);  draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, true);

    var _cor_tit = (_r.resultado == "sucesso") ? make_color_rgb(140, 235, 140) : ((_r.resultado == "parcial") ? _amarelo : make_color_rgb(255, 110, 100));
    oDia.texto(_x1 + _w / 2, _y1 + 28, tr("exp_res_" + _r.resultado), 4, _cor_tit, fa_center, fa_top);
    var _linha = tr("exp_voltou", relatorio.nome, tr("exp_" + relatorio.destino.id + "_nome"));
    oDia.texto(_x1 + _w / 2, _y1 + 80, oDia.texto_quebrar(_linha, 2, _w - 60), 2, c_white, fa_center, fa_top, 1, false, 4);

    var _mats = variable_struct_get_names(_r.coleta);
    if (array_length(_mats) > 0) {
        oDia.texto(_x1 + 40, _y1 + 136, tr("exp_trouxe"), 2, _suave, fa_left, fa_top);
        _icones(_x1 + 40, _y1 + 164, _r.coleta);
    } else {
        oDia.texto(_x1 + 40, _y1 + 136, tr("exp_nada"), 2, _suave, fa_left, fa_top);
    }
    if (_r.ferido) oDia.texto(_x1 + 40, _y1 + 210, tr("exp_ferido"), 2, make_color_rgb(255, 110, 100), fa_left, fa_top);

    bot_ok = [_gw / 2 - 100, _y1 + _h - 74, _gw / 2 + 100, _y1 + _h - 26];
    _botao(bot_ok, tr("modal_ok"), c_white, _m);
}
draw_set_alpha(1);
draw_set_color(c_white);
