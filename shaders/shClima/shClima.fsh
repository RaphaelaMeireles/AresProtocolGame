//
// shClima - efeitos de clima por cima da tela (desenhado num retângulo do tamanho da tela)
//   u_modo 1 = tempestade de poeira (névoa laranja que corre com o vento)
//   u_modo 2 = tempestade solar (aurora verde e roxa no alto do céu)
//   u_modo 3 = radiação (faíscas roxas piscando, como estática)
//   u_forca 0 a 1 = intensidade; u_tempo = segundos; u_res = tamanho da tela
// Tudo em blocos de 4 px, para combinar com a pixel art.
//
varying vec2 v_vPos;
varying vec4 v_vColour;

uniform float u_tempo;
uniform float u_modo;
uniform float u_forca;
uniform vec2  u_res;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main()
{
    vec2 bloco = floor(v_vPos / 4.0) * 4.0;   // pixelado
    vec2 uv = bloco / u_res;
    vec4 cor = vec4(0.0);

    if (u_modo < 1.5)
    {
        // Poeira: duas camadas de ruído correndo para a direita
        float n1 = ruido(uv * vec2(5.0, 3.0) + vec2(u_tempo * 0.5, u_tempo * 0.08));
        float n2 = ruido(uv * vec2(16.0, 8.0) + vec2(u_tempo * 1.4, 0.0));
        float a = (0.20 + 0.35 * n1 + 0.15 * n2) * u_forca;
        cor = vec4(0.80, 0.47, 0.24, a);
    }
    else if (u_modo < 2.5)
    {
        // Aurora: faixa ondulando no alto da tela
        float onda = sin(uv.x * 8.0 + u_tempo * 1.2 + sin(uv.x * 3.0 - u_tempo) * 2.0);
        float faixa = smoothstep(0.18, 0.0, abs(uv.y - 0.16 - 0.05 * onda));
        vec3 c = mix(vec3(0.25, 1.0, 0.55), vec3(0.75, 0.35, 1.0), uv.x);
        float pisca = 0.85 + 0.15 * sin(u_tempo * 6.0);
        cor = vec4(c, (faixa * 0.55 * pisca + 0.05) * u_forca);
    }
    else
    {
        // Radiação: faíscas que piscam em lugares sorteados
        float s = hash(bloco + floor(u_tempo * 10.0));
        float faisca = step(0.992, s);
        cor = vec4(0.78, 0.55, 1.0, (faisca * 0.9 + 0.06) * u_forca);
    }

    gl_FragColor = cor;
}
