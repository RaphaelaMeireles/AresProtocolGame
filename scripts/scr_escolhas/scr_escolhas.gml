// =====================================================================
// scr_escolhas - eventos do dia com escolha (estilo RPG)
// =====================================================================
// No início de cada dia aparecem os imprevistos do dia e o jogador escolhe entre duas saídas.
// Nenhuma escolha é de graça: cada uma tem uma consequência (o desafio da NASA pede isso).
//
// Cada evento:
//   id            nome interno; textos em scr_idioma: esc_<id>_titulo, esc_<id>_texto,
//                 esc_<id>_op1/op2 (botões) e esc_<id>_res1/res2 (o que aconteceu depois)
//   grupo         "clima" (vem do clima do dia), "manutencao" (máquinas e estufa) ou "expedicao" (fora do posto)
//   requer        "" (qualquer hora) ou "expedicao" (só quando há alguém lá fora)
//   busca_imagem  foto da biblioteca da NASA mostrada na janela
//   opcoes        [opção 1, opção 2]; cada uma:
//                   efeito  mudanças em % (como no roteiro): vida, energia, comida, escudo
//                   extra   (opcional) quebra/conserta máquina, bloqueia expedição, materiais
//
// Os % viram pontos das barras (que vão de 0 a 5): até 20% = 1 ponto; 25% ou mais = 2 pontos.
// Equilíbrio: nos imprevistos ruins, cada opção custa 1 ponto no total (perde 1, ou ganha 1 e perde 2);
// nos bons (colheita, gelo, caverna...), cada opção dá +1 no total. Nenhuma opção é de graça.
// Assim nenhum evento mexe mais que 2 pontos num status, igual aos eventos da noite.
// "Suporte à Vida" do roteiro = Vida; "Escudo contra Radiação" = Escudo.

#macro ESCOLHA_CHANCE_MANUTENCAO 0.6   // chance de um imprevisto de manutenção em cada dia

// Imprevistos do clima: as etiquetas do dia que fazem cada um acontecer (ver escolha_tags_do_dia)
global.escolhas_gatilhos = {
    poeira_regional:   ["poeira"],
    redemoinho_reator: ["poeira", "ventania"],
    frio_extremo:      ["frio"],
    ejecao_coronal:    ["radiacao"],
    racionamento:      ["poeira"],
    fissura_estufa:    ["meteoros"]
};

