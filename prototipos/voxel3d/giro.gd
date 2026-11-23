extends "res://render_ficha.gd"
## Animación de la Dehler girando sobre sí misma con la cámara del juego (alta y oblicua).
## El sol queda fijo, así que luces y sombras cambian como en el juego al girar.
## Uso: godot --path . res://giro.tscn -- --out=/carpeta [--elev=50] [--alto=0.9] [--dist=1.25]
## (guarda giro_000.png ...). --elev=0 --alto=1.0 = cámara a la altura de la parrilla.

const FRAMES := 72            # 5° por fotograma
const GAME_ELEVATION := 50.0  # grados
const GAME_DIST := 1.25

var van: Node3D
var frame := 0


func _ready() -> void:
	super._ready()
	for c in view.get_children():
		if c is Node3D and not (c is Camera3D or c is DirectionalLight3D or c is MeshInstance3D and (c as MeshInstance3D).mesh is PlaneMesh):
			van = c
	var elev := GAME_ELEVATION
	var alto := 0.9
	var dist := GAME_DIST
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--elev="):
			elev = float(a.substr(7))
		elif a.begins_with("--alto="):
			alto = float(a.substr(7))
		elif a.begins_with("--dist="):
			dist = float(a.substr(7))
	var el := deg_to_rad(elev)
	var target := Vector3(0, alto, 0)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = FOV
	cam.position = target + Vector3(0, sin(el), cos(el)) * DIST * dist
	cam.look_at(target, Vector3.UP)


func _next() -> void:
	idx = 0
	wait = 0


func _process(_d: float) -> void:
	if van == null:
		return
	van.rotation_degrees.y = frame * 360.0 / FRAMES
	wait += 1
	if wait == 4:
		var img := view.get_texture().get_image()
		img.resize(PIXEL_RES.x * UPSCALE, PIXEL_RES.y * UPSCALE, Image.INTERPOLATE_NEAREST)
		img.save_png("%s/giro_%03d.png" % [out_dir, frame])
		frame += 1
		wait = 0
		if frame >= FRAMES:
			get_tree().quit()
