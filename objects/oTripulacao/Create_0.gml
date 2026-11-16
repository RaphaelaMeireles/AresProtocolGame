// =====================================================================
// oTripulacao - cria a tripulação e cuida da convivência entre eles
// =====================================================================
// Criado pelo oGameManager, depois que a grade de caminhada (scr_mapa) já existe.
// Cada personagem pequeno da camada "Personagens" vira um oTripulante no mesmo lugar
// (o desenho do editor é substituído pelo personagem com vida). Assim a equipe continua
// posicionando os astronautas pelo editor da room.
// F2 mostra/esconde a grade por onde eles podem andar.

depth = -15000;
mostrar_grade = false;

// Nomes da tripulação (aparecem nas expedições): cada desenho da camada Personagens tem o seu nome.
// Desenhos sem nome aqui usam a lista de reserva.
var _nome_do_sprite = { Sprite1: "Mia", Sprite2: "John", Sprite3: "Kevin" };
var _nomes = ["Ana", "Leo", "Theo", "Lia", "Davi"];
var _n = 0;

var _lay = layer_get_id("Personagens");
if (_lay != -1) {
    var _els = layer_get_all_elements(_lay);
    for (var i = 0; i < array_length(_els); i++) {
        if (layer_get_element_type(_els[i]) != layerelementtype_sprite) continue;
        var _spr = layer_sprite_get_sprite(_els[i]);
        // Só personagens do tamanho de gente (até 24 px de largura na room, já com a escala do editor)
        var _r = mapa_retangulo_elemento(_els[i]);
        if (_r[2] - _r[0] > 24) continue;
        var _pes = mapa_ponto_livre_perto((_r[0] + _r[2]) / 2, _r[3] - 2);
        var _nome_tripulante = _nome_do_sprite[$ sprite_get_name(_spr)];
        if (_nome_tripulante == undefined) _nome_tripulante = _nomes[_n mod array_length(_nomes)];
        instance_create_depth(_pes[0], _pes[1], -_pes[1], oTripulante, { sprite_index: _spr, nome: _nome_tripulante, escala: layer_sprite_get_xscale(_els[i]) });
        _n += 1;
        layer_sprite_destroy(_els[i]);
    }
}
show_debug_message("Tripulação: " + string(instance_number(oTripulante)) + " astronautas");
