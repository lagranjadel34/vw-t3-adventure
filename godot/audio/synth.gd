class_name Synth
## Sonidos generados por código (sin archivos): provisionales hasta tener grabaciones.
## Cada función devuelve un AudioStreamWAV de 16 bits mono a AudioConfig.MIX_RATE.


## Motor bóxer a ritmo base (≈ 40 Hz de explosiones); se afina con pitch_scale según las vueltas.
static func engine_loop() -> AudioStreamWAV:
	var period := AudioConfig.ENGINE_PERIOD_SAMPLES
	var n := period * AudioConfig.ENGINE_LOOP_PERIODS
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var p := i / period
		var phase := float(i % period) / period
		var env := exp(-AudioConfig.ENGINE_PULSE_DECAY * phase)
		var tone := 0.0
		for h in AudioConfig.ENGINE_HARMONICS.size():
			tone += AudioConfig.ENGINE_HARMONICS[h] * sin(TAU * (h + 1) * phase)
		var cyl: float = AudioConfig.ENGINE_CYLINDER_GAIN[p % AudioConfig.ENGINE_CYLINDER_GAIN.size()]
		out[i] = cyl * env * (tone + AudioConfig.ENGINE_NOISE * randf_range(-1.0, 1.0))
	return _wav(out, AudioConfig.ENGINE_GAIN, true)


## Clac de la palanca. `play` = holgura de la caja (1 de serie, 0 arreglada en taller):
## con holgura rasca antes de entrar y la marcha entra con un golpe grave.
static func clack(play: float) -> AudioStreamWAV:
	play = clampf(play, 0.0, 1.0)
	var grind := _samples(AudioConfig.CLACK_GRIND_S * play)
	var ring := _samples(AudioConfig.CLACK_RING_S)
	var out := PackedFloat32Array()
	out.resize(grind + ring)
	# Rascado: ruido zumbando contra los sincros, que crece hasta que la marcha entra.
	for i in grind:
		var t := float(i) / AudioConfig.MIX_RATE
		var buzz := fposmod(t * AudioConfig.CLACK_GRIND_BUZZ_HZ, 1.0)
		out[i] = AudioConfig.CLACK_GRIND_GAIN * play * (float(i) / grind) * buzz * randf_range(-1.0, 1.0)
	# Clac: chasquido corto, anillo metálico y (con holgura) golpe grave.
	var tick := _samples(AudioConfig.CLACK_TICK_S)
	var clonk := _samples(AudioConfig.CLACK_CLONK_S)
	for i in ring:
		var t := float(i) / AudioConfig.MIX_RATE
		var v := 0.0
		if i < tick:
			v += (1.0 - float(i) / tick) * randf_range(-1.0, 1.0)
		var ring_env := exp(-AudioConfig.CLACK_RING_DECAY * float(i) / ring)
		for hz: float in AudioConfig.CLACK_RING_HZ:
			v += AudioConfig.CLACK_RING_GAIN * ring_env * sin(TAU * hz * t)
		if i < clonk:
			v += AudioConfig.CLACK_CLONK_GAIN * play * exp(-AudioConfig.CLACK_CLONK_DECAY * float(i) / clonk) * sin(TAU * AudioConfig.CLACK_CLONK_HZ * t)
		out[grind + i] = v
	return _wav(out, AudioConfig.CLACK_GAIN, false)


## Tráfico de fondo: ruido grave con coches que pasan (sube y baja), en bucle sin corte.
static func city_loop() -> AudioStreamWAV:
	var n := _samples(AudioConfig.CITY_LOOP_S)
	var fade := _samples(AudioConfig.CITY_CROSSFADE_S)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var brown := 0.0
	var peak := 0.0
	for i in raw.size():
		brown += AudioConfig.CITY_RUMBLE_SMOOTH * (randf_range(-1.0, 1.0) - brown)
		raw[i] = brown
		peak = maxf(peak, absf(brown))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var v := raw[i]
		# Fundido de la cola sobre el principio: el bucle no tiene salto.
		if i < fade:
			var k := float(i) / fade
			v = v * k + raw[n + i] * (1.0 - k)
		var swell := 1.0 - AudioConfig.CITY_SWELL_DEPTH * (0.5 + 0.5 * cos(TAU * AudioConfig.CITY_SWELL_PER_LOOP * i / n))
		out[i] = v / peak * swell
	return _wav(out, AudioConfig.CITY_GAIN, true)


