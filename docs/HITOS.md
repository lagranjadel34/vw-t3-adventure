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
- [x] G2. Menú de inicio (hoguera, estrellas fugaces) e intro con viñetas, portados de Phaser. Menú: Empezar, Elegir camperizador, Configuración y Salir; Configuración tiene Créditos; el botón "atrás" de Android vuelve al menú (y desde el menú sale del juego).
- [x] G3. HUD: cuentakilómetros de rodillos (arriba a la derecha, pegado al borde aunque la pantalla sea más ancha).
- [x] G4. Caja de cambios de 4 marchas (rejilla T3: 1ª abajo-izq, 2ª arriba-izq, 3ª abajo-der, 4ª arriba-der; palanca encima de los pedales): automática por defecto, manual deslizando la palanca o con Q/E.
- [x] G5. Derrape y agarre: la cola se va en curvas rápidas y con freno de mano (Espacio), peso según camperización, tope 100 km/h.
- [x] G6. Sprite isométrico de la T3 Dehler (prueba): 24 rumbos, ruedas girando y con volante, faros (L), daño 0-3 (K) y humo según daño. Hojas generadas con `tools/sprites/export_godot.py` desde un modelo 3D low-poly. Desde la 0.1.29+ las hojas (T3 y coches) se generan con la cámara cenital en perspectiva del mapa (`CAM_HEIGHT_PX` en `tools/sprites/t3gen.py` = `CITY_CAMERA_HEIGHT`).
- [x] G7. Mapa en perspectiva estilo GTA 1: cámara cenital con perspectiva (`CITY_CAMERA_HEIGHT`), los edificios se abren desde el centro de la pantalla, fachadas con ventanas, sombras en el suelo. Alturas por tipo (casas de 3 plantas, pisos en Nervión, Giralda, Torre Sevilla). Monumentos: Giralda, Catedral, Torre del Oro, Reales Alcázares, Archivo de Indias, Las Setas, Torre Sevilla, Maestranza y Plaza de España con sus torres. Volumen y colores como propiedades de los tiles en Tiled (`npm run map`).
- [x] G8. Sonido (sintetizado, provisional): motor bóxer que sigue las vueltas, clac de palanca según la holgura de la caja (de serie gastada; el taller la arreglará), ambiente de ciudad (tráfico y bocinas) que se apaga hacia la salida A-4 y deja paso a pájaros, y Configuración > Sonido (volumen y silencio, se guarda).
- [x] G9. Mapa del bosque (`scripts/gen-bosque-map.mjs`, `npm run map:bosque`): por la salida A-4 de Sevilla se entra a la extensión (A-4 entre olivares → carretera comarcal → camino de tierra → pinar → claro con laguna y spot de acampada); volviendo al borde oeste se regresa a Sevilla. Fundido corto y misma velocidad al cambiar de mapa. Ambiente de campo en todo el bosque. La T3 sale al pie del Puente de Triana, en la orilla del Arenal.
- [x] G10. Vida en la calle y puente de Triana: 10 coches en 4 circuitos (Triana–San Telmo, Triana–Remedios y Nervión) que frenan ante la furgo y en rojo; semáforos que cambian por ejes; naranjos en las aceras; peatones que se apartan de la furgo. Puente de Triana recto con barandillas de hierro, farolas, aceras, arcos con anillos bajo la calzada (`StreetProps`), Capillita del Carmen y Altozano. La T3 sale en la cabeza del puente, lado Paseo de Colón. Prueba: `tests/traffic_test.gd`.
- [x] G11. Peatones a escala de la T3: figuras de pie con la misma vista oblicua (16 px de alto), y si la furgo los atropella quedan tendidos en el suelo con un charco de sangre. Prueba: `tests/pedestrian_test.gd`.
- [x] G12. Elegir camperizador: pantalla del menú con escaparate girando (24 rumbos, ruedas rodando) y la furgo elegida se guarda. Icono "i" (o tecla F) que abre la ficha técnica: vista lateral de la ficha de Ara y datos (año, medidas, techo, motor, caja, peso, velocidad). Dos T3 de techo alto según las fichas de Ara: Dehler Profi 1983 (por defecto: gris azulado, techo de fibra con escotilla, faros redondos, llantas de chapa) y Carthago 1982 (ocre, techo blanco redondeado, llantas de aleación, antinieblas). Lista en `config/vehicle_config.gd`; hojas con `python3 tools/sprites/export_godot.py` (una carpeta por furgo).
- [x] G13. Taller Karvans: nave en el polígono junto a la A-4 (Nervión), carril desde la autovía y portón abierto; al entrar la furgo se pausa el juego y sale el menú del taller (provisional, `godot/ui/workshop_menu.gd`). Zonas de tipo `taller` en Tiled + `<nombre>_salida`.
- [x] G14. Acceso al bosque por carretera convencional: la salida de Sevilla (Nervión) y el bosque se unen con una carretera de dos carriles de 2 tiles, arcén y línea central discontinua (marcas viales como objetos `linea` de Tiled, `godot/scripts/road_markings.gd`), en vez de la autovía de 6 tiles. Entra recta desde la ciudad y serpentea hasta el cruce con la pista forestal. Prueba: `tests/road_test.gd`.
- [x] G15. T3 en HD y pasos de peatones: la furgo usa la vista superior de la ficha de Ara a 4x (`tools/sprites/top_hd.py`) y gira sin escalones con filtro lineal y mipmaps, con su sombra. Pasos de cebra con línea de detención y semáforo en los cruces (todos los de las rutas y alguno suelto), objetos `paso` de Tiled; los coches que llegan paran en rojo (en ámbar si les da) y ceden a quien cruza; los peatones cruzan al principio de su verde y si no esperan en el bordillo. Prueba: `tests/crossing_test.gd`.
- [x] G16. Alta resolución: stretch `canvas_items` (lógica en 320x180, dibujo a la resolución de la pantalla). Tiles pixelados; la T3 en HD, los polígonos y los textos salen nítidos. Líneas con `GameConfig.LINE_WIDTH` y rótulos del mapa con Fredoka.
- [x] G17. Circunvalación: la carretera comarcal no acaba en el bosque; rodea el pinar y vuelve a Sevilla por una segunda salida (sur). Dentro del circuito, una desviación de tierra abandona el asfalto hacia el claro y el spot. Sevilla tiene dos puertas (`salida_a4`, `salida_sur`). Mapas separados con fundido, no un mapa gigante. Prueba: `tests/road_test.gd`.
