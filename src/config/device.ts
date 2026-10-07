// Detecta pantallas táctiles (móvil/tablet) para mostrar controles y textos adecuados.
export const IS_TOUCH =
  typeof window !== 'undefined' &&
  ('ontouchstart' in window || navigator.maxTouchPoints > 0 || window.matchMedia('(pointer: coarse)').matches);
