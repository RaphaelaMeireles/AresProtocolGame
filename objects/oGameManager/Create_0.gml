// =====================================================================
// oGameManager - controlador principal da room
// =====================================================================
// Os status globais ficam em scr_status e os textos em scr_idioma.
// Este objeto monta a grade de caminhada, cria os outros controladores e cuida da tela cheia.

// --- Grade de caminhada: paredes, portas e móveis (scr_mapa) ---
// Precisa existir antes da tripulação e das máquinas.
// Placas solares retiradas da base (a energia vem só do Kilopower): somem da camada Maquinas
var _lay_maq = layer_get_id("Maquinas");
if (_lay_maq != -1) {
    var _els_maq = layer_get_all_elements(_lay_maq);
    for (var i = 0; i < array_length(_els_maq); i++) {
        if (layer_get_element_type(_els_maq[i]) == layerelementtype_sprite
            && layer_sprite_get_sprite(_els_maq[i]) == sPainelSolar) layer_sprite_destroy(_els_maq[i]);
    }
}

mapa_montar();
mapa_criar_portais();   // um oPortal em cada ponta dos tubos e corredores de ligação

// --- Controladores ---
instance_create_depth(0, 0, 0, oNasaAPI);       // comunicação com a NASA (HTTP e imagens)
instance_create_depth(0, 0, 0, oEventos);       // evento de cada noite e relatório da janela
instance_create_depth(0, 0, -16000, oHUD);      // raios, barras de status e efeitos
instance_create_depth(0, 0, -10000, oDia);      // dias, janela do dia, fade e rodapé
instance_create_depth(0, 0, -15000, oTripulacao); // cria a tripulação e as conversas
instance_create_depth(0, 0, -14000, oMaquinas); // clique nas máquinas (inclui o console)
instance_create_depth(0, 0, -11000, oExpedicao); // expedições pela porta do airlock
instance_create_depth(0, 0, -9000, oObjetivos);  // barra lateral da missão e tela final
instance_create_depth(0, 0, -12000, oEscolhas);  // imprevistos do dia com escolha
instance_create_depth(0, 0, -5000, oClima);      // clima do dia (poeira, aurora, meteoros)

// --- Música de fundo (pasta Sound) ---
// Toca em loop desde a abertura do jogo. A verificação evita tocar duas vezes por cima
// se a room for reiniciada. global.musica guarda a música tocando: o oDia usa a posição
// dela para sincronizar o fim da tela preta da abertura com a parte forte da música.
// O volume (global.volume_musica, em scr_config) muda no menu e no jogo com + e -.
if (!audio_is_playing(MusicaPrincipal)) {
    global.musica = audio_play_sound(MusicaPrincipal, 10, true, global.volume_musica);
}
