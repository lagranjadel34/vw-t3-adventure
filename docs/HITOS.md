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
- [x] G3. HUD: cuentakilómetros de rodillos (arriba a la derecha, pegado al borde aunque la pantalla sea más ancha).
- [x] G4. Caja de cambios de 4 marchas (rejilla T3: 1ª abajo-izq, 2ª arriba-izq, 3ª abajo-der, 4ª arriba-der; palanca encima de los pedales): automática por defecto, manual deslizando la palanca o con Q/E.
- [x] G5. Derrape y agarre: la cola se va en curvas rápidas y con freno de mano (Espacio), peso según camperización, tope 100 km/h.
- [x] G6. Sprite isométrico de la T3 Dehler (prueba): 24 rumbos, ruedas girando y con volante, faros (L), daño 0-3 (K) y humo según daño. Hojas generadas con `tools/sprites/export_godot.py` desde un modelo 3D low-poly. Desde la 0.1.29+ las hojas (T3 y coches) se generan con la cámara cenital en perspectiva del mapa (`CAM_HEIGHT_PX` en `tools/sprites/t3gen.py` = `CITY_CAMERA_HEIGHT`).
- [x] G7. Mapa en perspectiva estilo GTA 1: cámara cenital con perspectiva (`CITY_CAMERA_HEIGHT`), los edificios se abren desde el centro de la pantalla, fachadas con ventanas, sombras en el suelo. Alturas por tipo (casas de 3 plantas, pisos en Nervión, Giralda, Torre Sevilla). Monumentos: Giralda, Catedral, Torre del Oro, Reales Alcázares, Archivo de Indias, Las Setas, Torre Sevilla, Maestranza y Plaza de España con sus torres. Volumen y colores como propiedades de los tiles en Tiled (`npm run map`).
- [x] G8. Sonido (sintetizado, provisional): motor bóxer que sigue las vueltas, clac de palanca según la holgura de la caja (de serie gastada; el taller la arreglará), ambiente de ciudad (tráfico y bocinas) que se apaga hacia la salida A-4 y deja paso a pájaros, y Configuración > Sonido (volumen y silencio, se guarda).
- [x] G9. Mapa del bosque (`scripts/gen-bosque-map.mjs`, `npm run map:bosque`): por la salida A-4 de Sevilla se entra a la extensión (A-4 entre olivares → carretera comarcal → camino de tierra → pinar → claro con laguna y spot de acampada); volviendo al borde oeste se regresa a Sevilla. Fundido corto y misma velocidad al cambiar de mapa. Ambiente de campo en todo el bosque. La T3 sale al pie del Puente de Triana, en la orilla del Arenal.
- [x] G10. Vida en la calle y puente de Triana: 10 coches en 4 circuitos (Triana–San Telmo, Triana–Remedios y Nervión) que frenan ante la furgo y en rojo; semáforos que cambian por ejes; naranjos en las aceras; peatones que se apartan de la furgo. Puente de Triana recto con barandillas de hierro, farolas, aceras, arcos con anillos bajo la calzada (`StreetProps`), Capillita del Carmen y Altozano. La T3 sale en la cabeza del puente, lado Paseo de Colón. Prueba: `tests/traffic_test.gd`.
- [x] G11. Peatones a escala de la T3: figuras de pie con la misma vista oblicua (16 px de alto), y si la furgo los atropella quedan tendidos en el suelo con un charco de sangre. Prueba: `tests/pedestrian_test.gd`.
- [x] G12. Elegir camperizador: pantalla del menú con escaparate girando (24 rumbos, ruedas rodando) y la furgo elegida se guarda. Dos T3 de techo alto según las fichas de Ara: Dehler Profi 1983 (por defecto: gris azulado, techo de fibra con escotilla, faros redondos, llantas de chapa) y Carthago (ocre, techo blanco redondeado, llantas de aleación, antinieblas). Lista en `config/vehicle_config.gd`; hojas con `python3 tools/sprites/export_godot.py` (una carpeta por furgo).
