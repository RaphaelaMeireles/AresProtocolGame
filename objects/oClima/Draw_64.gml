// --- Efeito por cima da tela (shader shClima): poeira, aurora ou radiação ---
if (modo >= 1 && modo <= 3 && forca > 0 && usa_shader) {
    var _gw = display_get_gui_width(), _gh = display_get_gui_height();
    shader_set(shClima);
    shader_set_uniform_f(u_tempo, tempo);
    shader_set_uniform_f(u_modo, modo);
    shader_set_uniform_f(u_forca, forca);
    shader_set_uniform_f(u_res, _gw, _gh);
    draw_rectangle(0, 0, _gw, _gh, false);
    shader_reset();
}
