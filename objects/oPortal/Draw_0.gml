// O primeiro portal também desenha o cenário do chão (cabo do Kilopower e rampa do rover),
// porque fica na profundidade certa: em cima do fundo e embaixo das máquinas e do rover.
//if (id == instance_find(oPortal, 0)) mapa_desenhar_cenario();

// F2 (mesma tecla da grade de caminhada): mostra o portal e a ligação com o par
if (instance_exists(oTripulacao) && oTripulacao.mostrar_grade) {
    draw_set_color(c_aqua);
    draw_circle(x, y, 6, true);
    if (instance_exists(par)) draw_line(x, y, par.x, par.y);
}
draw_set_color(c_white);
