// =====================================================================
// scr_mapa - onde a tripulação pode andar (paredes, portas e móveis)
// =====================================================================
// A grade de caminhada é montada sozinha quando a room começa:
//   1) lê a arte do fundo (camada "Background") e marca como chão as cores de piso;
//   2) remove bordas finas (o contorno claro de fora dos módulos não é chão);
//   3) abre passagem pelas portas (cinza) e pela ponta dos corredores;
//   4) bloqueia o espaço ocupado pelas máquinas e móveis (camadas "Maquinas" e "Moveis").
// Se a arte do fundo mudar de cor, ajuste MAPA_CORES_* abaixo. F2 no jogo mostra a grade.

#macro MAPA_CEL 8   // tamanho de cada célula da grade, em pixels

// Cores do fundo (R, G, B). Tolerância: soma das diferenças menor que 12.
global.mapa_cores_piso     = [[213,176,157], [215,188,171], [218,185,164], [168,140,122], [137,137,137], [100,101,99]];
global.mapa_cores_porta    = [[137,137,137], [100,101,99]];    // portas e escotilhas
global.mapa_cores_corredor = [[215,188,171]];                   // piso dos corredores
global.mapa_cores_sala     = [[213,176,157]];                   // piso das salas

// Sprites que ficam nas camadas de cenário mas não bloqueiam a passagem (tapetes, quadros na parede)
global.mapa_sem_colisao = ["sTapete", "sQuadro"];

global.mapa = undefined;

#macro MAPA_REGIAO_MIN 60   // pedaços de chão menores que isto (em células) são descartados

/// @function mapa_cor_piso_generica(r, g, b)
/// @description Chão dos módulos sem depender da cor exata: tons claros de bege/cinza
///   (o chão de Marte lá fora é laranja forte e os contornos são escuros, então ficam de fora).
///   Assim a grade funciona mesmo se a arte do fundo for exportada com cores um pouco diferentes.
function mapa_cor_piso_generica(_r, _g, _b) {
    return (_r > 120 && _g > 100 && (_r - _b) < 100);
}

/// @function mapa_cor_perto(r, g, b, lista)
function mapa_cor_perto(_r, _g, _b, _lista) {
    for (var i = 0; i < array_length(_lista); i++) {
        var _c = _lista[i];
        if (abs(_c[0] - _r) + abs(_c[1] - _g) + abs(_c[2] - _b) < 12) return true;
    }
    return false;
}

/// @function mapa_sprite_fundo()
/// @description Sprite usado na camada de fundo da room (ou sPrincipal, se não achar)
function mapa_sprite_fundo() {
    var _camada = layer_get_id("Background");
    if (_camada != -1) {
        var _bg = layer_background_get_id(_camada);
        if (_bg != -1) {
            var _spr = layer_background_get_sprite(_bg);
            if (sprite_exists(_spr)) return _spr;
        }
    }
    return sPrincipal;
}

