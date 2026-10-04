# VW T3 Adventure

Juego indie top-down en pixel art, estilo GTA 1. Jugador: Ara.
Guion: ciudad caótica -> salir en la VW T3 -> bosque -> encontrar spot -> acampar -> FIN.

Estado: ver docs/HITOS.md

## Stack
Phaser 3 + TypeScript + Vite. Objetivo final: web/PWA y APK Android (Capacitor).

## Reglas técnicas
- Resolución interna 320x180, `pixelArt: true`, escala FIT. Tiles 16x16.
- Cámara top-down. Controles: WASD/flechas (más tarde, joystick táctil).
- Assets en `public/assets/` (sprites, maps, audio). Mapas con Tiled (JSON).
- Una escena por archivo en `src/scenes/`. Entidades en `src/entities/`.
- Constantes (tamaños, velocidades) en `src/config/`. Sin números mágicos.
- Placeholders (rectángulos) hasta tener arte. No inventes sprites.

## Flujo de trabajo
- Trabaja por hitos (ver `docs/HITOS.md`): un hito = un prompt, una prueba, un commit.
- Antes de dar algo por terminado: `npm run build` sin errores.
- Commits pequeños, en español, formato: `hito N: descripción`.
- No hagas búsquedas web ni uses herramientas externas salvo necesidad.
- Respuestas concisas; muestra solo lo modificado.

## Comandos
- `npm run dev` servidor local · `npm run build` compila y empaqueta · `npm run preview`
