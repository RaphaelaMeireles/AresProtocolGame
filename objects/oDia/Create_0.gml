// =====================================================================
// oDia - sistema de dias: cartão de troca de dia, janela do dia e dia no rodapé
// =====================================================================
// Criado pelo oGameManager. Usa global.dia, global.energia e global.ui_bloqueada (scr_status)
// e os textos de scr_idioma. Todo texto do jogo é desenhado pela fonte de pixel abaixo.

// GUI na resolução real da tela do jogo (1280 x 720), sem ampliação: bordas ficam nítidas.
// (O HUD da camada Status não usa a GUI; ele continua na escala da room.)
display_set_gui_size(view_wport[0], view_hport[0]);

// =====================================================================
// --- Fonte de pixel desenhada por código (5 x 7 pixels por letra) ---
// =====================================================================
// Cada letra é uma grade de "#" (pixel aceso) e "." (apagado). Desenhada com escala inteira
// (3 = cada pixel da letra vira um quadrado de 3 x 3 na tela), fica grossa e nítida em
// qualquer resolução, sem depender de recurso de fonte. Letras minúsculas viram maiúsculas.
var _g = {};
_g[$ "A"] = [".###.","#...#","#...#","#####","#...#","#...#","#...#"];
_g[$ "B"] = ["####.","#...#","#...#","####.","#...#","#...#","####."];
_g[$ "C"] = [".###.","#...#","#....","#....","#....","#...#",".###."];
_g[$ "D"] = ["####.","#...#","#...#","#...#","#...#","#...#","####."];
_g[$ "E"] = ["#####","#....","#....","####.","#....","#....","#####"];
_g[$ "F"] = ["#####","#....","#....","####.","#....","#....","#...."];
_g[$ "G"] = [".###.","#...#","#....","#.###","#...#","#...#",".####"];
_g[$ "H"] = ["#...#","#...#","#...#","#####","#...#","#...#","#...#"];
_g[$ "I"] = ["###",".#.",".#.",".#.",".#.",".#.","###"];
_g[$ "J"] = ["..###","...#.","...#.","...#.","#..#.","#..#.",".##.."];
_g[$ "K"] = ["#...#","#..#.","#.#..","##...","#.#..","#..#.","#...#"];
_g[$ "L"] = ["#....","#....","#....","#....","#....","#....","#####"];
_g[$ "M"] = ["#...#","##.##","#.#.#","#.#.#","#...#","#...#","#...#"];
_g[$ "N"] = ["#...#","##..#","#.#.#","#..##","#...#","#...#","#...#"];
_g[$ "O"] = [".###.","#...#","#...#","#...#","#...#","#...#",".###."];
_g[$ "P"] = ["####.","#...#","#...#","####.","#....","#....","#...."];
_g[$ "Q"] = [".###.","#...#","#...#","#...#","#.#.#","#..#.",".##.#"];
_g[$ "R"] = ["####.","#...#","#...#","####.","#.#..","#..#.","#...#"];
_g[$ "S"] = [".####","#....","#....",".###.","....#","....#","####."];
_g[$ "T"] = ["#####","..#..","..#..","..#..","..#..","..#..","..#.."];
_g[$ "U"] = ["#...#","#...#","#...#","#...#","#...#","#...#",".###."];
_g[$ "V"] = ["#...#","#...#","#...#","#...#","#...#",".#.#.","..#.."];
_g[$ "W"] = ["#...#","#...#","#...#","#.#.#","#.#.#","#.#.#",".#.#."];
_g[$ "X"] = ["#...#","#...#",".#.#.","..#..",".#.#.","#...#","#...#"];
_g[$ "Y"] = ["#...#","#...#",".#.#.","..#..","..#..","..#..","..#.."];
_g[$ "Z"] = ["#####","....#","...#.","..#..",".#...","#....","#####"];
_g[$ "0"] = [".###.","#...#","#..##","#.#.#","##..#","#...#",".###."];
_g[$ "1"] = ["..#..",".##..","..#..","..#..","..#..","..#..",".###."];
_g[$ "2"] = [".###.","#...#","....#","...#.","..#..",".#...","#####"];
_g[$ "3"] = ["#####","...#.","..#..","...#.","....#","#...#",".###."];
_g[$ "4"] = ["...#.","..##.",".#.#.","#..#.","#####","...#.","...#."];
_g[$ "5"] = ["#####","#....","####.","....#","....#","#...#",".###."];
_g[$ "6"] = ["..##.",".#...","#....","####.","#...#","#...#",".###."];
_g[$ "7"] = ["#####","....#","...#.","..#..",".#...",".#...",".#..."];
_g[$ "8"] = [".###.","#...#","#...#",".###.","#...#","#...#",".###."];
_g[$ "9"] = [".###.","#...#","#...#",".####","....#","...#.",".##.."];
_g[$ " "] = ["...","...","...","...","...","...","..."];
_g[$ "."] = ["..","..","..","..","..","##","##"];
_g[$ ","] = ["..","..","..","..","##",".#","#."];
_g[$ "!"] = ["#","#","#","#","#",".","#"];
_g[$ "?"] = [".###.","#...#","....#","...#.","..#..",".....","..#.."];
_g[$ "-"] = ["....","....","....","####","....","....","...."];
_g[$ ":"] = [".",".","#",".",".","#","."];
_g[$ "'"] = ["#","#",".",".",".",".","."];
_g[$ "/"] = ["....#","...#.","...#.","..#..",".#...",".#...","#...."];
_g[$ "("] = [".#","#.","#.","#.","#.","#.",".#"];
_g[$ ")"] = ["#.",".#",".#",".#",".#",".#","#."];
_g[$ "%"] = ["##..#","##..#","...#.","..#..",".#...","#..##","#..##"];
_g[$ "+"] = [".....","..#..","..#..","#####","..#..","..#..","....."];