/// @function mapa_montar()
/// @description Monta a grade de caminhada (mp_grid) da room atual em global.mapa.
function mapa_montar() {
    var _cel  = MAPA_CEL;
    var _w    = room_width;
    var _h    = room_height;
    var _cols = _w div _cel;
    var _lins = _h div _cel;

    // --- 1) Desenha o fundo numa superfície e copia os pixels para um buffer ---
    var _surf = surface_create(_w, _h);
    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0);
    draw_sprite(mapa_sprite_fundo(), 0, 0, 0);
    surface_reset_target();
    var _buf = buffer_create(_w * _h * 4, buffer_fixed, 1);
    buffer_get_surface(_buf, _surf, 0);
    surface_free(_surf);

    // Ordem dos bytes da superfície (RGBA ou BGRA) varia por plataforma: testa com um pixel vermelho
    var _teste = surface_create(1, 1);
    surface_set_target(_teste); draw_clear(c_red); surface_reset_target();
    var _bt = buffer_create(4, buffer_fixed, 1);
    buffer_get_surface(_bt, _teste, 0);
    var _rgba = (buffer_peek(_bt, 0, buffer_u8) > 128);   // primeiro byte é o vermelho?
    buffer_delete(_bt); surface_free(_teste);
    var _or = _rgba ? 0 : 2;
    var _ob = _rgba ? 2 : 0;

    // --- 2) Classifica cada célula (amostra 16 pontos por célula) ---
    var _n     = _cols * _lins;
    var _piso  = array_create(_n, false);
    var _porta = array_create(_n, false);
    var _corr  = array_create(_n, false);
    var _sala  = array_create(_n, false);

    for (var cy = 0; cy < _lins; cy++) {
        for (var cx = 0; cx < _cols; cx++) {
            var _cp = 0, _cpo = 0, _cc = 0, _cs = 0, _tot = 0, _escuro = false;
            for (var yy = cy * _cel; yy < cy * _cel + _cel; yy += 2) {
                for (var xx = cx * _cel; xx < cx * _cel + _cel; xx += 2) {
                    var _o = (yy * _w + xx) * 4;
                    var _r = buffer_peek(_buf, _o + _or, buffer_u8);
                    var _g = buffer_peek(_buf, _o + 1,   buffer_u8);
                    var _b = buffer_peek(_buf, _o + _ob, buffer_u8);
                    _tot += 1;
                    if (_r + _g + _b < 150) _escuro = true;   // contorno preto das paredes
                    if (mapa_cor_perto(_r, _g, _b, global.mapa_cores_piso) || mapa_cor_piso_generica(_r, _g, _b)) _cp += 1;
                    if (mapa_cor_perto(_r, _g, _b, global.mapa_cores_porta))    _cpo += 1;
                    if (mapa_cor_perto(_r, _g, _b, global.mapa_cores_corredor)) _cc += 1;
                    if (mapa_cor_perto(_r, _g, _b, global.mapa_cores_sala))     _cs += 1;
                }
            }
            var _i = cy * _cols + cx;
            // Chão: quase toda a célula com cor de piso E nenhum pedaço do contorno escuro das paredes.
            // Sem isso, a faixa clara/marrom entre os contornos da parede contava como chão.
            _piso[_i]  = (_cp  >= _tot * 0.6) && !_escuro;
            _porta[_i] = (_cpo >= _tot * 0.15);
            _corr[_i]  = (_cc  >= _tot * 0.5);
            _sala[_i]  = (_cs  >= _tot * 0.3);
        }
    }
    buffer_delete(_buf);

    // --- 3) Abertura: só é chão a célula que faz parte de um bloco 3x3 todo de chão ---
    var _livre = array_create(_n, false);
    for (var cy = 1; cy < _lins - 1; cy++) {
        for (var cx = 1; cx < _cols - 1; cx++) {
            var _cheio = true;
            for (var dy = -1; dy <= 1 && _cheio; dy++)
                for (var dx = -1; dx <= 1; dx++)
                    if (!_piso[(cy + dy) * _cols + cx + dx]) { _cheio = false; break; }
            if (_cheio) {
                for (var dy = -1; dy <= 1; dy++)
                    for (var dx = -1; dx <= 1; dx++) _livre[(cy + dy) * _cols + cx + dx] = true;
            }
        }
    }

    // --- 4) Portas e pontas de corredor: abre passagem em linha reta pela parede (até 5 células) ---
    var _dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    for (var cy = 0; cy < _lins; cy++) {
        for (var cx = 0; cx < _cols; cx++) {
            var _i = cy * _cols + cx;
            var _perto_sala = false;
            for (var dy = -2; dy <= 2 && !_perto_sala; dy++)
                for (var dx = -2; dx <= 2; dx++) {
                    var _x = cx + dx, _y = cy + dy;
                    if (_x >= 0 && _y >= 0 && _x < _cols && _y < _lins && _sala[_y * _cols + _x]) { _perto_sala = true; break; }
                }
            var _fonte = _porta[_i] || (_corr[_i] && _livre[_i] && !_perto_sala);
            if (!_fonte) continue;
            _livre[_i] = true;
            for (var d = 0; d < 4; d++) {
                for (var k = 1; k <= 5; k++) {
                    var _x = cx + _dirs[d][0] * k, _y = cy + _dirs[d][1] * k;
                    if (_x < 0 || _y < 0 || _x >= _cols || _y >= _lins) break;
                    var _j = _y * _cols + _x;
                    if (_livre[_j] && !_porta[_j]) {
                        for (var m = 1; m < k; m++) _livre[(cy + _dirs[d][1] * m) * _cols + cx + _dirs[d][0] * m] = true;
                        break;
                    }
                }
            }
        }
    }

    global.mapa = {
        cel: _cel, cols: _cols, lins: _lins,
        livre: _livre,
        grade: mp_grid_create(0, 0, _cols, _lins, _cel, _cel),
        lista: []          // células livres alcançáveis (preenchida no fim)
    };

    // --- 5) Máquinas e móveis bloqueiam a parte de baixo do desenho (a "base" no chão) ---
    var _camadas = ["Maquinas", "Moveis"];
    for (var c = 0; c < array_length(_camadas); c++) {
        var _lay = layer_get_id(_camadas[c]);
        if (_lay == -1) continue;
        var _els = layer_get_all_elements(_lay);
        for (var e = 0; e < array_length(_els); e++) {
            if (layer_get_element_type(_els[e]) != layerelementtype_sprite) continue;
            var _spr = layer_sprite_get_sprite(_els[e]);
            if (array_contains(global.mapa_sem_colisao, sprite_get_name(_spr))) continue;
            var _ret = mapa_retangulo_elemento(_els[e]);
            var _alt = _ret[3] - _ret[1];
            mapa_bloquear(_ret[0] + 2, _ret[1] + _alt * 0.35, _ret[2] - 2, _ret[3] - 2);
        }
    }

    // --- 6) Só valem os pedaços de chão grandes (cada módulo é um pedaço; cantinhos soltos saem) ---
    mapa_manter_regioes_grandes();

    // --- 7) Tubos e corredores de ligação deixam de ser chão (passa-se pelos portais) ---
    mapa_bloquear_passagens();


    // Passa para o mp_grid: tudo que não é livre fica bloqueado
    for (var _i = 0; _i < _n; _i++) {
        if (!global.mapa.livre[_i]) mp_grid_add_cell(global.mapa.grade, _i mod _cols, _i div _cols);
    }
    show_debug_message("Mapa: " + string(array_length(global.mapa.lista)) + " células livres para a tripulação");
}

