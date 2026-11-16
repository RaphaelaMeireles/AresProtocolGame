// =====================================================================
// scr_eventos - eventos da noite: catálogo, classificação dos dados da NASA e armazenamento
// =====================================================================
//
// 1) CATÁLOGO DE EVENTOS (global.eventos)
//    Os tipos de evento que o jogo sabe mostrar. Para cada um:
//      id            nome interno; os textos ficam em scr_idioma como evt_<id>_titulo e
//                    evt_<id>_texto (explicação para crianças)
//      busca_imagem  o que procurar na biblioteca de imagens da NASA (images-api.nasa.gov)
//      custo         quanto o evento tira dos status da base, por força:
//                    custo[0] = fraca, custo[1] = média, custo[2] = forte.
//                    Campos possíveis: vida, energia, comida (o que faltar vale 0).
//                    Nunca mais que STATUS_PERDA_MAX (2) de um mesmo status (scr_status).
//      ambiente      mudanças no global.ambiente enquanto o evento acontece (A DEFINIR)
//
// 2) OCORRÊNCIAS REAIS (global.ocorrencias)
//    Cada registro que a NASA devolve vira uma ocorrência classificada em um evento do catálogo,
//    com intensidade 1 (fraca), 2 (média) ou 3 (forte):
//      DONKI WSA-Enlil  previsão de ejeção chegando a MARTE -> tempestade_solar (pela velocidade)
//      DONKI CME        ejeção de massa coronal             -> tempestade_solar (classe S/C/O/R/ER)
//      DONKI IPS        onda de choque no vento solar       -> tempestade_solar (fraca)
//      DONKI SEP        partículas solares energéticas      -> raios_cosmicos   (forte)
//      DONKI HSS        corrente de vento solar rápido      -> raios_cosmicos   (fraca)
//      DONKI FLR        erupção solar (raios X e UV)        -> radiacao_uv      (classe C/M/X)
//      InSight          clima de Marte, arquivo de 2020     -> redemoinho_poeira / tempestade_poeira (pelo vento)
//      (GST, RBE e MPC acontecem só na Terra: não viram eventos de Marte)
//
// 3) ARMAZENAMENTO (arquivo nasa_ocorrencias.json, na pasta de saves do jogo)
//    As ocorrências e a marcação "usada" ficam salvas entre partidas: a mesma ocorrência só
//    volta depois que todas as daquele tipo já apareceram. Sem internet, o jogo usa o que já
//    foi salvo, mostrando a data real do dado (não finge que é ao vivo).

global.eventos = [
    // Partículas do Sol atingem a tripulação e os aparelhos elétricos
    { id: "tempestade_solar",  busca_imagem: "coronal mass ejection", ambiente: {},
      custo: [ { vida: 1 },
               { vida: 1, energia: 1 },
               { vida: 2, energia: 1 } ] },

    // Radiação atinge a tripulação e as plantas da estufa
    { id: "raios_cosmicos",    busca_imagem: "cosmic rays", ambiente: {},
      custo: [ { vida: 1 },
               { vida: 1, comida: 1 },
               { vida: 2, comida: 1 } ] },

    // Poeira cobre os painéis solares; na forte, a estufa fica sem luz
    { id: "tempestade_poeira", busca_imagem: "mars dust storm",
      ambiente: {},   // ex.: { tempestade_poeira: true, multiplicador_solar: 0.2 }
      custo: [ { energia: 1 },
               { energia: 2 },
               { energia: 2, comida: 1 } ] },

    // Redemoinho suja os painéis; o forte arremessa pedrinhas e machuca quem está fora
    { id: "redemoinho_poeira", busca_imagem: "dust devil mars", ambiente: {},
      custo: [ { energia: 1 },
               { energia: 1, comida: 1 },
               { energia: 2, vida: 1 } ] },

    // Pedras do espaço atingem a base: quebram equipamentos e podem ferir a tripulação
    { id: "chuva_meteoritos",  busca_imagem: "meteorite mars", ambiente: {},
      custo: [ { energia: 1 },
               { energia: 2, vida: 1 },
               { energia: 2, vida: 2 } ] },

    // Luz ultravioleta queima as plantas da estufa e a pele de quem sai sem traje
    { id: "radiacao_uv",       busca_imagem: "sun ultraviolet", ambiente: {},
      custo: [ { comida: 1 },
               { comida: 1, vida: 1 },
               { comida: 2, vida: 1 } ] }
];

