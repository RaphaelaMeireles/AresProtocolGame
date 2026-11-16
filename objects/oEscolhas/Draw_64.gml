// Janela do imprevisto do dia: foto da NASA, explicação, duas escolhas com o custo de cada uma
if (estado == "esperando" || evento == undefined || !instance_exists(oDia)) exit;

var _gw = display_get_gui_width(), _gh = display_get_gui_height();
var _painel  = make_color_rgb(24, 27, 34);
var _borda   = make_color_rgb(150, 155, 165);
var _amarelo = make_color_rgb(255, 230, 120);
var _suave   = make_color_rgb(150, 155, 165);
var _verde   = make_color_rgb(140, 235, 140);
var _vermelho = make_color_rgb(255, 110, 100);
var _m = mouse_gui();

/// Ícones das mudanças em linha: ícone da barra + "+2" / "-1" (verde ganha, vermelho perde)
var _desenhar_mudancas = function(_x, _y, _mud, _verde, _vermelho) {
    var _itens = [ ["vida", sVida], ["energia", sEnergia], ["comida", sComida], ["escudo", sEscudo] ];
    var _px = _x;
    for (var i = 0; i < array_length(_itens); i++) {
        var _v = _mud[$ _itens[i][0]];
        if (!is_numeric(_v) || _v == 0) continue;
        gpu_set_texfilter(false);
        draw_sprite_part_ext(_itens[i][1], 0, 0, 0, 15, 16, _px, _y, 2, 2, c_white, 1);
        oDia.texto(_px + 36, _y + 5, ((_v > 0) ? "+" : "") + string(_v), 3, (_v > 0) ? _verde : _vermelho, fa_left, fa_top);
        _px += 100;
    }
    return _px - _x;
};

// Fundo e painel
draw_set_alpha(0.65); draw_set_color(c_black); draw_rectangle(0, 0, _gw, _gh, false); draw_set_alpha(1);
draw_set_color(_painel); draw_rectangle(jan_x1, jan_y1, jan_x2, jan_y2, false);
draw_set_color(_borda);  draw_rectangle(jan_x1, jan_y1, jan_x2, jan_y2, true);
draw_rectangle(jan_x1 + 4, jan_y1 + 4, jan_x2 - 4, jan_y2 - 4, true);

// --- Status atuais da base, em cima do card (fora dele), para decidir vendo as barras ---
var _barras = [ ["vida", sVida], ["energia", sEnergia], ["comida", sComida], ["escudo", sEscudo] ];
var _bw  = sprite_get_width(sVida) * 2;
var _gap = 24;
var _bx0 = floor(_gw / 2 - (array_length(_barras) * _bw + (array_length(_barras) - 1) * _gap) / 2);
var _by0 = floor((jan_y1 - sprite_get_height(sVida) * 2) / 2);
gpu_set_texfilter(false);
for (var b = 0; b < array_length(_barras); b++) {
    var _nome_st = _barras[b][0], _spr_st = _barras[b][1];
    var _quadro = instance_exists(oHUD) ? oHUD.quadro_da_barra(_spr_st, variable_global_get(_nome_st), variable_global_get(_nome_st + "_max")) : 0;
    draw_sprite_ext(_spr_st, _quadro, _bx0 + b * (_bw + _gap) + sprite_get_xoffset(_spr_st) * 2,
                    _by0 + sprite_get_yoffset(_spr_st) * 2, 2, 2, 0, c_white, 1);
}

// Etiqueta do grupo + título
var _cores_grupo = { clima: make_color_rgb(230, 150, 80), maquinas: make_color_rgb(150, 170, 200), estufa: make_color_rgb(120, 210, 120), expedicao: make_color_rgb(200, 140, 230), manutencao: make_color_rgb(150, 170, 200) };
var _cor_g = _cores_grupo[$ evento.grupo];
if (_cor_g == undefined) _cor_g = _amarelo;
oDia.texto(jan_x1 + 40, jan_y1 + 28, tr("esc_grupo_" + evento.grupo), 2, _cor_g, fa_left, fa_top);
var _titulo = tr("esc_" + evento.id + "_titulo");
var _st = 5;
while (_st > 3 && oDia.texto_largura(_titulo, _st) > jan_x2 - jan_x1 - 80) _st -= 1;
oDia.texto(jan_x1 + 40, jan_y1 + 50, _titulo, _st, _amarelo, fa_left, fa_top);

// Foto da NASA
draw_set_color(make_color_rgb(14, 16, 20)); draw_rectangle(img_x, img_y, img_x + img_w, img_y + img_h, false);
draw_set_color(_borda); draw_rectangle(img_x, img_y, img_x + img_w, img_y + img_h, true);
if (imagem != -1 && sprite_exists(imagem)) {
    var _sw = sprite_get_width(imagem), _sh = sprite_get_height(imagem);
    var _k = min((img_w - 2) / _sw, (img_h - 2) / _sh);
    gpu_set_texfilter(true);
    draw_sprite_ext(imagem, 0, img_x + (img_w - _sw * _k) / 2, img_y + (img_h - _sh * _k) / 2, _k, _k, 0, c_white, 1);
    gpu_set_texfilter(false);
    // Crédito da foto: no máximo 2 linhas embaixo da imagem (corta com "..."), sem invadir os botões
    var _cred = string_split(oDia.texto_quebrar(tr("nasa_credito", imagem_titulo), 2, img_w), "\n");
    var _cred_txt = _cred[0];
    if (array_length(_cred) > 1) {
        var _l2 = _cred[1];
        if (array_length(_cred) > 2) {
            while (string_length(_l2) > 0 && oDia.texto_largura(_l2 + "...", 2) > img_w) _l2 = string_copy(_l2, 1, string_length(_l2) - 1);
            _l2 += "...";
        }
        _cred_txt += "\n" + _l2;
    }
    oDia.texto(img_x, img_y + img_h + 8, _cred_txt, 2, _suave, fa_left, fa_top, 1, false, 3);
} else {
    oDia.texto(img_x + img_w / 2, img_y + img_h / 2, imagem_pronta ? tr("nasa_imagem_indisponivel") : tr("nasa_imagem_carregando"),
               2, _suave, fa_center, fa_middle);
}