global.escolhas = [
    // --- Clima e eventos externos ---
    { id: "poeira_regional", grupo: "clima", requer: "", busca_imagem: "mars dust storm",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: { vida: -15 } } ] },
    { id: "redemoinho_reator", grupo: "clima", requer: "", busca_imagem: "dust devil mars",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: { energia: 15, escudo: -25 } } ] },
    { id: "frio_extremo", grupo: "clima", requer: "", busca_imagem: "mars frost",
      opcoes: [ { efeito: { vida: -15 } },
                { efeito: { comida: -15 } } ] },
    { id: "ejecao_coronal", grupo: "clima", requer: "", busca_imagem: "coronal mass ejection",
      opcoes: [ { efeito: { escudo: 15, vida: -25 } },
                { efeito: { energia: -15 } } ] },
    { id: "ventos_expedicao", grupo: "expedicao", requer: "expedicao", busca_imagem: "mars wind",
      opcoes: [ { efeito: { escudo: -15 } },
                { efeito: { escudo: 15, vida: -25 }, extra: { coleta: { regolito: 1 } } } ] },

    // --- Falhas mecânicas (ECLSS, reator e airlock) ---
    { id: "filtro_zeolita", grupo: "manutencao", requer: "", busca_imagem: "carbon dioxide removal space station",
      opcoes: [ { efeito: { vida: 15, comida: -25 } },
                { efeito: { vida: 15, energia: -25 } } ] },
    { id: "metano_sabatier", grupo: "manutencao", requer: "", busca_imagem: "sabatier system",
      opcoes: [ { efeito: { vida: -15 } },
                { efeito: { comida: -15 } } ] },
    { id: "bomba_agua", grupo: "manutencao", requer: "", busca_imagem: "water recovery system",
      opcoes: [ { efeito: { vida: 15, comida: -25 } },
                { efeito: { energia: -15 } } ] },
    { id: "radiadores_reator", grupo: "manutencao", requer: "", busca_imagem: "kilopower reactor",
      opcoes: [ { efeito: { energia: 15, escudo: -25 } },
                { efeito: { energia: -15 } } ] },
    { id: "vedacao_airlock", grupo: "manutencao", requer: "", busca_imagem: "airlock",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: {}, extra: { bloqueia_expedicao: 1 } } ] },

    // --- Estufa e alimentação ---
    { id: "fungos", grupo: "manutencao", requer: "", busca_imagem: "plants space station",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: { comida: -15 } } ] },
    { id: "led_estufa", grupo: "manutencao", requer: "", busca_imagem: "veggie plant growth",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: { comida: -15 } } ] },
    { id: "percloratos", grupo: "manutencao", requer: "", busca_imagem: "mars soil perchlorate",
      opcoes: [ { efeito: { vida: -15 } },
                { efeito: { energia: -15 } } ] },
    { id: "fissura_estufa", grupo: "clima", requer: "", busca_imagem: "micrometeoroid",
      opcoes: [ { efeito: {}, extra: { quebra: "estufa" } },
                { efeito: { vida: -15 } } ] },
    { id: "safra_excedente", grupo: "manutencao", requer: "", busca_imagem: "space station harvest",
      opcoes: [ { efeito: { comida: 25, energia: -15 } },
                { efeito: { vida: 15 } } ] },

    // --- Expedições, exploração e decisões de risco ---
    { id: "gelo_cratera", grupo: "expedicao", requer: "expedicao", busca_imagem: "mars ice",
      opcoes: [ { efeito: { vida: 25, energia: -15 } },
                { efeito: { vida: 25, escudo: -15 } } ] },
    { id: "sonda_perdida", grupo: "expedicao", requer: "expedicao", busca_imagem: "radioisotope thermoelectric generator",
      opcoes: [ { efeito: { energia: 25, escudo: -15 } },
                { efeito: { escudo: 25, comida: -15 }, extra: { coleta: { ferro: 1 } } } ] },
    { id: "tubo_lava", grupo: "expedicao", requer: "expedicao", busca_imagem: "mars lava tube",
      opcoes: [ { efeito: { escudo: 25, comida: -15 } },
                { efeito: { vida: 25, energia: -15 } } ] },
    { id: "falha_traje", grupo: "expedicao", requer: "expedicao", busca_imagem: "spacesuit",
      opcoes: [ { efeito: { energia: -15 } },
                { efeito: { escudo: -15 } } ] },
    { id: "racionamento", grupo: "clima", requer: "", busca_imagem: "mars global dust storm",
      opcoes: [ { efeito: { comida: 15, energia: 15, vida: -25 } },
                { efeito: { escudo: 25, comida: -15, energia: -15 } } ] }
];

global.escolhas_usadas = [];   // ids já vistos (não repetem até todos aparecerem)

/// @function escolha_pontos(porcentagem)
/// @description % do roteiro -> pontos da barra: até 20% = 1, 25% ou mais = 2 (com o sinal)
function escolha_pontos(_p) {
    if (_p == 0) return 0;
    return sign(_p) * ((abs(_p) >= 25) ? 2 : 1);
}

/// @function escolha_tags_do_dia()
/// @description Como está o dia, em "etiquetas" usadas para escolher o imprevisto do clima:
///   "radiacao", "poeira" ou "meteoros" (evento da noite com força média ou forte)
///   e "frio" ou "ventania" (clima do dia, dados do InSight).
function escolha_tags_do_dia() {
    var _tags = [];
    var _rel = instance_exists(oEventos) ? oEventos.relatorio : undefined;
    if (_rel != undefined && _rel.dia == global.dia && _rel.intensidade >= 2) {
        switch (_rel.evento.id) {
            case "tempestade_solar":
            case "raios_cosmicos":
            case "radiacao_uv":       array_push(_tags, "radiacao"); break;
            case "tempestade_poeira":
            case "redemoinho_poeira": array_push(_tags, "poeira");   break;
            case "chuva_meteoritos":  array_push(_tags, "meteoros"); break;
        }
    }
    // Clima do dia (o mesmo que o Mission Control mostrou ontem como "amanhã"):
    //   frio -> imprevistos de frio; ventania -> imprevistos de vento e poeira
    var _c = clima_do_dia(global.dia);
    if (_c != undefined) {
        if (_c.tipo == "frio") array_push(_tags, "frio");
        if (_c.tipo == "ventania") { array_push(_tags, "ventania"); array_push(_tags, "poeira"); }
    }
    return _tags;
}

