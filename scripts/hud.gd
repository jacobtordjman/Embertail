extends CanvasLayer

var health_label: Label
var lives_label: Label
var score_label: Label
var coin_label: Label
var timer_label: Label
var dash_label: Label
var progress: ProgressBar
var toast: Label
var toast_time: float = 0.0
var hearts: Array[TextureRect] = []

func _ready() -> void:
	var root := Control.new()
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var panel := Panel.new()
	panel.position = Vector2(18, 16)
	panel.size = Vector2(924, 64)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203d38ef")
	style.set_corner_radius_all(10)
	style.border_color = Color("92a77b")
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	label(root, "EMBERTRAIL", Vector2(35, 24), 12, Color("f2dbab"))
	for i in range(3):
		var heart := TextureRect.new()
		heart.texture = load("res://assets/sprites/heart.png")
		heart.position = Vector2(35 + i * 24, 45)
		heart.size = Vector2(20, 20)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(heart)
		hearts.append(heart)
	lives_label = label(root, "03 LIVES", Vector2(116, 47), 12, Color("b2c8b1"))
	coin_label = label(root, "EMBERS   00", Vector2(220, 23), 13, Color("f4d18d"))
	score_label = label(root, "000000", Vector2(220, 43), 20, Color("fff1cf"))
	label(root, "01  /  LANTERNWOOD", Vector2(402, 25), 11, Color("b4c7a8"))
	progress = ProgressBar.new()
	progress.position = Vector2(402, 49)
	progress.size = Vector2(197, 6)
	progress.show_percentage = false
	progress.add_theme_font_size_override("font_size", 1)
	progress.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("405a4e")
	bg.set_corner_radius_all(3)
	bg.set_content_margin_all(0)
	var fill := bg.duplicate()
	fill.bg_color = Color("ecc97f")
	progress.add_theme_stylebox_override("background", bg)
	progress.add_theme_stylebox_override("fill", fill)
	root.add_child(progress)
	dash_label = label(root, "X  DASH READY", Vector2(642, 39), 12, Color("a6e0c7"))
	timer_label = label(root, "00:00", Vector2(817, 24), 20, Color("fff0c8"))
	label(root, "ESC  PAUSE", Vector2(817, 50), 10, Color("b2c8b1"))
	toast = label(root, "", Vector2(100, 98), 14, Color("fff0cc"))
	toast.size = Vector2(760, 36)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_outline_color", Color("1f3938"))
	toast.add_theme_constant_override("outline_size", 6)
	var footer := label(root, "A D / ARROWS   move     SPACE   jump     SHIFT   run     X   dash", Vector2(24, 515), 10, Color("c9d3b8"))
	footer.add_theme_color_override("font_outline_color", Color("213e37"))
	footer.add_theme_constant_override("outline_size", 4)

func label(parent: Node, text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.position = at
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func update_values(health: int, lives: int, score: int, coins: int, seconds: float, distance: float, cooldown: float) -> void:
	for i in range(hearts.size()):
		hearts[i].modulate = Color.WHITE if i < health else Color(0.45, 0.5, 0.43, 0.5)
	lives_label.text = "%02d LIVES" % lives
	score_label.text = "%06d" % score
	coin_label.text = "EMBERS   %02d" % coins
	timer_label.text = "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	progress.value = clampf(distance, 0, 1)
	dash_label.text = "X  DASH READY" if cooldown <= 0 else "X  RECHARGING"
	dash_label.modulate.a = 1.0 if cooldown <= 0 else 0.5

func notify(message: String, duration: float = 3.0) -> void:
	toast.text = message
	toast_time = duration
	toast.modulate.a = 1.0

func _process(delta: float) -> void:
	if not get_tree().paused:
		toast_time = maxf(0.0, toast_time - delta)
	toast.modulate.a = minf(1.0, toast_time * 2.0)
