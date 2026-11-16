// =====================================================================
// oPortal - uma ponta de uma passagem entre módulos (tubo ou corredor de ligação)
// =====================================================================
// Criado por mapa_criar_portais() (scr_mapa), chamado pelo oGameManager. Cada passagem tem
// dois portais ligados (par). O tripulante que precisa ir a outro módulo anda até o portal,
// some aos poucos e reaparece no portal do outro lado (oTripulante, estado "portal").
// As posições ficam em global.mapa_passagens (scr_mapa). F2 mostra os portais e as ligações.

par    = noone;   // o portal da outra ponta da passagem
regiao = 0;       // módulo em que este portal fica (mapa_regiao)
nome   = "";      // nome da passagem (corredor, tubo, topo)
brilho = 0;       // luz rápida quando alguém passa (1 = acabou de passar)
