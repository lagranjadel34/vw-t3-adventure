class_name PixelFont
## Fuente de píxeles 3x5 para rótulos diminutos del HUD (números y letras sueltas).

const GLYPHS := {
	"0": ["111", "101", "101", "101", "111"],
	"1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "011", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"],
	"7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "111"],
	"A": ["010", "101", "111", "101", "101"],
	"M": ["101", "111", "111", "101", "101"],
	"k": ["100", "101", "110", "101", "101"],
	"m": ["000", "000", "111", "111", "101"],
}
const WIDTH := 3
const HEIGHT := 5


## Dibuja un carácter con su esquina superior izquierda en `pos`. Si se da `clip`,
## solo se pintan los píxeles que caen dentro (rodillos del cuentakilómetros).
static func draw_char(canvas: CanvasItem, ch: String, pos: Vector2, color: Color, clip := Rect2()) -> void:
	var rows: Array = GLYPHS[ch]
	for ry in rows.size():
		var row: String = rows[ry]
		for rx in row.length():
			var p := pos + Vector2(rx, ry)
			if row[rx] == "1" and (clip.size == Vector2.ZERO or clip.has_point(p)):
				canvas.draw_rect(Rect2(p, Vector2.ONE), color)
