extends Node2D

const ENEMY = preload("res://scenes/enemy.tscn")
const COIN = preload("res://scenes/collectible.tscn")
const HAZARD = preload("res://scenes/hazard.tscn")
const CHECKPOINT = preload("res://scenes/checkpoint.tscn")
const GOAL = preload("res://scenes/level_goal.tscn")
const WORLD_WIDTH: float = 6240.0

var grounds: Array[Rect2] = [
	Rect2(0, 470, 1120, 140), Rect2(1260, 470, 1180, 140),
	Rect2(2580, 470, 900, 140), Rect2(3620, 470, 1000, 140),
	Rect2(4760, 470, 1480, 140)
]
var ledges: Array[Rect2] = [
	Rect2(400, 375, 128, 24), Rect2(670, 330, 128, 24), Rect2(940, 370, 116, 24),
	Rect2(1380, 375, 150, 24), Rect2(1660, 300, 140, 24), Rect2(1880, 370, 144, 24),
	Rect2(2230, 365, 128, 24), Rect2(2680, 380, 140, 24), Rect2(2900, 300, 130, 24),
	Rect2(3100, 365, 160, 24), Rect2(3670, 365, 160, 24), Rect2(3910, 290, 150, 24),
	Rect2(4270, 370, 160, 24), Rect2(4820, 380, 140, 24), Rect2(5040, 300, 145, 24),
	Rect2(5410, 365, 165, 24), Rect2(5680, 360, 130, 24)
]
var signs: Array = [
	[Vector2(185, 418), "A / D   MOVE", "SHIFT   RUN"],
	[Vector2(468, 287), "SPACE   JUMP", "HOLD TO LEAP HIGHER"],
	[Vector2(962, 278), "X   EMBER DASH", "DASH THROUGH ENEMIES"],
	[Vector2(1340, 413), "MIND THE GAPS", "RUN + JUMP TO CROSS"],
	[Vector2(2120, 333), "A LIGHT TO RETURN TO", "LANTERNS RESTORE HEALTH"],
	[Vector2(5800, 273), "THE LAST LANTERN", "BRING THE WOODLAND HOME"]
]
var terrain: Texture2D

func _ready() -> void:
	add_to_group("level")
	terrain = load("res://assets/tiles/terrain.png")
	for rect in grounds:
		add_ground(rect, false)
	for rect in ledges:
		add_ground(rect, true)
	for spec in [[720, 64], [1900, 64], [3130, 64], [4340, 80], [5470, 64]]:
		var hazard := HAZARD.instantiate()
		hazard.position = Vector2(spec[0], 470)
		hazard.width = spec[1]
		add_child(hazard)
	for spec in [[835, 800, 1030], [1610, 1550, 1790], [2840, 2680, 3040], [3830, 3700, 4090], [5190, 4860, 5340], [5700, 5600, 5800]]:
		var enemy := ENEMY.instantiate()
		enemy.position = Vector2(spec[0], 467)
		enemy.patrol_left = spec[1]
		enemy.patrol_right = spec[2]
		add_child(enemy)
	for x in [2080, 4170]:
		var lantern := CHECKPOINT.instantiate()
		lantern.position = Vector2(x, 470)
		add_child(lantern)
	var goal := GOAL.instantiate()
	goal.position = Vector2(6020, 470)
	add_child(goal)
	# High routes hold more embers; the ground route always reaches the goal.
	for rect in ledges:
		for i in range(3):
			add_coin(Vector2(rect.position.x + 26 + i * 35, rect.position.y - 37))
	for start in [290, 1285, 2100, 2610, 4100, 4790, 5850]:
		for i in range(3):
			add_coin(Vector2(start + i * 33, 422))
	for center in [1190, 2510, 3550, 4690]:
		for i in range(3):
			add_coin(Vector2(center - 40 + i * 40, 355 - (18 if i == 1 else 0)))

func add_coin(at: Vector2) -> void:
	var coin := COIN.instantiate()
	coin.position = at
	add_child(coin)

