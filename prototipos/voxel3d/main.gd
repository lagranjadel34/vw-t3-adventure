extends Node
## Prototipo: mundo 3D de bloques (voxel/low-poly) renderizado a 320x180 y
## escalado con filtro nearest, para valorar el estilo "3D pixelado" en el
## renderer Compatibility. No es parte del juego: todo se genera por código.
## Teclas: flechas/WASD conducen. Argumentos: --shot=ruta.png [--frames=N]

const WHEEL_RADIUS := 0.33
const MAX_WHEEL_STEER := 0.45   # radianes de giro de las ruedas delanteras
const PIXEL_RES := Vector2i(320, 180)      # misma resolución lógica que el juego
const CAM_OFFSET := Vector3(0, 24, 17)     # cámara alta y oblicua, como el vídeo
const CAM_OFFSET_NEAR := Vector3(-5, 8, 8)  # --cerca: plano corto para capturas
const CAM_FOV := 38.0
const CAM_LERP := 4.0
const WORLD_SIZE := 160.0
const ROAD_WIDTH := 5.0
const TREE_COUNT := 260
const BUSH_COUNT := 420
const SEED := 34
const VAN_MODEL := "res://dehler.json"  # tools/sprites/export_mesh3d.py dehler ... --detalle
const VAN_MODEL_BIN := "res://dehler_curvas.bin"  # tools/sprites/t3_sdf.py

const MAX_SPEED := 14.0        # m/s
const ACCEL := 6.0
const BRAKE := 12.0
const DRAG := 1.2
const STEER_RATE := 1.6        # rad/s a velocidad plena

const PAL := {
	"ground_a": Color("b9835a"), "ground_b": Color("a8724d"), "ground_c": Color("c79a6b"),
	"grass": Color("8f8a4a"), "road": Color("d2a679"), "rut": Color("9c6a47"),
	"trunk": Color("5b3a26"), "leaf_a": Color("5f6b33"), "leaf_b": Color("7d8040"),
	"bush": Color("707a3c"), "dry": Color("6e4a2f"),
	"body": Color("2f5f9e"), "front": Color("8fc3e8"), "roof": Color("e9e4d8"),
	"glass": Color("2a3442"), "tyre": Color("1b1b1d"), "rim": Color("b9b9b9"),
	"light": Color("ffe7a3"), "tail": Color("d2442f"), "bumper": Color("3a3a3a"),
	"sky": Color("f2b98a"), "fog": Color("e9b48f"), "sun": Color("ffd2a1"),
	"ambient": Color("8f7aa8"),
}

var rng := RandomNumberGenerator.new()
var view: SubViewport
var cam: Camera3D
var van: Node3D
var wheel_roll := 0.0
var speed := 0.0
var heading := 0.0
var road_pts: PackedVector3Array = []
var auto_drive := false
var cam_offset := CAM_OFFSET
var shot_path := ""
var shot_frames := 90
var frame := 0
var fps_label: Label


func _ready() -> void:
	rng.seed = SEED
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
			auto_drive = true
		elif a == "--cerca":
			cam_offset = CAM_OFFSET_NEAR
		elif a.begins_with("--frames="):
			shot_frames = int(a.substr(9))
	_build_viewport()
	_build_environment()
	_build_ground()
	_build_road()
	_build_vegetation()
	van = _load_van() if FileAccess.file_exists(VAN_MODEL) else _build_van()
	view.add_child(van)
	var start := road_pts[2]
	van.position = start
	heading = atan2(road_pts[3].x - start.x, road_pts[3].z - start.z)
	cam.position = van.position + cam_offset
	cam.look_at(van.position)


func _build_viewport() -> void:
	view = SubViewport.new()
	view.size = PIXEL_RES
	view.msaa_3d = Viewport.MSAA_DISABLED
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var rect := TextureRect.new()
	rect.texture = view.get_texture()
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(rect)
	fps_label = Label.new()
	fps_label.position = Vector2(8, 8)
	add_child(fps_label)
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	view.add_child(cam)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PAL.sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = PAL.ambient
	env.ambient_light_energy = 0.3
	env.fog_enabled = true
	env.fog_light_color = PAL.fog
	env.fog_density = 0.0035
	env.fog_sky_affect = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = PAL.sun
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.rotation_degrees = Vector3(-52, 40, 0)
	view.add_child(sun)


