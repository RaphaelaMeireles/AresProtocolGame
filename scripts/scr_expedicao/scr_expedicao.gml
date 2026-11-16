// =====================================================================
// scr_expedicao - destinos das expedições (as "trajetórias" da missão)
// =====================================================================
// Os destinos são lugares reais da Cratera Jezero, onde o robô Perseverance da NASA explora:
//   dunas   areia e poeira perto da base (rápido e seguro)
//   maaz    planície de lava "Máaz", rocha basáltica rica em ferro
//   delta   o antigo delta do rio da cratera: sedimentos e argilas com silício
//   seitah  "Séítah": rochas de olivina, mineral feito de magnésio, ferro e silício
//   borda   a borda da cratera: rochas antigas, mas o caminho é perigoso
// Cada destino tem:
//   dias      quantos dias o astronauta fica fora (volta no começo do dia de retorno)
//   nivel     risco: "baixo", "medio" ou "alto" (define o custo em pontos de ação)
//   coleta    materiais que sempre traz: [mínimo, máximo] de cada um
// Textos em scr_idioma: exp_<id>_nome e exp_<id>_texto.

#macro EXPEDICAO_CUSTO_RAIOS 2   // (antigo, não usado: o custo agora vem do nível de risco)

// Nível de risco de cada destino: quanto custa sair e o que sempre traz de volta
//   baixo  1 ponto de ação  -> 2 materiais diferentes, 1 a 2 de cada
//   medio  2 pontos de ação -> 3 materiais diferentes, 2 a 4 de cada
//   alto   3 pontos de ação -> todos os 5 materiais, 3 de cada
// A expedição sempre dá certo: o risco decide o custo e o tamanho da coleta.
global.expedicao_niveis = {
    baixo: { custo: 1, texto: "exp_risco_baixo", cor: [120, 220, 120] },
    medio: { custo: 2, texto: "exp_risco_medio", cor: [255, 180, 70] },
    alto:  { custo: 3, texto: "exp_risco_alto",  cor: [255, 90, 80] }
};

// Lugares reais da Cratera Jezero, explorados pelo robô Perseverance da NASA (desde 2021).
// Cada lugar tem um risco (pela distância e pelo terreno) e os recursos que a NASA encontrou ali:
//   recursos  materiais que podem vir desse lugar (a cada dia alguns são sorteados)
// Textos em scr_idioma: exp_<id>_nome e exp_<id>_texto (um fato real para crianças).
global.locais_marte = [
    // --- Risco baixo: perto da base, chão plano ---
    { id: "octavia",     nivel: "baixo", recursos: ["poeira", "regolito", "ferro"] },        // local do pouso (2021)
    { id: "dunas",       nivel: "baixo", recursos: ["poeira", "regolito", "silicio"] },      // dunas de areia
    { id: "tres_forcas", nivel: "baixo", recursos: ["regolito", "poeira", "silicio"] },      // depósito de amostras (2022-2023)
    { id: "maaz",        nivel: "baixo", recursos: ["ferro", "magnesio", "silicio"] },       // lava basáltica, rica em ferro
    // --- Risco médio: mais longe, chão difícil ---
    { id: "seitah",      nivel: "medio", recursos: ["magnesio", "ferro", "silicio"] },       // olivina
    { id: "delta",       nivel: "medio", recursos: ["regolito", "silicio", "poeira", "ferro"] },   // delta do rio
    { id: "wildcat",     nivel: "medio", recursos: ["regolito", "silicio", "magnesio"] },    // lama do lago, moléculas orgânicas
    { id: "margem",      nivel: "medio", recursos: ["magnesio", "silicio", "ferro"] },       // carbonatos da margem do lago
    { id: "neretva",     nivel: "medio", recursos: ["poeira", "regolito", "silicio", "ferro"] },   // antigo canal do rio
    // --- Risco alto: subidas e lugares muito longe (trazem todos os recursos) ---
    { id: "borda",       nivel: "alto",  recursos: ["poeira", "regolito", "ferro", "silicio", "magnesio"] },
    { id: "bright_angel", nivel: "alto", recursos: ["poeira", "regolito", "ferro", "silicio", "magnesio"] },  // rocha Cheyava Falls (2024)
    { id: "witch_hazel", nivel: "alto",  recursos: ["poeira", "regolito", "ferro", "silicio", "magnesio"] },  // camadas antigas da borda (2025)
    { id: "kodiak",      nivel: "alto",  recursos: ["poeira", "regolito", "ferro", "silicio", "magnesio"] }   // morro que sobrou do delta
];

