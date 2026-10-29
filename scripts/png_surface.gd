extends Panel
## Nine-slice PNG atlas skin. Source margins are drawn at 3× scale so
## 48px of original ink becomes a crisp 16 logical-pixel corner on retina.
var skin: StyleBoxTexture
var tint = Color.WHITE

func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	resized.connect(queue_redraw)

func _draw() -> void:
	if skin == null:
		return
	var source_scale = float(skin.get_meta("source_scale", 3.0))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE / source_scale)
	skin.draw(get_canvas_item(), Rect2(Vector2.ZERO, size * source_scale))
