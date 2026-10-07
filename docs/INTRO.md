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
- Arte: placeholders (rectángulos) hasta tener las viñetas dibujadas.
- Controles: Espacio/Enter/clic completa el texto o pasa de viñeta; ESC salta la intro. Avanza sola a los 2,5 s.
- Flujo: Menú (Empezar) -> Intro -> Juego.

## Viñetas (borrador)
1. Ciudad de noche, atasco: "Otra semana igual. Ruido, prisas, humo."
2. Ara mirando por la ventana: "Necesito salir de aquí."
3. La T3 aparcada en la calle: "Ella siempre está lista."
4. Carretera hacia el bosque: "Rumbo al bosque. Sin plan. Solo un buen spot."

Textos y colores en `src/config/intro.ts`.
