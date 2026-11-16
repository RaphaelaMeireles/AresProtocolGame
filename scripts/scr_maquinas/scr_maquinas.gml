// =====================================================================
// scr_maquinas - o que cada máquina da base faz, como quebra e como conserta
// =====================================================================
// As máquinas são os sprites da camada "Maquinas" da room. O sprite define o tipo:
//   chave        id usado nos textos de scr_idioma (maq_<chave>_nome / maq_<chave>_acao)
//   tipo         "status" (padrão: dá status), "nasa" (console), "expedicao" (porta de saída),
//                "laboratorio" (analisa regolito), "estoque" (mostra o estoque), "decoracao"
//   custo        raios gastos quando o jogador clica na máquina
//   efeito       status ganhos (+1 no máximo de cada); negativos também valem (trocas)
//   icone        balão que o tripulante mostra quando usa a máquina (scr_emocoes)
//   necessidade  status que faz a tripulação procurar essa máquina quando está baixo
//   reparo       materiais do estoque para consertar quando quebra (ausente = nunca quebra)
// Regras de uso:
//   - se todos os status que a máquina dá já estão cheios, ela não funciona e não gasta raios;
//   - máquina quebrada não funciona: o clique conserta (gasta 1 raio + os materiais do reparo);
//   - máquina quebrada só deixa de funcionar até ser consertada (não tira pontos à noite).

#macro REPARO_CUSTO_RAIOS 1
#macro CLIQUE_CUSTO_RAIOS 1   // cada clique numa máquina gasta 1 raio (conserto, console, lab e status incluídos)

global.maquinas_def = {
    sConsoleCentral: { chave: "console",   tipo: "nasa",        custo: 2, efeito: {},                      icone: "estrela",    necessidade: "",        reparo: { silicio: 1, ferro: 1 } },
    Console:         { chave: "console",   tipo: "nasa",        custo: 2, efeito: {},                      icone: "estrela",    necessidade: "",        reparo: { silicio: 1, ferro: 1 } },
    // Só o Kilopower (reator de fissão) gera energia; o reator REM é cenário. As placas solares foram retiradas.
    sReatorREM:      { chave: "reator",    tipo: "decoracao",   custo: 0, efeito: {},                      icone: "energia",    necessidade: "" },
    sReatorFissao:   { chave: "fissao",    tipo: "status",      custo: 1, efeito: { energia: 1 },          icone: "energia",    necessidade: "energia", reparo: { ferro: 2 } },
    // Estação meteorológica: mostra o clima de Marte (NASA InSight) e a previsão de amanhã
    sAntena:         { chave: "antena",    tipo: "clima",       custo: 1, efeito: {},                      icone: "estrela",    necessidade: "" },
    sGeradorO2:      { chave: "oxigenio",  tipo: "status",      custo: 2, efeito: { vida: 1 },             icone: "coracao",    necessidade: "vida",    reparo: { ferro: 1, silicio: 1 } },
    sFiltroCO2:      { chave: "filtro",    tipo: "status",      custo: 2, efeito: { vida: 1 },             icone: "ferramenta", necessidade: "vida",    reparo: { silicio: 1, magnesio: 1 } },
    sTanquesH2O:     { chave: "agua",      tipo: "status",      custo: 2, efeito: { vida: 1 },             icone: "coracao",    necessidade: "vida",    reparo: { ferro: 1 } },   // água = suporte de vida
    sEstufa:         { chave: "estufa",    tipo: "status",      custo: 2, efeito: { comida: 1 },           icone: "planta",     necessidade: "comida",  reparo: { silicio: 1 } },
    sEstufaPequena:  { chave: "estufa",    tipo: "status",      custo: 2, efeito: { comida: 1 },           icone: "planta",     necessidade: "comida",  reparo: { silicio: 1 } },
    sCozinha:        { chave: "cozinha",   tipo: "decoracao",   custo: 0, efeito: {},                      icone: "fome",       necessidade: "" },   // só cenário (sem função)
    sCama1:          { chave: "cama",      tipo: "status",      custo: 2, efeito: { vida: 1 },             icone: "zzz",        necessidade: "vida" },
    sCama2:          { chave: "cama",      tipo: "status",      custo: 2, efeito: { vida: 1 },             icone: "zzz",        necessidade: "vida" },
    sLaboratorio:    { chave: "laboratorio", tipo: "laboratorio", custo: 1, efeito: {},                    icone: "estrela",    necessidade: "escudo",  reparo: { silicio: 1 } },
    sPortaBlindada:  { chave: "porta",     tipo: "expedicao",   custo: EXPEDICAO_CUSTO_RAIOS, efeito: {},  icone: "exclamacao", necessidade: "" },
    sEstoque:        { chave: "estoque",   tipo: "estoque",     custo: 0, efeito: {},                      icone: "ferramenta", necessidade: "" },
    sBanheiro:       { chave: "banheiro",  tipo: "decoracao",   custo: 0, efeito: {},                      icone: "feliz",      necessidade: "" }
};

