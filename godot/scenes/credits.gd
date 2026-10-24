extends Node2D
## Créditos: quién hace el juego y con qué. Toque, Intro, Esc o "atrás" vuelven al menú.

const MENU_SCENE := "res://scenes/menu.tscn"

@onready var _ui: CanvasLayer = $UI


func _ready() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bg := Sprite2D.new()
	bg.texture = load(MenuConfig.BACKGROUND)
	var bg_size := bg.texture.get_size()
	bg.scale = Vector2.ONE * maxf(screen.x / bg_size.x, screen.y / bg_size.y)
	bg.position = screen / 2
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = MenuConfig.CFG_DIM
	dim.size = screen
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(dim)

	_ui.add_child(UiKit.label(MenuConfig.CREDITS_TITLE, UiKit.POPPINS_BOLD_ITALIC, MenuConfig.TITLE_FONT_SIZE, Color.WHITE,
		MenuConfig.TITLE_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.CFG_TITLE_Y), Vector2(0, 0.5)))
	for i in MenuConfig.CREDITS_LINES.size():
		var y := MenuConfig.CREDITS_Y + i * MenuConfig.CREDITS_LINE_H
		var line: Array = MenuConfig.CREDITS_LINES[i]
		_ui.add_child(UiKit.label(line[0], UiKit.fredoka(true), MenuConfig.CREDITS_FONT_SIZE, MenuConfig.CFG_SECTION_COLOR,
			MenuConfig.CREDITS_OUTLINE, Vector2(MenuConfig.MENU_X, y), Vector2(0, 0.5)))
		_ui.add_child(UiKit.label(line[1], UiKit.fredoka(), MenuConfig.CREDITS_FONT_SIZE, Color.WHITE,
			MenuConfig.CREDITS_OUTLINE, Vector2(MenuConfig.CREDITS_NAME_X, y), Vector2(0, 0.5)))

	var back := UiKit.label(MenuConfig.CFG_BACK, UiKit.fredoka(true), MenuConfig.OPTION_FONT_SIZE, MenuConfig.OPTION_SELECTED_COLOR,
		MenuConfig.OPTION_OUTLINE, Vector2(MenuConfig.MENU_X, MenuConfig.CREDITS_BACK_Y), Vector2(0, 0.5))
	_ui.add_child(back)


func _notification(what: int) -> void:
	# Botón "atrás" de Android.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _unhandled_input(event: InputEvent) -> void:
	# Solo hay una opción (Volver): cualquier toque o tecla de confirmar vuelve.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_BACKSPACE]:
			_back()
	elif event is InputEventScreenTouch and event.pressed:
		_back()


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