/// @function evento_por_id(id)
function evento_por_id(_id) {
    for (var i = 0; i < array_length(global.eventos); i++) {
        if (global.eventos[i].id == _id) return global.eventos[i];
    }
    return global.eventos[0];
}

/// @function evento_aplicar_custo(evento, intensidade)
/// @description Tira dos status da base o custo do evento para essa força (1, 2 ou 3).
///   Cada status perde no máximo STATUS_PERDA_MAX e nunca fica abaixo de 0.
///   Devolve o que foi perdido de verdade, ex.: { vida: 1, energia: 2, comida: 0 },
///   para a janela da noite mostrar ao jogador.
function evento_aplicar_custo(_ev, _intensidade) {
    var _custo = _ev.custo[clamp(_intensidade, 1, array_length(_ev.custo)) - 1];
    var _perdas = { vida: 0, energia: 0, comida: 0, escudo: 0, protegeu: false };

    // Escudo contra radiação: nos eventos de radiação, segura 1 ponto de vida e se desgasta no lugar
    var _radiacao = (_ev.id == "tempestade_solar" || _ev.id == "raios_cosmicos" || _ev.id == "radiacao_uv");
    var _vida_custo = _custo[$ "vida"];
    if (_radiacao && is_numeric(_vida_custo) && _vida_custo > 0 && global.escudo > 0) {
        _custo = { vida: _vida_custo - 1, energia: _custo[$ "energia"], comida: _custo[$ "comida"] };
        global.escudo -= 1;
        _perdas.escudo = 1;
        _perdas.protegeu = true;
    }
    var _status = ["vida", "energia", "comida"];

    for (var i = 0; i < array_length(_status); i++) {
        var _nome  = _status[i];
        var _quer  = _custo[$ _nome];
        if (!is_numeric(_quer) || _quer <= 0) continue;
        _quer = min(_quer, STATUS_PERDA_MAX);

        var _atual = variable_global_get(_nome);
        var _perde = min(_quer, _atual);                 // não deixa o status ficar negativo
        variable_global_set(_nome, _atual - _perde);
        _perdas[$ _nome] = _perde;
    }

    // Copia para global.ambiente cada campo definido no evento
    var _campos = variable_struct_get_names(_ev.ambiente);
    for (var i = 0; i < array_length(_campos); i++) {
        global.ambiente[$ _campos[i]] = _ev.ambiente[$ _campos[i]];
    }
    return _perdas;
}

/// @function data_iso(data)
/// @description Data do GameMaker no formato AAAA-MM-DD, usado pela API DONKI.
function data_iso(_dt) {
    var _m = string_replace_all(string_format(date_get_month(_dt), 2, 0), " ", "0");
    var _d = string_replace_all(string_format(date_get_day(_dt), 2, 0), " ", "0");
    return string(date_get_year(_dt)) + "-" + _m + "-" + _d;
}

/// @function data_curta(texto)
/// @description "2026-10-27T12:00Z" -> "2026-10-27"
function data_curta(_texto) {
    return is_string(_texto) ? string_copy(_texto, 1, 10) : "?";
}

// =====================================================================
// --- Ocorrências: criação e catálogo ---
// =====================================================================
#macro OCORRENCIAS_ARQUIVO "nasa_ocorrencias.json"

global.ocorrencias      = [];   // catálogo classificado
global.ocorrencias_uids = {};   // uid -> true (para não guardar a mesma ocorrência duas vezes)

