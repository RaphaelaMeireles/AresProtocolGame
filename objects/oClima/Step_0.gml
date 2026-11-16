tempo += 1 / game_get_speed(gamespeed_fps);

// Novo dia: o clima passa a ser o do evento da última noite
if (global.dia != dia_visto) {
    dia_visto = global.dia;
    var _rel = instance_exists(oEventos) ? oEventos.relatorio : undefined;
    if (_rel != undefined) comecar(_rel.evento.id, _rel.intensidade);
}

// O clima vai acalmando ao longo do dia, mas não some de vez (fica um resto até a próxima noite)
if (modo != 0 && !global.ui_bloqueada) forca = max(0.25, forca - 0.00015);

var _cam = view_camera[0];
var _cx = camera_get_view_x(_cam), _cy = camera_get_view_y(_cam);
var _cw = camera_get_view_width(_cam), _ch = camera_get_view_height(_cam);

// --- Grãos de poeira voando com o vento (modo 1) ---
if (modo == 1 && random(1) < forca * 0.9) {
    array_push(graos, { x: _cx - 4, y: _cy + random(_ch), v: 1.5 + random(2.5) * forca, vy: random_range(-0.2, 0.3), t: 0 });
}
for (var i = array_length(graos) - 1; i >= 0; i--) {
    var _g = graos[i];
    _g.x += _g.v; _g.y += _g.vy + sin((_g.t + i) * 0.1) * 0.2; _g.t += 1;
    if (_g.x > _cx + _cw + 8 || _g.t > 600) array_delete(graos, i, 1);
}

// --- Meteoros (modo 4): riscam o céu e caem lá fora; perto da tela, a câmera treme ---
if (modo == 4 && random(1) < 0.012 * (1 + forca * 2)) {
    // Cai num ponto do chão de Marte (fora da base) dentro da área vista
    var _alvo = [_cx + random(_cw), _cy + random(_ch)];
    for (var k = 0; k < 8 && mapa_livre(_alvo[0], _alvo[1]); k++) _alvo = [_cx + random(_cw), _cy + random(_ch)];
    array_push(meteoros, { x: _alvo[0] - 90, y: _alvo[1] - 140, ax: _alvo[0], ay: _alvo[1], t: 0, impacto: 0 });
}
for (var i = array_length(meteoros) - 1; i >= 0; i--) {
    var _m = meteoros[i];
    if (_m.impacto == 0) {
        _m.t += 1;
        _m.x = lerp(_m.ax - 90, _m.ax, _m.t / 40);
        _m.y = lerp(_m.ay - 140, _m.ay, _m.t / 40);
        if (_m.t >= 40) { _m.impacto = 1; tremida = max(tremida, 10); }
    } else {
        _m.impacto += 1;
        if (_m.impacto > 45) array_delete(meteoros, i, 1);
    }
}
if (modo != 4) meteoros = [];
if (modo != 1) graos = [];

// Tremida da câmera no impacto (desloca a vista por poucos frames)
if (tremida > 0) {
    tremida -= 1;
    camera_set_view_pos(_cam, _cx + irandom_range(-1, 1), _cy + irandom_range(-1, 1));
}
