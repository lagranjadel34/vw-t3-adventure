# Intro (hito 4 → G2)

Presentación de la historia antes de que el jugador tome el control: ciudad caótica -> sale en la VW T3 -> bosque.

## Decisiones tomadas
- Formato: viñetas fijas con narración letra a letra.
- Arte: viñetas 1 y 2 con imágenes de Sevilla (`godot/assets/backgrounds/intro_sevilla_*.jpg`), 3 con el interior de la furgo (`intro_interior_furgo_v2.jpg`); 4 y 5 placeholders (rectángulos).
- Controles: Espacio/Enter/toque completa el texto o pasa de viñeta; SALTAR (o Esc) salta la intro. Avanza sola a los 2,5 s (`AUTO_ADVANCE_S`).
- Flujo: Menú (Empezar) -> Escribe tu nombre (G21) -> Intro -> Juego (recuadro con el objetivo, G22).

## Viñetas
1. Sevilla, Torre del Oro (imagen, pan lento + bocinas + neblina): "Otra semana igual."
2. Sevilla, avenida atascada (imagen, zoom al tráfico + bocinas + neblina): "Ruido, prisas, humo."
3. El personaje dentro de la T3, en mitad del atasco (imagen `intro_interior_furgo_v2.jpg`, humo de tubos de escape + bocinas): "Necesito salir de aquí."
4. La T3 aparcada en la calle: "Ella siempre está lista."
5. Carretera hacia el bosque: "Rumbo al bosque. Sin plan. Solo un buen spot."

Textos, imágenes y colores en `godot/config/intro_config.gd` (Phaser: `src/config/intro.ts`).
