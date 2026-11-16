// =====================================================================
// scr_mouse - posição do ponteiro em cada sistema de coordenadas
// =====================================================================
// Todo o jogo pergunta a posição do mouse por aqui (botão OK, console, foco do zoom),
// então a diferença entre Windows e navegador fica resolvida em um lugar só.
//
// - Windows: lê o ponteiro direto da janela, descontando as faixas pretas de quando a janela
//   não está em 16:9 (mouse_x/mouse_y não estavam confiáveis com a câmera).
// - Navegador (GX.games/HTML5): a página amplia o jogo por conta própria, e a posição da janela
//   não bate com a área desenhada. Por isso usa a conversão do próprio GameMaker para a GUI
//   (device_mouse_x_to_gui), que já considera essa ampliação.

/// @function mouse_no_navegador()
/// @description true quando o jogo está rodando dentro de um navegador
function mouse_no_navegador() {
    return os_browser != browser_not_a_browser || os_type == os_gxgames;
}

/// @function mouse_fracao_tela()
/// @description Onde o ponteiro está na imagem do jogo, de 0 a 1 em cada eixo: [fx, fy].
function mouse_fracao_tela() {
    if (mouse_no_navegador()) {
        return [
            device_mouse_x_to_gui(0) / display_get_gui_width(),
            device_mouse_y_to_gui(0) / display_get_gui_height()
        ];
    }
    var _area = application_get_position();      // [x1, y1, x2, y2] da imagem do jogo na janela
    return [
        (window_mouse_get_x() - _area[0]) / (_area[2] - _area[0]),
        (window_mouse_get_y() - _area[1]) / (_area[3] - _area[1])
    ];
}

/// @function mouse_gui()
/// @description Ponteiro em coordenadas da GUI (Draw GUI): [x, y].
function mouse_gui() {
    if (mouse_no_navegador()) return [device_mouse_x_to_gui(0), device_mouse_y_to_gui(0)];
    var _f = mouse_fracao_tela();
    return [_f[0] * display_get_gui_width(), _f[1] * display_get_gui_height()];
}

/// @function mouse_room()
/// @description Ponteiro em coordenadas da room, pela câmera da view 0: [x, y].
function mouse_room() {
    var _f   = mouse_fracao_tela();
    var _cam = view_camera[0];
    return [
        camera_get_view_x(_cam) + _f[0] * camera_get_view_width(_cam),
        camera_get_view_y(_cam) + _f[1] * camera_get_view_height(_cam)
    ];
}