// Que máquinas cada evento da noite pode quebrar (pelo id da chave)
global.maquinas_quebra_por_evento = {
    tempestade_solar:  ["console", "fissao", "oxigenio"],
    raios_cosmicos:    ["console", "filtro", "laboratorio"],
    tempestade_poeira: ["fissao", "filtro", "oxigenio"],
    redemoinho_poeira: ["fissao", "filtro"],
    chuva_meteoritos:  ["agua", "estufa", "fissao"],
    radiacao_uv:       ["estufa", "laboratorio"]
};
// Chance de quebrar uma máquina por força do evento (fraca, média, forte)
global.maquinas_chance_quebra = [0.10, 0.20, 0.35];   // antes: 0.25, 0.5 e 0.8

global.maquinas = [];   // máquinas encontradas na room (preenchido por maquinas_listar)

/// @function maquinas_listar()
/// @description Procura os sprites de máquina na camada "Maquinas" e calcula onde a tripulação
///   para para usar cada uma (a célula livre mais perto da frente da máquina).
function maquinas_listar() {
    global.maquinas = [];
    var _lay = layer_get_id("Maquinas");
    if (_lay == -1) return;
    var _els = layer_get_all_elements(_lay);
    for (var i = 0; i < array_length(_els); i++) {
        if (layer_get_element_type(_els[i]) != layerelementtype_sprite) continue;
        var _spr = layer_sprite_get_sprite(_els[i]);
        var _def = global.maquinas_def[$ sprite_get_name(_spr)];
        if (_def == undefined) continue;

        var _r = mapa_retangulo_elemento(_els[i]);
        var _uso = mapa_ponto_livre_perto((_r[0] + _r[2]) / 2, _r[3] + 6);
        array_push(global.maquinas, {
            el: _els[i], spr: _spr, def: _def, nome: sprite_get_name(_spr),
            x1: _r[0], y1: _r[1], x2: _r[2], y2: _r[3],
            uso_x: _uso[0], uso_y: _uso[1],
            quebravel: (_def[$ "reparo"] != undefined),
            quebrada: false
        });
    }
    show_debug_message("Máquinas encontradas: " + string(array_length(global.maquinas)));
}

/// @function maquina_por_tipo(tipo)
function maquina_por_tipo(_tipo) {
    for (var i = 0; i < array_length(global.maquinas); i++) {
        if (global.maquinas[i].def.tipo == _tipo) return global.maquinas[i];
    }
    return undefined;
}

/// @function maquina_por_necessidade(status)
/// @description Uma máquina funcionando que ajuda no status pedido (ou qualquer uma)
function maquina_por_necessidade(_status) {
    var _opcoes = [];
    for (var i = 0; i < array_length(global.maquinas); i++) {
        var _m = global.maquinas[i];
        if (_m.quebrada || _m.def.tipo == "expedicao") continue;
        if (_status == "" || _m.def.necessidade == _status) array_push(_opcoes, _m);
    }
    if (array_length(_opcoes) == 0) return undefined;
    return _opcoes[irandom(array_length(_opcoes) - 1)];
}

/// @function maquina_efeito_texto(efeito)
/// @description Texto curto do efeito, ex.: "+1 Life  -1 Food"
function maquina_efeito_texto(_efeito) {
    var _txt = "";
    var _nomes = ["vida", "energia", "comida", "escudo"];
    for (var i = 0; i < array_length(_nomes); i++) {
        var _v = _efeito[$ _nomes[i]];
        if (!is_numeric(_v) || _v == 0) continue;
        if (_txt != "") _txt += "  ";
        _txt += ((_v > 0) ? "+" : "") + string(_v) + " " + tr("status_" + _nomes[i]);
    }
    return _txt;
}