/// @function escolha_do_grupo(grupo, tags)
/// @description Sorteia um imprevisto do grupo ainda não visto. Com tags (grupo "clima"),
///   só vale o imprevisto cujo gatilho combina com o dia. Se todos já apareceram, repete.
function escolha_do_grupo(_grupo, _tags) {
    var _cands = [], _livres = [];
    for (var i = 0; i < array_length(global.escolhas); i++) {
        var _e = global.escolhas[i];
        if (_e.grupo != _grupo) continue;
        if (is_array(_tags)) {
            var _gat = global.escolhas_gatilhos[$ _e.id];
            if (!is_array(_gat)) continue;
            var _combina = false;
            for (var t = 0; t < array_length(_gat); t++) if (array_contains(_tags, _gat[t])) _combina = true;
            if (!_combina) continue;
        }
        array_push(_cands, _e);
        if (!array_contains(global.escolhas_usadas, _e.id)) array_push(_livres, _e);
    }
    if (array_length(_cands) == 0) return undefined;
    var _lista = (array_length(_livres) > 0) ? _livres : _cands;
    var _escolhido = _lista[irandom(array_length(_lista) - 1)];
    array_push(global.escolhas_usadas, _escolhido.id);
    return _escolhido;
}

/// @function escolhas_do_dia()
/// @description Os imprevistos do dia, todos mostrados no início do dia, nesta ordem:
///   1) clima: só se o dia tiver radiação/poeira/meteoros fortes ou frio/ventania;
///   2) manutenção: com chance ESCOLHA_CHANCE_MANUTENCAO;
///   3) fora do posto: só no dia seguinte ao envio de um tripulante em expedição.
function escolhas_do_dia() {
    var _fila = [];
    if (global.dia <= 1) return _fila;   // o primeiro dia é tranquilo: nenhum imprevisto
    var _tags = escolha_tags_do_dia();
    if (array_length(_tags) > 0) {
        var _c = escolha_do_grupo("clima", _tags);
        if (_c != undefined) array_push(_fila, _c);
    }
    if (random(1) < ESCOLHA_CHANCE_MANUTENCAO) {
        var _m = escolha_do_grupo("manutencao", undefined);
        if (_m != undefined) array_push(_fila, _m);
    }
    if (global.expedicao_enviada_dia == global.dia - 1) {
        var _x = escolha_do_grupo("expedicao", undefined);
        if (_x != undefined) array_push(_fila, _x);
    }
    return _fila;
}

/// @function escolha_mudancas(opcao)
/// @description Mudanças em pontos que a opção causaria: { vida: -1, energia: 0, comida: 0, escudo: 2 }
function escolha_mudancas(_op) {
    var _m = { vida: 0, energia: 0, comida: 0, escudo: 0 };
    var _nomes = variable_struct_get_names(_op.efeito);
    for (var i = 0; i < array_length(_nomes); i++) _m[$ _nomes[i]] = escolha_pontos(_op.efeito[$ _nomes[i]]);
    return _m;
}

/// @function escolha_aplicar(opcao)
/// @description Aplica a opção escolhida. Devolve o que mudou de verdade (respeitando 0 e o máximo).
function escolha_aplicar(_op) {
    var _m = escolha_mudancas(_op);
    var _real = { vida: 0, energia: 0, comida: 0, escudo: 0 };
    var _nomes = ["vida", "energia", "comida", "escudo"];
    for (var i = 0; i < array_length(_nomes); i++) {
        var _n = _nomes[i];
        if (_m[$ _n] == 0) continue;
        var _antes = variable_global_get(_n);
        var _depois = clamp(_antes + _m[$ _n], 0, variable_global_get(_n + "_max"));
        variable_global_set(_n, _depois);
        _real[$ _n] = _depois - _antes;
    }

    var _extra = _op[$ "extra"];
    if (is_struct(_extra)) {
        // Quebra uma máquina daquele tipo (ex.: o filtro entupiu)
        if (is_string(_extra[$ "quebra"])) {
            for (var i = 0; i < array_length(global.maquinas); i++) {
                var _q = global.maquinas[i];
                if (_q.quebravel && !_q.quebrada && _q.def.chave == _extra.quebra) { _q.quebrada = true; _real.quebrou = tr("maq_" + _q.def.chave + "_nome"); break; }
            }
        }
        // Expedições ficam proibidas até o próximo dia
        if (is_numeric(_extra[$ "bloqueia_expedicao"])) global.expedicao_bloqueada_ate = global.dia + _extra.bloqueia_expedicao;
        // Materiais trazidos para o estoque
        if (is_struct(_extra[$ "coleta"])) {
            var _mats = variable_struct_get_names(_extra.coleta);
            for (var i = 0; i < array_length(_mats); i++) estoque_adicionar(_mats[i], _extra.coleta[$ _mats[i]]);
            _real.coleta = _extra.coleta;
        }
    }
    return _real;
}
