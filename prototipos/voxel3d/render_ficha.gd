extends Node
## Saca las vistas de la ficha 3D de la Dehler: cada vista se renderiza en 3D a baja
## resolución (PIXEL_RES) y se guarda ampliada con nearest, como se vería en el juego.
## Uso: godot --path . res://render_ficha.tscn -- --out=/carpeta

const PIXEL_RES := Vector2i(320, 240)
const UPSCALE := 3
const DIST := 9.0
const FOV := 30.0
const MODEL := "res://dehler.json"
const BG := Color("bfe0e0")
const FLOOR_SHADE := 0.72  # el suelo iluminado queda del tono del fondo
# nombre, yaw (grados, 0 = de frente), elevación (grados), ortogonal, tamaño (m) o distancia relativa
const VIEWS := [
	["tres_cuartos", 35.0, 22.0, false, 1.0],
	["tres_cuartos_trasera", 215.0, 22.0, false, 1.0],
	["lateral_izq", 90.0, 0.0, true, 4.4],
	["lateral_dcha", -90.0, 0.0, true, 4.4],
	["frontal", 0.0, 0.0, true, 3.0],
	["trasera", 180.0, 0.0, true, 3.0],
	["superior", 0.0, 89.0, true, 5.2],
	["juego", 150.0, 52.0, false, 1.25],
]

var view: SubViewport
var cam: Camera3D
var out_dir := "/tmp"
var idx := -1
var wait := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	view = SubViewport.new()
	view.size = PIXEL_RES
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9fb4c8")
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("fff0dc")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_bias = 0.3
	sun.shadow_normal_bias = 4.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.rotation_degrees = Vector3(-55, 30, 0)
	view.add_child(sun)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = BG * FLOOR_SHADE
	floor_mat.albedo_color.a = 1.0
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	pm.material = floor_mat
	var g := MeshInstance3D.new()
	g.mesh = pm
	view.add_child(g)
	view.add_child(VanMesh.load_van(MODEL))
	cam = Camera3D.new()
	view.add_child(cam)
	_next()


func _next() -> void:
	idx += 1
	if idx >= VIEWS.size():
		get_tree().quit()
		return
	var v: Array = VIEWS[idx]
	var yaw := deg_to_rad(v[1])
	var el := deg_to_rad(v[2])
	var target := Vector3(0, 1.1, 0)
	var dir := Vector3(sin(yaw) * cos(el), sin(el), cos(yaw) * cos(el))
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL if v[3] else Camera3D.PROJECTION_PERSPECTIVE
	cam.size = v[4]
	cam.fov = FOV
	cam.position = target + dir * DIST * (1.0 if v[3] else v[4])
	var up := Vector3.UP if v[2] < 80.0 else Vector3(0, 0, 1)
	cam.look_at(target, up)
	wait = 0


func _process(_d: float) -> void:
	wait += 1
	if wait == 6:
		var img := view.get_texture().get_image()
		img.resize(PIXEL_RES.x * UPSCALE, PIXEL_RES.y * UPSCALE, Image.INTERPOLATE_NEAREST)
		img.save_png("%s/%s.png" % [out_dir, VIEWS[idx][0]])
		_next()