/// @function mapa_retangulo_elemento(elemento)
/// @description [x1, y1, x2, y2] na room de um sprite de camada de asset (considera origem e escala)
function mapa_retangulo_elemento(_el) {
    var _spr = layer_sprite_get_sprite(_el);
    var _sx  = layer_sprite_get_xscale(_el);
    var _sy  = layer_sprite_get_yscale(_el);
    var _x1  = layer_sprite_get_x(_el) - sprite_get_xoffset(_spr) * _sx;
    var _y1  = layer_sprite_get_y(_el) - sprite_get_yoffset(_spr) * _sy;
    return [_x1, _y1, _x1 + sprite_get_width(_spr) * _sx, _y1 + sprite_get_height(_spr) * _sy];
}

/// @function mapa_bloquear(x1, y1, x2, y2)
function mapa_bloquear(_x1, _y1, _x2, _y2) {
    var _m = global.mapa;
    var _c1 = max(0, floor(_x1 / _m.cel)), _c2 = min(_m.cols - 1, floor(_x2 / _m.cel));
    var _l1 = max(0, floor(_y1 / _m.cel)), _l2 = min(_m.lins - 1, floor(_y2 / _m.cel));
    for (var cy = _l1; cy <= _l2; cy++)
        for (var cx = _c1; cx <= _c2; cx++) _m.livre[cy * _m.cols + cx] = false;
}