/// @function ocorrencia_criar(uid, evento, intensidade, data, fonte, ao_vivo, dado_chave, dado_args)
/// @param uid         identificador único (ex.: "CME:2026-10-15T20:24:00-CME-001")
/// @param evento      id do evento em global.eventos
/// @param intensidade 1 fraca, 2 média, 3 forte
/// @param data        data do acontecimento real ("AAAA-MM-DD")
/// @param fonte       nome da fonte ("NASA DONKI", "NASA InSight"); "" = sem dado real
/// @param ao_vivo     true = dado recente; false = dado de arquivo (missão encerrada)
/// @param dado_chave  chave do texto em scr_idioma com o dado real ("" = nenhum)
/// @param dado_args   valores que preenchem {0}, {1}... desse texto
function ocorrencia_criar(_uid, _evento, _intensidade, _data, _fonte, _ao_vivo, _dado_chave, _dado_args) {
    return {
        uid: _uid, evento: _evento, intensidade: clamp(_intensidade, 1, 3),
        data: _data, fonte: _fonte, ao_vivo: _ao_vivo,
        dado_chave: _dado_chave, dado_args: _dado_args,
        prioridade: 1,   // maior = escolhida antes entre as não usadas do mesmo tipo
        usada: false, baixada_em: data_iso(date_current_datetime())
    };
}

/// @function ocorrencia_prioridade(ocorrencia)
/// @description Prioridade da ocorrência (as salvas antes deste campo existir valem 1)
function ocorrencia_prioridade(_oc) {
    var _p = _oc[$ "prioridade"];
    return is_numeric(_p) ? _p : 1;
}

/// @function ocorrencia_adicionar(ocorrencia)
/// @description Guarda no catálogo se ainda não existir. Devolve true se era nova.
function ocorrencia_adicionar(_oc) {
    if (variable_struct_exists(global.ocorrencias_uids, _oc.uid)) return false;
    global.ocorrencias_uids[$ _oc.uid] = true;
    array_push(global.ocorrencias, _oc);
    return true;
}

// =====================================================================
// --- Escalas de intensidade ---
// =====================================================================

/// Classe de uma ejeção (CME) pela velocidade, escala usada pela NASA (CCMC):
/// S < 500 km/s, C < 1000, O < 2000, R < 3000, ER >= 3000
function cme_classe(_vel) {
    if (_vel < 500)  return "S";
    if (_vel < 1000) return "C";
    if (_vel < 2000) return "O";
    if (_vel < 3000) return "R";
    return "ER";
}

/// Intensidade de jogo pela classe da ejeção: S fraca, C média, O/R/ER forte
function cme_intensidade(_classe) {
    switch (_classe) {
        case "S": return 1;
        case "C": return 2;
        default:  return 3;
    }
}

/// Intensidade de jogo pela classe da erupção solar (A, B, C fracas; M média; X forte)
function flr_intensidade(_classe) {
    var _letra = is_string(_classe) ? string_upper(string_char_at(_classe, 1)) : "";
    if (_letra == "X") return 3;
    if (_letra == "M") return 2;
    return 1;
}

// =====================================================================
// --- Classificadores: recebem o JSON da NASA e devolvem quantas ocorrências novas ---
// =====================================================================

