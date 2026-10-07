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

export interface IntroPanel {
  bgColor: number;
  shapes: IntroShape[];
  text: string;
}

export const INTRO_PANELS: IntroPanel[] = [
  {
    // Ciudad de noche, atasco
    bgColor: 0x1a1a2e,
    shapes: [
      { x: 10, y: 30, w: 40, h: 110, color: 0x2e2e4a },
      { x: 60, y: 50, w: 50, h: 90, color: 0x34345a },
      { x: 120, y: 20, w: 35, h: 120, color: 0x2e2e4a },
      { x: 170, y: 45, w: 60, h: 95, color: 0x34345a },
      { x: 245, y: 35, w: 65, h: 105, color: 0x2e2e4a },
      { x: 20, y: 118, w: 30, h: 14, color: 0xc0392b, label: 'coche' },
      { x: 70, y: 118, w: 30, h: 14, color: 0x2980b9 },
      { x: 120, y: 118, w: 30, h: 14, color: 0xf1c40f },
      { x: 170, y: 118, w: 30, h: 14, color: 0x27ae60 },
      { x: 220, y: 118, w: 30, h: 14, color: 0xc0392b },
    ],
    text: 'Otra semana igual. Ruido, prisas, humo.',
  },
  {
    // Ara mirando por la ventana
    bgColor: 0x2c2c3e,
    shapes: [
      { x: 90, y: 20, w: 140, h: 100, color: 0x0f0f1f, label: 'ventana' },
      { x: 145, y: 80, w: 30, h: 60, color: 0xe6a57e, label: 'Ara' },
    ],
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
