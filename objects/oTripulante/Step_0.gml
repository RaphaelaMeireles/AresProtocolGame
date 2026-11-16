// Em expedição: está fora da base (invisível), o oExpedicao traz de volta
if (estado == "fora") exit;

// Quem está mais embaixo na tela fica na frente (visão de cima)
depth = -y;

// --- Animação: está andando? para que lado? ---
andando = (abs(x - x_ant) + abs(y - y_ant) > 0.05);
if (abs(x - x_ant) > 0.05) virado = sign(x - x_ant);
x_ant = x;
y_ant = y;
anim  += andando ? 0.3 : 0.05;
passo += andando ? 0.12 + vel * 0.08 : 0;
if (!andando) passo = 0;
pulo = max(0, pulo - 0.4);
if (estado != "portal") alpha_corpo = min(1, alpha_corpo + 0.03);   // no portal o corpo some (fade)

// --- Balão: aparece com um "pop" e some sozinho ---
if (emocao_tempo > 0) {
    emocao_tempo -= 1;
    emocao_pop = min(1, emocao_pop + 0.15);
} else {
    emocao_pop = max(0, emocao_pop - 0.2);
}

// --- Reação à noite: quando o dia muda, cada um reage ao evento que aconteceu ---
if (global.dia != dia_visto) {
    dia_visto = global.dia;
    var _rel = instance_exists(oEventos) ? oEventos.relatorio : undefined;
    var _icone = "feliz";
    if (_rel != undefined) {
        var _p = _rel.perdas;
        if (_p.vida > 0)                                  _icone = "triste";
        else if (_rel.intensidade >= 3)                   _icone = "medo";
        else if (_p.energia > 0 || _p.comida > 0)         _icone = "exclamacao";
    }
    falar(_icone, 180 + irandom(120));
}

cooldown_conversa = max(0, cooldown_conversa - 1);

// --- Comportamento ---
switch (estado) {
    case "parado":
        espera -= 1;
        if (espera <= 0) decidir();
        break;

    case "andando":
        // Preso (ex.: caminho bloqueado por outro motivo): desiste e pensa de novo
        travado = andando ? 0 : travado + 1;
        // Se travou indo para um portal, atravessa assim mesmo (nunca fica preso na porta)
        if (travado > 90 && portal_alvo != noone && instance_exists(portal_alvo)) { estado = "portal"; break; }
        if (travado > 90) { alvo_maquina = undefined; parar(); break; }

        if (path_position >= 1) {
            if (portal_alvo != noone && instance_exists(portal_alvo)) {
                // Chegou no portal da passagem: entra no tubo (some aos poucos)
                estado = "portal";
                break;
            }
            if (indo_expedicao) {
                // Chegou no airlock vindo de outro módulo: sai para a expedição
                indo_expedicao = false;
                estado = "expedicao";
                break;
            }
            if (alvo_maquina != undefined) {
                // Chegou na máquina: vira para ela e usa por um tempo
                estado = "usando";
                espera = irandom_range(150, 300);
                virado = ((alvo_maquina.x1 + alvo_maquina.x2) / 2 >= x) ? 1 : -1;
                falar(icone_uso != "" ? icone_uso : alvo_maquina.def.icone, espera);
            } else {
                parar();
            }
        }
        break;

    case "portal":
        // Entrando no tubo: some, reaparece do outro lado e segue o caminho
        alpha_corpo = max(0, alpha_corpo - 0.08);
        if (alpha_corpo <= 0) {
            if (instance_exists(portal_alvo) && instance_exists(portal_alvo.par)) atravessar_portal();
            else { portal_alvo = noone; parar(); }
        }
        break;

    case "usando":
        espera -= 1;
        if (espera <= 0) { alvo_maquina = undefined; icone_uso = ""; parar(); }
        break;

    case "conversando":
        espera -= 1;
        if (instance_exists(parceiro)) virado = (parceiro.x >= x) ? 1 : -1;
        // A cada pouco, um balão novo (os dois se revezam: um fala enquanto o outro escuta)
        if (emocao_tempo <= 0 && (espera mod 70) < 2) {
            falar(choose("conversa", "conversa", "feliz", "coracao", "musica", "interrogacao", "estrela"), 55);
        }
        if (espera <= 0) {
            parceiro = noone;
            cooldown_conversa = irandom_range(300, 600);
            parar();
        }
        break;

    case "expedicao":
        // Chegou na porta: some (o rover sai dirigindo lá fora)
        if (path_position >= 1 || path_index == -1) {
            alpha_corpo = max(0, alpha_corpo - 0.05);
            if (alpha_corpo <= 0) {
                path_end();
                estado = "fora";
                visible = false;
            }
        } else {
            alpha_corpo = 1;
        }
        break;
}