// Cada letra vira um sprite pequeno (1 pixel do sprite = 1 pixel da letra), montado pixel a pixel
// por um buffer. Desenhar esse sprite ampliado deixa a letra sólida, sem as frestas (listras)
// que apareciam entre as linhas quando cada linha era um retângulo separado.
// Os sprites são criados uma única vez no jogo e guardados em global.fonte_glifos.
if (!variable_global_exists("fonte_glifos")) {
    global.fonte_glifos = {};
    var _chaves = variable_struct_get_names(_g);
    for (var k = 0; k < array_length(_chaves); k++) {
        var _linhas = _g[$ _chaves[k]];
        var _w = string_length(_linhas[0]);
        var _h = array_length(_linhas);

        // Pixels RGBA: branco opaco onde há "#", transparente no resto
        var _buf = buffer_create(_w * _h * 4, buffer_fixed, 1);
        for (var r = 0; r < _h; r++) {
            for (var c = 0; c < _w; c++) {
                var _v = (string_char_at(_linhas[r], c + 1) == "#") ? 255 : 0;
                buffer_write(_buf, buffer_u8, _v);
                buffer_write(_buf, buffer_u8, _v);
                buffer_write(_buf, buffer_u8, _v);
                buffer_write(_buf, buffer_u8, _v);
            }
        }

        var _surf = surface_create(_w, _h);
        buffer_set_surface(_buf, _surf, 0);
        var _spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
        surface_free(_surf);
        buffer_delete(_buf);

        global.fonte_glifos[$ _chaves[k]] = { w: _w, spr: _spr };
    }
}

// Letras acentuadas usam a letra sem acento (para quando houver textos em português)
fonte_acentos = {
    "Á":"A", "À":"A", "Â":"A", "Ã":"A", "á":"A", "à":"A", "â":"A", "ã":"A",
    "É":"E", "Ê":"E", "é":"E", "ê":"E", "Í":"I", "í":"I",
    "Ó":"O", "Ô":"O", "Õ":"O", "ó":"O", "ô":"O", "õ":"O",
    "Ú":"U", "ú":"U", "Ç":"C", "ç":"C"
};

