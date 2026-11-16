// --- Efeito do raio gasto: brilho que some e uma tremidinha ---
// O raio da camada Status fica invisível durante o efeito; aqui desenhamos a versão animada
// na mesma posição e escala (já ajustadas pelo zoom no oMovementVisor).
var _cor_brilho = make_color_rgb(255, 230, 120);

for (var i = 0; i < array_length(raios); i++) {
    if (efeito_tempo[i] <= 0) continue;

    var _el = raios[i];
    var _sx = layer_sprite_get_xscale(_el);
    var _sy = layer_sprite_get_yscale(_el);
    var _w  = sprite_get_width(sRaioApagado)  * _sx;
    var _h  = sprite_get_height(sRaioApagado) * _sy;

    // t vai de 1 (início) a 0 (fim do efeito)
    var _t = efeito_tempo[i] / efeito_dur;

    // Tremidinha: vai e volta rápido, diminuindo até parar
    var _amp = 1.5 * _sx * _t;
    var _ox  = sin(efeito_tempo[i] * 1.7) * _amp;
    var _oy  = cos(efeito_tempo[i] * 2.3) * _amp * 0.5;
    var _x   = layer_sprite_get_x(_el) + _ox;
    var _y   = layer_sprite_get_y(_el) + _oy;

    // Halo de luz: maior e mais forte no começo, encolhe e some
    var _k  = 1 + 0.6 * _t;
    var _cx = _x + _w / 2;
    var _cy = _y + _h / 2;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(sRaioPreenchido, 0, _cx - _w * _k / 2, _cy - _h * _k / 2,
                    _sx * _k, _sy * _k, 0, _cor_brilho, 0.7 * _t);
    gpu_set_blendmode(bm_normal);

    // Raio: o apagado por baixo, e o preenchido por cima desaparecendo aos poucos
    draw_sprite_ext(sRaioApagado,    0, _x, _y, _sx, _sy, 0, c_white, 1);
    draw_sprite_ext(sRaioPreenchido, 0, _x, _y, _sx, _sy, 0, c_white, _t);

    // Clarão por cima, para o raio "acender" antes de apagar
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(sRaioPreenchido, 0, _x, _y, _sx, _sy, 0, c_white, 0.6 * _t);
    gpu_set_blendmode(bm_normal);
}