/// @function maquina_efeito_bloqueio(efeito)
/// @description Por que a máquina não pode dar o efeito agora: "cheio" (tudo que ela dá já está
///   no máximo), "falta" (ela gasta um status que está em 0) ou "" (pode usar).
function maquina_efeito_bloqueio(_efeito) {
    var _nomes = ["vida", "energia", "comida", "escudo"];
    var _da_algo = false, _algum_nao_cheio = false;
    for (var i = 0; i < array_length(_nomes); i++) {
        var _v = _efeito[$ _nomes[i]];
        if (!is_numeric(_v) || _v == 0) continue;
        var _atual = variable_global_get(_nomes[i]);
        if (_v > 0) {
            _da_algo = true;
            if (_atual < variable_global_get(_nomes[i] + "_max")) _algum_nao_cheio = true;
        } else if (_atual + _v < 0) {
            return "falta";
        }
    }
    if (_da_algo && !_algum_nao_cheio) return "cheio";
    return "";
}

/// @function maquina_aplicar_efeito(efeito)
/// @description Soma o efeito nos status (respeitando 0 e o máximo de cada um)
function maquina_aplicar_efeito(_efeito) {
    var _nomes = ["vida", "energia", "comida", "escudo"];
    for (var i = 0; i < array_length(_nomes); i++) {
        var _v = _efeito[$ _nomes[i]];
        if (!is_numeric(_v) || _v == 0) continue;
        var _max = variable_global_get(_nomes[i] + "_max");
        variable_global_set(_nomes[i], clamp(variable_global_get(_nomes[i]) + _v, 0, _max));
    }
}

/// @function maquinas_quebrar_por_evento(id_evento, intensidade)
/// @description Pode quebrar uma máquina na noite (chance pela força do evento).
///   Devolve os nomes (textos) das máquinas que quebraram.
function maquinas_quebrar_por_evento(_evento, _intensidade) {
    var _alvos = global.maquinas_quebra_por_evento[$ _evento];
    var _quebradas = [];
    if (!is_array(_alvos)) return _quebradas;

    var _vezes = 1;   // no máximo 1 máquina quebra por noite (antes: 2 nos eventos fortes)
    var _chance = global.maquinas_chance_quebra[clamp(_intensidade, 1, 3) - 1];
    for (var v = 0; v < _vezes; v++) {
        if (random(1) > _chance) continue;
        var _candidatas = [];
        for (var i = 0; i < array_length(global.maquinas); i++) {
            var _m = global.maquinas[i];
            if (_m.quebravel && !_m.quebrada && array_contains(_alvos, _m.def.chave)) array_push(_candidatas, _m);
        }
        if (array_length(_candidatas) == 0) break;
        var _m = _candidatas[irandom(array_length(_candidatas) - 1)];
        _m.quebrada = true;
        array_push(_quebradas, tr("maq_" + _m.def.chave + "_nome"));
    }
    return _quebradas;
}

/// @function maquinas_penalidade_noite()
/// @description Quanto cada status perde nesta noite por causa das máquinas quebradas
///   (1 por máquina quebrada que cuida daquele status). Ex.: { vida: 1, energia: 0, comida: 1 }
function maquinas_penalidade_noite() {
    var _p = { vida: 0, energia: 0, comida: 0, escudo: 0 };
    for (var i = 0; i < array_length(global.maquinas); i++) {
        var _m = global.maquinas[i];
        if (_m.quebrada && _m.def.necessidade != "") _p[$ _m.def.necessidade] += 1;
    }
    return _p;
}

/// @function maquinas_quebradas()
function maquinas_quebradas() {
    var _n = 0;
    for (var i = 0; i < array_length(global.maquinas); i++) if (global.maquinas[i].quebrada) _n += 1;
    return _n;
}

/// @function nasa_previsao_marte()
/// @description Frase com o dado real mais útil para o console:
///   1) a próxima (ou mais recente) tempestade solar prevista para chegar a Marte (WSA-Enlil);
///   2) senão, a ejeção solar mais recente vista pela NASA;
///   3) senão, avisa que não há dados.
function nasa_previsao_marte() {
    var _marte = undefined, _cme = undefined;
    for (var i = 0; i < array_length(global.ocorrencias); i++) {
        var _oc = global.ocorrencias[i];
        if (string_pos("MARTE:", _oc.uid) == 1) {
            if (_marte == undefined || _oc.data > _marte.data) _marte = _oc;
        } else if (string_pos("CME:", _oc.uid) == 1) {
            if (_cme == undefined || _oc.data > _cme.data) _cme = _oc;
        }
    }
    if (_marte != undefined) return tr("nasa_previsao_marte", _marte.data, _marte.dado_args[1]);
    if (_cme != undefined)   return tr("nasa_previsao_cme", _cme.data, _cme.dado_args[1]);
    return tr("nasa_previsao_nada");
}