// Quantos lugares de cada risco aparecem por dia, quantos recursos cada um traz e quanto
#macro EXPEDICAO_QTD_BAIXO 2
#macro EXPEDICAO_QTD_MEDIO 2
#macro EXPEDICAO_QTD_ALTO  1

global.destinos = [];          // os 5 lugares de hoje (sorteados em expedicao_destinos_do_dia)
global.destinos_dia = -1;      // dia em que a lista foi sorteada
global.destinos_ontem = [];    // ids de ontem (evita repetir o mesmo lugar dois dias seguidos)

/// @function expedicao_embaralhar(array)
function expedicao_embaralhar(_a) {
    var _c = array_create(array_length(_a));
    array_copy(_c, 0, _a, 0, array_length(_a));
    for (var i = array_length(_c) - 1; i > 0; i--) {
        var j = irandom(i);
        var _t = _c[i]; _c[i] = _c[j]; _c[j] = _t;
    }
    return _c;
}

/// @function expedicao_criar_destino(local)
/// @description Destino do dia: sorteia quais recursos o lugar vai dar hoje (diferentes entre si)
///   baixo: 2 recursos, 1 a 2 de cada   medio: 3 recursos, 2 a 4 de cada   alto: todos, 3 de cada
function expedicao_criar_destino(_local) {
    var _qtd = 2, _faixa = [1, 2], _dias = 1;
    if (_local.nivel == "medio") { _qtd = 3; _faixa = [2, 4]; _dias = 2; }
    if (_local.nivel == "alto")  { _qtd = 5; _faixa = [3, 3]; _dias = 2; }
    var _recs = expedicao_embaralhar(_local.recursos);
    var _coleta = {};
    for (var i = 0; i < min(_qtd, array_length(_recs)); i++) _coleta[$ _recs[i]] = [_faixa[0], _faixa[1]];
    return { id: _local.id, nivel: _local.nivel, dias: _dias, coleta: _coleta };
}

/// @function expedicao_destinos_do_dia()
/// @description Sorteia os lugares do dia (uma vez por dia): 2 de risco baixo, 2 médio e 1 alto,
///   evitando os de ontem quando há outros. Chamado quando a janela da expedição abre.
function expedicao_destinos_do_dia() {
    if (global.destinos_dia == global.dia && array_length(global.destinos) > 0) return;
    var _novos = [];
    var _niveis = [["baixo", EXPEDICAO_QTD_BAIXO], ["medio", EXPEDICAO_QTD_MEDIO], ["alto", EXPEDICAO_QTD_ALTO]];
    for (var n = 0; n < array_length(_niveis); n++) {
        var _frescos = [], _todos = [];
        for (var i = 0; i < array_length(global.locais_marte); i++) {
            var _l = global.locais_marte[i];
            if (_l.nivel != _niveis[n][0]) continue;
            array_push(_todos, _l);
            if (!array_contains(global.destinos_ontem, _l.id)) array_push(_frescos, _l);
        }
        // primeiro os que não apareceram ontem; se faltar, completa com os outros
        var _lista = expedicao_embaralhar(_frescos);
        var _resto = expedicao_embaralhar(_todos);
        for (var i = 0; i < array_length(_resto); i++) if (!array_contains(_lista, _resto[i])) array_push(_lista, _resto[i]);
        for (var i = 0; i < min(_niveis[n][1], array_length(_lista)); i++) array_push(_novos, expedicao_criar_destino(_lista[i]));
    }
    global.destinos_ontem = [];
    for (var i = 0; i < array_length(_novos); i++) array_push(global.destinos_ontem, _novos[i].id);
    global.destinos = _novos;
    global.destinos_dia = global.dia;
}

/// @function expedicao_custo(destino)
/// @description Pontos de ação gastos ao sair para esse destino (1, 2 ou 3, pelo risco)
function expedicao_custo(_dest) {
    return global.expedicao_niveis[$ _dest.nivel].custo;
}

/// @function expedicao_resolver(destino)
/// @description Resultado da expedição: sempre traz os materiais do destino, na quantidade do nível.
///   Devolve { resultado: "sucesso", coleta: {material: qtd}, ferido: false }
function expedicao_resolver(_dest) {
    var _res = { resultado: "sucesso", coleta: {}, ferido: false };
    var _mats = variable_struct_get_names(_dest.coleta);
    for (var i = 0; i < array_length(_mats); i++) {
        var _faixa = _dest.coleta[$ _mats[i]];
        _res.coleta[$ _mats[i]] = irandom_range(_faixa[0], _faixa[1]);
    }
    return _res;
}
