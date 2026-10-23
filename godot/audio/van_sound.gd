class_name VanSound
extends Node
## Sonido de la T3: el motor sigue las vueltas y cada cambio suena según la holgura de la caja.

var _van: Van
var _engine := AudioStreamPlayer.new()
var _clack := AudioStreamPlayer.new()
var _clack_play := -1.0
var _engine_base_hz: float
## Vueltas del motor ahora mismo (rpm), suavizadas.
var rpm := AudioConfig.ENGINE_IDLE_RPM


func setup(van: Van) -> void:
	_van = van
	_engine.stream = Synth.engine_loop()
	_engine_base_hz = float(AudioConfig.MIX_RATE) / AudioConfig.ENGINE_PERIOD_SAMPLES
	_engine.volume_db = AudioConfig.ENGINE_IDLE_DB
	add_child(_engine)
	add_child(_clack)
	_engine.play()
	van.gearbox.shifted.connect(func(_from: int, _to: int) -> void: _play_clack())
	_update_engine(0.0)


## Vueltas que pide la marcha a esta velocidad: al tope de la marcha, al corte.
func target_rpm() -> float:
	var gb := _van.gearbox
	var spd := absf(_van.speed)
	var top := GameConfig.VAN_MAX_REVERSE_SPEED if _van.speed < 0.0 else Gearbox.max_speed(gb.gear)
	var target := AudioConfig.ENGINE_REDLINE_RPM * clampf(spd / top, 0.0, 1.0)
	if gb.shifting:
		target *= AudioConfig.ENGINE_CLUTCH_RPM_RATIO
	return maxf(target, AudioConfig.ENGINE_IDLE_RPM)


func _process(delta: float) -> void:
	if _van:
		_update_engine(delta)


func _update_engine(delta: float) -> void:
	rpm = lerpf(rpm, target_rpm(), 1.0 - exp(-AudioConfig.ENGINE_RPM_LERP * delta)) if delta > 0.0 else target_rpm()
	_engine.pitch_scale = rpm / 60.0 * AudioConfig.FIRES_PER_REV / _engine_base_hz
	var stopped := absf(_van.speed) <= GameConfig.VAN_STOP_SPEED
	var db := AudioConfig.ENGINE_IDLE_DB if stopped and not _van.gas_input else (
		AudioConfig.ENGINE_GAS_DB if _van.gas_input else AudioConfig.ENGINE_COAST_DB)
	_engine.volume_db = lerpf(_engine.volume_db, db, 1.0 - exp(-AudioConfig.ENGINE_DB_LERP * delta))


func _play_clack() -> void:
	# La holgura solo cambia en el taller: se regenera el sonido cuando cambia.
	if _van.gearbox.play != _clack_play:
		_clack_play = _van.gearbox.play
		_clack.stream = Synth.clack(_clack_play)
	_clack.volume_db = AudioConfig.CLACK_DB
	_clack.pitch_scale = 1.0 + randf_range(-AudioConfig.CLACK_PITCH_JITTER, AudioConfig.CLACK_PITCH_JITTER)
	_clack.play()
