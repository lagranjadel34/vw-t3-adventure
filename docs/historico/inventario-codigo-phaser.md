# Inventario de código — VW T3 Adventure (commit d53fd1c, hito 10)

Medido con `cloc 2.10` sobre `src/` (19 archivos TS): **1.456 líneas físicas = 1.202 de código**, 87 de comentario, 167 en blanco.
Clasificación línea a línea (solo líneas de código) con un script que asigna rangos de cada archivo a una categoría.

## Resumen

| Categoría | Líneas | % del código |
|---|---:|---:|
| **Motor** (total) | **948** | **78,9 %** |
| · Render / dibujo UI / FX (textos, partículas, tweens, HUD) | 585 | 48,7 % |
| · Input (teclado, joystick, pedales, toque) | 169 | 14,1 % |
| · Física / modelo de conducción (Van) | 76 | 6,3 % |
| · Escenas, arranque, config Phaser | 54 | 4,5 % |
| · Carga de assets / Tiled | 43 | 3,6 % |
| · Plataforma (fullscreen, detección táctil) | 11 | 0,9 % |
| · Cámara (seguimiento y zoom) | 10 | 0,8 % |
| **Lógica pura de juego** (total) | **119** | **9,9 %** |
| · Flujo de intro/menú (viñetas, avance, opciones) | 92 | 7,7 % |
| · Estadísticas (km recorridos, escala m/px, km iniciales) | 18 | 1,5 % |
| · Textos de juego (narración, bocinas, rótulos UI) | 9 | 0,7 % |
| · RPG, economía, averías, talleres, diálogos | 0 | 0 % |
| **Imports** (pegamento) | 135 | 11,2 % |
| **Total** | **1.202** | 100 % |

Sin contar imports (1.067 líneas): **motor 88,8 % · lógica 11,2 %**.

## Por carpeta

| Carpeta | Código | Motor | Lógica | Imports |
|---|---:|---:|---:|---:|
| `src/scenes/` (5) | 553 | 397 | 93 | 63 |
| `src/ui/` (4) | 274 | 225 | 0 | 49 |
| `src/config/` (7) | 239 | 227 | 12 | 0 |
| `src/entities/` (1) | 116 | 87 | 14 | 15 |
| `src/main.ts` | 20 | 12 | 0 | 8 |

## Por archivo

| Archivo | Código | Motor | Lógica | Qué hay |
|---|---:|---:|---:|---|
| scenes/IntroScene.ts | 260 | 163 | 68 | Viñetas, humo, bocinas (render) + máquina de avance/tecleo (lógica) |
| scenes/MenuScene.ts | 175 | 146 | 24 | Fondo, fuego, estrellas fugaces, menú táctil |
| config/intro.ts | 136 | 127 | 9 | Datos de viñetas: posiciones, zoom, humo; 6 líneas de texto |
| entities/Van.ts | 116 | 87 | 14 | Modelo bicicleta, freno/marcha atrás, pivote en eje trasero; km recorridos |
| ui/Odometer.ts | 107 | 88 | 0 | Rodillos mecánicos dibujados por píxel |
| ui/TouchJoystick.ts | 80 | 67 | 0 | Joystick flotante |
| ui/Pedals.ts | 79 | 62 | 0 | Pedales táctiles dibujados |
| scenes/PlayScene.ts | 77 | 54 | 1 | Carga Tiled, colisiones, cámara con zoom por velocidad |
| config/odometer.ts | 28 | 25 | 3 | Medidas/colores del odómetro; escala m/px y km iniciales |
| config/pedals.ts | 28 | 28 | 0 | Medidas/colores de pedales |
| scenes/BootScene.ts | 23 | 21 | 0 | Carga de fuentes |
| main.ts | 20 | 12 | 0 | Config Phaser |
| scenes/HudScene.ts | 18 | 13 | 0 | Capa HUD |
| config/constants.ts | 17 | 17 | 0 | Resolución, tuning de conducción y cámara |
| config/map.ts | 15 | 15 | 0 | Claves Tiled y estilo de rótulos |
| config/touch.ts | 12 | 12 | 0 | Medidas del joystick y zona de toque |
| ui/fullscreen.ts | 8 | 8 | 0 | Pantalla completa + apaisado |
| config/device.ts | 3 | 3 | 0 | Detección táctil |

Fuera de `src/`: `scripts/gen-sevilla-map.mjs` (258 líneas, herramienta que genera el mapa Tiled; no se incluye en el juego).

## Criterio
- **Motor**: todo lo que habla con Phaser o resuelve presentación/simulación: dibujo, partículas, tweens, cámara, input, física (incluido el modelo de conducción propio de la T3, que es física aunque esté escrito a mano), carga de assets y Tiled, y sus constantes de tamaño/color.
- **Lógica**: reglas y estado del juego independientes del motor: flujo de escenas/viñetas y menú, contador de km, textos.
- Casos frontera: los datos de colocación de las viñetas de la intro (posición, escala, humo) cuentan como motor/render; el tecleo y avance de la narración cuentan como lógica aunque usen timers de Phaser.