/// @function mapa_manter_regioes_grandes()
/// @description Rotula os pedaços de chão (global.mapa.regiao) e descarta os menores que
///   MAPA_REGIAO_MIN. Cada módulo da base vira uma região; os portais ligam as regiões.
function mapa_manter_regioes_grandes() {
    var _m = global.mapa;
    var _n = _m.cols * _m.lins;
    var _rot = array_create(_n, 0);
    var _tam = [0];
    var _prox = 0;
    for (var s = 0; s < _n; s++) {
        if (!_m.livre[s] || _rot[s] != 0) continue;
        _prox += 1;
        _rot[s] = _prox;
        var _fila = [s], _t = 0;
        while (array_length(_fila) > 0) {
            var _i = array_pop(_fila); _t += 1;
            var _x = _i mod _m.cols, _y = _i div _m.cols;
            if (_x > 0           && _m.livre[_i - 1]       && _rot[_i - 1] == 0)       { _rot[_i - 1] = _prox;       array_push(_fila, _i - 1); }
            if (_x < _m.cols - 1 && _m.livre[_i + 1]       && _rot[_i + 1] == 0)       { _rot[_i + 1] = _prox;       array_push(_fila, _i + 1); }
            if (_y > 0           && _m.livre[_i - _m.cols] && _rot[_i - _m.cols] == 0) { _rot[_i - _m.cols] = _prox; array_push(_fila, _i - _m.cols); }
            if (_y < _m.lins - 1 && _m.livre[_i + _m.cols] && _rot[_i + _m.cols] == 0) { _rot[_i + _m.cols] = _prox; array_push(_fila, _i + _m.cols); }
        }
        array_push(_tam, _t);
    }
    // Renumera só as regiões grandes (1, 2, 3...) e refaz a lista de células livres
    var _novo = array_create(_prox + 1, 0), _k = 0, _txt = "";
    for (var r = 1; r <= _prox; r++) if (_tam[r] >= MAPA_REGIAO_MIN) { _k += 1; _novo[r] = _k; _txt += string(_tam[r]) + " "; }
    _m.regiao = array_create(_n, 0);
    _m.lista = [];
    for (var i = 0; i < _n; i++) {
        var _r = (_rot[i] > 0) ? _novo[_rot[i]] : 0;
        _m.livre[i] = (_r > 0);
        _m.regiao[i] = _r;
        if (_r > 0) array_push(_m.lista, i);
    }
    show_debug_message("Mapa: " + string(_k) + " regiões de chão (células: " + _txt + ")");
}

/// @function mapa_manter_maior_regiao()
function mapa_manter_maior_regiao() {
    var _m = global.mapa;
    var _n = _m.cols * _m.lins;
    var _rot = array_create(_n, 0);
    var _melhor = 0, _melhor_tam = 0, _prox = 0;
    for (var s = 0; s < _n; s++) {
        if (!_m.livre[s] || _rot[s] != 0) continue;
        _prox += 1;
        var _fila = [s]; _rot[s] = _prox; var _tam = 0;
        while (array_length(_fila) > 0) {
            var _i = array_pop(_fila); _tam += 1;
            var _x = _i mod _m.cols, _y = _i div _m.cols;
            if (_x > 0           && _m.livre[_i - 1]       && _rot[_i - 1] == 0)       { _rot[_i - 1] = _prox;       array_push(_fila, _i - 1); }
            if (_x < _m.cols - 1 && _m.livre[_i + 1]       && _rot[_i + 1] == 0)       { _rot[_i + 1] = _prox;       array_push(_fila, _i + 1); }
            if (_y > 0           && _m.livre[_i - _m.cols] && _rot[_i - _m.cols] == 0) { _rot[_i - _m.cols] = _prox; array_push(_fila, _i - _m.cols); }
            if (_y < _m.lins - 1 && _m.livre[_i + _m.cols] && _rot[_i + _m.cols] == 0) { _rot[_i + _m.cols] = _prox; array_push(_fila, _i + _m.cols); }
        }
        if (_tam > _melhor_tam) { _melhor_tam = _tam; _melhor = _prox; }
    }
    _m.lista = [];
    for (var i = 0; i < _n; i++) {
        _m.livre[i] = (_rot[i] == _melhor && _melhor != 0);
        if (_m.livre[i]) array_push(_m.lista, i);
    }
}

/// @function mapa_livre(x, y)
function mapa_livre(_x, _y) {
    var _m = global.mapa;
    if (_m == undefined) return true;
    var _cx = floor(_x / _m.cel), _cy = floor(_y / _m.cel);
    if (_cx < 0 || _cy < 0 || _cx >= _m.cols || _cy >= _m.lins) return false;
    return _m.livre[_cy * _m.cols + _cx];
}

