// Poeira levantada pelas rodas do rover
for (var i = 0; i < array_length(poeira_rover); i++) {
    var _p = poeira_rover[i];
    draw_set_alpha(0.5 * (1 - _p.t / 40));
    draw_set_color(make_color_rgb(205, 140, 90));
    draw_circle(_p.x, _p.y - _p.t * 0.15, 1 + _p.t * 0.08, false);
}
draw_set_alpha(1);
draw_set_color(c_white);
