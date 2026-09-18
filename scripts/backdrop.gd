extends Node2D

var scroll_x: float = 0.0
var time: float = 0.0
var mountain_texture: Texture2D
var tree_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://assets/backgrounds/mountains.png"):
		mountain_texture = load("res://assets/backgrounds/mountains.png")
	if ResourceLoader.exists("res://assets/backgrounds/trees.png"):
		tree_texture = load("res://assets/backgrounds/trees.png")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	# A fixed sky, then three independent depths of scenery.
	for y in range(0, 540, 6):
		var color := Color("c0d9cf").lerp(Color("f0dfaa"), float(y) / 540.0)
		draw_rect(Rect2(0, y, 960, 6), color)
	draw_circle(Vector2(715 - scroll_x * 0.035, 125), 64, Color(1, 0.94, 0.69, 0.17))
	draw_circle(Vector2(715 - scroll_x * 0.035, 125), 47, Color("f8ebbc"))
	for index in range(-1, 6):
		var x: float = float(index * 275) - fposmod(scroll_x * 0.06, 275.0)
		paint_ellipse(Vector2(x, 99 + index % 2 * 45), Vector2(93, 6), Color(0.98, 0.97, 0.84, 0.45))
	for layer in range(3):
		var points := PackedVector2Array([Vector2(-100, 550)])
		var offset: float = scroll_x * (0.10 + layer * 0.08)
		for x in range(-100, 1101, 25):
			var wave: float = sin((x + offset) * 0.008 + layer * 3) * (43 + layer * 6) + sin((x + offset) * 0.019) * 15
			points.append(Vector2(x, 248 + layer * 67 + wave))
		points.append(Vector2(1100, 550))
		draw_colored_polygon(points, [Color("94b5a5"), Color("6b9c8d"), Color("457b70")][layer])
	if mountain_texture:
		tile_layer(mountain_texture, 0.16, 155, Color(1, 1, 1, 0.75))
	if tree_texture:
		tile_layer(tree_texture, 0.42, 121, Color(1, 1, 1, 0.9))
	# Foreground trunks sit behind the collision world.
	for i in range(-1, 7):
		var x: float = i * 237.0 - fposmod(scroll_x * 0.65, 237.0)
		var h: float = 130 + (i * i * 17 % 80)
		draw_rect(Rect2(x, 472 - h, 12, h), Color("355f56"))
		draw_line(Vector2(x + 5, 370), Vector2(x - 18, 341), Color("355f56"), 5)
		for k in range(4):
			paint_ellipse(Vector2(x - 20 + k * 18, 471 - h - sin(k * 1.2) * 13), Vector2(40, 25), [Color("56836b"), Color("649174"), Color("84a474"), Color("95ad7b")][k])
	for i in range(26):
		var x: float = fposmod(i * 117.31 + sin(time * 0.3 + i) * 20 - scroll_x * 0.6, 980)
		var y: float = 150 + fposmod(i * 57.7 + time * (3 + i % 3), 305)
		draw_circle(Vector2(x, y), 1.4, Color(1, 0.91, 0.6, 0.35 + 0.25 * sin(time + i)))

func tile_layer(texture: Texture2D, speed: float, y: float, tint: Color) -> void:
	var width: float = texture.get_width()
	var offset: float = fposmod(scroll_x * speed, width)
	for i in range(-1, 2):
		draw_texture(texture, Vector2(i * width - offset, y), tint)

func paint_ellipse(at: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle: float = float(i) / 24.0 * TAU
		points.append(at + Vector2(cos(angle), sin(angle)) * size)
	draw_colored_polygon(points, color)
