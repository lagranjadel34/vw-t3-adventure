extends Node
## Ajustes del jugador (autoload `Settings`), guardados en AudioConfig.SETTINGS_FILE.
## Sonido (volumen general en pasos y silencio), furgoneta elegida y nombre del jugador.

const SECTION_SOUND := "sonido"
const SECTION_VAN := "furgoneta"
const SECTION_WORKSHOP := "taller"
const SECTION_PLAYER := "jugador"

## Volumen general de 0 a AudioConfig.VOLUME_STEPS.
var volume := AudioConfig.VOLUME_DEFAULT
var muted := false
## Furgoneta elegida (id de VehicleConfig.VEHICLES).
var vehicle_id := VehicleConfig.DEFAULT_ID
## Mejoras instaladas en el taller (ids de WorkshopConfig.UPGRADES).
var upgrades: Array[String] = []
## Nombre que el jugador escribe antes de la intro; se usa en toda la partida.
var player_name := ""


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(AudioConfig.SETTINGS_FILE) == OK:
		volume = clampi(cfg.get_value(SECTION_SOUND, "volumen", volume), 0, AudioConfig.VOLUME_STEPS)
		muted = cfg.get_value(SECTION_SOUND, "silencio", muted)
		vehicle_id = VehicleConfig.find(cfg.get_value(SECTION_VAN, "id", vehicle_id)).id
		for id: Variant in cfg.get_value(SECTION_WORKSHOP, "mejoras", []):
			upgrades.append(str(id))
		player_name = cfg.get_value(SECTION_PLAYER, "nombre", player_name)
	apply()


func has_upgrade(id: String) -> bool:
	return upgrades.has(id)


func install_upgrade(id: String) -> void:
	if has_upgrade(id):
		return
	upgrades.append(id)
	save()


func set_volume(value: int) -> void:
	volume = clampi(value, 0, AudioConfig.VOLUME_STEPS)
	apply()
	save()


func set_muted(value: bool) -> void:
	muted = value
	apply()
	save()


func set_player_name(value: String) -> void:
	player_name = value.strip_edges()
	save()


func set_vehicle(id: String) -> void:
	vehicle_id = VehicleConfig.find(id).id
	save()


func vehicle() -> Dictionary:
	return VehicleConfig.find(vehicle_id)


func apply() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(float(volume) / AudioConfig.VOLUME_STEPS))
	AudioServer.set_bus_mute(master, muted or volume == 0)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_SOUND, "volumen", volume)
	cfg.set_value(SECTION_SOUND, "silencio", muted)
	cfg.set_value(SECTION_VAN, "id", vehicle_id)
	cfg.set_value(SECTION_WORKSHOP, "mejoras", upgrades)
	cfg.set_value(SECTION_PLAYER, "nombre", player_name)
	cfg.save(AudioConfig.SETTINGS_FILE)
