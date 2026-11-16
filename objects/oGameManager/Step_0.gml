
//Opção de colcoar o jogo em tela cheia
if (keyboard_check_pressed(vk_f11)) {
    window_set_fullscreen(!window_get_fullscreen());
}

if (mouse_check_button_pressed(mb_left)) {
    var _bx = room_width - 60;
    if (point_in_rectangle(mouse_x, mouse_y, _bx, 10, room_width - 10, 50)) {
        window_set_fullscreen(!window_get_fullscreen());
    }
}

// O jogador só interage com o posto quando a janela do dia está fechada e não há troca de dia.
// (O clique nas máquinas, inclusive no console, agora fica no oMaquinas.)
if (!global.ui_bloqueada) {
    // TESTE: E gasta um raio, R recupera (remover quando a lógica real existir)
    if (keyboard_check_pressed(ord("E"))) global.raios = max(0, global.raios - 1);
    if (keyboard_check_pressed(ord("R"))) global.raios = min(global.raios_max, global.raios + 1);

    // TESTE: V perde vida, B recupera (remover quando a lógica real existir)
    if (keyboard_check_pressed(ord("V"))) global.vida = max(0, global.vida - 1);
    if (keyboard_check_pressed(ord("B"))) global.vida = min(global.vida_max, global.vida + 1);
}
