// F2: mostra a grade de caminhada (para a equipe conferir paredes e móveis)
// Só funciona com MAPA_DEBUG = true (scr_config); no jogo a grade fica sempre escondida
if (MAPA_DEBUG && keyboard_check_pressed(vk_f2)) mostrar_grade = !mostrar_grade;
if (!MAPA_DEBUG) mostrar_grade = false;

// --- Convivência: dois tripulantes perto um do outro às vezes param para conversar ---
if ((current_time div 250) mod 2 == 0) {
    var _n = instance_number(oTripulante);
    for (var i = 0; i < _n; i++) {
        var _a = instance_find(oTripulante, i);
        if (_a.cooldown_conversa > 0 || (_a.estado != "parado" && _a.estado != "andando")) continue;
        for (var j = i + 1; j < _n; j++) {
            var _b = instance_find(oTripulante, j);
            if (_b.cooldown_conversa > 0 || (_b.estado != "parado" && _b.estado != "andando")) continue;
            if (point_distance(_a.x, _a.y, _b.x, _b.y) > 22 || random(1) > 0.05) continue;

            // Começa a conversa: os dois param, se olham e trocam balões (um começa, o outro responde)
            var _dur = irandom_range(200, 340);
            with (_a) { path_end(); estado = "conversando"; parceiro = _b; espera = _dur;      falar("conversa", 55); }
            with (_b) { path_end(); estado = "conversando"; parceiro = _a; espera = _dur - 35; falar("interrogacao", 40); }
            break;
        }
    }
}