/// DONKI CME: usa a análise mais precisa de cada ejeção (velocidade e classe)
function classificar_cme(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _cme = _dados[i];
        var _analises = _cme[$ "cmeAnalyses"];
        if (!is_array(_analises)) continue;

        var _melhor = undefined;
        for (var j = 0; j < array_length(_analises); j++) {
            var _a = _analises[j];
            if (!is_numeric(_a[$ "speed"])) continue;
            if (_melhor == undefined || _a[$ "isMostAccurate"] == true) _melhor = _a;
        }
        if (_melhor == undefined) continue;

        var _vel    = _melhor.speed;
        var _classe = (is_string(_melhor[$ "type"]) && _melhor.type != "") ? _melhor.type : cme_classe(_vel);
        var _data   = data_curta(_cme[$ "startTime"]);
        var _oc = ocorrencia_criar("CME:" + string(_cme[$ "activityID"]), "tempestade_solar",
                                   cme_intensidade(_classe), _data, "NASA DONKI", true,
                                   "dado_cme", [_data, round(_vel)]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

/// DONKI WSA-Enlil: simulações que preveem a chegada de uma ejeção em MARTE
function classificar_enlil(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _sim = _dados[i];
        var _impactos = _sim[$ "impactList"];
        if (!is_array(_impactos)) continue;

        for (var j = 0; j < array_length(_impactos); j++) {
            var _imp = _impactos[j];
            if (_imp[$ "location"] != "Mars") continue;

            var _entrada = (is_array(_sim[$ "cmeInputs"]) && array_length(_sim.cmeInputs) > 0) ? _sim.cmeInputs[0] : {};
            var _vel     = is_numeric(_entrada[$ "speed"]) ? _entrada.speed : 0;
            // O campo vem em maiúsculas ("CMEID"); os campos de struct no GameMaker diferenciam maiúsculas
            var _cme_id  = is_string(_entrada[$ "CMEID"]) ? _entrada.CMEID : string(_sim[$ "simulationID"]);
            var _intens  = cme_intensidade(cme_classe(_vel));
            if (_imp[$ "isGlancingBlow"] == true) _intens = max(1, _intens - 1);   // só de raspão: mais fraca

            var _data = data_curta(_imp[$ "arrivalTime"]);
            // Várias simulações podem prever a mesma ejeção: uma ocorrência por ejeção
            var _oc = ocorrencia_criar("MARTE:" + _cme_id, "tempestade_solar", _intens, _data,
                                       "NASA DONKI WSA-Enlil", true, "dado_enlil_marte", [_data, round(_vel)]);
            _oc.prioridade = 2;   // previsão para MARTE: aparece antes das ejeções em geral
            if (ocorrencia_adicionar(_oc)) _novas += 1;
        }
    }
    return _novas;
}

/// DONKI SEP: chuvas de partículas solares energéticas (a principal fonte de radiação perigosa)
function classificar_sep(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _data = data_curta(_dados[i][$ "eventTime"]);
        var _oc = ocorrencia_criar("SEP:" + string(_dados[i][$ "sepID"]), "raios_cosmicos", 3, _data,
                                   "NASA DONKI", true, "dado_sep", [_data]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

/// DONKI FLR: erupções solares, classificadas pela classe de raios X (C, M, X)
function classificar_flr(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _flr    = _dados[i];
        var _classe = is_string(_flr[$ "classType"]) ? _flr.classType : "?";
        var _data   = data_curta(is_string(_flr[$ "peakTime"]) ? _flr.peakTime : _flr[$ "beginTime"]);
        var _oc = ocorrencia_criar("FLR:" + string(_flr[$ "flrID"]), "radiacao_uv", flr_intensidade(_classe),
                                   _data, "NASA DONKI", true, "dado_flr", [_data, _classe]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

/// DONKI IPS: ondas de choque no vento solar
function classificar_ips(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _data  = data_curta(_dados[i][$ "eventTime"]);
        var _local = is_string(_dados[i][$ "location"]) ? _dados[i].location : "?";
        var _oc = ocorrencia_criar("IPS:" + string(_dados[i][$ "activityID"]), "tempestade_solar", 1, _data,
                                   "NASA DONKI", true, "dado_ips", [_data, _local]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

/// DONKI HSS: correntes de vento solar rápido
function classificar_hss(_dados) {
    if (!is_array(_dados)) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados); i++) {
        var _data = data_curta(_dados[i][$ "eventTime"]);
        var _oc = ocorrencia_criar("HSS:" + string(_dados[i][$ "hssID"]), "raios_cosmicos", 1, _data,
                                   "NASA DONKI", true, "dado_hss", [_data]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

/// InSight (arquivo de 2020): cada Sol registrado vira um evento de vento.
/// Vento máximo < 20 m/s = redemoinho de poeira; a partir de 20 m/s = tempestade de poeira.
function classificar_insight(_dados) {
    if (!is_struct(_dados) || !is_array(_dados[$ "sol_keys"])) return 0;
    var _novas = 0;
    for (var i = 0; i < array_length(_dados.sol_keys); i++) {
        var _sol_id = _dados.sol_keys[i];
        var _sol = _dados[$ _sol_id];
        if (!is_struct(_sol) || !is_struct(_sol[$ "HWS"]) || !is_numeric(_sol.HWS[$ "mx"])) continue;

        var _vento = _sol.HWS.mx;
        var _temp  = (is_struct(_sol[$ "AT"]) && is_numeric(_sol.AT[$ "av"])) ? round(_sol.AT.av) : "?";
        var _evento, _intens;
        if (_vento < 20) { _evento = "redemoinho_poeira"; _intens = (_vento < 18.5) ? 1 : 2; }
        else             { _evento = "tempestade_poeira"; _intens = (_vento < 24)   ? 2 : 3; }

        clima_guardar(_sol_id, _sol);
        var _oc = ocorrencia_criar("INSIGHT:" + string(_sol_id), _evento, _intens, data_curta(_sol[$ "First_UTC"]),
                                   "NASA InSight", false, "dado_insight", [_sol_id, round(_vento), _temp]);
        if (ocorrencia_adicionar(_oc)) _novas += 1;
    }
    return _novas;
}

// =====================================================================
// --- Armazenamento em arquivo ---
// =====================================================================

/// @function ocorrencias_salvar()
function ocorrencias_salvar() {
    var _clima = is_array(global.clima_registros) ? global.clima_registros : [];
    var _txt = json_stringify({ versao: 2, ocorrencias: global.ocorrencias, clima: _clima });
    var _buf = buffer_create(string_byte_length(_txt) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_string, _txt);
    buffer_save(_buf, OCORRENCIAS_ARQUIVO);
    buffer_delete(_buf);
}

/// @function ocorrencias_carregar()
/// @description Lê o catálogo salvo (com as marcações "usada"). Devolve quantas ocorrências leu.
function ocorrencias_carregar() {
    global.ocorrencias = [];
    global.ocorrencias_uids = {};
    global.clima_registros = [];
    if (!file_exists(OCORRENCIAS_ARQUIVO)) return 0;

    var _buf = buffer_load(OCORRENCIAS_ARQUIVO);
    if (_buf == -1) return 0;
    var _txt = buffer_read(_buf, buffer_string);
    buffer_delete(_buf);

    try {
        var _salvo = json_parse(_txt);
        var _lista = is_struct(_salvo) ? _salvo[$ "ocorrencias"] : undefined;
        if (is_array(_lista)) {
            for (var i = 0; i < array_length(_lista); i++) ocorrencia_adicionar(_lista[i]);
        }
        var _clima = is_struct(_salvo) ? _salvo[$ "clima"] : undefined;
        if (is_array(_clima)) global.clima_registros = _clima;
    } catch (_erro) {
        show_debug_message("NASA: arquivo de ocorrências corrompido, começando do zero");
    }
    return array_length(global.ocorrencias);
}

// =====================================================================
// --- Sorteio da noite ---
// =====================================================================

/// @function ocorrencia_sortear(evento_anterior)
/// @description Escolhe a ocorrência da noite sem repetir:
///   1) sorteia o tipo de evento, diferente do da noite anterior (todos os tipos com a mesma chance,
///      para as dezenas de ejeções solares não dominarem o jogo);
///   2) escolhe uma ocorrência real ainda não usada desse tipo e marca como usada (fica salvo);
///   3) se todas desse tipo já foram usadas, o tipo recomeça do zero;
///   4) se não há dado real para o tipo (ex.: meteoritos), cria uma ocorrência sem dado,
///      com intensidade sorteada.
function ocorrencia_sortear(_evento_anterior) {
    var _tipos = [];
    for (var i = 0; i < array_length(global.eventos); i++) {
        if (global.eventos[i].id != _evento_anterior) array_push(_tipos, global.eventos[i].id);
    }
    var _tipo = _tipos[irandom(array_length(_tipos) - 1)];

    var _todas  = [];
    var _livres = [];
    for (var i = 0; i < array_length(global.ocorrencias); i++) {
        var _oc = global.ocorrencias[i];
        if (_oc.evento != _tipo) continue;
        array_push(_todas, _oc);
        if (!_oc.usada) array_push(_livres, _oc);
    }

    if (array_length(_todas) == 0) {
        return ocorrencia_criar("LOCAL:" + _tipo, _tipo, irandom_range(1, 3), "", "", false, "", []);
    }
    if (array_length(_livres) == 0) {
        for (var i = 0; i < array_length(_todas); i++) _todas[i].usada = false;
        _livres = _todas;
    }

    // Entre as livres, só as de maior prioridade (ex.: previsões para Marte vêm primeiro)
    var _max_prio = 0;
    for (var i = 0; i < array_length(_livres); i++) _max_prio = max(_max_prio, ocorrencia_prioridade(_livres[i]));
    var _melhores = [];
    for (var i = 0; i < array_length(_livres); i++) {
        if (ocorrencia_prioridade(_livres[i]) == _max_prio) array_push(_melhores, _livres[i]);
    }
    _livres = _melhores;

    var _escolhida = _livres[irandom(array_length(_livres) - 1)];
    _escolhida.usada = true;
    ocorrencias_salvar();
    return _escolhida;
}

/// @function ocorrencias_resumo()
/// @description Texto com quantas ocorrências há de cada evento (para a janela Saída)
function ocorrencias_resumo() {
    var _cont = {};
    for (var i = 0; i < array_length(global.ocorrencias); i++) {
        var _e = global.ocorrencias[i].evento;
        var _n = _cont[$ _e];
        _cont[$ _e] = (is_numeric(_n) ? _n : 0) + 1;
    }
    return json_stringify(_cont);
}

// =====================================================================
// --- Clima de Marte (NASA InSight) ---
// =====================================================================
// Cada Sol medido pelo InSight vira um registro: temperatura média, vento médio e pressão.
// Cada dia da missão usa um registro real, sorteado na primeira vez que o dia é preciso
// e guardado em global.clima_dias até o fim da partida. Sem dados (offline e sem arquivo),
// não há clima e nenhum efeito é aplicado; o jogo avisa isso.
// Os registros ficam salvos no mesmo arquivo das ocorrências (campo "clima").

/// @function clima_guardar(id, dados_do_sol)
/// @description Guarda o clima de um Sol do InSight (sem repetir o mesmo Sol)
function clima_guardar(_id, _sol) {
    if (!is_array(global.clima_registros)) global.clima_registros = [];
    var _sid = string(_id);
    for (var i = 0; i < array_length(global.clima_registros); i++) {
        if (global.clima_registros[i].sol == _sid) return;
    }
    var _temp   = (is_struct(_sol[$ "AT"]) && is_numeric(_sol.AT[$ "av"])) ? round(_sol.AT.av) : undefined;
    var _vento  = (is_struct(_sol[$ "HWS"]) && is_numeric(_sol.HWS[$ "av"])) ? round(_sol.HWS.av * 10) / 10 : undefined;
    var _pressao = (is_struct(_sol[$ "PRE"]) && is_numeric(_sol.PRE[$ "av"])) ? round(_sol.PRE.av) : undefined;
    var _data   = is_string(_sol[$ "First_UTC"]) ? data_curta(_sol.First_UTC) : "?";
    if (_temp == undefined || _vento == undefined) return;
    array_push(global.clima_registros, { sol: _sid, temp: _temp, vento: _vento, pressao: _pressao, data: _data });
}

/// @function clima_do_dia(dia)
/// @description Clima real do dia: { dia, tipo, temp, vento, pressao, sol, data }.
///   tipo "frio" (temperatura média de -75 C ou menos), "ventania" (vento médio de 7 m/s ou mais)
///   ou "calmo". Devolve undefined se não há dados do InSight.
function clima_do_dia(_dia) {
    if (!variable_global_exists("clima_dias")) global.clima_dias = {};
    var _k = string(_dia);
    if (global.clima_dias[$ _k] != undefined) return global.clima_dias[$ _k];
    if (!is_array(global.clima_registros) || array_length(global.clima_registros) == 0) return undefined;

    // Sorteia um Sol que ainda não foi usado em outro dia desta partida (se acabarem, pode repetir)
    var _usados = [];
    var _dias = variable_struct_get_names(global.clima_dias);
    for (var d = 0; d < array_length(_dias); d++) array_push(_usados, global.clima_dias[$ _dias[d]].sol);
    var _livres = [];
    for (var i = 0; i < array_length(global.clima_registros); i++) {
        if (!array_contains(_usados, global.clima_registros[i].sol)) array_push(_livres, global.clima_registros[i]);
    }
    if (array_length(_livres) == 0) _livres = global.clima_registros;
    var _r = _livres[irandom(array_length(_livres) - 1)];
    var _tipo = "calmo";
    if (_r.temp <= -75) _tipo = "frio";
    else if (_r.vento >= 7) _tipo = "ventania";

    var _c = { dia: _dia, tipo: _tipo, temp: _r.temp, vento: _r.vento, pressao: _r.pressao, sol: _r.sol, data: _r.data };
    global.clima_dias[$ _k] = _c;
    return _c;
}

/// @function clima_ajustar_efeito(definicao_maquina)
/// @description Efeito da máquina com o clima de hoje (hoje nenhum clima muda o que a máquina dá).
function clima_ajustar_efeito(_def) {
    var _ef = { vida: _def.efeito[$ "vida"], energia: _def.efeito[$ "energia"], comida: _def.efeito[$ "comida"] };
    var _c = clima_do_dia(global.dia);
    return _ef;
}

/// @function clima_extra_maquina(definicao_maquina)
/// @description Raios A MAIS (além do clique) para usar a máquina com o clima de hoje.
///   Dia de ventania: o reator de fissão custa 1 ponto de ação a mais.
function clima_extra_maquina(_def) {
    var _c = clima_do_dia(global.dia);
    if (_c != undefined && _c.tipo == "ventania" && _def.chave == "fissao") return 1;
    return 0;
}

// =====================================================================
// --- Previsão da próxima noite ---
// =====================================================================

/// @function previsao_maquinas_texto(id_evento)
/// @description Quais máquinas o evento pode quebrar, em texto
function previsao_maquinas_texto(_evento) {
    var _alvos = global.maquinas_quebra_por_evento[$ _evento];
    if (!is_array(_alvos) || array_length(_alvos) == 0) return tr("previsao_sem_risco");
    var _nomes = "";
    for (var i = 0; i < array_length(_alvos); i++) {
        if (_nomes != "") _nomes += ", ";
        _nomes += tr("maq_" + _alvos[i] + "_nome");
    }
    return tr("previsao_risco", _nomes);
}

/// @function previsao_resumo()
/// @description Previsão para amanhã: clima e a próxima noite (evento, força e máquinas em risco).
///   Usada no console da NASA e no painel do canto da tela.
function previsao_resumo() {
    var _txt = "";
    var _c = clima_do_dia(global.dia + 1);
    if (_c == undefined) _txt += tr("clima_sem_dados");
    else _txt += tr("clima_linha", tr("clima_amanha"), tr("clima_nome_" + _c.tipo), _c.temp, _c.vento);

    var _oc = instance_exists(oEventos) ? oEventos.previsao : undefined;
    if (_oc != undefined) {
        var _ev = evento_por_id(_oc.evento);
        _txt += "\n" + tr("previsao_evento", tr("evt_" + _ev.id + "_titulo"), tr("intensidade_" + string(_oc.intensidade)));
        _txt += "\n" + previsao_maquinas_texto(_ev.id);
    }
    return _txt;
}

/// @function clima_registro_aleatorio_texto()
/// @description Texto do console (Mission Control): a PREVISÃO do clima de Marte para amanhã.
///   É um dia real medido pelo InSight; cada sol da missão usa um dia diferente (sorteado por partida).
///   O clima de amanhã decide os imprevistos de clima de amanhã (escolha_tags_do_dia).
function clima_registro_aleatorio_texto() {
    var _amanha = global.dia + 1;
    var _c = clima_do_dia(_amanha);
    if (_c == undefined) return tr("nasa_clima_nada");
    var _pressao = is_numeric(_c.pressao) ? string(_c.pressao) : "?";
    return tr("nasa_clima_registro", _c.sol, _c.data, _c.temp, _c.vento, _pressao, _amanha,
              tr("clima_nome_" + _c.tipo));
}
