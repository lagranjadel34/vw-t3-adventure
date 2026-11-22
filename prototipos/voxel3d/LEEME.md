# Prototipo 3D pixelado (no es el juego)

Mundo 3D de bloques renderizado a 320x180 en un SubViewport y escalado con filtro nearest, renderer Compatibility. Todo se genera en `main.gd`.

- Jugar: abrir `prototipos/voxel3d/project.godot` en Godot 4.5 y F5. Flechas/WASD.
- Captura sin manos: `godot --path prototipos/voxel3d -- --shot=/tmp/shot.png --frames=160`

## Ficha 3D de la Dehler Profi
1. Modelo con curvas medido sobre la ficha dehler-profi-1983: `python3 tools/sprites/t3_ficha3d.py prototipos/voxel3d/dehler_curvas.bin` (la versión azul anterior: `t3_sdf.py`) (necesita scikit-image; si no existe se usa el de polígonos planos). Modelo plano: `python3 tools/sprites/export_mesh3d.py dehler prototipos/voxel3d/dehler.json --detalle` (mismo modelo que los sprites + piezas de detalle).
2. Vistas: `godot --path prototipos/voxel3d res://render_ficha.tscn -- --out=/carpeta` (8 PNG).
3. En el mundo: `godot --path prototipos/voxel3d -- --shot=/carpeta/mundo.png --frames=150 --cerca`.
4. Ficha: `python3 prototipos/voxel3d/componer_ficha.py /carpeta godot/assets/fonts/Fredoka-Variable.ttf ficha.png` (espera las vistas en `/carpeta/ficha/`).
