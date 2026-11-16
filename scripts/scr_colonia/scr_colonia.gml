// =====================================================================
// scr_colonia - recursos da colônia (ECLSS e energia) e ciclo de cada Sol
// =====================================================================
// Baseado na proposta do João (obj_game_manager / execute_sol_tick), adaptado ao jogo:
// - o dia (Sol) não passa por tempo; ele muda quando os raios de energia acabam (oDia),
//   e é nessa troca que colonia_ciclo_sol() roda;
// - os nomes seguem o padrão em português do projeto.
//
// Não confundir: global.energia é a barra de energia da base (scr_status);
// global.colonia.geracao_energia_kw é quanta eletricidade a base gera.

/// @function colonia_iniciar()
/// @description Valores iniciais da colônia e do ambiente (início ou reinício do jogo)
function colonia_iniciar() {
    global.tripulacao = 4;    // astronautas na base

    global.colonia = {
        oxigenio: 100.0,            // %
        agua: 100.0,                // litros
        comida: 100.0,              // kg de biomassa
        geracao_energia_kw: 50.0    // kW gerados
    };

    global.ambiente = {
        tempestade_poeira: false,
        indice_radiacao: 0.1,       // mSv por Sol
        multiplicador_solar: 1.0    // cai para 0.2 durante tempestades de poeira
    };
}
colonia_iniciar();

/// @function colonia_ciclo_sol()
/// @description Consumo da tripulação e produção de energia de um Sol. Roda na troca de dia.
function colonia_ciclo_sol() {
    var _tripulacao = global.tripulacao;
    var _c = global.colonia;

    // Consumo básico (ECLSS)
    _c.oxigenio -= _tripulacao * 2.5;
    _c.agua     -= _tripulacao * 3.0;
    _c.comida   -= _tripulacao * 1.5;

    // Produção de energia: painéis solares (afetados pela poeira) + reator de fissão fixo
    var _solar  = 20 * global.ambiente.multiplicador_solar;
    var _fissao = 40;
    _c.geracao_energia_kw = _solar + _fissao;

    // Limites de segurança
    _c.oxigenio = clamp(_c.oxigenio, 0, 100);
    _c.agua     = clamp(_c.agua, 0, 100);
    _c.comida   = clamp(_c.comida, 0, 100);

    // TODO (João): checagens de falta de recursos - a mensagem original chegou cortada
}
