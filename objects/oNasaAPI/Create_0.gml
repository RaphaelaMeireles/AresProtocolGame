// =====================================================================
// oNasaAPI - toda comunicação com a internet passa por aqui
// =====================================================================
// Criado pelo oGameManager. Os outros objetos pedem dados ou imagens e passam uma função
// (callback) que é chamada quando a resposta chega:
//     callback(sucesso, resultado)
//       pedir_json / pedir_api / pedir_imagens_busca -> resultado = struct/array do JSON
//       baixar_imagem                                -> resultado = sprite da imagem
// As respostas chegam nos eventos assíncronos HTTP (Other_62) e Image Loaded (Other_60).

pedidos = {};   // id da requisição HTTP -> callback
imagens = {};   // id do sprite sendo baixado -> callback

/// Chave única para um id. sprite_add devolve uma referência de sprite ("ref sprite 123"),
/// mas o evento Image Loaded informa só o número (123). Convertendo os dois para número,
/// a resposta encontra o pedido certo.
chave = function(_id) {
    return string(real(_id));
};

/// Pede uma URL que devolve JSON
pedir_json = function(_url, _callback) {
    if (!NASA_ONLINE) { _callback(false, undefined); return -1; }
    var _id = http_get(_url);
    pedidos[$ chave(_id)] = _callback;
    return _id;
};

/// Pede um endpoint de api.nasa.gov já com a chave. Ex.: pedir_api("/DONKI/CME", "startDate=2026-10-01", cb)
pedir_api = function(_caminho, _parametros, _callback) {
    var _url = NASA_API + _caminho + "?" + _parametros;
    if (_parametros != "") _url += "&";
    _url += "api_key=" + NASA_CHAVE;
    return pedir_json(_url, _callback);
};

/// Busca imagens na biblioteca da NASA (images-api.nasa.gov). Resultado: o JSON da busca
pedir_imagens_busca = function(_termo, _callback) {
    var _url = NASA_IMAGENS_API + "/search?media_type=image&page_size=20&q="
             + string_replace_all(_termo, " ", "%20");
    return pedir_json(_url, _callback);
};

/// Endereço da mesma foto no armazenamento da NASA que autoriza o navegador (ou "" se não se aplica)
url_foto_web = function(_url) {
    var _p = string_pos(NASA_FOTOS_HOST, _url);
    if (_p == 0) return "";
    return NASA_FOTOS_HOST_WEB + string_delete(_url, 1, _p - 1 + string_length(NASA_FOTOS_HOST));
};

/// Baixa uma imagem (JPG/PNG) da internet e devolve um sprite pronto para desenhar.
/// Fotos da biblioteca da NASA têm dois endereços: no navegador começa pelo que autoriza a web;
/// no Windows começa pelo normal. Se o primeiro falhar, tenta o outro antes de desistir.
baixar_imagem = function(_url, _callback) {
    if (!NASA_ONLINE) { _callback(false, -1); return -1; }

    var _web = url_foto_web(_url);
    var _tentativas = [_url];
    if (_web != "") {
        _tentativas = (os_browser != browser_not_a_browser) ? [_web, _url] : [_url, _web];
    }
    return baixar_imagem_tentar(_tentativas, 0, _callback);
};

/// Uso interno: baixa a URL de número _i da lista (as outras ficam guardadas para o caso de falha)
baixar_imagem_tentar = function(_tentativas, _i, _callback) {
    var _url = _tentativas[_i];
    var _spr = sprite_add(_url, 0, false, false, 0, 0);
    if (_spr == -1) {
        show_debug_message("NASA: sprite_add recusou a URL " + _url);
        if (_i + 1 < array_length(_tentativas)) return baixar_imagem_tentar(_tentativas, _i + 1, _callback);
        _callback(false, -1);
        return -1;
    }
    imagens[$ chave(_spr)] = { callback: _callback, tentativas: _tentativas, i: _i };
    show_debug_message("NASA: baixando imagem " + _url);
    return _spr;
};
