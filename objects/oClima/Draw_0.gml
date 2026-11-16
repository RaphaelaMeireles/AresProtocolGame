// --- Grãos de poeira (na room) ---
if (modo == 1) {
    draw_set_color(make_color_rgb(225, 150, 95));
    for (var i = 0; i < array_length(graos); i++) {
        draw_set_alpha(0.6 * forca);
        draw_rectangle(graos[i].x, graos[i].y, graos[i].x + 1, graos[i].y, false);
    }
}

// --- Meteoros: rastro brilhante, e no impacto uma nuvem de poeira que se espalha ---
for (var i = 0; i < array_length(meteoros); i++) {
    var _m = meteoros[i];
    if (_m.impacto == 0) {
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(255, 210, 120));
        draw_line_width(_m.x - 9, _m.y - 14, _m.x, _m.y, 2);
        draw_set_color(c_white);
        draw_rectangle(_m.x - 1, _m.y - 1, _m.x + 1, _m.y + 1, false);
    } else {
        var _r = 3 + _m.impacto * 0.4;
        draw_set_alpha(max(0, 0.7 - _m.impacto / 45));
        draw_set_color(make_color_rgb(190, 110, 60));
        draw_circle(_m.ax, _m.ay, _r, false);
        if (_m.impacto < 6) {
            draw_set_color(make_color_rgb(255, 230, 160));
            draw_circle(_m.ax, _m.ay, 3, false);
        }
    }
}
draw_set_alpha(1);
draw_set_color(c_white);
