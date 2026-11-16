// =====================================================================
// oEventos - evento de cada noite e o relatório mostrado na janela do dia
// =====================================================================
// Criado pelo oGameManager. Na troca de dia, o oDia chama iniciar_noite(): este objeto
// sorteia o evento (scr_eventos), aplica o impacto e pede à NASA (oNasaAPI) o dado real
// e uma imagem. O oDia desenha o "relatorio" na janela que abre depois da troca de dia.
//
// relatorio = undefined enquanto nenhuma noite aconteceu (dia 1).

relatorio     = undefined;
ultimo_evento = "";
noite_seq     = 0;      // muda a cada noite: respostas atrasadas de noites antigas são ignoradas

// =====================================================================
// --- Catálogo de ocorrências reais da NASA (classificação em scr_eventos) ---
// =====================================================================
// Ao abrir o jogo: lê o que já foi salvo e pede à NASA os dados mais recentes.
// Cada resposta é classificada, juntada ao catálogo (sem duplicar) e salva em arquivo.
// Tudo isso acontece em segundo plano, durante o dia 1.
var _salvas = ocorrencias_carregar();
show_debug_message("NASA: " + string(_salvas) + " ocorrências carregadas do arquivo " + ocorrencias_resumo());

/// Callback que classifica uma resposta da NASA e salva o catálogo
ao_receber_lote = function(_nome, _classificador) {
    return method({ nome: _nome, classificar: _classificador }, function(_ok, _dados) {
        if (!_ok) { show_debug_message("NASA: não foi possível atualizar " + nome); return; }
        var _novas = classificar(_dados);
        ocorrencias_salvar();
        show_debug_message("NASA: " + nome + " +" + string(_novas) + " ocorrências novas " + ocorrencias_resumo());
    });
};

/// Pede à NASA todos os tipos de dado usados pelos eventos
atualizar_catalogo = function() {
    var _hoje    = date_current_datetime();
    var _periodo = "startDate=" + data_iso(date_inc_day(_hoje, -NASA_DIAS_DONKI)) + "&endDate=" + data_iso(_hoje);

    oNasaAPI.pedir_api("/DONKI/WSAEnlilSimulations", _periodo, ao_receber_lote("WSA-Enlil (Marte)", classificar_enlil));
    oNasaAPI.pedir_api("/DONKI/CME", _periodo, ao_receber_lote("CME", classificar_cme));
    oNasaAPI.pedir_api("/DONKI/SEP", _periodo, ao_receber_lote("SEP", classificar_sep));
    oNasaAPI.pedir_api("/DONKI/FLR", _periodo, ao_receber_lote("FLR", classificar_flr));
    oNasaAPI.pedir_api("/DONKI/IPS", _periodo, ao_receber_lote("IPS", classificar_ips));
    oNasaAPI.pedir_api("/DONKI/HSS", _periodo, ao_receber_lote("HSS", classificar_hss));
    oNasaAPI.pedir_api("/insight_weather/", "feedtype=json&ver=1.0", ao_receber_lote("InSight", classificar_insight));
};
atualizar_catalogo();

// =====================================================================
// --- Noite ---
// =====================================================================

/// Começa a noite: escolhe uma ocorrência ainda não usada, cobra o custo do evento e pede a imagem
iniciar_noite = function(_dia) {
    limpar_imagem();
    noite_seq += 1;

    // A noite já prevista (vista no console durante o dia anterior) é a que acontece agora
    var _oc = (previsao != undefined) ? previsao : ocorrencia_sortear(ultimo_evento);
    previsao = undefined;
    var _ev = evento_por_id(_oc.evento);
    ultimo_evento = _ev.id;
    var _perdas = evento_aplicar_custo(_ev, _oc.intensidade);   // tira vida/energia/comida pela força

    // Clima frio (do dia que começa): os aquecedores gastam 1 de energia nesta noite
    var _clima = clima_do_dia(_dia);
    if (_clima != undefined && _clima.tipo == "frio" && global.energia > 0) {
        global.energia -= 1;
        _perdas.energia += 1;
    }

    // (Máquina quebrada não tira mais pontos à noite: ela só deixa de funcionar até o conserto.)
    // E o evento desta noite pode quebrar máquinas
    var _quebras = maquinas_quebrar_por_evento(_ev.id, _oc.intensidade);

    // Fonte do dado: data real do acontecimento; dado de missão encerrada aparece como arquivo
    var _fonte = "";
    if (_oc.fonte != "") {
        _fonte = _oc.ao_vivo ? tr("fonte_dado", _oc.fonte, _oc.data)
                             : tr("fonte_arquivo", _oc.fonte, string_copy(_oc.data, 1, 4));
    }

    relatorio = {
        evento:         _ev,
        ocorrencia:     _oc,
        intensidade:    _oc.intensidade,
        perdas:         _perdas,     // o que a base perdeu nesta noite (mostrado na janela)
        quebras:        _quebras,    // nomes das máquinas que quebraram nesta noite
        dia:            _dia,
        titulo:         tr("evt_" + _ev.id + "_titulo"),
        texto:          tr("evt_" + _ev.id + "_texto"),   // explicação para crianças
        dado:           (_oc.dado_chave != "") ? tr_lista(_oc.dado_chave, _oc.dado_args) : "",
        fonte:          _fonte,
        imagem:         -1,          // sprite baixado da NASA
        imagem_titulo:  "",          // título da imagem na biblioteca da NASA (crédito)
        dados_prontos:  true,        // o dado já está no catálogo; só a imagem é pedida agora
        imagem_pronta:  false,
        tempo:          0
    };
    show_debug_message("NASA: noite " + string(_dia) + " -> " + _oc.uid + " (intensidade " + string(_oc.intensidade) + ")");

    prever_proxima();     // a noite seguinte já fica sorteada, para o jogador se planejar
    pedir_imagem(_ev);
};

