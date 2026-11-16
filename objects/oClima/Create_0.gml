// =====================================================================
// oClima - o clima do dia depois do evento da noite
// =====================================================================
// Criado pelo oGameManager. Quando um novo dia começa, o evento da noite continua no céu:
//   tempestade/redemoinho de poeira -> névoa laranja (shader shClima, modo 1) + grãos voando
//   tempestade solar                -> aurora no céu (modo 2)
//   raios cósmicos / radiação UV    -> faíscas de radiação (modo 3)
//   chuva de meteoritos             -> meteoros riscando o céu e caindo lá fora, com tremida
// A força segue a intensidade do evento e diminui devagar durante o dia.

depth = -5000;   // Draw GUI antes do oDia (-10000): o clima fica por baixo das janelas
modo     = 0;       // 0 = céu limpo
forca    = 0;       // 0 a 1
evento   = "";
dia_visto = global.dia;
tempo    = 0;

// Partículas desenhadas por código (grãos de poeira e meteoros)
graos    = [];
meteoros = [];
tremida  = 0;       // frames de tremida da câmera (impacto de meteoro)

// O shader pode não existir em placas de vídeo muito antigas: sem ele, só as partículas aparecem
usa_shader = shader_is_compiled(shClima);
u_tempo = shader_get_uniform(shClima, "u_tempo");
u_modo  = shader_get_uniform(shClima, "u_modo");
u_forca = shader_get_uniform(shClima, "u_forca");
u_res   = shader_get_uniform(shClima, "u_res");

/// Liga o clima do evento (chamado quando o dia muda)
comecar = function(_evento, _intensidade) {
    evento = _evento;
    forca = 0.35 + 0.2 * _intensidade;      // fraca 0.55, média 0.75, forte 0.95
    switch (_evento) {
        case "tempestade_poeira":
        case "redemoinho_poeira": modo = 1; break;
        case "tempestade_solar":  modo = 2; break;
        case "raios_cosmicos":
        case "radiacao_uv":       modo = 3; break;
        case "chuva_meteoritos":  modo = 4; break;
        default:                  modo = 0;
    }
    global.ambiente.tempestade_poeira = (modo == 1);   // deixa expedições mais arriscadas
};
