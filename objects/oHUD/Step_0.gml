// --- Efeito ao gastar um raio: inicia nos raios que acabaram de apagar ---
if (global.raios < raios_anterior) {
    for (var i = global.raios; i < raios_anterior; i++) {
        if (i < array_length(efeito_tempo)) efeito_tempo[i] = efeito_dur;
    }
}
raios_anterior = global.raios;

// Atualiza os raios da camada Status: preenchidos até o valor atual, o resto apagado.
// Durante o efeito, o raio da camada fica invisível e o Draw desenha a versão animada.
efeito_rodando = false;
for (var i = 0; i < array_length(raios); i++) {
    layer_sprite_change(raios[i], (i < global.raios) ? sRaioPreenchido : sRaioApagado);

    if (efeito_tempo[i] > 0) efeito_tempo[i]--;
    if (efeito_tempo[i] > 0) efeito_rodando = true;
    layer_sprite_alpha(raios[i], (efeito_tempo[i] > 0) ? 0 : 1);
}

// Barras de status: mostra o quadro que corresponde ao valor de global.vida/energia/comida/escudo.
// Com o card de evento aberto, as barras daqui somem: o card desenha as dele por cima (oEscolhas).
var _card_aberto = instance_exists(oEscolhas) && oEscolhas.estado != "esperando";
for (var b = 0; b < array_length(barras); b++) {
    var _barra = barras[b];
    var _valor = variable_global_get(_barra.status);
    var _max   = variable_global_get(_barra.status + "_max");
    layer_sprite_index(_barra.el, quadro_da_barra(_barra.spr, _valor, _max));
    layer_sprite_alpha(_barra.el, _card_aberto ? 0 : 1);
}