/// @function mapa_centro_celula(indice)
function mapa_centro_celula(_i) {
    var _m = global.mapa;
    return [(_i mod _m.cols) * _m.cel + _m.cel / 2, (_i div _m.cols) * _m.cel + _m.cel / 2];
}

/// @function mapa_ponto_aleatorio()
/// @description Centro de uma célula livre qualquer: [x, y]
function mapa_ponto_aleatorio() {
    var _m = global.mapa;
    if (_m == undefined || array_length(_m.lista) == 0) return [room_width / 2, room_height / 2];
    return mapa_centro_celula(_m.lista[irandom(array_length(_m.lista) - 1)]);
}

/// @function mapa_ponto_livre_perto(x, y)
/// @description Célula livre mais perto do ponto (procura em anéis, até 12 células de distância)
function mapa_ponto_livre_perto(_x, _y) {
    var _m = global.mapa;
    if (mapa_livre(_x, _y)) return [_x, _y];
    var _cx = floor(_x / _m.cel), _cy = floor(_y / _m.cel);
    for (var r = 1; r <= 12; r++) {
        for (var dy = -r; dy <= r; dy++) {
            for (var dx = -r; dx <= r; dx++) {
                if (abs(dx) != r && abs(dy) != r) continue;
                var _nx = _cx + dx, _ny = _cy + dy;
                if (_nx < 0 || _ny < 0 || _nx >= _m.cols || _ny >= _m.lins) continue;
                if (_m.livre[_ny * _m.cols + _nx]) return mapa_centro_celula(_ny * _m.cols + _nx);
            }
        }
    }
    return mapa_ponto_aleatorio();
}

// =====================================================================
// --- Passagens entre os módulos (objeto oPortal) ---
// =====================================================================
// Os tubos e corredores de ligação NÃO são chão: a tripulação não anda por cima deles.
// Cada passagem tem um oPortal em cada ponta (dentro de cada módulo). Para ir a outro módulo,
// o tripulante anda até o portal da sua sala, some aos poucos (como se entrasse no tubo)
// e reaparece no portal do outro lado, seguindo até o destino.
// Coordenadas em pixels da room, medidas na arte de fundo (sprites/sPrincipal):
//   bloqueio  retângulo do tubo/corredor que deixa de ser chão
//   a, b      onde ficam os dois portais (um ponto dentro de cada módulo, perto do tubo)
global.mapa_passagens = [
    { nome: "corredor", bloqueio: [446, 326, 632, 432], a: [432, 378], b: [650, 378] },   // módulo central <-> módulo da direita
    { nome: "tubo",     bloqueio: [255, 472, 340, 552], a: [297, 455], b: [297, 568] },   // módulo central <-> módulo de baixo
    { nome: "topo",     bloqueio: [255, 228, 340, 250], a: [297, 268], b: [297, 205] }    // módulo central <-> módulo do topo
];

/// @function mapa_bloquear_passagens()
/// @description Tira os tubos/corredores da grade de caminhada e separa os módulos em regiões
///   (global.mapa.regiao[i] = número do módulo de cada célula; 0 = não é chão).
function mapa_bloquear_passagens() {
    var _m = global.mapa;
    for (var i = 0; i < array_length(global.mapa_passagens); i++) {
        var _b = global.mapa_passagens[i].bloqueio;
        mapa_bloquear(_b[0], _b[1], _b[2], _b[3]);
    }

    // Refaz as regiões: cada módulo fica separado (sobras pequenas dos tubos saem)
    mapa_manter_regioes_grandes();
}

/// @function mapa_regiao(x, y)
/// @description Número do módulo do ponto (0 se não for chão)
function mapa_regiao(_x, _y) {
    var _m = global.mapa;
    if (_m == undefined || !is_array(_m[$ "regiao"])) return 0;
    var _cx = floor(_x / _m.cel), _cy = floor(_y / _m.cel);
    if (_cx < 0 || _cy < 0 || _cx >= _m.cols || _cy >= _m.lins) return 0;
    return _m.regiao[_cy * _m.cols + _cx];
}

