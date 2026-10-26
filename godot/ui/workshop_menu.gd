class_name WorkshopMenu
extends CanvasLayer
## Menú del taller: mejoras de la furgo (gratis de momento) y "Salir del taller".
## Se muestra con el juego en pausa; avisa con `closed` al salir (toque, Enter o atrás).

signal closed

var _title := ""
var _rows := OptionRows.new()
var _opened_frame := 0


static func create(title: String) -> WorkshopMenu:
	var menu := WorkshopMenu.new()
	menu.layer = GameConfig.WORKSHOP_LAYER
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	menu._title = title
	return menu


func _ready() -> void:
	_opened_frame = Engine.get_process_frames()
	var dim := ColorRect.new()
	dim.color = GameConfig.WORKSHOP_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# Centrado en lo que se ve (en móviles anchos la pantalla mide más de 320).
	var cx := get_viewport().get_visible_rect().size.x / 2
	add_child(UiKit.label(_title, UiKit.POPPINS_BOLD_ITALIC, GameConfig.WORKSHOP_TITLE_SIZE, GameConfig.WORKSHOP_ACCENT,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_TITLE_Y), Vector2(0.5, 0.5)))
	add_child(UiKit.label(WorkshopConfig.MENU_NOTE, UiKit.fredoka(), GameConfig.WORKSHOP_TEXT_SIZE, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_TEXT_Y), Vector2(0.5, 0.5)))

	for i in WorkshopConfig.UPGRADES.size():
		_rows.add(self, "", Vector2(cx, _row_y(i)))
	_rows.add(self, WorkshopConfig.MENU_LEAVE, Vector2(cx, _row_y(WorkshopConfig.UPGRADES.size())))
	_rows.picked.connect(_on_picked)
	_refresh_upgrades()


func _row_y(index: int) -> float:
	return GameConfig.WORKSHOP_ROW_Y + index * GameConfig.WORKSHOP_ROW_SPACING


func _refresh_upgrades() -> void:
	for i in WorkshopConfig.UPGRADES.size():
		var upgrade: Dictionary = WorkshopConfig.UPGRADES[i]
		var installed := Settings.has_upgrade(upgrade.id)
		var state := WorkshopConfig.MENU_INSTALLED if installed else WorkshopConfig.MENU_FREE
		_rows.set_text(i, "%s: %s" % [upgrade.name, state])
		_rows.set_enabled(i, not installed)


func _on_picked(index: int) -> void:
	if index == WorkshopConfig.UPGRADES.size():
		close()
		return
	var upgrade: Dictionary = WorkshopConfig.UPGRADES[index]
	Settings.install_upgrade(upgrade.id)
	_refresh_upgrades()


func _unhandled_input(event: InputEvent) -> void:
	# La misma pulsación que abrió el menú no debe contar aquí.
	if Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP, KEY_W:
				_rows.move(-1)
			KEY_DOWN, KEY_S:
				_rows.move(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_rows.activate()
			KEY_ESCAPE, KEY_BACKSPACE:
				close()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()