if (estado == "escolhendo") {
    // O que está acontecendo
    var _ctx = oDia.texto_quebrar(tr("esc_" + evento.id + "_texto"), 3, txt_w);
    oDia.texto(txt_x, img_y, _ctx, 3, c_white, fa_left, fa_top, 1, false, 4);
    oDia.texto(txt_x, bot1[1] - 34, tr("esc_pergunta"), 2, _amarelo, fa_left, fa_top);

    // Duas escolhas: texto da opção + o que ela custa/dá
    for (var b = 1; b <= 2; b++) {
        var _r = (b == 1) ? bot1 : bot2;
        var _hover = point_in_rectangle(_m[0], _m[1], _r[0], _r[1], _r[2], _r[3]);
        draw_set_color(_hover ? make_color_rgb(60, 64, 74) : make_color_rgb(40, 44, 54));
        draw_rectangle(_r[0], _r[1], _r[2], _r[3], false);
        draw_set_color(_hover ? _amarelo : _borda);
        draw_rectangle(_r[0], _r[1], _r[2], _r[3], true);
        var _op_txt = oDia.texto_quebrar(string(b) + ". " + tr("esc_" + evento.id + "_op" + string(b)), 2, _r[2] - _r[0] - 32);
        oDia.texto(_r[0] + 16, _r[1] + 14, _op_txt, 2, c_white, fa_left, fa_top, 1, false, 3);
        var _w_mud = _desenhar_mudancas(_r[0] + 16, _r[3] - 46, escolha_mudancas(evento.opcoes[b - 1]), _verde, _vermelho);
        // Custos que não são barras também aparecem antes de escolher (quebra, porta fechada, coleta)
        var _ex = evento.opcoes[b - 1][$ "extra"];
        if (is_struct(_ex)) {
            var _aviso = "", _cor_aviso = _vermelho;
            if (is_string(_ex[$ "quebra"])) _aviso = tr("esc_quebrou", tr("maq_" + _ex.quebra + "_nome"));
            else if (is_numeric(_ex[$ "bloqueia_expedicao"])) _aviso = tr("esc_sem_expedicao");
            else if (is_struct(_ex[$ "coleta"])) { _aviso = tr("esc_coletou", materiais_texto(_ex.coleta)); _cor_aviso = _verde; }
            if (_aviso != "") oDia.texto(_r[0] + 16 + _w_mud + ((_w_mud > 0) ? 12 : 0), _r[3] - 38, _aviso, 2, _cor_aviso, fa_left, fa_top);
        }
    }
} else {
    // Resultado: o que aconteceu depois da escolha
    var _res = oDia.texto_quebrar(tr("esc_" + evento.id + "_res" + string(escolhida)), 3, txt_w);
    oDia.texto(txt_x, img_y, _res, 3, c_white, fa_left, fa_top, 1, false, 4);
    var _y = img_y + oDia.texto_altura(_res, 3, 4) + 30;

    oDia.texto(txt_x, _y, tr("esc_consequencia"), 2, _amarelo, fa_left, fa_top);
    _y += 26;
    var _w = _desenhar_mudancas(txt_x, _y, mudancas, _verde, _vermelho);
    if (_w == 0) oDia.texto(txt_x, _y + 6, tr("esc_nada_mudou"), 2, _suave, fa_left, fa_top);
    _y += 50;
    if (is_string(mudancas[$ "quebrou"])) {
        oDia.texto(txt_x, _y, oDia.texto_quebrar(tr("esc_quebrou", mudancas.quebrou), 2, txt_w), 2, _vermelho, fa_left, fa_top);
        _y += 30;
    }
    if (is_struct(mudancas[$ "coleta"])) {
        oDia.texto(txt_x, _y, tr("esc_coletou", materiais_texto(mudancas.coleta)), 2, _verde, fa_left, fa_top);
        _y += 30;
    }
    if (is_struct(evento.opcoes[escolhida - 1][$ "extra"]) && is_numeric(evento.opcoes[escolhida - 1].extra[$ "bloqueia_expedicao"])) {
        oDia.texto(txt_x, _y, tr("esc_sem_expedicao"), 2, _vermelho, fa_left, fa_top);
    }

    var _hover = point_in_rectangle(_m[0], _m[1], bot_ok[0], bot_ok[1], bot_ok[2], bot_ok[3]);
    draw_set_color(_hover ? make_color_rgb(80, 85, 95) : make_color_rgb(50, 54, 62));
    draw_rectangle(bot_ok[0], bot_ok[1], bot_ok[2], bot_ok[3], false);
    draw_set_color(_hover ? _amarelo : _borda);
    draw_rectangle(bot_ok[0], bot_ok[1], bot_ok[2], bot_ok[3], true);
    oDia.texto((bot_ok[0] + bot_ok[2]) / 2, (bot_ok[1] + bot_ok[3]) / 2 + 1, tr("modal_ok"), 3, c_white, fa_center, fa_middle);
}
draw_set_alpha(1);
draw_set_color(c_white);