/// @function mapa_criar_portais()
/// @description Cria um oPortal em cada ponta de cada passagem e liga os pares. Chamado pelo
///   oGameManager logo depois de mapa_montar().
function mapa_criar_portais() {
    for (var i = 0; i < array_length(global.mapa_passagens); i++) {
        var _ps = global.mapa_passagens[i];
        var _pa = mapa_ponto_livre_perto(_ps.a[0], _ps.a[1]);
        var _pb = mapa_ponto_livre_perto(_ps.b[0], _ps.b[1]);
        var _a = instance_create_depth(_pa[0], _pa[1], 50, oPortal);
        var _b = instance_create_depth(_pb[0], _pb[1], 50, oPortal);
        _a.par = _b;  _a.regiao = mapa_regiao(_a.x, _a.y);  _a.nome = _ps.nome;
        _b.par = _a;  _b.regiao = mapa_regiao(_b.x, _b.y);  _b.nome = _ps.nome;
        if (_a.regiao == 0 || _b.regiao == 0 || _a.regiao == _b.regiao) {
            show_debug_message("Aviso: a passagem '" + _ps.nome + "' não liga dois módulos diferentes. Ajuste global.mapa_passagens.");
        }
    }
}

/// @function mapa_portal_rumo(x1, y1, x2, y2)
/// @description Primeiro oPortal a usar para ir de (x1, y1) até (x2, y2) quando estão em módulos
///   diferentes (procura o menor número de passagens). noone se estão no mesmo módulo ou sem ligação.
function mapa_portal_rumo(_x1, _y1, _x2, _y2) {
    var _r1 = mapa_regiao(_x1, _y1), _r2 = mapa_regiao(_x2, _y2);
    if (_r1 == 0 || _r2 == 0 || _r1 == _r2) return noone;
    var _visto = {}, _primeiro = {};
    _visto[$ string(_r1)] = true;
    var _fila = [_r1];
    while (array_length(_fila) > 0) {
        var _r = _fila[0];
        array_delete(_fila, 0, 1);
        for (var i = 0; i < instance_number(oPortal); i++) {
            var _p = instance_find(oPortal, i);
            if (_p.regiao != _r || !instance_exists(_p.par)) continue;
            var _rn = _p.par.regiao;
            if (_visto[$ string(_rn)] == true) continue;
            _visto[$ string(_rn)] = true;
            _primeiro[$ string(_rn)] = (_r == _r1) ? _p : _primeiro[$ string(_r)];
            if (_rn == _r2) return _primeiro[$ string(_rn)];
            array_push(_fila, _rn);
        }
    }
    return noone;
}

// =====================================================================
// --- Cenário desenhado por código no chão de Marte (embaixo das máquinas e do rover) ---
// =====================================================================
// Desenhado pelo primeiro oPortal (profundidade 50: em cima do fundo, embaixo das camadas
// Maquinas e Moveis), assim o cabo passa por baixo do Kilopower e o rover sobe por cima da rampa.

// Cabo de energia: sai da parede direita do módulo da direita e vai até a base do Kilopower
// (sReatorFissao em 1040,470; o núcleo fica embaixo do "guarda-chuva", perto de 1085,548).
// Pontos em pixels da room; as curvas são de 45 graus, como os cabos da arte da base.
global.cabo_kilopower = [[951, 452], [990, 452], [1030, 492], [1030, 548], [1082, 548]];

// Rampa do rover na borda direita do mapa: o rover sobe por ela ao sair e desce ao voltar
#macro RAMPA_X1   1180    // começo da rampa (no chão)
#macro RAMPA_X2   1250    // fim da rampa (no alto, na borda do mapa)
#macro RAMPA_ALT  14      // altura da rampa (pixels)
#macro RAMPA_CHAO 628     // altura do chão onde as rodas do rover andam (sRover em y 600, 28 de altura)

/// @function rampa_altura(x)
/// @description Quanto o rover está levantado pela rampa na posição x (das rodas da frente)
function rampa_altura(_x) {
    if (_x <= RAMPA_X1) return 0;
    if (_x >= RAMPA_X2) return RAMPA_ALT;
    return RAMPA_ALT * (_x - RAMPA_X1) / (RAMPA_X2 - RAMPA_X1);
}

