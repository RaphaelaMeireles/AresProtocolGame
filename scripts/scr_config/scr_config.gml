// =====================================================================
// scr_config - configuração da integração com a NASA
// =====================================================================
// Tudo que é endereço, chave ou limite de tempo fica aqui, em um lugar só.
//
// ATENÇÃO: a chave abaixo vai junto no jogo exportado. Na versão para navegador (HTML5)
// qualquer pessoa consegue vê-la. Para o hackathon isso é aceitável (a chave é gratuita e
// só dá acesso a dados públicos); para publicar de verdade, o ideal é um servidor
// intermediário que guarde a chave.

#macro NASA_CHAVE         "6RRwbNRRczhbJpdnrKT9NJzWPmLHJjFmb6dqNpNk"
#macro NASA_API           "https://api.nasa.gov"            // DONKI, InSight, APOD (usam a chave)
#macro NASA_IMAGENS_API   "https://images-api.nasa.gov"     // biblioteca de imagens (não usa chave)

// Fotos da biblioteca: o endereço normal (images-assets.nasa.gov) não autoriza o navegador (CORS),
// então na versão web (GX.games/HTML5) a foto não carregaria. O mesmo arquivo, no armazenamento
// oficial da NASA na Amazon, autoriza. O oNasaAPI troca o endereço quando precisa.
#macro NASA_FOTOS_HOST       "images-assets.nasa.gov/"
#macro NASA_FOTOS_HOST_WEB   "https://s3.amazonaws.com/images-assets.nasa.gov/"

// Ferramenta da equipe: true = a tecla F2 mostra a grade de caminhada (verde) e os portais.
// Deixe false no jogo de verdade: o jogador nunca vê a grade.
#macro MAPA_DEBUG false

#macro NASA_ONLINE        true    // false = joga sem internet (usa só os textos do jogo)
#macro NASA_TEMPO_LIMITE  480     // frames esperando a NASA (8 s) antes de seguir sem os dados
#macro NASA_DIAS_DONKI    30      // quantos dias para trás buscar eventos de clima espacial

// Sorteios diferentes a cada vez que o jogo abre (sem isso, o GameMaker repete a mesma sequência)
randomize();

// Volume da música: 0 = mudo, 1 = máximo. Muda no menu e no jogo com + e - (passos de 10%).
global.volume_musica = 0.6;

/// @function musica_ajustar_volume(delta)
/// @description Soma _delta ao volume da música (limitado entre 0 e 1) e aplica na música que está tocando
function musica_ajustar_volume(_delta) {
    global.volume_musica = clamp(round((global.volume_musica + _delta) * 10) / 10, 0, 1);
    if (variable_global_exists("musica") && audio_is_playing(global.musica)) {
        audio_sound_gain(global.musica, global.volume_musica, 0);
    }
    return global.volume_musica;
}
