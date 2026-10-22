class_name UiKit
## Fuentes, textos con contorno y texturas generadas para las pantallas (sin arte inventado).

const POPPINS_BOLD_ITALIC := preload("res://assets/fonts/Poppins-BoldItalic.ttf")
const FREDOKA := preload("res://assets/fonts/Fredoka-Variable.ttf")
const FREDOKA_WEIGHT := 600
const FREDOKA_BOLD_WEIGHT := 700


static func fredoka(bold := false) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = FREDOKA
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): FREDOKA_BOLD_WEIGHT if bold else FREDOKA_WEIGHT}
	return f


## Label con contorno negro; `origin` como en Phaser (0,0 arriba-izq; 0.5,0.5 centro).
static func label(text: String, font: Font, size: int, color: Color, outline: int, pos: Vector2, origin := Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = l.get_minimum_size()
	l.pivot_offset = l.size * origin
	l.position = pos - l.pivot_offset
	return l


## Círculo blanco relleno, para partículas (se tiñe después).
static func circle_texture(radius: int) -> ImageTexture:
	var d := radius * 2
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius, radius) - Vector2(0.5, 0.5)
	for y in d:
		for x in d:
			if Vector2(x, y).distance_to(c) <= radius - 0.5:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


## Estela horizontal que se desvanece hacia la cola (izquierda).
static func streak_texture(size: Vector2i) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for x in size.x:
		var t := float(x) / (size.x - 1)
		for y in size.y:
			img.set_pixel(x, y, Color(1, 1, 1, t * t))
	return ImageTexture.create_from_image(img)


## Partículas tipo Phaser: vida, velocidad, escala y alpha de inicio a fin, tinte al azar.
static func particles(texture: Texture2D, frequency: float, life: Vector2, direction: Vector2, spread_deg: float, speed: Vector2, scale: Vector2, alpha: float, tints: Array[Color]) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.lifetime = life.y
	p.amount = ceili(life.y / frequency)
	p.lifetime_randomness = 1.0 - life.x / life.y
	p.direction = direction.normalized()
	p.spread = spread_deg
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.scale_amount_min = scale.x
	p.scale_amount_max = scale.x
	var curve := Curve.new()
	curve.max_value = maxf(1.0, scale.y / scale.x)
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, scale.y / scale.x))
	p.scale_amount_curve = curve
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, alpha))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	var tint := Gradient.new()
	tint.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	tint.offsets = PackedFloat32Array(range(tints.size()).map(func(i: int) -> float: return float(i) / tints.size()))
	tint.colors = PackedColorArray(tints)
	p.color_initial_ramp = tint
	return p