/// @function mapa_desenhar_cabo(pontos)
/// @description Cabo grosso com contorno escuro, corpo marrom e brilho em cima (pixel art)
function mapa_desenhar_cabo(_p) {
    var _cores = [ [make_color_rgb(30, 20, 18), 7], [make_color_rgb(110, 66, 52), 5] ];
    for (var c = 0; c < array_length(_cores); c++) {
        draw_set_color(_cores[c][0]);
        var _l = _cores[c][1];
        for (var i = 0; i < array_length(_p) - 1; i++) {
            draw_line_width(_p[i][0], _p[i][1], _p[i + 1][0], _p[i + 1][1], _l);
            draw_circle(_p[i + 1][0], _p[i + 1][1], _l / 2 - 0.5, false);   // curva arredondada
        }
        draw_circle(_p[0][0], _p[0][1], _l / 2 - 0.5, false);
    }
    // brilho fino em cima do cabo
    draw_set_color(make_color_rgb(178, 112, 86));
    for (var i = 0; i < array_length(_p) - 1; i++) {
        draw_line_width(_p[i][0], _p[i][1] - 1, _p[i + 1][0], _p[i + 1][1] - 1, 1);
    }
    // conector na parede da base
    draw_set_color(make_color_rgb(30, 20, 18));
    draw_rectangle(_p[0][0] - 3, _p[0][1] - 6, _p[0][0] + 3, _p[0][1] + 6, false);
    draw_set_color(make_color_rgb(140, 145, 155));
    draw_rectangle(_p[0][0] - 2, _p[0][1] - 5, _p[0][0] + 2, _p[0][1] + 5, false);
}

/// @function mapa_desenhar_rampa()
/// @description Rampa de metal na borda do mapa, por onde o rover sai e volta
function mapa_desenhar_rampa() {
    var _x1 = RAMPA_X1, _x2 = RAMPA_X2, _ch = RAMPA_CHAO, _h = RAMPA_ALT;
    // sombra
    draw_set_alpha(0.3); draw_set_color(c_black);
    draw_triangle(_x1 + 4, _ch + 3, _x2 + 4, _ch + 3, _x2 + 4, _ch - _h + 3, false);
    draw_set_alpha(1);
    // lateral (metal escuro) e o piso da rampa (metal claro)
    draw_set_color(make_color_rgb(70, 74, 82));
    draw_triangle(_x1, _ch, _x2, _ch, _x2, _ch - _h, false);
    draw_set_color(make_color_rgb(150, 155, 165));
    draw_line_width(_x1, _ch - 1, _x2, _ch - _h - 1, 3);
    // faixas de aviso amarelas no piso
    draw_set_color(make_color_rgb(235, 190, 60));
    for (var k = 1; k < 5; k++) {
        var _t = k / 5;
        var _px = lerp(_x1, _x2, _t), _py = lerp(_ch - 1, _ch - _h - 1, _t);
        draw_line_width(_px - 1, _py - 1, _px + 1, _py + 1, 2);
    }
    // contorno e o pé da rampa na borda
    draw_set_color(make_color_rgb(30, 20, 18));
    draw_line(_x1, _ch, _x2, _ch - _h);
    draw_line(_x1, _ch, _x2, _ch);
    draw_rectangle(_x2, _ch - _h, _x2 + 3, _ch, false);
}

/// @function mapa_desenhar_cenario()
/// @description Cabo do Kilopower e rampa do rover (chamado pelo primeiro oPortal)
//function mapa_desenhar_cenario() {
    //mapa_desenhar_cabo(global.cabo_kilopower);
   // mapa_desenhar_rampa();
  //  draw_set_color(c_white);
   // draw_set_alpha(1);
//}

/// @function mapa_desenhar_debug()
/// @description Desenha a grade por cima da room (verde = pode andar). Chamado com F2.
function mapa_desenhar_debug() {
    var _m = global.mapa;
    if (_m == undefined) return;
    draw_set_alpha(0.35);
    draw_set_color(c_lime);
    for (var i = 0; i < array_length(_m.lista); i++) {
        var _x = (_m.lista[i] mod _m.cols) * _m.cel, _y = (_m.lista[i] div _m.cols) * _m.cel;
        draw_rectangle(_x, _y, _x + _m.cel - 2, _y + _m.cel - 2, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}