/// Glifo de um caractere (caractere desconhecido vira "?")
glifo = function(_ch) {
    var _sem_acento = fonte_acentos[$ _ch];
    if (_sem_acento != undefined) _ch = _sem_acento;
    var _gl = global.fonte_glifos[$ string_upper(_ch)];
    return (_gl != undefined) ? _gl : global.fonte_glifos[$ "?"];
};

/// Largura em pixels de uma linha de texto, na escala _s
texto_largura = function(_txt, _s) {
    var _w = 0;
    var _n = string_length(_txt);
    for (var i = 1; i <= _n; i++) _w += (glifo(string_char_at(_txt, i)).w + 1) * _s;
    return max(0, _w - _s);    // sem o espaço depois da última letra
};

/// Desenha uma linha a partir do canto superior esquerdo (uso interno)
texto_linha = function(_x, _y, _txt, _s, _cor, _alpha) {
    _x = floor(_x);
    _y = floor(_y);
    gpu_set_texfilter(false);                  // pixels ampliados sem suavização
    var _n = string_length(_txt);
    for (var i = 1; i <= _n; i++) {
        var _gl = glifo(string_char_at(_txt, i));
        draw_sprite_ext(_gl.spr, 0, _x, _y, _s, _s, 0, _cor, _alpha);
        _x += (_gl.w + 1) * _s;
    }
};

/// Desenha texto (aceita \n) com alinhamento, sombra e transparência.
/// _ha: fa_left / fa_center / fa_right    _va: fa_top / fa_middle / fa_bottom
/// _entre: linhas de pixel vazias entre uma linha de texto e outra
texto = function(_x, _y, _txt, _s, _cor, _ha = fa_left, _va = fa_top, _alpha = 1, _sombra = false, _entre = 3) {
    var _linhas = string_split(_txt, "\n");
    var _alt_linha  = (7 + _entre) * _s;
    var _alt_total  = array_length(_linhas) * _alt_linha - _entre * _s;
    var _y0 = _y;
    if (_va == fa_middle) _y0 -= _alt_total / 2;
    else if (_va == fa_bottom) _y0 -= _alt_total;

    for (var i = 0; i < array_length(_linhas); i++) {
        var _l  = _linhas[i];
        var _lx = _x;
        if (_ha == fa_center) _lx -= texto_largura(_l, _s) / 2;
        else if (_ha == fa_right) _lx -= texto_largura(_l, _s);
        var _ly = _y0 + i * _alt_linha;
        if (_sombra) texto_linha(_lx + _s, _ly + _s, _l, _s, c_black, _alpha);
        texto_linha(_lx, _ly, _l, _s, _cor, _alpha);
    }
};

/// Quebra o texto em linhas que caibam em _larg_max pixels (mantém os \n que já existem)
texto_quebrar = function(_txt, _s, _larg_max) {
    var _saida = "";
    var _paragrafos = string_split(_txt, "\n");
    for (var p = 0; p < array_length(_paragrafos); p++) {
        var _palavras = string_split(_paragrafos[p], " ");
        var _linha = "";
        for (var w = 0; w < array_length(_palavras); w++) {
            var _teste = (_linha == "") ? _palavras[w] : _linha + " " + _palavras[w];
            if (_linha != "" && texto_largura(_teste, _s) > _larg_max) {
                _saida += _linha + "\n";
                _linha = _palavras[w];
            } else {
                _linha = _teste;
            }
        }
        _saida += _linha;
        if (p < array_length(_paragrafos) - 1) _saida += "\n";
    }
    return _saida;
};

// Tamanho de cada texto (escala inteira: cada pixel da letra vira um quadrado desse tamanho)
escala_rodape = 3;
escala_titulo = 6;
escala_texto  = 3;
escala_botao  = 3;
escala_cartao = 12;     // cartão de troca de dia, bem grande no meio da tela preta
escala_credito = 2;     // crédito da imagem e fonte dos dados da NASA

/// Altura em pixels de um texto (com \n), com o mesmo espaçamento usado em texto()
texto_altura = function(_txt, _s, _entre = 3) {
    var _n = array_length(string_split(_txt, "\n"));
    return _n * (7 + _entre) * _s - _entre * _s;
};

