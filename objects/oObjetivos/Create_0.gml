// =====================================================================
// oObjetivos - barra lateral da missão e tela final dos 10 Sols
// =====================================================================
// Criado pelo oGameManager.
// - Barra lateral (direita): o motivo da missão, os objetivos com barras de progresso,
//   o estoque de materiais e onde está a expedição. Tab esconde/mostra.
// - Tela final: quando global.fim_missao vira "vitoria" ou "derrota" (oDia), mostra o
//   resultado com estrelas e o botão para jogar de novo.

depth = -9000;     // Draw GUI antes do oDia (-10000): fica por baixo das janelas
aberta = true;
minimizada = false;      // começa aberto; o botão [-] recolhe no botão "!" (Mission)
card_rect = undefined;   // retângulo do card na tela (o clique ali não vai para as máquinas)
bot_denovo = [640 - 140, 0, 640 + 140, 0];   // posição vertical calculada ao desenhar