func _box(size: Vector3, color: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	bm.material = mat
	m.mesh = bm
	m.position = pos
	parent.add_child(m)
	return m


func _build_ground() -> void:
	# Textura de manchas a baja resolución: con nearest da el moteado del vídeo.
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.06
	for y in 128:
		for x in 128:
			var n := noise.get_noise_2d(x, y)
			var c: Color = PAL.ground_a
			if n > 0.25: c = PAL.grass
			elif n > 0.05: c = PAL.ground_c
			elif n < -0.3: c = PAL.ground_b
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(6, 6, 1)
	mat.roughness = 1.0
	var pm := PlaneMesh.new()
	pm.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	pm.material = mat
	var g := MeshInstance3D.new()
	g.mesh = pm
	view.add_child(g)


func _build_road() -> void:
	# Camino de tierra serpenteante hecho de losas planas (como un tile 3D).
	var root := Node3D.new()
	view.add_child(root)
	var z := WORLD_SIZE * 0.45
	while z > -WORLD_SIZE * 0.45:
		var x := sin(z * 0.045) * 18.0 + sin(z * 0.11) * 4.0
		road_pts.append(Vector3(x, 0, z))
		z -= 2.0
	for i in road_pts.size() - 1:
		var a := road_pts[i]
		var b := road_pts[i + 1]
		var mid := (a + b) * 0.5
		var seg := _box(Vector3(ROAD_WIDTH, 0.04, a.distance_to(b) + 0.6), PAL.road, mid + Vector3(0, 0.02, 0), root)
		seg.rotation.y = atan2(b.x - a.x, b.z - a.z)
		for side in [-1.2, 1.2]:
			var rut := _box(Vector3(0.5, 0.05, a.distance_to(b) + 0.6), PAL.rut, Vector3(side, 0.005, 0), seg)
			rut.position.y = 0.005


func _near_road(p: Vector3, margin: float) -> bool:
	for r in road_pts:
		if Vector2(p.x - r.x, p.z - r.z).length() < margin:
			return true
	return false


func _rand_spot(margin: float) -> Vector3:
	var p := Vector3.ZERO
	for _i in 20:
		p = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * WORLD_SIZE * 0.48
		if not _near_road(p, margin):
			return p
	return p


func _build_vegetation() -> void:
	for _i in TREE_COUNT:
		var t := Node3D.new()
		t.position = _rand_spot(ROAD_WIDTH + 2.0)
		t.rotation.y = rng.randf() * TAU
		var h := rng.randf_range(2.5, 4.5)
		_box(Vector3(0.5, h, 0.5), PAL.trunk, Vector3(0, h * 0.5, 0), t)
		# Copa de pino escalonada: bloques que se estrechan hacia arriba.
		var w := rng.randf_range(2.6, 3.4)
		var y := h
		var leaf: Color = PAL.leaf_a if rng.randf() < 0.6 else PAL.leaf_b
		for k in 3:
			_box(Vector3(w, 0.8, w), leaf, Vector3(rng.randf_range(-0.2, 0.2), y, rng.randf_range(-0.2, 0.2)), t)
			w *= 0.62
			y += 0.75
		view.add_child(t)
	for _i in BUSH_COUNT:
		var b := Node3D.new()
		b.position = _rand_spot(ROAD_WIDTH * 0.5 + 0.8)
		var c: Color = PAL.bush if rng.randf() < 0.7 else PAL.dry
		for k in rng.randi_range(2, 4):
			var s := rng.randf_range(0.3, 0.6)
			_box(Vector3(s, s, s), c, Vector3(rng.randf_range(-0.4, 0.4), s * 0.5, rng.randf_range(-0.4, 0.4)), b)
		view.add_child(b)


func _load_van() -> Node3D:
	var v := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	v.add_child(body)
	if FileAccess.file_exists(VAN_MODEL_BIN):
		var full := VanMesh.load_full(VAN_MODEL_BIN)
		var wheels := full.get_node_or_null("Ruedas")
		if wheels:
			full.remove_child(wheels)
			v.add_child(wheels)   # las ruedas no se inclinan con la carrocería
		body.add_child(full)
	else:
		body.add_child(VanMesh.load_van(VAN_MODEL))
	return v


func _build_van() -> Node3D:
	# T3 Dehler Profi a bloques (medidas reales aprox.: 4,6 x 1,85 m, techo alto).
	var v := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	v.add_child(body)
	_box(Vector3(1.85, 0.9, 4.6), PAL.body, Vector3(0, 0.75, 0), body)            # chapa baja
	_box(Vector3(1.86, 0.55, 4.0), PAL.glass, Vector3(0, 1.47, -0.25), body)      # ventanillas
	_box(Vector3(1.86, 0.55, 0.5), PAL.body, Vector3(0, 1.47, -2.05), body)       # pilar trasero
	_box(Vector3(1.8, 0.6, 3.9), PAL.roof, Vector3(0, 2.05, -0.3), body)          # techo alto
	_box(Vector3(1.86, 0.5, 0.12), PAL.front, Vector3(0, 1.0, 2.31), body)        # frontal celeste
	_box(Vector3(1.5, 0.48, 0.1), PAL.glass, Vector3(0, 1.5, 2.26), body)         # parabrisas
	_box(Vector3(1.9, 0.18, 0.2), PAL.bumper, Vector3(0, 0.38, 2.35), body)       # paragolpes
	_box(Vector3(1.9, 0.18, 0.2), PAL.bumper, Vector3(0, 0.38, -2.35), body)
	for sx in [-0.65, 0.65]:
		_box(Vector3(0.28, 0.2, 0.08), PAL.light, Vector3(sx, 0.85, 2.36), body)
		_box(Vector3(0.22, 0.3, 0.08), PAL.tail, Vector3(sx * 1.15, 0.85, -2.33), body)
	for wz in [1.45, -1.45]:
		for wx in [-0.88, 0.88]:
			_box(Vector3(0.28, 0.65, 0.65), PAL.tyre, Vector3(wx, 0.33, wz), v)
			_box(Vector3(0.3, 0.28, 0.28), PAL.rim, Vector3(wx, 0.33, wz), v)
	return v


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	if auto_drive:
		throttle = 1.0
		steer = _auto_steer()
	else:
		throttle = Input.get_axis("ui_down", "ui_up")
		steer = Input.get_axis("ui_right", "ui_left")
		if Input.is_key_pressed(KEY_W): throttle = 1.0
		if Input.is_key_pressed(KEY_S): throttle = -1.0
		if Input.is_key_pressed(KEY_A): steer = 1.0
		if Input.is_key_pressed(KEY_D): steer = -1.0
	if throttle > 0.0:
		speed = move_toward(speed, MAX_SPEED, ACCEL * throttle * delta)
	elif throttle < 0.0:
		speed = move_toward(speed, -MAX_SPEED * 0.3, BRAKE * -throttle * delta)
	speed = move_toward(speed, 0.0, DRAG * delta)
	heading += steer * STEER_RATE * clampf(speed / MAX_SPEED, -1.0, 1.0) * delta
	van.rotation.y = heading
	van.position += Vector3(sin(heading), 0, cos(heading)) * speed * delta
	wheel_roll += speed * delta / WHEEL_RADIUS
	VanMesh.set_wheels(van, wheel_roll, steer * MAX_WHEEL_STEER)
	# Balanceo leve de la caja al girar: suaviza y da peso.
	van.get_node("Body").rotation.z = lerpf(van.get_node("Body").rotation.z, -steer * speed / MAX_SPEED * 0.06, 0.1)
	var target := van.position + cam_offset
	cam.position = cam.position.lerp(target, clampf(CAM_LERP * delta, 0.0, 1.0))
	cam.look_at(cam.position - cam_offset)


func _auto_steer() -> float:
	var best := 0
	var best_d := INF
	for i in road_pts.size():
		var d := road_pts[i].distance_to(van.position)
		if d < best_d:
			best_d = d
			best = i
	var tgt := road_pts[mini(best + 3, road_pts.size() - 1)]
	var want := atan2(tgt.x - van.position.x, tgt.z - van.position.z)
	return clampf(wrapf(want - heading, -PI, PI) * 2.0, -1.0, 1.0)


func _process(_delta: float) -> void:
	fps_label.visible = shot_path == ""
	fps_label.text = "%d fps" % Engine.get_frames_per_second()
	frame += 1
	if shot_path != "" and frame == shot_frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_path)
		get_tree().quit()