// =====================================================================
// --- Estados ---
// =====================================================================
//   "abertura"    só na abertura do jogo: tela preta esperando a música chegar na parte forte
//   "cartao"      tela preta com "DAY N" no meio; na troca de dia, o número rola para o próximo
//   "clareando"   fade de volta do preto, depois abre a janela do dia
//   "modal"       janela do dia aberta (o jogo fica parado até clicar em OK)
//   "liberando"   OK foi apertado: libera o jogo no frame seguinte, para o clique não "vazar"
//   "jogando"     jogo normal
//   "esperando"   energia acabou: espera o efeito do último raio terminar
//   "escurecendo" fade para preto, depois mostra o cartão do próximo dia
global.ui_bloqueada = true;

fade_alpha    = 1;                // começa totalmente preto
fade_vel      = 1 / 45;           // 45 frames para escurecer ou clarear (~0,75 s)
espera_minima = 0;                // frames mínimos no estado "esperando"

// --- Tempos do cartão (em frames, 60 = 1 segundo) ---
cartao_entra   = 20;    // texto aparece
cartao_espera  = 30;    // mostra o dia atual antes de rolar
cartao_rola    = 30;    // número sobe e o próximo entra por baixo
cartao_segura  = 60;    // mostra o novo dia
cartao_sai     = 20;    // texto some

cartao_t      = 0;
cartao_total  = 0;
cartao_rolar  = false;
cartao_de     = global.dia;
cartao_para   = global.dia;

/// Começa o cartão. _rolar = true na troca de dia (número rola para o próximo)
iniciar_cartao = function(_rolar) {
    estado       = "cartao";
    cartao_t     = 0;
    cartao_rolar = _rolar;
    cartao_de    = global.dia;
    cartao_para  = _rolar ? global.dia + 1 : global.dia;
    cartao_total = cartao_entra + (_rolar ? cartao_espera + cartao_rola : 0) + cartao_segura + cartao_sai;

    // Troca de dia fecha os painéis que o jogador abriu (clima e console da NASA)
    painel_clima = false;
    if (instance_exists(oMaquinas)) oMaquinas.nasa_tempo = 0;
};

// Painel do clima e previsão: só aparece depois de clicar numa máquina (fecha pelo X)
painel_clima = false;
painel_fy    = 0;        // posição do X do painel (preenchida ao desenhar)

// =====================================================================
// --- Abertura sincronizada com a música ---
// =====================================================================
// A tela preta da abertura termina exatamente quando a MusicaPrincipal se intensifica:
// o cartão "DAY 1" aparece e some a tempo de a tela começar a clarear nesse instante,
// e o fade termina junto com o pico da música (~25 s).
// O ponto foi medido no arquivo MusicaPrincipal.mp3 (o volume sobe de repente em 24,06 s).
// Se trocar a música, ajuste este valor.
musica_ponto_forte = 24.06;    // segundos
abertura_t = 0;                // frames desde que o jogo abriu
abertura_pode_pular = 30;      // frames antes de aceitar "pular" (evita pular sem querer)

/// Posição atual da música em segundos, ou -1 se ela não estiver tocando
/// (ex.: navegador bloqueou o som até o primeiro clique). Sem música, a abertura usa o relógio do jogo.
musica_posicao = function() {
    if (variable_global_exists("musica") && audio_is_playing(global.musica)) {
        return audio_sound_get_track_position(global.musica);
    }
    return -1;
};

/// Momento (em segundos da música) em que o cartão "DAY 1" precisa começar
/// para terminar exatamente no ponto forte
abertura_inicio_cartao = function() {
    var _dur = (cartao_entra + cartao_segura + cartao_sai) / game_get_speed(gamespeed_fps);
    return musica_ponto_forte - _dur;
};

// Ao abrir o jogo: tela preta até a música chegar perto do ponto forte,
// depois o cartão "DAY 1", a tela clareia e abre a janela do dia
estado = "menu";     // o menu inicial vem antes da abertura (ver menu_jogar)

