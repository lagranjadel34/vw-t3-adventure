extends SceneTree
## Sonido sin pantalla: godot --headless -s res://tests/audio_test.gd
## Sintetizador, vueltas del motor, clac según holgura, ambiente ciudad -> campo y ajustes.

var world: Node
var van: Van
var sound: VanSound
var frame := 0
var max_rpm := 0.0
var rpm_drop := false
var last_rpm := 0.0
var errors := 0

func _initialize() -> void:
	_check_synth()
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	van = world.get_node("Van")
	world.ready.connect(func() -> void: world.set_physics_process(false))

func _check_synth() -> void:
	for s: AudioStreamWAV in [Synth.engine_loop(), Synth.city_loop(), Synth.horn(0.3), Synth.bird(3), Synth.clack(1.0)]:
		_expect(s.data.size() > 0 and _peak(s) > 0.1, "sonido vacío")
	_expect(Synth.engine_loop().loop_mode == AudioStreamWAV.LOOP_FORWARD, "el motor no va en bucle")
	_expect(Synth.clack(1.0).get_length() > Synth.clack(0.0).get_length(), "con holgura el clac debería durar más (rascado)")

func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		sound = _find(world, VanSound)
		_expect(sound != null, "falta VanSound en el mundo")
		_expect(_find(world, Soundscape).countryside < 0.5, "la salida no debería sonar a campo")
	van.gas_input = frame < 240
	if sound:
		max_rpm = maxf(max_rpm, sound.rpm)
		if van.gearbox.shifting and sound.rpm < last_rpm:
			rpm_drop = true
		last_rpm = sound.rpm
	if frame == 300:
		_expect(max_rpm > AudioConfig.ENGINE_IDLE_RPM * 2.0, "el motor no sube de vueltas al acelerar (%.0f)" % max_rpm)
		_expect(rpm_drop, "las vueltas no caen al cambiar de marcha")
		# Junto a la salida de la ciudad: suena a campo.
		van.global_position = Vector2(3168, 976)
	if frame == 302:
		var scape: Soundscape = _find(world, Soundscape)
		_expect(scape.countryside > 0.9, "en la salida A-4 debería sonar a campo (%.2f)" % scape.countryside)
		var settings: Node = root.get_node_or_null("Settings")
		if settings == null:
			settings = load("res://scripts/settings.gd").new()
			root.add_child(settings)
		settings.set_volume(0)
		_expect(AudioServer.is_bus_mute(0), "volumen 0 debería silenciar")
		settings.set_volume(AudioConfig.VOLUME_DEFAULT)
		settings.set_muted(false)
		_expect(not AudioServer.is_bus_mute(0), "el sonido debería volver")
		var options: Node = load("res://scenes/options.tscn").instantiate()
		root.add_child(options)
		options.queue_free()
		print("audio_test: max_rpm=%.0f errores=%d" % [max_rpm, errors])
		return true
	return false

func _find(node: Node, type: Variant) -> Node:
	for c in node.get_children():
		if is_instance_of(c, type):
			return c
	return null

func _peak(s: AudioStreamWAV) -> float:
	var p := 0
	for i in range(0, s.data.size(), 2):
		p = maxi(p, absi(s.data.decode_s16(i)))
	return p / AudioConfig.GAIN_MAX

func _expect(ok: bool, msg: String) -> void:
	if not ok:
		errors += 1
		push_error(msg)
