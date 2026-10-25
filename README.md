# VW T3 Adventure

Juego top-down en pixel art, estilo GTA 1: Ara sale de una Sevilla caótica en su VW T3, llega al bosque, busca un buen spot y acampa.

Motor: Godot 4.5 (`godot/`). Cada cambio en `godot/` que llega a master genera un APK en [Releases](https://github.com/lagranjadel34/vw-t3-adventure/releases), que Obtainium detecta e instala en el móvil.

## Versiones

Lo más nuevo arriba. El número coincide con el que muestra Obtainium (0.1.N = Release `apk-N`).

### 0.1.75 · 2026-10-25
- La T3 se ve con más detalle y gira suave, sin saltos entre posiciones, y lleva su sombra.
- Pasos de cebra con semáforo y línea de detención en los cruces por donde pasa el tráfico (y en alguno más).
- Los coches paran antes del paso cuando su semáforo está en rojo y esperan a quien esté cruzando.
- Los peatones cruzan por los pasos cuando les toca; si no, esperan en el bordillo.

### 0.1.73 · 2026-10-24
- Ya no se va al bosque por autovía: de Sevilla sale una carretera convencional de dos carriles, con arcén y línea central discontinua, que cruza el campo hasta el bosque.
- En el bosque la carretera entra recta desde la ciudad y luego serpentea entre olivares y pinos hasta el cruce con la pista forestal que lleva al spot.

### 0.1.72 · 2026-10-24
- La Dehler y la Carthago, vistas desde arriba tal como en sus fichas (techo, claraboya, colores y franjas): ahora se reconocen al conducir.
- Taller Karvans: nave en el polígono junto a la A-4, en Nervión. Un carril sale de la autovía hasta el portón; entra con la furgo y se abre el menú del taller (de momento provisional, con "Salir del taller").

### 0.1.71 · 2026-10-24
- La T3 se mueve el doble de rápido por la pantalla (los km/h son los mismos): antes, a 100 km/h, solo avanzaba 2 furgonetas por segundo y las primeras marchas parecían arrastrarse. Los coches del tráfico van igual de rápido que antes respecto a ti.
- Esto se puede subir más (a la escala real de una T3) si se queda corto.

### 0.1.67 · 2026-10-24
- Cada marcha se nota: la 1ª tira fuerte y dura poco, la 2ª y la 3ª duran más y empujan menos, y la 4ª es solo velocidad.
- Al cambiar hay un bache: el embrague corta el empuje y la furgo pierde algo de velocidad antes de que entre la nueva. La cámara cabecea y el móvil vibra un momento.
- Al soltar el gas, el motor retiene mucho en 1ª y casi nada en 4ª.
- A fondo, de 0 a 100 km/h en unos 11 segundos.

### 0.1.61 · 2026-10-24
- La Dehler Profi pasa a ser azul, como en la ficha nueva: frente y panel del techo celestes, marcos de las ventanas y banda baja celestes, y llantas de aleación. Su ficha técnica enseña los dos lados.
- Elegir camperizador: la furgo gira en 3D en el escaparate, montada con las vistas de su ficha.

### 0.1.57 · 2026-10-24
- Elegir camperizador: el escaparate enseña cada furgo con su dibujo de 3/4.
- Ficha técnica con el motor de cada una: Dehler 1.9 gasolina de 90 CV y Carthago 1.6 diésel de 78 CV.
- La ficha de la Carthago enseña sus dos lados. En el derecho se ven la franja granate, las rejillas de la nevera y el tuareg.

### 0.1.47 · 2026-10-24
- Menú "Elegir camperizador": eliges la furgo antes de empezar. Hay dos: la VW T3 Dehler Profi (1983), que sale por defecto, y la Carthago (1982), con su ficha técnica.
- Configuración tiene Créditos. El menú de título queda en Empezar, Elegir camperizador, Configuración y Salir.
- El botón atrás de Android ya no cierra la app desde cualquier pantalla: en el juego vuelve al menú y en el menú sale.

### 0.1.39 · 2026-10-24
- Caja de cambios en escalera: la 1ª es corta y empuja muchísimo (0 a 25 km/h de golpe), la 2ª empuja bastante menos pero llega a 50, la 3ª aún menos y llega a 75, y la 4ª es solo velocidad: tarda en subir hasta los 100 km/h.
- A fondo, de 0 a 100 km/h en unos 11 segundos.

### 0.1.37 · 2026-10-23
- La T3 y los coches del tráfico, redibujados con la cámara nueva del mapa: vistos desde arriba, con la misma perspectiva que los edificios.

### 0.1.36 · 2026-10-23
- Los peatones ahora tienen el tamaño que les toca al lado de la T3: se ven de pie, con piernas, brazos y pelo.
- Si atropellas a alguien, se queda tendido en el suelo con un charco de sangre.

### 0.1.34 · 2026-10-23
- Puente de Triana de verdad: recto de orilla a orilla, con aceras, barandillas de hierro, farolas y, por los costados, sus tres arcos de hierro con anillos sobre pilas de piedra. En la cabeza de Triana, la Capillita del Carmen y el Altozano.
- La T3 sale al pie del puente, en el lado del Paseo de Colón.
- Tráfico: unos pocos coches (taxis de Sevilla incluidos) circulan por la ribera, cruzan los puentes de Triana, San Telmo y Los Remedios y dan vueltas por Nervión. Frenan si te pones delante.
- Semáforos en los cruces que cambian de color; los coches paran en rojo.
- Naranjos en las aceras y algún peatón paseando, que se aparta de un salto si llega la furgo.

### 0.1.32 · 2026-10-23
- Nuevo mapa: el bosque. Sigue por la salida A-4 hacia el este y llegas a la extensión: A-4 entre olivares, carretera comarcal, camino de tierra por el pinar y un claro junto a una laguna con el spot de acampada. Allí solo se oyen el motor y los pájaros.
- Al cambiar de mapa la pantalla funde a negro y la furgo mantiene la velocidad. Volviendo por la A-4 hacia el oeste regresas a Sevilla.
- La T3 sale ahora al pie del Puente de Triana, en la orilla del Arenal.

### 0.1.31 · 2026-10-23
- Ciudad: de vez en cuando pasa un avión por encima (rugido que crece y se aleja); en el campo no suena.

### 0.1.29 · 2026-10-23
- Edificios altos con perspectiva estilo GTA 1: la cámara mira desde arriba y los edificios se abren hacia los bordes de la pantalla, así que se ven sus fachadas y la calle por la que vas nunca queda tapada.
- Alturas de verdad: casas de 3 plantas, pisos en Nervión y la Giralda y la Torre Sevilla destacando sobre todo lo demás.
- Sombras de los edificios en el suelo.

### 0.1.28 · 2026-10-23
- Sonido (provisional, generado por el juego): el motor bóxer sube y baja de tono con las revoluciones y cae en cada cambio de marcha.
- Clac de la palanca: la caja de serie tiene holgura y la marcha cuesta entrar (rasca y entra con golpe seco). En el futuro se podrá arreglar en el taller.
- Ambiente: tráfico y bocinas en Sevilla, que se van apagando al acercarte a la salida A-4, donde solo quedan el motor y los pájaros.
- Menú > Configuración > Sonido: volumen (0-10) y silencio; se guarda entre partidas.

### 0.1.26 · 2026-10-23
- Sevilla en perspectiva: los edificios tienen fachada y altura, vistos con el mismo ángulo que la T3, y la furgo pasa por delante o por detrás de ellos.
- Monumentos reconocibles: Giralda, Catedral, Torre del Oro, Reales Alcázares, Archivo de Indias, Las Setas, Torre Sevilla, Maestranza y Plaza de España con sus torres.
- Casas de cal con zócalo de albero en el centro y en Triana, y bloques de pisos en Nervión.

### 0.1.23 · 2026-10-23
- Topes por marcha 25 / 50 / 75 / 100 km/h: en 4ª va 4 veces más que en 1ª.
- 1ª con más brío (llega a 25 km/h en 0,4 s) y cambios más suaves (embrague 0,15 s). 0-100 en unos 7,5 s.

### 0.1.21 · 2026-10-23
- Icono del juego y del APK: la parrilla de la T3.

### 0.1.19 · 2026-10-23
- Marchas algo más largas (34 / 60 / 85 / 100 km/h).
- Tracción trasera: acelerar en curva suelta la cola.

### 0.1.17 · 2026-10-22
- Sprite isométrico de la T3 Dehler.

### 0.1.15 · 2026-10-22
- Curva de par: la 1ª empuja fuerte y cada marcha menos; dentro de cada marcha el empuje baja con las vueltas.
- Inercia, freno y retención del motor más suaves: al soltar el gas ya no se para en seco.

### 0.1.13 · 2026-10-22
- Palanca de cambios encima de los pedales y rejilla real de la T3 (1ª abajo-izquierda).

### 0.1.11 · 2026-10-22
- Derrape: en curva rápida se va la cola (motor y tracción traseros); hay que contravolantear.
- Freno de mano con Espacio.
- Peso según camperización (furgón, camper, westfalia).
- A fondo marca 100 km/h, la punta real de la T3.

### 0.1.9 · 2026-10-22
- Caja de cambios de 4 marchas con palanca en H: automática por defecto, manual deslizando la palanca o con Q/E.

### 0.1.7 · 2026-10-22
- Más visión del mapa y furgo más rápida.

### 0.1.5 · 2026-10-22
- Menú de inicio (hoguera, estrellas fugaces) e intro con viñetas.

### 0.1.3 · 2026-10-22
- Primera versión en Godot: la T3 conduce por Sevilla con joystick y pedales, y la cámara se aleja con la velocidad.
