// Intro (hito 4): viñetas con placeholders hasta tener arte.

export const INTRO_TYPE_DELAY_MS = 45;
export const INTRO_AUTO_ADVANCE_MS = 2500;
export const INTRO_FADE_MS = 400;

export const INTRO_TEXT_BOX_HEIGHT = 40;
export const INTRO_TEXT_PADDING = 8;

export interface IntroShape {
  x: number;
  y: number;
  w: number;
  h: number;
  color: number;
  label?: string;
}

export interface IntroImage {
  key: string;
  file: string;
  // Escala y posición del centro de la imagen en pantalla (inicio -> fin).
  fromScale: number;
  toScale: number;
  fromX: number;
  toX: number;
  fromY: number;
  toY: number;
  durationMs: number;
  // Tubos de escape (humo): posición en píxeles de la propia imagen original.
  exhausts?: Array<[number, number]>;
}

export interface IntroHorns {
  // Zona de pantalla donde aparecen las bocinas.
  x: [number, number];
  y: [number, number];
}

export interface IntroPanel {
  bgColor: number;
  shapes: IntroShape[];
  text: string;
  image?: IntroImage;
  horns?: IntroHorns;
  haze?: boolean;
}

export const INTRO_HORN_WORDS = ['PIII!', '¡PI PI!', 'BIP!', 'PÍIIII!'];
export const INTRO_HORN_INTERVAL_MS = 650;
export const INTRO_HORN_RISE_PX = 10;
export const INTRO_HORN_LIFE_MS = 700;
export const INTRO_HORN_SHAKE_MS = 120;
export const INTRO_HORN_SHAKE_INTENSITY = 0.002;

export const INTRO_SMOKE_TEXTURE_SIZE = 16;
export const INTRO_SMOKE_TINTS = [0xe0e0e0, 0xb5b5b5, 0x8f8f8f];
export const INTRO_SMOKE_FREQUENCY_MS = 110;
export const INTRO_SMOKE_LIFE_MS: [number, number] = [1100, 1800];
export const INTRO_SMOKE_SPEED_Y: [number, number] = [-70, -35];
export const INTRO_SMOKE_SPEED_X: [number, number] = [4, 22];
export const INTRO_SMOKE_SCALE: [number, number] = [0.7, 2.2];
export const INTRO_SMOKE_ALPHA = 0.75;

export const INTRO_HAZE_COLOR = 0xc9a66b;
export const INTRO_HAZE_MAX_ALPHA = 0.4;

export const INTRO_PANELS: IntroPanel[] = [
  {
    // Sevilla, Torre del Oro: plano general con pan hacia la torre
    bgColor: 0x000000,
    shapes: [],
    image: {
      key: 'intro_torre_oro',
      file: 'assets/backgrounds/intro_sevilla_torre_oro_v1.jpg',
      fromScale: 0.26,
      toScale: 0.26,
      fromX: 193,
      toX: 127,
      fromY: 75,
      toY: 65,
      durationMs: 4500,
    },
    horns: { x: [150, 290], y: [75, 115] },
    haze: true,
    text: 'Otra semana igual.',
  },
  {
    // Sevilla, avenida atascada: zoom hacia el tráfico
    bgColor: 0x000000,
    shapes: [],
    image: {
      key: 'intro_atasco',
      file: 'assets/backgrounds/intro_sevilla_atasco_v1.jpg',
      fromScale: 0.22,
      toScale: 0.4,
      fromX: 160,
      toX: 298,
      fromY: 70,
      toY: 14,
      durationMs: 4500,
    },
    horns: { x: [40, 140], y: [45, 110] },
    haze: true,
    text: 'Ruido, prisas, humo.',
  },
  {
    // Ara dentro de la T3, en mitad del atasco (humo de tubos de escape)
    bgColor: 0x000000,
    shapes: [],
    image: {
      key: 'intro_interior_furgo',
      file: 'assets/backgrounds/intro_interior_furgo_v1.jpg',
      fromScale: 0.25,
      toScale: 0.27,
      fromX: 175,
      toX: 165,
      fromY: 72,
      toY: 70,
      durationMs: 4500,
      exhausts: [
        [540, 452],
        [610, 425],
        [700, 492],
        [820, 448],
        [985, 418],
      ],
    },
    horns: { x: [120, 280], y: [55, 100] },
    text: 'Necesito salir de aquí.',
  },
  {
    // La T3 aparcada en la calle
    bgColor: 0x22303c,
    shapes: [
      { x: 0, y: 110, w: 320, h: 30, color: 0x3a3a3a },
      { x: 110, y: 70, w: 100, h: 50, color: 0xf2efe6, label: 'VW T3' },
      { x: 125, y: 115, w: 16, h: 10, color: 0x111111 },
      { x: 179, y: 115, w: 16, h: 10, color: 0x111111 },
    ],
    text: 'Ella siempre está lista.',
  },
  {
    // Carretera alejándose de la ciudad, hacia el bosque
    bgColor: 0x3d5a80,
    shapes: [
      { x: 0, y: 90, w: 320, h: 50, color: 0x2d6a4f },
      { x: 140, y: 90, w: 40, h: 50, color: 0x555555, label: 'carretera' },
      { x: 20, y: 60, w: 20, h: 30, color: 0x1b4332, label: 'bosque' },
      { x: 260, y: 55, w: 24, h: 35, color: 0x1b4332 },
      { x: 150, y: 120, w: 20, h: 12, color: 0xf2efe6 },
    ],
    text: 'Rumbo al bosque. Sin plan. Solo un buen spot.',
  },
];
