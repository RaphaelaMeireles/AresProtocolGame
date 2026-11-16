// =====================================================================
// --- Sistema de dias: máquina de estados ---
// =====================================================================
// --- X do painel do clima (canto inferior esquerdo) ---
if (painel_clima && (estado == "jogando" || estado == "esperando" || estado == "escurecendo")
    && mouse_check_button_pressed(mb_left)) {
    var _mx_painel = mouse_gui();
    if (point_in_rectangle(_mx_painel[0], _mx_painel[1], 602, painel_fy, 624, painel_fy + 22)) {
        painel_clima = false;
    }
}

// --- Volume da música: + e - funcionam em qualquer tela (teclado numérico e teclas principais) ---
if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(187)) volume_mudar(0.1);
if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(189)) volume_mudar(-0.1);
if (musica_aviso > 0) musica_aviso -= 1;

switch (estado) {
    case "menu":
        if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) { menu_iniciar(); break; }
        if (clicou_em(menu_x, menu_y_jogar, menu_w, menu_h)) menu_iniciar();
        else if (clicou_em(menu_x, menu_y_tutorial, menu_w, menu_h)) { estado = "tutorial"; tut_pagina = 0; tut_antes_do_jogo = false; }
        else if (clicou_em(menu_x, menu_y_idioma, menu_w, menu_h)) idioma_alternar();
        else if (clicou_em(menu_x, menu_y_musica, 80, menu_h)) volume_mudar(-0.1);
        else if (clicou_em(menu_x + menu_w - 80, menu_y_musica, 80, menu_h)) volume_mudar(0.1);
        break;

    case "tutorial":
        // "Skip tutorial" (canto de cima): só antes do dia 1, vai direto para o jogo
        if (tut_antes_do_jogo && clicou_em(tut_pular_x, tut_pular_y, tut_pular_w, tut_pular_h)) { menu_jogar(); break; }
        // Botão "Menu" (embaixo, no meio) ou Esc: volta para o menu
        if (keyboard_check_pressed(vk_escape) || clicou_em(tut_x_menu, tut_y, tut_w_meio, 56)) { estado = "menu"; break; }
        if (keyboard_check_pressed(vk_left) || clicou_em(tut_x_anterior, tut_y, tut_w, 56)) {
            if (tut_pagina > 0) tut_pagina -= 1;
            break;
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)
            || clicou_em(tut_x_proxima, tut_y, tut_w, 56)) {
            if (tut_pagina >= tut_total - 1) menu_jogar();   // última página: Jogar
            else tut_pagina += 1;
        }
        break;

    case "abertura":
        abertura_t += 1;
        var _inicio = abertura_inicio_cartao();
        var _pos    = musica_posicao();
        var _agora  = (_pos >= 0) ? _pos : abertura_t / game_get_speed(gamespeed_fps);

        // Pular a espera: avança a música até o mesmo ponto, então a sincronia continua
        if (abertura_t > abertura_pode_pular && _agora < _inicio
            && (keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_left))) {
            if (_pos >= 0) audio_sound_set_track_position(global.musica, _inicio);
            abertura_t = ceil(_inicio * game_get_speed(gamespeed_fps));
            _agora = _inicio;
        }

        if (_agora >= _inicio) iniciar_cartao(false);
        break;

    case "cartao":
        cartao_t += 1;
        // Quando o número termina de rolar, o dia muda de verdade
        if (cartao_rolar && global.dia != cartao_para
            && cartao_t >= cartao_entra + cartao_espera + cartao_rola) {
            global.dia = cartao_para;
        }
        if (cartao_t >= cartao_total) estado = "clareando";
        break;

    case "clareando":
        fade_alpha = max(0, fade_alpha - fade_vel);
        if (fade_alpha <= 0) estado = "modal";
        break;

    case "modal":
        // Fecha a janela do dia com clique no OK, Enter ou Espaço
        var _m = mouse_gui();
        var _clicou_ok = mouse_check_button_pressed(mb_left)
            && point_in_rectangle(_m[0], _m[1], botao_x1, botao_y1, botao_x2, botao_y2);
        if (_clicou_ok || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
            estado = "liberando";
        }
        break;

    case "liberando":
        // Um frame depois do OK: o clique que fechou a janela já não conta como clique no posto
        if (missao_falhou()) break;     // status em zero depois da noite: a missão acaba aqui
        global.ui_bloqueada = false;
        estado = "jogando";
        break;

    case "jogando":
        // Qualquer status (vida, energia, comida ou escudo) em zero: a missão falha
        if (missao_falhou()) break;
        // Botão "Skip the Day": termina o dia agora (os pontos de ação que sobraram são perdidos)
        if (skip_visivel() && mouse_check_button_pressed(mb_left)) {
            var _bs = skip_botao(), _ms = mouse_gui();
            if (point_in_rectangle(_ms[0], _ms[1], _bs[0], _bs[1], _bs[2], _bs[3])) global.raios = 0;
        }
        if (global.raios <= 0 && !global.ui_bloqueada) {
            estado = "esperando";
            espera_minima = 2;   // dá tempo do oHUD perceber a queda e iniciar o efeito
        }
        break;

    case "esperando":
        // Deixa o efeito do último raio terminar antes de escurecer
        if (espera_minima > 0) { espera_minima -= 1; break; }
        var _efeito = instance_exists(oHUD) && oHUD.efeito_rodando;
        if (!_efeito) {
            estado = "escurecendo";
            global.ui_bloqueada = true;
        }
        break;

    case "escurecendo":
        fade_alpha = min(1, fade_alpha + fade_vel);
        if (fade_alpha >= 1) {
            // Tela totalmente preta: recarrega os raios, passa o Sol da colônia,
            // começa o evento da noite (a NASA responde enquanto o cartão está na tela)
            // e mostra o cartão do próximo dia
            // Último Sol da missão: em vez de outra noite, vem a tela final (oObjetivos)
            if (global.dia >= MISSAO_DIAS) {
                global.fim_missao = "vitoria";
                estado = "fim";
                break;
            }
            global.raios = global.raios_max;
            colonia_ciclo_sol();
            if (instance_exists(oEventos)) oEventos.iniciar_noite(global.dia + 1);
            if (instance_exists(oExpedicao)) oExpedicao.nova_noite(global.dia + 1);
            iniciar_cartao(true);
        }
        break;

    case "fim":
        // Tela final da missão (oObjetivos): a tela preta clareia e o jogo para
        fade_alpha = max(0, fade_alpha - fade_vel);
        global.ui_bloqueada = true;
        break;
}
