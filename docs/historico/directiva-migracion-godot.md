# Directiva de Migración a Godot 4 — VW T3 Adventure

## 1. Contexto y Decisión Estratégica
Hemos decidido pivotar el desarrollo desde **Phaser 3 + TypeScript** hacia **Godot 4** (GDScript) para optimizar el rendimiento en dispositivos móviles Android, aprovechar las físicas 2D nativas y escalar el mundo abierto RPG de forma eficiente.

**Objetivo de esta directiva:** 
Servir de prompt maestro para Claude Code, guiando la extracción de lógica, matemáticas, constantes y diseño desde la versión de Phaser para reconstruir el proyecto en Godot 4 sin perder avance conceptual.

---

## 2. Inventario de Lo Que SE SALVA y MIGRARÁ

A pesar de que el código de render de Phaser se descarta, la inteligencia y calibración del proyecto se conservan íntegramente:

### A. Modelo de Conducción y Físicas (Física de la T3 / `entities/Van.ts`)
* **Modelo Bicicleta (BicycleKinematicModel):** Mapear exactamente las fórmulas de aceleración, frenado, marcha atrás, fricción, ángulo de giro y pivote en el eje trasero.
* **Tuning de conducción (`config/constants.ts`):** Extraer los valores numéricos calibrados (aceleración, fricción, masa, velocidad máxima, radio de giro).
* **Conversión de Escala:** Mantener la constante de conversión metros/píxeles (`m/px`) y la lógica del odómetro/distancia recorrida.

### B. Configuración y Datos Narrativos
* **Estructura de la Intro (`config/intro.ts`):** Preservar la secuencia de viñetas, posiciones de cámara, efectos de zoom, temporización del texto tipo máquina de escribir y textos narrativos.
* **Constantes de Dispositivo y UI (`config/`):** Tiempos de animación, colores, proporciones de controles táctiles y constantes globales.

### C. Assets y Mapas
* **Tilemaps de Tiled (`scripts/gen-sevilla-map.mjs` / `scenes/PlayScene.ts`):** Reutilizar los archivos de mapas `.json`/`.tmx` generados y los tilesets pixel art. Godot 4 los importa nativamente mediante su sistema de `TileMapLayer`.
* **Audio y Fuentes:** Conservar los archivos de sonido de bocina, motor y las fuentes tipográficas Pixel Art.

---

## 3. Hoja de Ruta para Claude Code (Paso a Paso)

Ejecuta el siguiente plan de trabajo modular dentro del repositorio:

```
[Fase 1: Extracción] -> [Fase 2: Arquitectura Godot] -> [Fase 3: Puentes de Código]
```

### Fase 1: Extracción de Parámetros Puros
1. Lee `src/config/constants.ts`, `src/entities/Van.ts` y `src/config/intro.ts`.
2. Genera un archivo en GDScript de constantes globales / Autoload llamado `GlobalConfig.gd` que contenga todas las constantes calibradas.

### Fase 2: Configuración del Proyecto en Godot 4
1. Crear la estructura básica de carpetas en Godot:
   * `res://scenes/` (escenas principales: Boot, Intro, Menu, World, UI)
   * `res://entities/` (jugador/vehículo)
   * `res://scripts/` (lógica y autoloads)
   * `res://assets/` (sprites, tilemaps, fuentes, audios)
   * `res://resources/` (objetos de datos RPG `.tres`)
2. Configurar la resolución base y el escalado de pixel art para pantallas móviles Android (`viewport` mode, `integer` scaling).

### Fase 3: Reconstrucción de Componentes Clave

#### 1. El Coche (`entities/Van.tscn` / `Van.gd`)
* Usar un nodo `CharacterBody2D`.
* Traducir la lógica de la clase `Van.ts` (modelo bicicleta de 116 líneas) a GDScript.
* Aplicar el pivote en el eje trasero para simular la masa de la VW T3.
* Implementar la cámara `Camera2D` con *smoothing* y zoom dinámico según la velocidad (tomando como referencia `PlayScene.ts`).

#### 2. La Interfaz Móvil y Odómetro (`scenes/UI/`)
* Sustituir el código de dibujo manual de canvas por nodos nativos de Godot (`Control`, `TouchscreenButton`, `TextureProgressBar`).
* Recrear el odómetro analógico en GDScript conectando la señal de kilómetros recorridos de la T3 a la interfaz.

#### 3. El Mapa Abierto
* Importar el mapa de Sevilla desde el archivo generado por `gen-sevilla-map.mjs` utilizando el nodo `TileMapLayer` con capas de colisión configuradas.

---

## 4. Instrucciones Directas para el Asistente (Claude)

> **Rol:** Eres un Ingeniero Senior de Videojuegos especializado en Godot 4 y desarrollo móvil para Android.
>
> **Tu tarea:**
> 1. Analiza los archivos de TypeScript en `src/` indicados en este documento para extraer todas las constantes, fórmulas físicas de la T3 y la lógica de flujo.
> 2. No reescribas la lógica en Phaser; tradúcela y adáptala a las buenas prácticas de Godot 4 (`GDScript`, arquitectura de nodos, señales y `Resources`).
> 3. Al implementar el movimiento de la T3, prioriza la fidelidad del modelo bicicleta previamente ajustado en TypeScript para mantener la misma sensación de conducción.
> 4. Asegúrate de estructurar el código de forma modular para preparar la llegada del sistema RPG (inventario, talleres, estadísticas de piezas).