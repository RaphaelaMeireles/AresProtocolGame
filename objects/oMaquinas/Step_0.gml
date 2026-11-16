// --- Máquina embaixo do mouse (só quando o jogador pode interagir) ---
hover = undefined;
if (!global.ui_bloqueada) {
    var _m = mouse_room();
    for (var i = 0; i < array_length(global.maquinas); i++) {
        var _q = global.maquinas[i];
        if (_q.def.tipo == "decoracao") continue;
        if (point_in_rectangle(_m[0], _m[1], _q.x1, _q.y1, _q.x2, _q.y2)) hover = _q;
    }
    // Clique no X do painel da NASA fecha o painel (e não conta como clique na máquina)
    var _no_x = false;
    if (nasa_tempo > 0 && mouse_check_button_pressed(mb_left)) {
        var _mg = mouse_gui();
        var _fim_painel = (display_get_gui_width() - 900) / 2 - 24 + 948;   // canto direito do painel
        if (point_in_rectangle(_mg[0], _mg[1], _fim_painel - 30, nasa_painel_y + 8, _fim_painel - 8, nasa_painel_y + 30)) {
            nasa_tempo = 0;
            _no_x = true;
        }
    }
    var _na_interface = instance_exists(oDia) && oDia.mouse_no_hud();
    if (!_no_x && !_na_interface && hover != undefined && mouse_check_button_pressed(mb_left)) usar(hover);
}

// --- Fumaça saindo das máquinas quebradas ---
for (var i = 0; i < array_length(global.maquinas); i++) {
    var _q = global.maquinas[i];
    if (_q.quebrada && random(1) < 0.08) {
        array_push(fumacas, { x: random_range(_q.x1 + 4, _q.x2 - 4), y: _q.y1 + 4, t: 0, faisca: (random(1) < 0.25) });
    }
}
for (var i = array_length(fumacas) - 1; i >= 0; i--) {
    var _f = fumacas[i];
    _f.t += 1; _f.y -= 0.25; _f.x += sin(_f.t * 0.1) * 0.15;
    if (_f.t > 70) array_delete(fumacas, i, 1);
}

// --- Textos que sobem e somem ---
for (var i = array_length(popups) - 1; i >= 0; i--) {
    popups[i].t += 1;
    if (popups[i].t > 90) array_delete(popups, i, 1);
}

if (nasa_tempo > 0) nasa_tempo -= 1;

// Painel do Mission Control acabou de fechar (X ou troca de dia): o card de missão volta como estava
if (nasa_aberto_antes && nasa_tempo <= 0) {
    if (card_missao_era_aberto && instance_exists(oObjetivos)) oObjetivos.minimizada = false;
    card_missao_era_aberto = false;
}
nasa_aberto_antes = (nasa_tempo > 0);
