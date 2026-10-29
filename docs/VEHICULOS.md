# Furgonetas (Elegir camperizador)

Fuente de verdad: `godot/config/vehicle_config.gd` (la primera de la lista es la de por defecto). Fichas originales de Ara en `docs/arte/fichas/`.

| | Dehler Profi (por defecto) | Carthago |
|---|---|---|
| id | `t3_dehler_profi` | `t3_carthago` |
| Año | 1983 | 1982 |
| Motor | 1.9 gasolina, 90 CV | 1.6 diésel, 78 CV |
| Techo | Fibra, con escotilla | Blanco, redondeado |
| Aspecto (G12) | gris azulado, faros redondos, llantas de chapa | ocre, llantas de aleación, antinieblas |
| Medidas | 4,57 × 1,84 m, alto 2,34 m, batalla 2,46 m | igual |
| Carga | `camper` (300 kg, `GameConfig.VAN_LOAD_PRESETS_KG`) | igual |

Comunes: caja de 4 marchas, tope 100 km/h (`GameConfig.VAN_TOP_SPEED_KMH`); peso = `VAN_EMPTY_MASS_KG` + carga.

## Sprites
- En el mapa: vista superior en HD por estado de daño (`tools/sprites/top_hd.py` → `godot/assets/sprites/<furgo>/top_d*.png`).
- Escaparate del menú: 24 rumbos con ruedas rodando (`tools/sprites/export_garage.py` → `garage.png`).
- Ficha técnica: vistas laterales recortadas de la ficha de Ara (`godot/assets/vehicles/`).
- Estados de daño 0-3 (motor): limpia → óxido → abolladuras, luna rajada, faro roto → óxido grande, puerta de imprimación; el humo pasa de gris claro a negro.

La propuesta isométrica de 16 direcciones (T3 Westfalia, oct-22) quedó superada por la vista superior HD (G15).
