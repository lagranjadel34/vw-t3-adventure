class_name WorkshopEntry
extends CanvasLayer
## Popup al llegar al portón del taller: "¿Entrar?". Se muestra con el juego en pausa.
## Avisa con `confirmed` (entrar) o `declined` (seguir de largo).

signal confirmed
signal declined

const ENTER := 0
const SKIP := 1

var _title := ""
var _rows := OptionRows.new()
var _done := false
var _opened_frame := 0


static func create(title: String) -> WorkshopEntry:
	var entry := WorkshopEntry.new()
	entry.layer = GameConfig.WORKSHOP_LAYER
	entry.process_mode = Node.PROCESS_MODE_ALWAYS
	entry._title = title
	return entry


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

	# Hueco de la foto de Karvan's: se cambia por la imagen cuando llegue.
	var frame := ColorRect.new()
	frame.color = GameConfig.WORKSHOP_PHOTO_COLOR
	frame.size = GameConfig.WORKSHOP_PHOTO_SIZE
	frame.position = Vector2(cx - frame.size.x / 2, GameConfig.WORKSHOP_PHOTO_TOP)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	add_child(UiKit.label(WorkshopConfig.ENTRY_PHOTO, UiKit.fredoka(), GameConfig.WORKSHOP_TEXT_SIZE, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_PHOTO_TOP + frame.size.y / 2), Vector2(0.5, 0.5)))

	add_child(UiKit.label(WorkshopConfig.ENTRY_QUESTION, UiKit.fredoka(true), GameConfig.WORKSHOP_TEXT_SIZE + 2, Color.WHITE,
		GameConfig.WORKSHOP_OUTLINE, Vector2(cx, GameConfig.WORKSHOP_QUESTION_Y), Vector2(0.5, 0.5)))

	_rows.add(self, WorkshopConfig.ENTRY_ENTER, Vector2(cx, GameConfig.WORKSHOP_ENTRY_ROW_Y))
	_rows.add(self, WorkshopConfig.ENTRY_SKIP, Vector2(cx, GameConfig.WORKSHOP_ENTRY_ROW_Y + GameConfig.WORKSHOP_ROW_SPACING))
	_rows.picked.connect(choose_row)


## Elige una opción: ENTER o SKIP (teclado, toque o prueba).
func choose_row(index: int) -> void:
	if _done:
		return
	_done = true
	if index == ENTER:
		confirmed.emit()
	else:
		declined.emit()
	queue_free()


func choose(enter: bool) -> void:
	choose_row(ENTER if enter else SKIP)


func _unhandled_input(event: InputEvent) -> void:
	# La misma pulsación que abrió el popup no debe contar aquí.
	if Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("ui_cancel"):
		choose(false)
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
				choose(false)
