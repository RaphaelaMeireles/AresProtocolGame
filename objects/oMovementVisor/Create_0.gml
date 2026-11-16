// Só uma instância controla a câmera (se houver duplicadas na room, as extras se removem).
// Usa uma variável global para não depender da ordem em que o GameMaker cria as instâncias.
if (variable_global_exists("controlador_camera") && instance_exists(global.controlador_camera)
    && global.controlador_camera != id) {
    instance_destroy();
    exit;
}
global.controlador_camera = id;

// Velocidade da câmera, em pixels por frame
vel = 4;

// Câmera da view 0 (a que está habilitada na room)
cam = view_camera[0];

// A câmera é controlada só por este código (desliga o "Objeto seguindo" da room)
camera_set_view_target(cam, noone);

// Tamanho atual da câmera, lido da configuração da room
cam_w = camera_get_view_width(cam);
cam_h = camera_get_view_height(cam);

// Posição e tamanho iniciais: a camada Status foi montada no editor com a câmera assim
cam_x0 = camera_get_view_x(cam);
cam_y0 = camera_get_view_y(cam);
cam_w0 = cam_w;

// Posição atual da câmera, guardada pelo próprio objeto (fonte única da verdade)
cam_x = cam_x0;
cam_y = cam_y0;

// --- Zoom (Ctrl + scroll) ---
proporcao  = cam_h / cam_w;                                 // mantém o formato da câmera (16:9)
zoom_passo = 1.1;                                           // cada clique da roda muda 10%
// Limite de aproximação: a câmera nunca fica mais perto que zoom_max_vezes
// (2 = cada pixel da arte vira 2 x 2 na tela, a mesma aproximação com que o jogo abre)
zoom_max_vezes = 2;
zoom_min_w = view_wport[0] / zoom_max_vezes;                // mais perto: 640 x 360 (2x)
zoom_max_w = min(room_width, room_height / proporcao);      // mais longe: a room inteira

// --- Rolagem: scroll = vertical, Shift + scroll = horizontal ---
rolagem_passo = 0.1;   // cada clique da roda anda 10% da área visível (igual em qualquer zoom)

// Camada de status (vida, energia...) que deve ficar fixa na tela
layer_status  = layer_get_id("Status");
status_itens  = [];      // posição e escala original de cada sprite da camada
status_pronto = false;   // preenchido no primeiro Step, depois que o oHUD criou os raios
