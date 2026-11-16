// Se a NASA demorar demais, segue sem o que faltou (a janela mostra o texto mesmo assim)
if (relatorio != undefined && !relatorio_pronto()) {
    relatorio.tempo += 1;
    if (relatorio.tempo >= NASA_TEMPO_LIMITE) {
        show_debug_message("NASA: tempo esgotado (dados prontos: " + string(relatorio.dados_prontos)
                           + ", imagem pronta: " + string(relatorio.imagem_pronta) + ")");
        relatorio.imagem_pronta = true;
        noite_seq += 1;   // respostas que chegarem depois disso são descartadas
    }
}
