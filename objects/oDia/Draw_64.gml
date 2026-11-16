// =====================================================================
// oDia - interface fixa na tela: dia no rodapé, janela do dia, fade e cartão de troca de dia
// =====================================================================
// Todo texto usa a fonte de pixel do Create: texto(x, y, texto, escala, cor, alinhamentos...)
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

var _cor_painel = make_color_rgb(24, 27, 34);
var _cor_borda  = make_color_rgb(150, 155, 165);
var _cor_titulo = make_color_rgb(255, 230, 120);

// --- Dia atual, sempre visível no rodapé ---
// (com sombra, para ler sobre o mapa; os outros textos ficam sobre fundo liso e não precisam)
texto(_gw / 2, _gh - 16, tr("dia_rodape", global.dia), escala_rodape, c_white, fa_center, fa_bottom, 1, true);

// --- Janela do dia ---
if (estado == "modal") {
    // Escurece o fundo
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    // Painel com borda dupla
    draw_set_color(_cor_painel);
    draw_rectangle(modal_x1, modal_y1, modal_x2, modal_y2, false);
    draw_set_color(_cor_borda);
    draw_rectangle(modal_x1, modal_y1, modal_x2, modal_y2, true);
    draw_rectangle(modal_x1 + 4, modal_y1 + 4, modal_x2 - 4, modal_y2 - 4, true);

    var _cor_suave = make_color_rgb(150, 155, 165);
    var _larg_util = modal_w - modal_margem * 2;

    // Relatório da noite (oEventos). No dia 1 ainda não houve noite: mostra o texto de abertura
    var _rel = instance_exists(oEventos) ? oEventos.relatorio : undefined;
    var _tem_evento = (_rel != undefined && _rel.dia == global.dia);

    // Título (diminui a escala se não couber na largura do painel)
    var _cx = (modal_x1 + modal_x2) / 2;
    var _titulo = _tem_evento ? tr("modal_titulo_evento", global.dia, _rel.titulo) : tr("modal_titulo", global.dia);
    var _st = escala_titulo;
    while (_st > 3 && texto_largura(_titulo, _st) > _larg_util) _st -= 1;
    texto(_cx, modal_y1 + modal_margem, _titulo, _st, _cor_titulo, fa_center, fa_top);

    // Linha separando o título do conteúdo
    var _linha_y = modal_y1 + modal_margem + 7 * _st + 20;
    draw_set_color(_cor_borda);
    draw_rectangle(modal_x1 + modal_margem, _linha_y, modal_x2 - modal_margem, _linha_y + 1, false);
    var _topo = _linha_y + 28;

    if (!_tem_evento) {
        // --- Dia 1: registro de abertura (quebra linha sozinho dentro do painel) ---
        var _corpo = texto_quebrar(tr("modal_texto", global.dia), escala_texto, _larg_util);
        texto(modal_x1 + modal_margem, _topo, _corpo, escala_texto, c_white, fa_left, fa_top, 1, false, 5);
    } else {
        // --- Imagem da NASA à esquerda ---
        var _img_w = 400;
        var _img_h = 300;
        var _ix = modal_x1 + modal_margem;
        var _iy = _topo;
        draw_set_color(make_color_rgb(14, 16, 20));
        draw_rectangle(_ix, _iy, _ix + _img_w, _iy + _img_h, false);
        draw_set_color(_cor_borda);
        draw_rectangle(_ix, _iy, _ix + _img_w, _iy + _img_h, true);

        if (_rel.imagem != -1 && sprite_exists(_rel.imagem)) {
            // Encaixa a foto na moldura sem distorcer
            var _sw = sprite_get_width(_rel.imagem);
            var _sh = sprite_get_height(_rel.imagem);
            var _k  = min((_img_w - 2) / _sw, (_img_h - 2) / _sh);
            gpu_set_texfilter(true);   // foto: suavizar ao reduzir fica melhor
            draw_sprite_ext(_rel.imagem, 0, _ix + (_img_w - _sw * _k) / 2, _iy + (_img_h - _sh * _k) / 2,
                            _k, _k, 0, c_white, 1);
            gpu_set_texfilter(false);

            // Crédito da imagem (título encurtado para caber em 2 linhas)
            var _titulo_img = _rel.imagem_titulo;
            if (string_length(_titulo_img) > 50) _titulo_img = string_copy(_titulo_img, 1, 47) + "...";
            var _cred = texto_quebrar(tr("nasa_credito", _titulo_img), escala_credito, _img_w);
            texto(_ix, _iy + _img_h + 12, _cred, escala_credito, _cor_suave, fa_left, fa_top, 1, false, 4);
        } else {
            var _msg = _rel.imagem_pronta ? tr("nasa_imagem_indisponivel") : tr("nasa_imagem_carregando");
            texto(_ix + _img_w / 2, _iy + _img_h / 2, texto_quebrar(_msg, escala_credito, _img_w - 40),
                  escala_credito, _cor_suave, fa_center, fa_middle);
        }

        // --- O que a base perdeu nesta noite (abaixo da imagem): ícone da barra + quantidade ---
        var _py = _iy + _img_h + 12 + 2 * (7 + 4) * escala_credito + 16;   // espaço reservado ao crédito
        texto(_ix, _py, tr("perdas_titulo"), escala_credito, _cor_suave, fa_left, fa_top);
        _py += 7 * escala_credito + 12;

        var _itens_perda = [
            { nome: "vida",    spr: sVida    },
            { nome: "energia", spr: sEnergia },
            { nome: "comida",  spr: sComida  },
            { nome: "escudo",  spr: sEscudo  }
        ];
        var _px = _ix;
        var _perdeu_algo = false;
        for (var p = 0; p < array_length(_itens_perda); p++) {
            var _q = _rel.perdas[$ _itens_perda[p].nome];
            if (!is_numeric(_q) || _q <= 0) continue;
            _perdeu_algo = true;
            // O ícone é o desenho que fica no começo da barra (vida, raio, maçã), ampliado 2x
            draw_sprite_part_ext(_itens_perda[p].spr, 0, 0, 0, 15, 16, _px, _py, 2, 2, c_white, 1);
            texto(_px + 40, _py + 5, "-" + string(_q), escala_texto, make_color_rgb(255, 110, 100), fa_left, fa_top);
            _px += 110;
        }
        if (_rel.perdas[$ "protegeu"] == true) {
            texto(_ix, _py + 64, tr("perdas_escudo_protegeu"), escala_credito, make_color_rgb(130, 190, 255), fa_left, fa_top);
        }
        if (!_perdeu_algo) {
            texto(_ix, _py + 8, tr("perdas_nenhuma"), escala_credito, make_color_rgb(120, 220, 120), fa_left, fa_top);
        }
        // Máquinas que quebraram nesta noite
        var _qb = _rel[$ "quebras"];
        if (is_array(_qb) && array_length(_qb) > 0) {
            var _lista = "";
            for (var q = 0; q < array_length(_qb); q++) _lista += ((q > 0) ? ", " : "") + _qb[q];
            texto(_ix, _py + 40, texto_quebrar(tr("quebras_noite", _lista), escala_credito, _img_w),
                  escala_credito, make_color_rgb(255, 110, 100), fa_left, fa_top, 1, false, 3);
        }

        // --- Explicação para crianças, dado real e fonte à direita ---
        var _tx = _ix + _img_w + 32;
        var _tw = modal_x2 - modal_margem - _tx;
        var _y  = _topo;

        var _corpo_ev = texto_quebrar(_rel.texto, escala_texto, _tw);
        texto(_tx, _y, _corpo_ev, escala_texto, c_white, fa_left, fa_top, 1, false, 4);
        _y += texto_altura(_corpo_ev, escala_texto, 4) + 24;

        // Força do evento (classificada a partir do dado da NASA): texto + 3 blocos coloridos
        var _int = _rel.intensidade;
        // (o GameMaker não aceita um "? :" encadeado em outro sem parênteses, por isso o if)
        var _cor_int = make_color_rgb(255, 90, 80);                  // forte: vermelho
        if (_int == 1) _cor_int = make_color_rgb(120, 220, 120);     // fraca: verde
        else if (_int == 2) _cor_int = make_color_rgb(255, 180, 70); // média: laranja
        var _txt_int = tr("intensidade", tr("intensidade_" + string(_int)));
        texto(_tx, _y, _txt_int, escala_texto, _cor_int, fa_left, fa_top);
        var _bx = _tx + texto_largura(_txt_int, escala_texto) + 16;
        for (var b = 0; b < 3; b++) {
            var _x1 = _bx + b * 26;
            draw_set_color((b < _int) ? _cor_int : make_color_rgb(60, 64, 72));
            draw_rectangle(_x1, _y, _x1 + 20, _y + 7 * escala_texto - 1, false);
        }
        _y += 7 * escala_texto + 20;

        if (!_rel.dados_prontos) {
            texto(_tx, _y, tr("nasa_carregando"), escala_texto, _cor_titulo, fa_left, fa_top);
        } else {
            if (_rel.dado != "") {
                var _dado = texto_quebrar(_rel.dado, escala_texto, _tw);
                texto(_tx, _y, _dado, escala_texto, _cor_titulo, fa_left, fa_top, 1, false, 4);
                _y += texto_altura(_dado, escala_texto, 4) + 20;
            }
            if (_rel.fonte != "") {
                texto(_tx, _y, texto_quebrar(_rel.fonte, escala_credito, _tw), escala_credito,
                      _cor_suave, fa_left, fa_top, 1, false, 4);
            }
        }
    }

    // Botão OK (clareia com o mouse em cima)
    var _m = mouse_gui();
    var _hover = point_in_rectangle(_m[0], _m[1], botao_x1, botao_y1, botao_x2, botao_y2);
    draw_set_color(_hover ? make_color_rgb(80, 85, 95) : make_color_rgb(50, 54, 62));
    draw_rectangle(botao_x1, botao_y1, botao_x2, botao_y2, false);
    draw_set_color(_hover ? _cor_titulo : _cor_borda);
    draw_rectangle(botao_x1, botao_y1, botao_x2, botao_y2, true);
    texto((botao_x1 + botao_x2) / 2, (botao_y1 + botao_y2) / 2 + 1, tr("modal_ok"),
          escala_botao, c_white, fa_center, fa_middle);
}

