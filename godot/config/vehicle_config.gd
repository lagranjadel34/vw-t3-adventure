class_name VehicleConfig
## Furgonetas elegibles en "Elegir camperizador". La primera es la de por defecto.
## Cada una trae sus hojas de sprite (mismo formato: ver tools/sprites/export_godot.py)
## y su camperización (clave de GameConfig.VAN_LOAD_PRESETS_KG, que da la carga en kg).
## Ficha técnica: vista lateral recortada de la ficha dibujada por Ara y datos.

const VEHICLES: Array[Dictionary] = [
	{
		"id": "t3_dehler_profi",
		"nombre": "VW T3 Dehler Profi",
		"anio": 1983,
		"detalle": ["Techo alto de fibra", "Motor bóxer trasero", "Caja de 4 marchas"],
		"sprites": "res://assets/sprites/dehler/d%d%s.png",
		"lateral": "res://assets/vehicles/dehler_lateral.png",
		"carga": "camper",
		"techo": "Fibra, con escotilla",
		"medidas_m": {"largo": 4.57, "ancho": 1.84, "alto": 2.34, "batalla": 2.46},
	},
	{
		"id": "t3_carthago",
		"nombre": "VW T3 Carthago",
		"anio": 1982,
		"detalle": ["Techo alto blanco", "Llantas de aleación", "Antinieblas amarillos"],
		"sprites": "res://assets/sprites/carthago/d%d%s.png",
		"lateral": "res://assets/vehicles/carthago_lateral.png",
		"carga": "camper",
		"techo": "Blanco, redondeado",
		"medidas_m": {"largo": 4.57, "ancho": 1.84, "alto": 2.34, "batalla": 2.46},
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


## Filas de la ficha técnica: [etiqueta, valor].
static func sheet_rows(vehicle: Dictionary) -> Array:
	var m: Dictionary = vehicle.medidas_m
	return [
		["Año", str(vehicle.anio)],
		["Largo × ancho", "%.2f × %.2f m" % [m.largo, m.ancho]],
		["Alto", "%.2f m" % m.alto],
		["Batalla", "%.2f m" % m.batalla],
		["Techo", vehicle.techo],
		["Motor", "Bóxer trasero"],
		["Caja", "%d marchas" % GameConfig.GEAR_GATE.size()],
		["Peso", "%d kg" % roundi(GameConfig.VAN_EMPTY_MASS_KG + load_kg(vehicle))],
		["Velocidad máx.", "%d km/h" % roundi(GameConfig.VAN_TOP_SPEED_KMH)],
	]


## Furgoneta elegida en Settings. Sin el autoload (pruebas con -s), la de por defecto.
static func chosen(node: Node) -> Dictionary:
	var settings := node.get_node_or_null("/root/Settings")
	return find(settings.vehicle_id if settings else DEFAULT_ID)
