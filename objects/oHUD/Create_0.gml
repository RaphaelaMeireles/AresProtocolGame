// =====================================================================
// oHUD - raios (ações do dia) e barras de status (vida, energia, comida) da camada Status
// =====================================================================
// Criado pelo oGameManager. Os sprites ficam na camada Status (visíveis no editor);
// este objeto cria as cópias dos raios, troca os sprites e desenha os efeitos.

// Desenha por cima de todas as camadas (os efeitos precisam aparecer na frente do HUD)
depth = -16000;   // acima da camada Status (-15500), para o brilho dos raios aparecer por cima

var _camada = layer_get_id("Status");

// O HUD fica acima de tudo que está na room (tripulação, máquinas e textos de clique).
// O oHUD (os efeitos dos raios) fica ainda mais acima, em -16000.
if (_camada != -1) layer_depth(_camada, -15500);

// --- Raios: ações do dia ---
// No editor, coloque UM sRaioPreenchido na camada Status: ele marca o raio da direita.
// O código cria as outras cópias para a esquerda, até completar raios_max.
raios = [];
var _ancora = -1;

if (_camada != -1) {
    var _elementos = layer_get_all_elements(_camada);
    for (var i = 0; i < array_length(_elementos); i++) {
        var _el = _elementos[i];
        if (layer_get_element_type(_el) == layerelementtype_sprite
            && layer_sprite_get_sprite(_el) == sRaioPreenchido) {
            _ancora = _el;
            break;
        }
    }
}

if (_ancora != -1) {
    var _ax     = layer_sprite_get_x(_ancora);
    var _ay     = layer_sprite_get_y(_ancora);
    var _escx   = layer_sprite_get_xscale(_ancora);   // mantém a escala usada no editor
    var _escy   = layer_sprite_get_yscale(_ancora);
    var _esp    = 2;                                  // espaço entre os raios
    var _passo  = sprite_get_width(sRaioPreenchido) * _escx + _esp;

    for (var i = 0; i < global.raios_max; i++) {
        if (i == global.raios_max - 1) {
            raios[i] = _ancora;                       // o raio do editor é o último (direita)
        } else {
            var _x = _ax - (global.raios_max - 1 - i) * _passo;
            raios[i] = layer_sprite_create(_camada, _x, _ay, sRaioPreenchido);
            layer_sprite_xscale(raios[i], _escx);
            layer_sprite_yscale(raios[i], _escy);
        }
    }
} else {
    show_debug_message("Aviso: nenhum sRaioPreenchido encontrado na camada Status.");
}

// --- Barras de status: sVida, sEnergia e sComida ---
// Cada sprite tem 6 quadros: o primeiro é a barra cheia (5) e o último, vazia (0).
// No editor a camada animaria os quadros sem parar (a barra "subia e descia"); aqui a animação
// é parada e o quadro mostrado passa a ser escolhido pelo valor do status.
barras = [];
var _defs = [
    { spr: sVida,    status: "vida"    },
    { spr: sEnergia, status: "energia" },
    { spr: sComida,  status: "comida"  },
    { spr: sEscudo,  status: "escudo"  }
];
if (_camada != -1) {
    var _els = layer_get_all_elements(_camada);
    for (var d = 0; d < array_length(_defs); d++) {
        var _achou = false;
        for (var i = 0; i < array_length(_els); i++) {
            if (layer_get_element_type(_els[i]) == layerelementtype_sprite
                && layer_sprite_get_sprite(_els[i]) == _defs[d].spr) {
                layer_sprite_speed(_els[i], 0);      // sem animação automática
                array_push(barras, { el: _els[i], spr: _defs[d].spr, status: _defs[d].status });
                _achou = true;
                break;
            }
        }
        if (!_achou) show_debug_message("Aviso: barra " + sprite_get_name(_defs[d].spr) + " não encontrada na camada Status.");
    }
}

/// Quadro da barra para um valor: cheio = quadro 0, vazio = último quadro
quadro_da_barra = function(_spr, _valor, _max) {
    var _n = sprite_get_number(_spr);
    var _cheio = clamp(_valor / max(1, _max), 0, 1);
    // O sEscudo foi desenhado ao contrário (quadro 0 = vazio, último = cheio)
    if (_spr == sEscudo) return round(_cheio * (_n - 1));
    return round((1 - _cheio) * (_n - 1));
};

// --- Efeito ao gastar um raio: o raio brilha e treme antes de apagar ---
raios_anterior  = global.raios;
efeito_dur      = 30;                                    // duração em frames (meio segundo a 60 FPS)
efeito_tempo    = array_create(global.raios_max, 0);   // tempo restante do efeito em cada raio
efeito_rodando  = false;                                 // lido pelo oDia antes de escurecer a tela
