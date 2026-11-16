if (!instance_exists(oDia)) exit;
// Missão acabou (tela final): fecha a janela, se estiver aberta
if (global.fim_missao != "") {
    if (estado != "esperando") { estado = "esperando"; evento = undefined; }
    fila = [];
    exit;
}

// --- Novo dia: monta a fila de imprevistos do dia (clima, manutenção e expedição).
// Todos aparecem no início do dia, um depois do outro, assim que a janela do dia fecha.
if (global.dia != dia_visto && oDia.estado == "jogando") {
    dia_visto = global.dia;
    fila = escolhas_do_dia();
}

switch (estado) {
    case "esperando":
        if (array_length(fila) > 0 && oDia.estado == "jogando" && !global.ui_bloqueada) {
            var _ev = fila[0];
            array_delete(fila, 0, 1);
            abrir(_ev);
        }
        break;

    case "escolhendo":
        global.ui_bloqueada = true;
        var _m = mouse_gui();
        if (mouse_check_button_pressed(mb_left)) {
            if (point_in_rectangle(_m[0], _m[1], bot1[0], bot1[1], bot1[2], bot1[3])) escolher(1);
            else if (point_in_rectangle(_m[0], _m[1], bot2[0], bot2[1], bot2[2], bot2[3])) escolher(2);
        }
        if (keyboard_check_pressed(ord("1"))) escolher(1);
        if (keyboard_check_pressed(ord("2"))) escolher(2);
        break;

    case "resultado":
        global.ui_bloqueada = true;
        var _m = mouse_gui();
        if ((mouse_check_button_pressed(mb_left) && point_in_rectangle(_m[0], _m[1], bot_ok[0], bot_ok[1], bot_ok[2], bot_ok[3]))
            || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
            fechar();
        }
        break;
}
