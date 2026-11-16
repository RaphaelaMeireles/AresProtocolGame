// =====================================================================
// Evento assíncrono Image Loaded: imagem pedida em baixar_imagem terminou de baixar
// =====================================================================
var _chave = chave(async_load[? "id"]);
var _pedido = imagens[$ _chave];
if (_pedido == undefined) {
    show_debug_message("NASA: imagem carregada sem pedido correspondente (id " + _chave + ")");
    exit;
}
variable_struct_remove(imagens, _chave);

var _spr = async_load[? "id"];
var _ok = (async_load[? "status"] >= 0) && sprite_exists(_spr);
if (_ok) {
    show_debug_message("NASA: imagem pronta (" + string(sprite_get_width(_spr)) + " x "
                       + string(sprite_get_height(_spr)) + ")");
    _pedido.callback(true, _spr);
    exit;
}

// Falhou: libera o sprite vazio e tenta o outro endereço da mesma foto, se houver
show_debug_message("NASA: não foi possível baixar a imagem (status "
                   + string(async_load[? "status"]) + ") " + string(_pedido.tentativas[_pedido.i]));
if (sprite_exists(_spr)) sprite_delete(_spr);

if (_pedido.i + 1 < array_length(_pedido.tentativas)) {
    baixar_imagem_tentar(_pedido.tentativas, _pedido.i + 1, _pedido.callback);
} else {
    _pedido.callback(false, -1);
}
