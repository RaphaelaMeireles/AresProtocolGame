// =====================================================================
// scr_emocoes - ícones de pixel art dos balões de emoção da tripulação
// =====================================================================
// Cada ícone é uma grade 7x7: "." = transparente; letras = cores (tabela abaixo).
// Os sprites são criados uma vez, na primeira vez que alguém pede um ícone.
// Para criar um ícone novo: acrescente em global.emocoes_grades e use pelo nome.

global.emocoes_cores = {
    R: [222, 56, 56],    // vermelho
    Y: [255, 214, 64],   // amarelo
    B: [70, 140, 230],   // azul
    G: [70, 180, 80],    // verde
    P: [160, 90, 200],   // roxo
    O: [150, 95, 60],    // marrom (vaso)
    S: [130, 135, 145],  // cinza (metal)
    K: [30, 30, 36],     // preto
    W: [250, 250, 250],  // branco
    D: [200, 120, 70],   // poeira / regolito marciano
    F: [176, 84, 60],    // ferro (vermelho de ferrugem)
    L: [120, 160, 210],  // silício (cristal azulado)
    N: [205, 205, 215]   // magnésio (metal prateado)
};

global.emocoes_grades = {
    coracao:      [".RR.RR.", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R...", "......."],
    exclamacao:   ["...R...", "..RRR..", "..RRR..", "...R...", "...R...", ".......", "...R..."],
    interrogacao: [".BBBB..", "B....B.", ".....B.", "...BB..", "...B...", ".......", "...B..."],
    zzz:          ["BBBB...", "..B....", ".B.....", "BBBB...", "....BBB", ".....B.", "....BBB"],
    musica:       ["..PPPPP", "..P...P", "..P...P", "..P...P", "PPP.PPP", "PPP.PPP", "......."],
    fome:         ["...G...", "..G....", ".RRRRR.", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..R.R.."],
    triste:       ["...B...", "..BBB..", ".BBBBB.", ".BBBBB.", ".BBBBB.", "..BBB..", "......."],
    feliz:        [".YYYYY.", "YYKYKYY", "YYYYYYY", "YKYYYKY", "YYKKKYY", ".YYYYY.", "......."],
    conversa:     [".......", ".......", ".......", ".K.K.K.", ".......", ".......", "......."],
    ferramenta:   [".S.S.S.", "SSSSSSS", ".SS.SS.", "SS...SS", ".SS.SS.", "SSSSSSS", ".S.S.S."],
    energia:      ["...YY..", "..YY...", ".YYYYY.", "...YY..", "..YY...", ".YY....", "......."],
    planta:       ["..G.G..", ".GGGGG.", "..GGG..", "...G...", "...G...", "..OOO..", "..OOO.."],
    estrela:      ["...Y...", "...Y...", "YYYYYYY", ".YYYYY.", "..YYY..", ".YY.YY.", "Y.....Y"],
    medo:         ["R.R.R..", "R.R.R..", "R.R.R..", "R.R.R..", ".......", "R.R.R..", "......."],

    // Materiais de Marte (estoque e expedições)
    mat_poeira:   [".D...D.", "...D...", "D..D.D.", ".D...D.", "..D.D..", "D...D.D", ".D.D..."],
    mat_regolito: [".......", "..DDD..", ".DDKDD.", "DDDDDKD", "DKDDDDD", ".DDDDD.", "......."],
    mat_ferro:    [".......", "..FFFFF", ".FFFFFF", "FFFFFFK", "FFFFFK.", "KKKKK..", "......."],
    mat_silicio:  ["...L...", "..LLL..", ".LLWLL.", "LLLLLLL", ".LLLLL.", "..LLL..", "...L..."],
    mat_magnesio: [".......", ".NNN...", "NNNNN..", "NNWNNN.", ".NNNNNN", "..NNNN.", "......."]
};

global.emocoes_sprites = {};
global.emocoes_rgba = undefined;

/// @function emocao_superficie_rgba()
/// @description true se as superfícies guardam os bytes como R,G,B,A (varia por plataforma)
function emocao_superficie_rgba() {
    if (global.emocoes_rgba == undefined) {
        var _s = surface_create(1, 1);
        surface_set_target(_s); draw_clear(c_red); surface_reset_target();
        var _b = buffer_create(4, buffer_fixed, 1);
        buffer_get_surface(_b, _s, 0);
        global.emocoes_rgba = (buffer_peek(_b, 0, buffer_u8) > 128);
        buffer_delete(_b); surface_free(_s);
    }
    return global.emocoes_rgba;
}

/// @function emocao_sprite(nome)
/// @description Sprite 7x7 do ícone (criado na primeira vez). Nome desconhecido usa "interrogacao".
function emocao_sprite(_nome) {
    var _spr = global.emocoes_sprites[$ _nome];
    if (_spr != undefined && sprite_exists(_spr)) return _spr;

    var _grade = global.emocoes_grades[$ _nome];
    if (_grade == undefined) return emocao_sprite("interrogacao");

    var _w = string_length(_grade[0]), _h = array_length(_grade);
    var _rgba = emocao_superficie_rgba();
    var _buf = buffer_create(_w * _h * 4, buffer_fixed, 1);
    for (var _yy = 0; _yy < _h; _yy++) {
        for (var _xx = 0; _xx < _w; _xx++) {
            var _ch  = string_char_at(_grade[_yy], _xx + 1);
            var _cor = global.emocoes_cores[$ _ch];
            if (_cor == undefined) {
                buffer_write(_buf, buffer_u32, 0);
            } else {
                buffer_write(_buf, buffer_u8, _rgba ? _cor[0] : _cor[2]);
                buffer_write(_buf, buffer_u8, _cor[1]);
                buffer_write(_buf, buffer_u8, _rgba ? _cor[2] : _cor[0]);
                buffer_write(_buf, buffer_u8, 255);
            }
        }
    }
    var _surf = surface_create(_w, _h);
    buffer_set_surface(_buf, _surf, 0);
    _spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
    surface_free(_surf);
    buffer_delete(_buf);

    global.emocoes_sprites[$ _nome] = _spr;
    return _spr;
}

/// @function emocao_desenhar_balao(x, y, nome, escala)
/// @description Balão branco com o ícone dentro. (x, y) = ponta de baixo do balão.
///   escala anima o "pop" do balão (0 a 1).
function emocao_desenhar_balao(_x, _y, _nome, _escala) {
    if (_escala <= 0) return;
    var _w = 13 * _escala, _h = 11 * _escala;
    var _x1 = round(_x - _w / 2), _y1 = round(_y - _h - 3 * _escala);
    var _x2 = round(_x + _w / 2), _y2 = round(_y - 3 * _escala);

    // Contorno e fundo do balão
    draw_set_color(make_color_rgb(30, 30, 36));
    draw_rectangle(_x1 - 1, _y1, _x2 + 1, _y2, false);
    draw_rectangle(_x1, _y1 - 1, _x2, _y2 + 1, false);
    draw_set_color(c_white);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    // Rabinho apontando para a cabeça
    draw_set_color(make_color_rgb(30, 30, 36));
    draw_triangle(_x - 2, _y2, _x + 2, _y2, _x, _y + 1, false);
    draw_set_color(c_white);
    draw_triangle(_x - 1, _y2 - 1, _x + 1, _y2 - 1, _x, _y, false);

    // Ícone no meio
    gpu_set_texfilter(false);
    draw_sprite_ext(emocao_sprite(_nome), 0, round(_x - 3.5 * _escala), round(_y1 + 2 * _escala),
                    _escala, _escala, 0, c_white, 1);
}
