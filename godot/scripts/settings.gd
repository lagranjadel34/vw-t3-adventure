extends Node
## Ajustes del jugador (autoload `Settings`), guardados en AudioConfig.SETTINGS_FILE.
## Por ahora solo Sonido: volumen general en pasos y silencio.

const SECTION_SOUND := "sonido"

## Volumen general de 0 a AudioConfig.VOLUME_STEPS.
var volume := AudioConfig.VOLUME_DEFAULT
var muted := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(AudioConfig.SETTINGS_FILE) == OK:
		volume = clampi(cfg.get_value(SECTION_SOUND, "volumen", volume), 0, AudioConfig.VOLUME_STEPS)
		muted = cfg.get_value(SECTION_SOUND, "silencio", muted)
	apply()


func set_volume(value: int) -> void:
	volume = clampi(value, 0, AudioConfig.VOLUME_STEPS)
	apply()
	save()


func set_muted(value: bool) -> void:
	muted = value
	apply()
	save()


func apply() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(float(volume) / AudioConfig.VOLUME_STEPS))
	AudioServer.set_bus_mute(master, muted or volume == 0)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_SOUND, "volumen", volume)
	cfg.set_value(SECTION_SOUND, "silencio", muted)
	cfg.save(AudioConfig.SETTINGS_FILE)
