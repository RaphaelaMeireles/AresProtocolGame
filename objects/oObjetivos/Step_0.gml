
// Botão [-] / [+] da barra lateral: minimiza ou mostra
if (aberta && global.fim_missao == "" && !global.ui_bloqueada && mouse_check_button_pressed(mb_left)) {
    var _mo = mouse_gui();
    var _gw_o = display_get_gui_width();
    if (minimizada) {
        // Botão "!" (36 x 36) abre a missão
        if (is_array(card_rect) && point_in_rectangle(_mo[0], _mo[1], card_rect[0], card_rect[1], card_rect[2], card_rect[3])) minimizada = false;
    } else if (point_in_rectangle(_mo[0], _mo[1], _gw_o - 46, 106, _gw_o - 22, 130)) {
        // Botão [-] ao lado do título recolhe a missão no botão "!"
        minimizada = true;
    }
}

// Tela final: botão "jogar de novo" (ou Enter)
if (global.fim_missao != "") {
    var _m = mouse_gui();
    if ((mouse_check_button_pressed(mb_left) && point_in_rectangle(_m[0], _m[1], bot_denovo[0], bot_denovo[1], bot_denovo[2], bot_denovo[3]))
        || keyboard_check_pressed(vk_enter)) {
        jogo_reiniciar();
    }
}
