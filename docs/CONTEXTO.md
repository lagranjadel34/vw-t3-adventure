# Contexto del proyecto

- Juego indie "VW T3 Adventure": top-down estilo GTA 1, pixel art. Autoría pública: "La Granja del 34".
- Guion: ciudad caótica (Sevilla) -> salir en la VW T3 -> carretera -> bosque -> spot -> acampar -> FIN. El personaje no tiene nombre fijo (lo escribe quien juega).
- Motor: Godot 4.5 (GDScript) en `godot/`, renderer Compatibility. Phaser 3 + TypeScript (`src/`) queda congelado como referencia (ver `docs/historico/`).
- Pruebas en real: cada push a master con cambios en `godot/` genera el APK en GitHub Releases; Obtainium lo instala en el móvil. Cambios por versión en `README.md`.
- Diseño central: salir del ruido de la ciudad al silencio del campo; caja de cambios con holgura que se arregla en el taller; desgaste/averías y talleres como base del RPG.
- Estado: `docs/HITOS.md`. Furgos: `docs/VEHICULOS.md`. Arte: `docs/ARTE.md`.
- Repo GitHub: lagranjadel34/vw-t3-adventure.
- Preferencias de Ara: respuestas concisas, pasos accionables, solo lo modificado, en español.