/// true quando a imagem já chegou (ou desistimos de esperar)
relatorio_pronto = function() {
    return relatorio != undefined && relatorio.dados_prontos && relatorio.imagem_pronta;
};

/// Cria um callback que lembra de qual noite ele é (para ignorar respostas atrasadas)
callback_da_noite = function(_funcao) {
    return method({ dono: id, seq: noite_seq, funcao: _funcao }, function(_ok, _resultado) {
        if (!instance_exists(dono) || dono.noite_seq != seq) {
            // Resposta de uma noite que já passou: descarta (e libera a imagem, se for uma)
            if ((is_real(_resultado) || is_handle(_resultado)) && sprite_exists(_resultado)) sprite_delete(_resultado);
            return;
        }
        funcao(_ok, _resultado);
    });
};

// =====================================================================
// --- Imagem da biblioteca da NASA ---
// =====================================================================
pedir_imagem = function(_ev) {
    oNasaAPI.pedir_imagens_busca(_ev.busca_imagem, callback_da_noite(ao_receber_busca));
};

/// Busca de imagens: escolhe uma das imagens encontradas (varia a cada partida) e baixa
ao_receber_busca = function(_ok, _dados) {
    var _itens = (_ok && is_struct(_dados) && is_struct(_dados[$ "collection"])) ? _dados.collection[$ "items"] : undefined;
    if (!is_array(_itens) || array_length(_itens) == 0) {
        show_debug_message("NASA: a busca de imagens não trouxe resultados (" + relatorio.evento.busca_imagem + ")");
        relatorio.imagem_pronta = true;
        return;
    }

    var _item = _itens[irandom(array_length(_itens) - 1)];
    var _links = _item[$ "links"];
    if (!is_array(_links) || array_length(_links) == 0) { relatorio.imagem_pronta = true; return; }

    // Prefere a versão "small" (boa para a janela e leve); senão usa a primeira disponível
    var _url = _links[0].href;
    for (var i = 0; i < array_length(_links); i++) {
        if (string_pos("~small.", _links[i].href) > 0) { _url = _links[i].href; break; }
    }
    if (is_array(_item[$ "data"]) && array_length(_item.data) > 0) {
        relatorio.imagem_titulo = string(_item.data[0][$ "title"]);
    }
    oNasaAPI.baixar_imagem(_url, callback_da_noite(ao_receber_imagem));
};

ao_receber_imagem = function(_ok, _spr) {
    relatorio.imagem = _ok ? _spr : -1;
    relatorio.imagem_pronta = true;
};

/// Libera a imagem da noite anterior da memória
limpar_imagem = function() {
    if (relatorio != undefined && relatorio.imagem != -1 && sprite_exists(relatorio.imagem)) {
        sprite_delete(relatorio.imagem);
    }
};

// --- Previsão da próxima noite ---
// A noite seguinte é sorteada antes de acontecer, para aparecer no console e no painel do dia.
// iniciar_noite() usa essa previsão e sorteia a seguinte logo depois.
previsao = undefined;   // ocorrência da próxima noite (campos: evento, intensidade)
prever_proxima = function() {
    previsao = ocorrencia_sortear(ultimo_evento);
};
prever_proxima();
