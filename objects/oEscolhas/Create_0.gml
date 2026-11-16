// =====================================================================
// oEscolhas - imprevistos do dia com escolha (estilo RPG)
// =====================================================================
// Criado pelo oGameManager. No início de cada dia aparecem os imprevistos do dia (scr_escolhas:
// clima, manutenção e expedição), um de cada vez, com duas opções. O jogador vê o que
// cada opção custa, escolhe, e depois vê a consequência.
// A janela mostra uma foto da NASA (biblioteca de imagens) ligada ao assunto do evento.

depth = -12000;   // acima do oDia e da janela de expedição

estado    = "esperando";   // "esperando" | "escolhendo" | "resultado"
dia_visto = -1;
fila      = [];            // imprevistos do dia que ainda vão aparecer (início do dia)
evento    = undefined;
escolhida = 0;             // 1 ou 2 depois de escolher
mudancas  = undefined;     // o que mudou de verdade (para mostrar no resultado)
imagem    = -1;            // foto da NASA
imagem_titulo = "";
imagem_pronta = false;
seq       = 0;             // ignora fotos que chegarem atrasadas de um evento anterior

// --- Layout (coordenadas da GUI, 1280 x 720) ---
jan_x1 = 90;  jan_y1 = 50;  jan_x2 = 1190; jan_y2 = 670;
img_x = jan_x1 + 40; img_y = jan_y1 + 110; img_w = 400; img_h = 270;   // espaço embaixo para o crédito da foto
txt_x = img_x + img_w + 32; txt_w = jan_x2 - 40 - txt_x;
bot1 = [jan_x1 + 40, jan_y2 - 170, (jan_x1 + jan_x2) / 2 - 12, jan_y2 - 40];
bot2 = [(jan_x1 + jan_x2) / 2 + 12, jan_y2 - 170, jan_x2 - 40, jan_y2 - 40];
bot_ok = [640 - 100, jan_y2 - 90, 640 + 100, jan_y2 - 40];

/// Tem alguém em expedição lá fora agora?
tem_expedicao = function() {
    return instance_exists(oExpedicao) && oExpedicao.missao != undefined;
};

/// Abre a janela de um evento
abrir = function(_ev) {
    evento = _ev;
    estado = "escolhendo";
    escolhida = 0;
    mudancas = undefined;
    global.ui_bloqueada = true;
    pedir_imagem(_ev.busca_imagem);
};

/// Fecha a janela e devolve o jogo ao jogador
fechar = function() {
    estado = "esperando";
    evento = undefined;
    global.ui_bloqueada = false;
    if (imagem != -1 && sprite_exists(imagem)) sprite_delete(imagem);
    imagem = -1;
};

/// Escolhe uma das opções (1 ou 2)
escolher = function(_n) {
    escolhida = _n;
    mudancas = escolha_aplicar(evento.opcoes[_n - 1]);
    estado = "resultado";
};

/// Foto da NASA para a janela (mesmo caminho das fotos da noite: oNasaAPI)
pedir_imagem = function(_busca) {
    seq += 1;
    imagem_pronta = false;
    imagem_titulo = "";
    if (imagem != -1 && sprite_exists(imagem)) sprite_delete(imagem);
    imagem = -1;
    if (!instance_exists(oNasaAPI)) { imagem_pronta = true; return; }

    var _cb_busca = method({ dono: id, s: seq }, function(_ok, _dados) {
        if (!instance_exists(dono) || dono.seq != s) return;
        var _itens = (_ok && is_struct(_dados) && is_struct(_dados[$ "collection"])) ? _dados.collection[$ "items"] : undefined;
        if (!is_array(_itens) || array_length(_itens) == 0) { dono.imagem_pronta = true; return; }
        var _item = _itens[irandom(array_length(_itens) - 1)];
        var _links = _item[$ "links"];
        if (!is_array(_links) || array_length(_links) == 0) { dono.imagem_pronta = true; return; }
        var _url = _links[0].href;
        for (var i = 0; i < array_length(_links); i++) if (string_pos("~small.", _links[i].href) > 0) { _url = _links[i].href; break; }
        if (is_array(_item[$ "data"]) && array_length(_item.data) > 0) dono.imagem_titulo = string(_item.data[0][$ "title"]);
        var _cb_img = method({ dono: dono, s: s }, function(_ok2, _spr) {
            if (!instance_exists(dono) || dono.seq != s) {
                if ((is_real(_spr) || is_handle(_spr)) && sprite_exists(_spr)) sprite_delete(_spr);
                return;
            }
            dono.imagem = _ok2 ? _spr : -1;
            dono.imagem_pronta = true;
        });
        oNasaAPI.baixar_imagem(_url, _cb_img);
    });
    oNasaAPI.pedir_imagens_busca(_busca, _cb_busca);
};
