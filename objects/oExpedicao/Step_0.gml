var _m = mouse_gui();
var _clique = mouse_check_button_pressed(mb_left);

// --- Janela de escolha do destino ---
if (aberta) {
    // Clique numa linha escolhe o destino; setas também
    for (var i = 0; i < array_length(global.destinos); i++) {
        var _y1 = linha_y0 + i * linha_h;
        if (_clique && point_in_rectangle(_m[0], _m[1], jan_x1 + 40, _y1, jan_x2 - 40, _y1 + linha_h - 8)) escolhido = i;
    }
    if (keyboard_check_pressed(vk_down)) escolhido = (escolhido + 1) mod array_length(global.destinos);
    if (keyboard_check_pressed(vk_up))   escolhido = (escolhido - 1 + array_length(global.destinos)) mod array_length(global.destinos);

    if (_clique && point_in_rectangle(_m[0], _m[1], bot_ir[0], bot_ir[1], bot_ir[2], bot_ir[3])) partir();
    else if ((_clique && point_in_rectangle(_m[0], _m[1], bot_voltar[0], bot_voltar[1], bot_voltar[2], bot_voltar[3]))
             || keyboard_check_pressed(vk_escape)) fechar();
}

// --- Relatório da volta: aparece quando o dia já começou e os imprevistos do dia terminaram ---
// (assim o evento da expedição aparece antes de o tripulante voltar)
var _eventos_livres = !instance_exists(oEscolhas)
    || (oEscolhas.dia_visto == global.dia && oEscolhas.estado == "esperando" && array_length(oEscolhas.fila) == 0);
if (relatorio != undefined && !relatorio_visivel && instance_exists(oDia) && oDia.estado == "jogando"
    && !aberta && _eventos_livres && !global.ui_bloqueada) {
    relatorio_visivel = true;
    if (!relatorio.aplicado) voltar_agora();   // agora o tripulante entra pela porta com os recursos
}
if (relatorio == undefined) relatorio_visivel = false;
if (relatorio_visivel) {
    global.ui_bloqueada = true;
    if ((_clique && point_in_rectangle(_m[0], _m[1], bot_ok[0], bot_ok[1], bot_ok[2], bot_ok[3]))
        || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
        relatorio = undefined;
        relatorio_visivel = false;
        global.ui_bloqueada = false;
    }
}

// --- Rover: sai dirigindo quando o astronauta está fora e volta para casa depois ---
if (rover_el != -1) {
    var _fora = (missao != undefined && instance_exists(missao.tripulante) && missao.tripulante.estado == "fora");
    var _alvo = _fora ? room_width + 80 : rover_casa;
    var _vx = clamp(_alvo - rover_x, -1.4, 1.4);
    rover_x += _vx;
    if (abs(_vx) > 0.1 && random(1) < 0.5) {
        array_push(poeira_rover, { x: rover_x + ((_vx > 0) ? 0 : rover_w), y: layer_sprite_get_y(rover_el) + 22, t: 0 });
    }
    // Indo para a esquerda (voltando), o desenho é espelhado para o rover ficar de frente
    var _esquerda = (_vx < -0.1);
    layer_sprite_xscale(rover_el, _esquerda ? -1 : 1);
    layer_sprite_x(rover_el, _esquerda ? rover_x + rover_w : rover_x);
    // Rampa na borda do mapa: sobe pela frente do rover, inclinado enquanto está nela
    var _frente = rover_x + rover_w * 0.75;
    var _sobe = rampa_altura(_frente);
    layer_sprite_y(rover_el, rover_y0 - _sobe);
    var _na_rampa = (_frente > RAMPA_X1 && rover_x < RAMPA_X2);
    layer_sprite_angle(rover_el, _na_rampa ? 11 : 0);
}
for (var i = array_length(poeira_rover) - 1; i >= 0; i--) {
    poeira_rover[i].t += 1;
    if (poeira_rover[i].t > 40) array_delete(poeira_rover, i, 1);
}
