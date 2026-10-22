class_name PixelFont
## Fuente de píxeles 3x5 para rótulos diminutos del HUD (números y letras sueltas).

const GLYPHS := {
	"1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "011", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"A": ["010", "101", "111", "101", "101"],
	"M": ["101", "111", "111", "101", "101"],
}
const WIDTH := 3
const HEIGHT := 5


## Dibuja un carácter con su esquina superior izquierda en `pos`.
static func draw_char(canvas: CanvasItem, ch: String, pos: Vector2, color: Color) -> void:
	var rows: Array = GLYPHS[ch]
	for ry in rows.size():
		var row: String = rows[ry]
		for rx in row.length():
			if row[rx] == "1":
				canvas.draw_rect(Rect2(pos + Vector2(rx, ry), Vector2.ONE), color)
