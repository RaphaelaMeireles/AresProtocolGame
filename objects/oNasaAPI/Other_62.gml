// =====================================================================
// Evento assíncrono HTTP: resposta de pedir_json / pedir_api / pedir_imagens_busca
// =====================================================================
var _id = chave(async_load[? "id"]);
var _callback = pedidos[$ _id];
if (_callback == undefined) exit;          // não é uma requisição deste objeto

var _status = async_load[? "status"];
if (_status == 1) exit;                    // ainda baixando: espera a próxima chamada
variable_struct_remove(pedidos, _id);

var _ok = false;
var _dados = undefined;
var _http = async_load[? "http_status"];

if (_status == 0 && _http == 200) {
    try {
        _dados = json_parse(async_load[? "result"]);
        _ok = true;
    } catch (_erro) {
        show_debug_message("NASA: resposta não é JSON válido em " + string(async_load[? "url"]));
    }
} else {
    show_debug_message("NASA: falha (status " + string(_status) + ", HTTP " + string(_http)
                       + ") em " + string(async_load[? "url"]));
}

_callback(_ok, _dados);