## Viento de montaña: casi silencio, con alguna racha lenta.
static func wind_loop() -> AudioStreamWAV:
	var n := _samples(AudioConfig.WIND_LOOP_S)
	var fade := _samples(AudioConfig.CITY_CROSSFADE_S)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var brown := 0.0
	var peak := 0.0
	for i in raw.size():
		brown += AudioConfig.WIND_SMOOTH * (randf_range(-1.0, 1.0) - brown)
		raw[i] = brown
		peak = maxf(peak, absf(brown))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var v := raw[i]
		if i < fade:
			var k := float(i) / fade
			v = v * k + raw[n + i] * (1.0 - k)
		var gust := 1.0 - AudioConfig.WIND_GUST_DEPTH * (0.5 + 0.5 * cos(TAU * AudioConfig.WIND_GUSTS_PER_LOOP * i / n))
		out[i] = v / peak * gust
	return _wav(out, AudioConfig.WIND_GAIN, true)


## Bocinazo de dos tonos (onda cuadrada suavizada), de duración `seconds`.
static func horn(seconds: float) -> AudioStreamWAV:
	var n := _samples(seconds)
	var attack := _samples(AudioConfig.HORN_ATTACK_S)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / AudioConfig.MIX_RATE
		var v := 0.0
		for hz: float in AudioConfig.HORN_HZ:
			v += signf(sin(TAU * hz * t))
		var env := minf(1.0, minf(float(i) / attack, float(n - i) / attack))
		out[i] = v * env
	return _wav(out, AudioConfig.HORN_GAIN, false)


## Avión pasando: rugido grave que crece y se va, con silbido de turbina que baja de tono (Doppler).
static func plane() -> AudioStreamWAV:
	var n := _samples(AudioConfig.PLANE_S)
	var out := PackedFloat32Array()
	out.resize(n)
	var brown := 0.0
	var peak := 0.0
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		brown += AudioConfig.PLANE_RUMBLE_SMOOTH * (randf_range(-1.0, 1.0) - brown)
		peak = maxf(peak, absf(brown))
		var hz := lerpf(AudioConfig.PLANE_WHINE_HZ.x, AudioConfig.PLANE_WHINE_HZ.y, smoothstep(AudioConfig.PLANE_PEAK_AT - 0.1, AudioConfig.PLANE_PEAK_AT + 0.1, k))
		phase += TAU * hz / AudioConfig.MIX_RATE
		out[i] = brown + AudioConfig.PLANE_WHINE_GAIN * sin(phase)
	for i in n:
		var k := float(i) / n
		# Sube despacio hasta tenerlo encima y se aleja más despacio aún.
		var env := k / AudioConfig.PLANE_PEAK_AT if k < AudioConfig.PLANE_PEAK_AT else (1.0 - k) / (1.0 - AudioConfig.PLANE_PEAK_AT)
		out[i] = out[i] / peak * env * env
	return _wav(out, AudioConfig.PLANE_GAIN, false)


## Pájaro: `chirps` píos rápidos que suben de tono.
static func bird(chirps: int) -> AudioStreamWAV:
	var chirp := _samples(AudioConfig.BIRD_CHIRP_S)
	var gap := _samples(AudioConfig.BIRD_GAP_S)
	var out := PackedFloat32Array()
	out.resize(chirps * (chirp + gap))
	var lo := AudioConfig.BIRD_CHIRP_HZ.x
	var hi := AudioConfig.BIRD_CHIRP_HZ.y
	for c in chirps:
		var phase := 0.0
		# Cada pío del canto un poco distinto.
		var top := randf_range(lerpf(lo, hi, AudioConfig.BIRD_TOP_MIN), hi)
		for i in chirp:
			var k := float(i) / chirp
			phase += TAU * lerpf(lo, top, k) / AudioConfig.MIX_RATE
			out[c * (chirp + gap) + i] = sin(phase) * sin(PI * k)
	return _wav(out, AudioConfig.BIRD_GAIN, false)


static func _samples(seconds: float) -> int:
	return int(seconds * AudioConfig.MIX_RATE)


static func _wav(samples: PackedFloat32Array, gain: float, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * AudioConfig.GAIN_MAX))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = AudioConfig.MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
