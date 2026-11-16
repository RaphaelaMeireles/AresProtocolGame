// Pixel art nítida
gpu_set_texfilter(false);

// --- Dormindo: deitado em cima da cama, com Zzz ---
var _dormindo = (estado == "usando" && alvo_maquina != undefined && alvo_maquina.def.chave == "cama");
if (_dormindo) {
    var _cx = (alvo_maquina.x1 + alvo_maquina.x2) / 2;
    var _cy = (alvo_maquina.y1 + alvo_maquina.y2) / 2;
    var _resp = sin(anim) * 0.5;   // respiração
    draw_sprite_ext(sprite_index, 0, round(_cx - h / 2), round(_cy + w / 2 + _resp), escala, escala, 90, c_white, 1);
    if (emocao_pop > 0) emocao_desenhar_balao(_cx + 4, _cy - h / 2 + 4, "zzz", emocao_pop);
    exit;
}

// Sombra nos pés
draw_set_alpha(0.25 * alpha_corpo);
draw_set_color(c_black);
draw_ellipse(x - w * 0.4, y - 2, x + w * 0.4, y + 2, false);
draw_set_alpha(1);

// Corpo: andando usa os 4 quadros de caminhada; parado "respira"; usando a máquina, trabalha
var _quique  = andando ? abs(sin(passo * pi / 2)) * 1 : 0;
var _esticar = andando ? 1 : 1 + sin(anim) * 0.02;
if (estado == "usando") _quique = abs(sin(anim * 2)) * 1;   // mexendo na máquina
_quique += pulo;
var _quadro = andando ? floor(passo) mod 4 : 0;
draw_sprite_ext(spr_andar, _quadro,
                round(x - (w / 2) * virado), round(y - h * _esticar - _quique),
                virado * escala, _esticar * escala, 0, c_white, alpha_corpo);

// Balão de emoção em cima da cabeça
if (emocao_pop > 0 && emocao != "") {
    emocao_desenhar_balao(x, y - h - _quique - 2, emocao, emocao_pop);
}

draw_set_color(c_white);