// --- Layout da janela do dia (coordenadas da GUI, 1280 x 720) ---
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
modal_w  = 1200;                  // largo o bastante para a imagem da NASA ao lado do texto
modal_h  = 660;
modal_x1 = floor((_gw - modal_w) / 2);
modal_y1 = floor((_gh - modal_h) / 2);
modal_x2 = modal_x1 + modal_w;
modal_y2 = modal_y1 + modal_h;
modal_margem = 40;                // espaço interno do painel

botao_w  = 160;
botao_h  = 48;
botao_x1 = floor((_gw - botao_w) / 2);
botao_y1 = modal_y2 - botao_h - 32;
botao_x2 = botao_x1 + botao_w;
botao_y2 = botao_y1 + botao_h;

// =====================================================================
// --- Menu inicial, tutorial e volume ---
// =====================================================================
// Estados "menu" e "tutorial": tela cheia desenhada no fim do Draw_64, por cima de tudo.
// Clique ou Enter/Espaço escolhem. Jogar começa a abertura normal (estado "abertura").
tut_pagina   = 0;
tut_total    = 10;          // páginas do tutorial (chaves tut_p1_titulo ... tut_p10_texto)
musica_aviso = 0;           // frames em que o aviso "Música: 60%" aparece no alto da tela

menu_w          = 440;
menu_h          = 56;
menu_x          = floor(_gw / 2 - menu_w / 2);
menu_y_jogar    = 260;
menu_y_tutorial = 336;
menu_y_idioma   = 412;
menu_y_musica   = 488;      // linha do volume: botão - à esquerda, + à direita
tut_y           = 600;
tut_w           = 200;
tut_w_meio      = 260;      // botão do meio (Menu ou Skip tutorial) é mais largo
tut_x_anterior  = floor(_gw / 2 - 370);
tut_x_menu      = floor(_gw / 2 - 130);
tut_x_proxima   = floor(_gw / 2 + 170);
tut_antes_do_jogo = false;
// "Skip tutorial" (canto de cima, só quando o tutorial abre pelo Jogar, antes do dia 1)
tut_pular_w = 280; tut_pular_h = 48;
tut_pular_x = floor(_gw - 24 - tut_pular_w); tut_pular_y = 24;

/// true se houve clique (na GUI) dentro do retângulo
clicou_em = function(_x, _y, _w, _h) {
    var _m = mouse_gui();
    return mouse_check_button_pressed(mb_left) && point_in_rectangle(_m[0], _m[1], _x, _y, _x + _w, _y + _h);
};

/// Botão com texto centralizado; fica mais claro quando o mouse está em cima
botao_desenhar = function(_x, _y, _w, _h, _txt) {
    var _m = mouse_gui();
    var _sobre = point_in_rectangle(_m[0], _m[1], _x, _y, _x + _w, _y + _h);
    draw_set_color(_sobre ? make_color_rgb(150, 70, 45) : make_color_rgb(60, 40, 42));
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(make_color_rgb(230, 170, 120));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    texto(_x + _w / 2, _y + _h / 2, _txt, 3, c_white, fa_center, fa_middle);
};