// --- Fade da troca de dia (tela preta, por cima de tudo) ---
// Curva suave: começa e termina devagar, em vez de escurecer em ritmo constante
if (fade_alpha > 0) {
    var _a = fade_alpha * fade_alpha * (3 - 2 * fade_alpha);
    draw_set_alpha(_a);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

// --- Abertura: aviso discreto de que dá para pular a espera (aparece depois de 2 s, pulsando) ---
if (estado == "abertura" && abertura_t > 120) {
    var _pulso = 0.35 + 0.25 * sin(current_time / 400);
    texto(_gw / 2, _gh - 40, tr("abertura_pular"), escala_credito, make_color_rgb(150, 155, 165),
          fa_center, fa_bottom, _pulso);
}

// --- Cartão de troca de dia: "DAY N" grande no meio da tela preta ---
if (estado == "cartao") {
    var _s = escala_cartao;
    var _t = cartao_t;

    // Transparência do cartão: aparece no início e some no fim
    var _alpha = 1;
    if (_t < cartao_entra) _alpha = _t / cartao_entra;
    else if (_t > cartao_total - cartao_sai) _alpha = (cartao_total - _t) / cartao_sai;

    // Progresso da rolagem do número (0 a 1), com curva suave
    var _p = 0;
    if (cartao_rolar) _p = clamp((_t - cartao_entra - cartao_espera) / cartao_rola, 0, 1);
    var _e = _p * _p * (3 - 2 * _p);

    // Separa a parte fixa ("DAY ") da parte que rola (o número), comparando os dois textos.
    // Assim funciona em qualquer idioma, sem saber onde o número fica.
    var _txt_de   = tr("cartao_dia", cartao_de);
    var _txt_para = tr("cartao_dia", cartao_para);
    var _n = 0;
    var _min = min(string_length(_txt_de), string_length(_txt_para));
    while (_n < _min && string_char_at(_txt_de, _n + 1) == string_char_at(_txt_para, _n + 1)) _n++;
    if (_txt_de == _txt_para) _n = string_length(_txt_de);

    var _fixo      = string_copy(_txt_de, 1, _n);
    var _rola_de   = string_delete(_txt_de, 1, _n);
    var _rola_para = string_delete(_txt_para, 1, _n);

    var _w_fixo  = (_fixo == "") ? 0 : texto_largura(_fixo, _s) + _s;
    var _w_rola  = max(texto_largura(_rola_de, _s), texto_largura(_rola_para, _s));
    var _x0 = floor(_gw / 2 - (_w_fixo + _w_rola - ((_w_rola == 0) ? _s : 0)) / 2);
    var _y0 = floor(_gh / 2 - 7 * _s / 2);

    texto(_x0, _y0, _fixo, _s, c_white, fa_left, fa_top, _alpha, false);

    if (_rola_de != "" || _rola_para != "") {
        // O número atual sobe e some; o próximo sobe de baixo e aparece
        var _desloc = 7 * _s * 1.3;
        if (_e < 1) texto(_x0 + _w_fixo, _y0 - _e * _desloc, _rola_de, _s, c_white,
                          fa_left, fa_top, _alpha * (1 - _e), false);
        if (_e > 0) texto(_x0 + _w_fixo, _y0 + (1 - _e) * _desloc, _rola_para, _s, c_white,
                          fa_left, fa_top, _alpha * _e, false);
    }
}

// Volta o desenho ao padrão para não afetar outros objetos
draw_set_color(c_white);
draw_set_alpha(1);

// --- Clima de Marte de hoje e previsão de amanhã (canto inferior esquerdo) ---
if (painel_clima && (estado == "jogando" || estado == "esperando" || estado == "escurecendo")) {
    var _c_hoje = clima_do_dia(global.dia);
    var _painel = tr("clima_titulo") + "\n";
    if (_c_hoje == undefined) {
        _painel += tr("clima_sem_dados");
    } else {
        _painel += tr("clima_linha", tr("clima_hoje"), tr("clima_nome_" + _c_hoje.tipo), _c_hoje.temp, _c_hoje.vento);
        _painel += "\n" + tr("clima_efeito_" + _c_hoje.tipo);
    }
    _painel += "\n" + previsao_resumo();
    if (_c_hoje != undefined) _painel += "\n" + tr("clima_fonte", _c_hoje.sol, _c_hoje.data);
    _painel = texto_quebrar(_painel, 2, 600);

    var _alt_painel = texto_altura(_painel, 2, 3);
    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_rectangle(10, _gh - 50 - _alt_painel, 630, _gh - 34, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    texto(16, _gh - 40, _painel, 2, c_white, fa_left, fa_bottom, 1, true, 3);

    // X para fechar no canto superior direito (o clique é tratado no Step)
    painel_fy = _gh - 50 - _alt_painel + 6;
    draw_set_color(make_color_rgb(24, 27, 34));
    draw_rectangle(602, painel_fy, 624, painel_fy + 22, false);
    draw_set_color(make_color_rgb(150, 155, 165));
    draw_rectangle(602, painel_fy, 624, painel_fy + 22, true);
    texto(613, painel_fy + 11, "X", 2, c_white, fa_center, fa_middle);
}

// --- Nome da barra de status embaixo do mouse (Life support, Food, Energy, Shield) ---
// As barras ficam na camada Status (presa à câmera): converte a posição delas para a tela.
if (estado != "menu" && estado != "tutorial" && instance_exists(oHUD)) {
    var _cam_b = view_camera[0];
    var _f_b   = _gw / camera_get_view_width(_cam_b);
    var _cx_b  = camera_get_view_x(_cam_b), _cy_b = camera_get_view_y(_cam_b);
    var _m_b   = mouse_gui();
    for (var b = 0; b < array_length(oHUD.barras); b++) {
        var _br = oHUD.barras[b];
        if (layer_sprite_get_alpha(_br.el) <= 0) continue;   // escondida (card de evento aberto)
        var _sx_b = layer_sprite_get_xscale(_br.el), _sy_b = layer_sprite_get_yscale(_br.el);
        var _bx1 = (layer_sprite_get_x(_br.el) - sprite_get_xoffset(_br.spr) * _sx_b - _cx_b) * _f_b;
        var _by1 = (layer_sprite_get_y(_br.el) - sprite_get_yoffset(_br.spr) * _sy_b - _cy_b) * _f_b;
        var _bx2 = _bx1 + sprite_get_width(_br.spr) * _sx_b * _f_b;
        var _by2 = _by1 + sprite_get_height(_br.spr) * _sy_b * _f_b;
        if (!point_in_rectangle(_m_b[0], _m_b[1], _bx1, _by1, _bx2, _by2)) continue;

        var _txt_b = tr("status_" + _br.status) + ": " + string(variable_global_get(_br.status))
                   + "/" + string(variable_global_get(_br.status + "_max"));
        var _lw_b = texto_largura(_txt_b, 2) + 20;
        var _tx_b = clamp(_m_b[0] + 16, 4, _gw - _lw_b - 4);
        var _ty_b = clamp(_m_b[1] + 16, 4, _gh - 34);
        draw_set_alpha(0.92); draw_set_color(make_color_rgb(8, 8, 10));
        draw_rectangle(_tx_b, _ty_b, _tx_b + _lw_b, _ty_b + 30, false);
        draw_set_alpha(1); draw_set_color(make_color_rgb(150, 155, 165));
        draw_rectangle(_tx_b, _ty_b, _tx_b + _lw_b, _ty_b + 30, true);
        texto(_tx_b + 10, _ty_b + 15, _txt_b, 2, make_color_rgb(255, 230, 120), fa_left, fa_middle);
        draw_set_color(c_white);
        break;
    }
}

// --- Botão "Skip the Day" embaixo dos pontos de ação ---
if (skip_visivel()) {
    var _bs = skip_botao(), _ms = mouse_gui();
    var _sobre_skip = point_in_rectangle(_ms[0], _ms[1], _bs[0], _bs[1], _bs[2], _bs[3]);
    draw_set_alpha(0.9);
    draw_set_color(_sobre_skip ? make_color_rgb(40, 40, 46) : make_color_rgb(8, 8, 10));
    draw_rectangle(_bs[0], _bs[1], _bs[2], _bs[3], false);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(150, 155, 165));
    draw_rectangle(_bs[0], _bs[1], _bs[2], _bs[3], true);
    texto((_bs[0] + _bs[2]) / 2, (_bs[1] + _bs[3]) / 2, tr("skip_dia"), 2, make_color_rgb(255, 230, 120), fa_center, fa_middle);
    draw_set_color(c_white);
}

// --- Aviso do volume da música (no alto da tela, durante o jogo) ---
if (musica_aviso > 0 && estado != "menu" && estado != "tutorial") {
    texto(_gw / 2, 16, tr("menu_musica", round(global.volume_musica * 100)), 2, c_white, fa_center, fa_top, 1, true);
}

// --- Menu inicial e tutorial: tela cheia, por cima de tudo ---
var _amarelo_menu = make_color_rgb(255, 230, 120);
var _cinza_menu   = make_color_rgb(200, 200, 210);
if (estado == "menu") {
    menu_fundo();
    texto(_gw / 2, 80, tr("menu_titulo"), 9, _amarelo_menu, fa_center, fa_top, 1, true);
    texto(_gw / 2, 185, tr("menu_subtitulo"), 2, _cinza_menu, fa_center, fa_top);
    botao_desenhar(menu_x, menu_y_jogar, menu_w, menu_h, tr("menu_jogar"));
    botao_desenhar(menu_x, menu_y_tutorial, menu_w, menu_h, tr("menu_tutorial"));
    botao_desenhar(menu_x, menu_y_idioma, menu_w, menu_h, tr("menu_idioma", tr("idioma_nome")));
    botao_desenhar(menu_x, menu_y_musica, 80, menu_h, "-");
    botao_desenhar(menu_x + menu_w - 80, menu_y_musica, 80, menu_h, "+");
    texto(_gw / 2, menu_y_musica + menu_h / 2, tr("menu_musica", round(global.volume_musica * 100)), 3, c_white, fa_center, fa_middle);
    texto(_gw / 2, 620, tr("menu_creditos"), 2, _cinza_menu, fa_center, fa_top);
    texto(_gw / 2, 660, tr("menu_dica"), 2, _cinza_menu, fa_center, fa_top);
}
if (estado == "tutorial") {
    var _n = tut_pagina + 1;
    menu_fundo();
    texto(_gw / 2, 40, tr("tut_titulo"), 6, _amarelo_menu, fa_center, fa_top, 1, true);
    texto(_gw / 2, 130, tr("tut_p" + string(_n) + "_titulo"), 4, _amarelo_menu, fa_center, fa_top);
    var _corpo = texto_quebrar(tr("tut_p" + string(_n) + "_texto"), 2, 900);
    texto(_gw / 2, 200, _corpo, 2, c_white, fa_center, fa_top, 1, false, 8);
    texto(_gw / 2, tut_y - 24, tr("tut_pagina", _n, tut_total), 2, _cinza_menu, fa_center, fa_bottom);
    if (tut_antes_do_jogo) botao_desenhar(tut_pular_x, tut_pular_y, tut_pular_w, tut_pular_h, tr("tut_pular"));
    botao_desenhar(tut_x_anterior, tut_y, tut_w, 56, tr("tut_anterior"));
    botao_desenhar(tut_x_menu, tut_y, tut_w_meio, 56, tr("tut_menu"));
    botao_desenhar(tut_x_proxima, tut_y, tut_w, 56, (_n >= tut_total) ? tr("tut_jogar") : tr("tut_proxima"));
}
