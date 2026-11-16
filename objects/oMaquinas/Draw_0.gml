// --- Máquinas quebradas: mais escuras, piscando um alerta e soltando fumaça ---
for (var i = 0; i < array_length(global.maquinas); i++) {
    var _q = global.maquinas[i];
    if (!_q.quebrada) continue;
    var _el = _q.el;
    draw_sprite_ext(_q.spr, layer_sprite_get_index(_el), layer_sprite_get_x(_el), layer_sprite_get_y(_el),
                    layer_sprite_get_xscale(_el), layer_sprite_get_yscale(_el), 0, c_black, 0.35);
    var _pulso = 0.85 + 0.15 * sin(current_time / 120);
    emocao_desenhar_balao((_q.x1 + _q.x2) / 2, _q.y1 - 1, "exclamacao", _pulso);
}
for (var i = 0; i < array_length(fumacas); i++) {
    var _f = fumacas[i];
    if (_f.faisca && _f.t < 8) {
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(255, 230, 120));
        draw_rectangle(_f.x, _f.y, _f.x + 1, _f.y + 1, false);
    } else {
        draw_set_alpha(0.45 * (1 - _f.t / 70));
        draw_set_color(make_color_rgb(90, 90, 96));
        draw_circle(_f.x, _f.y, 1 + _f.t * 0.05, false);
    }
}
draw_set_alpha(1);

// --- Brilho na máquina embaixo do mouse ---
if (hover != undefined) {
    var _el = hover.el;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(hover.spr, layer_sprite_get_index(_el), layer_sprite_get_x(_el), layer_sprite_get_y(_el),
                    layer_sprite_get_xscale(_el), layer_sprite_get_yscale(_el), 0, c_white,
                    0.18 + 0.1 * sin(current_time / 150));
    gpu_set_blendmode(bm_normal);
}

// --- Textos do clique: sobem e somem (fonte de pixel do oDia, na escala da room) ---
if (instance_exists(oDia)) {
    for (var i = 0; i < array_length(popups); i++) {
        var _p = popups[i];
        var _a = (_p.t < 60) ? 1 : 1 - (_p.t - 60) / 30;
        oDia.texto(_p.x, _p.y - 4 - _p.t * 0.25, _p.texto, 1, _p.cor, fa_center, fa_bottom, _a, true);
    }
}
draw_set_alpha(1);
draw_set_color(c_white);


// --- Placa "Expedição" em cima da porta cinza do airlock (módulo de baixo, parede da direita) ---
// A porta fica em x 508-522, y 578-638 na arte de fundo (sprites/sPrincipal).
if (instance_exists(oDia)) {
    var _txt_porta = tr("porta_expedicao");
    var _px = 515, _py = 568;                       // centro do texto, logo acima da porta
    var _lt = oDia.texto_largura(_txt_porta, 1);
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(_px - _lt / 2 - 2, _py - 6, _px + _lt / 2 + 2, _py + 4, false);
    draw_set_alpha(1);
    oDia.texto(_px, _py - 1, _txt_porta, 1, make_color_rgb(255, 230, 120), fa_center, fa_middle);
    draw_set_color(c_white);
}