/// Fundo do menu e do tutorial: céu escuro com o horizonte de Marte
menu_fundo = function() {
    var _lw = display_get_gui_width();
    var _lh = display_get_gui_height();
    draw_set_alpha(1);
    // Paisagem de Marte desenhada (sMenuFundo), com um véu escuro para os botões ficarem legíveis
    var _bg = sMenuFundo;
    if (sprite_exists(_bg)) {
        gpu_set_texfilter(false);
        draw_sprite_stretched(_bg, 0, 0, 0, _lw, _lh);
        draw_set_color(c_black);
        draw_set_alpha(0.25);
        draw_rectangle(0, 0, _lw, _lh, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        return;
    }
    draw_set_color(make_color_rgb(18, 12, 18));
    draw_rectangle(0, 0, _lw, _lh, false);
    draw_set_color(make_color_rgb(120, 52, 30));
    draw_ellipse(-400, _lh - 150, _lw + 400, _lh + 520, false);
    draw_set_color(make_color_rgb(160, 70, 40));
    draw_ellipse(-200, _lh - 70, _lw + 200, _lh + 620, false);
    draw_set_color(c_white);
};

/// Jogar no menu: primeiro o tutorial (que pode ser pulado), depois o dia 1
menu_iniciar = function() {
    estado = "tutorial";
    tut_pagina = 0;
    tut_antes_do_jogo = true;
};

/// Começa o jogo: a música volta ao início para a abertura cair no ponto forte
menu_jogar = function() {
    estado = "abertura";
    abertura_t = 0;
    if (variable_global_exists("musica") && audio_is_playing(global.musica)) {
        audio_sound_set_track_position(global.musica, 0);
    }
};

/// Aumenta ou diminui o volume da música e mostra o aviso
volume_mudar = function(_delta) {
    musica_ajustar_volume(_delta);
    musica_aviso = 120;
};

/// Derrota: se algum status (vida, energia, comida ou escudo) está em zero, a missão falha.
/// Devolve true quando a missão terminou (quem chama deve parar o que estava fazendo).
missao_falhou = function() {
    var _z = status_zerado();
    if (_z == "") return false;
    global.motivo_derrota = _z;
    global.fim_missao = "derrota";
    global.ui_bloqueada = true;
    estado = "fim";
    return true;
};


// =====================================================================
// --- Botão "Skip the Day" (embaixo dos pontos de ação) ---
// =====================================================================
/// Retângulo do botão na GUI [x1, y1, x2, y2]: logo abaixo dos ícones de ponto de ação do HUD
/// (que ficam na camada Status, presa à câmera). Acompanha zoom e movimento da câmera.
skip_botao = function() {
    var _gwl = display_get_gui_width();
    if (!instance_exists(oHUD) || array_length(oHUD.raios) == 0) return [_gwl - 200, 60, _gwl - 20, 90];
    var _cam = view_camera[0];
    var _f   = _gwl / camera_get_view_width(_cam);
    var _cx  = camera_get_view_x(_cam), _cy = camera_get_view_y(_cam);
    var _x1 = infinity, _x2 = -infinity, _y2 = -infinity;
    for (var i = 0; i < array_length(oHUD.raios); i++) {
        var _el  = oHUD.raios[i];
        var _spr = layer_sprite_get_sprite(_el);
        var _sx  = layer_sprite_get_xscale(_el), _sy = layer_sprite_get_yscale(_el);
        var _ex  = layer_sprite_get_x(_el) - sprite_get_xoffset(_spr) * _sx;
        var _ey  = layer_sprite_get_y(_el) - sprite_get_yoffset(_spr) * _sy;
        _x1 = min(_x1, _ex);
        _x2 = max(_x2, _ex + sprite_get_width(_spr) * _sx);
        _y2 = max(_y2, _ey + sprite_get_height(_spr) * _sy);
    }
    var _gx1 = (_x1 - _cx) * _f, _gx2 = (_x2 - _cx) * _f, _gy = (_y2 - _cy) * _f + 6;
    // Largura mínima para caber o texto, centralizado embaixo dos ícones
    var _larg = max(_gx2 - _gx1, texto_largura(tr("skip_dia"), 2) + 24);
    var _meio = (_gx1 + _gx2) / 2;
    _gx1 = clamp(_meio - _larg / 2, 4, _gwl - _larg - 4);
    return [floor(_gx1), floor(_gy), floor(_gx1 + _larg), floor(_gy + 30)];
};

/// O botão aparece só com o jogo correndo e nenhuma janela aberta
skip_visivel = function() {
    return (estado == "jogando" && !global.ui_bloqueada && global.raios > 0);
};

/// true se o mouse está em cima de algum botão/painel da interface (o clique não vai para as máquinas)
mouse_no_hud = function() {
    var _m = mouse_gui();
    if (skip_visivel()) {
        var _b = skip_botao();
        if (point_in_rectangle(_m[0], _m[1], _b[0], _b[1], _b[2], _b[3])) return true;
    }
    if (instance_exists(oObjetivos) && is_array(oObjetivos.card_rect)) {
        var _c = oObjetivos.card_rect;
        if (point_in_rectangle(_m[0], _m[1], _c[0], _c[1], _c[2], _c[3])) return true;
    }
    return false;
};
