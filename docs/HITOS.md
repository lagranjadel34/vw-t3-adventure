# Hitos

Hito = entregable pequeño, probable y cerrado. Un prompt, una prueba, un commit.

- [x] 1. Proyecto base: Phaser + Vite arrancando (pantalla negra 320x180).
- [x] 2. Furgoneta controlable (sprite T3 de Ara): aceleración, giro, inercia.
- [x] 3. Pantalla de menú/título: fondo (arte de Ara) + Empezar/Elegir VW/Configuración.
- [ ] 4. Intro: presentación de la historia (ciudad caótica -> salir en la VW T3 -> bosque).
- [x] 5. Mapa Tiled: ciudad con calles y colisiones (Sevilla esquemática: río, Triana, casco, Catedral, Maestranza, María Luisa, Plaza de España, salida A-4; regenerar con `npm run map`).
- [ ] 6. Caos urbano: coches IA, peatones, obstáculos.
- [ ] 7. Salida de la ciudad -> carretera -> bosque.
- [ ] 8. Spot de acampada: zona trigger para aparcar.
- [ ] 9. Final: acampada nocturna + "FIN".
- [ ] 10. Pulido: audio, controles táctiles (base táctil hecha: joystick, menú e intro por toque, layout móvil).
- [ ] 11. PWA en Vercel y APK con Capacitor.

## Godot (desde 2026-10-22)

Migración por paridad: Phaser queda como referencia. Hitos con prefijo G.

- [x] G1. Proyecto Godot: T3 conduciendo por Sevilla (modelo bicicleta portado), cámara con zoom, joystick y pedales, APK automático en Releases.
- [x] G2. Menú de inicio (hoguera, estrellas fugaces) e intro con viñetas, portados de Phaser.
- [ ] G3. HUD: cuentakilómetros de rodillos.
- [x] G4. Caja de cambios de 4 marchas (rejilla T3, 1ª arriba): automática por defecto, manual deslizando la palanca o con Q/E.
- [x] G5. Derrape y agarre: la cola se va en curvas rápidas y con freno de mano (Espacio), peso según camperización, tope 100 km/h.
