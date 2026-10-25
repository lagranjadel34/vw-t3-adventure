# VW T3 Adventure

Juego indie top-down en pixel art, estilo GTA 1. Jugador: Ara.
Guion: ciudad caótica -> salir en la VW T3 -> bosque -> encontrar spot -> acampar -> FIN.

Estado: ver docs/HITOS.md

## Stack
**Godot 4.5 (GDScript) en `godot/`**, renderer Compatibility. Objetivo: APK Android (y escritorio).
La versión Phaser 3 + TypeScript (`src/`, `public/`) queda congelada como referencia: solo se toca si hace falta.

## Reglas técnicas
- Resolución lógica 320x180 (Godot: stretch `canvas_items`, se dibuja a la resolución de la pantalla: tiles pixelados con filtro nearest, T3 y polígonos nítidos; líneas con `GameConfig.LINE_WIDTH`). Tiles 16x16.
- Cámara top-down. Controles: WASD/flechas y, en táctil, joystick flotante (mitad izquierda) = volante y pedales en pantalla (abajo derecha) = acelerar/frenar; sin acelerador no hay potencia; palanca de cambios encima de los pedales (deslizar = subir/bajar, toque = auto/manual; teclado Q/E/M). Zonas de toque >= `TAP_MIN_HEIGHT` (`src/config/touch.ts`).
- Godot: assets en `godot/assets/`, escenas en `godot/scenes/`, entidades en `godot/entities/`, UI en `godot/ui/`.
- Constantes (tamaños, velocidades) en `godot/config/game_config.gd`. Sin números mágicos.
- Mapas con Tiled (JSON), cargados en runtime por `godot/scripts/tiled_map.gd`.
- Placeholders (rectángulos) hasta tener arte. No inventes sprites.

## Flujo de trabajo
- Trabaja por hitos (ver `docs/HITOS.md`): un hito = un prompt, una prueba, un commit.
- Antes de dar algo por terminado: `godot --headless --path godot -s res://tests/drive_test.gd` sin errores.
- Cada push a master con cambios en `godot/` genera el APK (GitHub Actions) en Releases:
  https://github.com/lagranjadel34/vw-t3-adventure/releases/latest/download/vw-t3-adventure.apk
- Ara instala con Obtainium: no adjuntes el APK en el chat. Cuando salga la Release, añade al principio de la sección `## Versiones` de `README.md` la entrada `### 0.1.N · fecha` (N = número de `apk-N`) con los cambios en lenguaje de jugador, y súbela a master (un cambio solo en README no genera APK).
- Commits pequeños, en español, formato: `hito N: descripción`.
- No hagas búsquedas web ni uses herramientas externas salvo necesidad.
- Respuestas concisas; muestra solo lo modificado.

## Comandos
- Godot: abrir `godot/project.godot` en el editor (F5 juega). Con el móvil por USB, botón de despliegue remoto.
- Phaser (referencia): `npm run dev` · `npm run build`