func add_ground(rect: Rect2, platform: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = platform
	shape.one_way_collision_margin = 8
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	for rect in grounds:
		draw_terrain(rect, false)
	for rect in ledges:
		draw_terrain(rect, true)
	# Deterministic foliage, stones, and ancient path markers.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77591
	for rect in grounds:
		for i in range(int(rect.size.x / 23)):
			var x: float = rect.position.x + i * 23 + rng.randf_range(0, 14)
			var height: float = rng.randf_range(5, 14)
			draw_line(Vector2(x, 470), Vector2(x - 3, 470 - height), Color("56856b"), 2)
			draw_line(Vector2(x + 1, 470), Vector2(x + 5, 475 - height), Color("84ab75"), 2)
			if i % 7 == 0:
				draw_rect(Rect2(x - 4, 463 - height, 5, 5), Color("eaba7a"))
	for x in [80, 1550, 2750, 3740, 4960, 5810]:
		draw_rect(Rect2(x, 413, 13, 56), Color("5a7370"))
		draw_rect(Rect2(x - 3, 409, 19, 7), Color("8ea28a"))
		draw_rect(Rect2(x + 4, 425, 4, 13), Color("bcd6a0"))
	for sign in signs:
		draw_sign(sign[0], sign[1], sign[2])
	# Finish shrine setting.
	draw_line(Vector2(5900, 280), Vector2(6140, 280), Color("845c43"), 4)
	for x in range(5910, 6140, 32):
		draw_line(Vector2(x, 280), Vector2(x, 298 + (x % 3) * 6), Color("a9835b"), 1)
		draw_rect(Rect2(x - 3, 296 + (x % 3) * 6, 7, 14), Color("f4d193"))

func draw_terrain(rect: Rect2, platform: bool) -> void:
	if platform:
		draw_style_box(make_box(Color("3c635b"), 5), rect)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color("a6c482"))
		draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(rect.size.x - 8, 4)), Color("6d9870"))
		for x in range(int(rect.position.x) + 10, int(rect.end.x) - 5, 23):
			draw_line(Vector2(x, rect.end.y), Vector2(x + 5, rect.end.y + 13), Color("4e7f60"), 3)
		return
	draw_rect(rect, Color("334943"))
	draw_rect(Rect2(rect.position + Vector2(0, 10), Vector2(rect.size.x, 18)), Color("6c7752"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), Color("adc98a"))
	draw_rect(Rect2(rect.position + Vector2(0, 7), Vector2(rect.size.x, 5)), Color("548565"))
	for x in range(int(rect.position.x), int(rect.end.x), 32):
		if terrain:
			draw_texture_rect_region(terrain, Rect2(x, rect.position.y + 28, 32, 32), Rect2(32, 0, 32, 32), Color(1, 1, 1, 0.43))
		var depth: float = 55.0 + float((x * 13) % 49)
		draw_rect(Rect2(x + 5, rect.position.y + depth, 9, 3), Color("50614d"))
	# The cliff edge has a readable rim above each pit.
	draw_rect(Rect2(rect.position.x, rect.position.y + 12, 5, rect.size.y - 12), Color("607558"))
	draw_rect(Rect2(rect.end.x - 5, rect.position.y + 12, 5, rect.size.y - 12), Color("243f3c"))

func make_box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func draw_sign(at: Vector2, heading: String, caption: String) -> void:
	var font := ThemeDB.fallback_font
	var width: float = maxf(font.get_string_size(heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x) + 26
	var rect := Rect2(at.x - width * 0.5, at.y - 25, width, 43)
	draw_style_box(make_box(Color("254943"), 5), rect)
	draw_rect(Rect2(rect.position + Vector2(0, 7), Vector2(2, 24)), Color("e5bc72"))
	draw_string(font, Vector2(at.x - width * 0.5 + 13, at.y - 6), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2e4bb"))
	draw_string(font, Vector2(at.x - width * 0.5 + 13, at.y + 8), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a9c6aa"))
