// Com a janela do dia aberta ou durante a troca de dia, a câmera não responde ao jogador
var _bloq = global.ui_bloqueada;   // definida em scr_status, controlada pelo oDia

// --- Zoom: Ctrl + roda do mouse ---
if (_bloq) {
    // nada: entrada da câmera bloqueada
}
else if (keyboard_check(vk_control)) {
    var _roda = mouse_wheel_down() - mouse_wheel_up();     // +1 afasta, -1 aproxima
    if (_roda != 0) {
        var _novo_w = clamp(cam_w * power(zoom_passo, _roda), zoom_min_w, zoom_max_w);
        var _novo_h = _novo_w * proporcao;

        // Onde o ponteiro está na tela do jogo, de 0 a 1 em cada eixo (scr_mouse)
        var _f  = mouse_fracao_tela();
        var _fx = clamp(_f[0], 0, 1);
        var _fy = clamp(_f[1], 0, 1);

        // Ponto da room que está embaixo do ponteiro antes do zoom
        var _px = cam_x + _fx * cam_w;
        var _py = cam_y + _fy * cam_h;

        // Novo tamanho, e posição que mantém esse ponto embaixo do ponteiro
        cam_w = _novo_w;
        cam_h = _novo_h;
        cam_x = _px - _fx * cam_w;
        cam_y = _py - _fy * cam_h;
        camera_set_view_size(cam, cam_w, cam_h);
    }
}
// --- Rolagem horizontal: Shift + roda do mouse (só quando o Ctrl não está apertado) ---
else if (keyboard_check(vk_shift)) {
    var _roda_h = mouse_wheel_down() - mouse_wheel_up();   // +1 vai para a direita, -1 para a esquerda
    if (_roda_h != 0) {
        cam_x += _roda_h * cam_w * rolagem_passo;          // o limite da room é aplicado logo abaixo
    }
}
// --- Rolagem vertical: só a roda do mouse (sem Ctrl e sem Shift) ---
else {
    var _roda_v = mouse_wheel_down() - mouse_wheel_up();   // +1 desce, -1 sobe
    if (_roda_v != 0) {
        cam_y += _roda_v * cam_h * rolagem_passo;          // o limite da room é aplicado logo abaixo
    }
}

// --- Movimento: setas ou WASD (-1, 0 ou 1 em cada eixo) ---
var _dx = (keyboard_check(vk_right) + keyboard_check(ord("D"))
         - keyboard_check(vk_left)  - keyboard_check(ord("A"))) * !_bloq;
var _dy = (keyboard_check(vk_down)  + keyboard_check(ord("S"))
         - keyboard_check(vk_up)    - keyboard_check(ord("W"))) * !_bloq;

// Nova posição da câmera, limitada às bordas da room
cam_x = clamp(cam_x + _dx * vel, 0, room_width  - cam_w);
cam_y = clamp(cam_y + _dy * vel, 0, room_height - cam_h);

camera_set_view_pos(cam, cam_x, cam_y);

// Nomes usados pelo bloco da camada Status abaixo
var _x = cam_x;
var _y = cam_y;

// --- Camada Status fixa na tela, mesmo com movimento e zoom ---
if (layer_status != -1) {
    // Primeira vez: guarda posição e escala de cada sprite como foi montado no editor
    if (!status_pronto) {
        var _els = layer_get_all_elements(layer_status);
        for (var i = 0; i < array_length(_els); i++) {
            var _el = _els[i];
            if (layer_get_element_type(_el) == layerelementtype_sprite) {
                array_push(status_itens, {
                    el: _el,
                    x0: layer_sprite_get_x(_el),
                    y0: layer_sprite_get_y(_el),
                    sx: layer_sprite_get_xscale(_el),
                    sy: layer_sprite_get_yscale(_el)
                });
            }
        }
        status_pronto = true;
    }

    // Reposiciona e reescala cada sprite na proporção do zoom atual
    var _f = cam_w / cam_w0;
    for (var i = 0; i < array_length(status_itens); i++) {
        var _it = status_itens[i];
        layer_sprite_x(_it.el, _x + (_it.x0 - cam_x0) * _f);
        layer_sprite_y(_it.el, _y + (_it.y0 - cam_y0) * _f);
        layer_sprite_xscale(_it.el, _it.sx * _f);
        layer_sprite_yscale(_it.el, _it.sy * _f);
    }
}
