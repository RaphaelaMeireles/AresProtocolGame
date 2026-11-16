// =====================================================================
// scr_animacao - animação de caminhada dos astronautas, gerada a partir do desenho parado
// =====================================================================
// Os sprites dos astronautas têm um quadro só. Na primeira vez que cada sprite é usado,
// criamos 4 quadros de caminhada mexendo nas pernas (o quarto de baixo do desenho):
//   quadro 0: parado (pés no chão)
//   quadro 1: perna esquerda levantada e um pouco à frente
//   quadro 2: parado
//   quadro 3: perna direita levantada e um pouco à frente
// Assim qualquer astronauta novo que a equipe desenhar já anda sozinho.
// Se um dia desenharem os quadros à mão, basta trocar o sprite gerado pelo desenhado.

global.anim_andar = {};

/// @function tripulante_frames_andar(sprite)
/// @description Sprite com 4 quadros de caminhada (criado uma vez e guardado)
function tripulante_frames_andar(_spr) {
    var _chave = sprite_get_name(_spr);
    var _pronto = global.anim_andar[$ _chave];
    if (_pronto != undefined && sprite_exists(_pronto)) return _pronto;

    var _w = sprite_get_width(_spr), _h = sprite_get_height(_spr);
    var _pernas = max(3, floor(_h * 0.25));   // altura das pernas
    var _topo   = _h - _pernas;               // onde as pernas começam
    var _meio   = floor(_w / 2);              // divide perna esquerda e direita

    var _surf = surface_create(_w, _h);
    var _novo = -1;
    gpu_set_texfilter(false);
    for (var f = 0; f < 4; f++) {
        var _esq = (f == 1) ? -2 : 0;         // perna esquerda sobe 2 px
        var _dir = (f == 3) ? -2 : 0;         // perna direita sobe 2 px
        surface_set_target(_surf);
        draw_clear_alpha(c_black, 0);
        // Corpo (sem as pernas); no meio do passo o corpo sobe 1 px
        draw_sprite_part(_spr, 0, 0, 0, _w, _topo, 0, (f == 1 || f == 3) ? -1 : 0);
        // Pernas: a levantada vai 1 px para a frente
        draw_sprite_part(_spr, 0, 0, _topo, _meio, _pernas, (f == 1) ? 1 : 0, _topo + _esq);
        draw_sprite_part(_spr, 0, _meio, _topo, _w - _meio, _pernas, _meio + ((f == 3) ? 1 : 0), _topo + _dir);
        surface_reset_target();

        if (f == 0) _novo = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
        else sprite_add_from_surface(_novo, _surf, 0, 0, _w, _h, false, false);
    }
    surface_free(_surf);

    global.anim_andar[$ _chave] = _novo;
    return _novo;
}

