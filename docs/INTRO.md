# Intro (hito 4)

Presentación de la historia antes de que el jugador tome el control: ciudad caótica -> sale en la VW T3 -> bosque.

## Pendiente de decidir
- Formato: ¿texto narrado sobre imágenes fijas (tipo cómic/viñetas), escena jugable breve, o solo texto sobre fondo negro?
- Duración aproximada.
- Se puede saltar (skip) con una tecla, como en los juegos retro.
- Arte necesario (si lleva imágenes): cuántas escenas/viñetas y qué debe mostrar cada una.
- Texto/diálogo de la narración.

## Decisiones tomadas
- Formato: viñetas fijas con narración letra a letra (provisional, para probar).
- Arte: viñetas 1 y 2 con imágenes de Sevilla (`public/assets/backgrounds/intro_sevilla_*.jpg`); el resto placeholders (rectángulos).
- Controles: Espacio/Enter/clic completa el texto o pasa de viñeta; ESC salta la intro. Avanza sola a los 2,5 s.
- Flujo: Menú (Empezar) -> Intro -> Juego.

## Viñetas (borrador)
1. Sevilla, Torre del Oro (imagen, pan lento + bocinas + neblina): "Otra semana igual."
2. Sevilla, avenida atascada (imagen, zoom al tráfico + bocinas + neblina): "Ruido, prisas, humo."
3. Ara dentro de la T3, en mitad del atasco (imagen `intro_interior_furgo_v1.jpg`, humo de tubos de escape + bocinas): "Necesito salir de aquí."
4. La T3 aparcada en la calle: "Ella siempre está lista."
5. Carretera hacia el bosque: "Rumbo al bosque. Sin plan. Solo un buen spot."

Textos y colores en `src/config/intro.ts`.
