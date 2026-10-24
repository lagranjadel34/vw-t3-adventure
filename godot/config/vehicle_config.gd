class_name VehicleConfig
## Furgonetas elegibles en "Elegir camperizador". La primera es la de por defecto.
## Cada una trae sus hojas de sprite (mismo formato: ver tools/sprites/export_godot.py)
## y su camperización (clave de GameConfig.VAN_LOAD_PRESETS_KG, que da la carga en kg).

const VEHICLES: Array[Dictionary] = [
	{
		"id": "t3_dehler_profi",
		"nombre": "VW T3 Dehler Profi",
		"anio": 1983,
		"detalle": ["Techo alto de fibra", "Motor bóxer trasero", "Caja de 4 marchas"],
		"sprites": "res://assets/sprites/dehler/d%d%s.png",
		"carga": "camper",
	},
	{
		"id": "t3_carthago",
		"nombre": "VW T3 Carthago",
		"detalle": ["Techo alto blanco", "Llantas de aleación", "Antinieblas amarillos"],
		"sprites": "res://assets/sprites/carthago/d%d%s.png",
		"carga": "camper",
	},
]
const DEFAULT_ID := "t3_dehler_profi"


static func find(id: String) -> Dictionary:
	for v in VEHICLES:
		if v.id == id:
			return v
	return VEHICLES[0]


static func load_kg(vehicle: Dictionary) -> float:
	return GameConfig.VAN_LOAD_PRESETS_KG[vehicle.carga]


## Furgoneta elegida en Settings. Sin el autoload (pruebas con -s), la de por defecto.
static func chosen(node: Node) -> Dictionary:
	var settings := node.get_node_or_null("/root/Settings")
	return find(settings.vehicle_id if settings else DEFAULT_ID)
