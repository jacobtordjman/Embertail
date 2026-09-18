extends Node2D

var fox: SpriteFrames
var time: float = 0.0
var portraits: Array[AtlasTexture] = []

func _ready() -> void:
	fox = load("res://assets/sprites/player_frames.tres")
	var crop: Rect2 = fox.get_meta("portrait_region", Rect2(0, 0, 128, 128))
	for index in range(fox.get_frame_count("idle")):
		var original: AtlasTexture = fox.get_frame_texture("idle", index)
		var portrait := AtlasTexture.new()
		portrait.atlas = original.atlas
		portrait.region = Rect2(original.region.position + crop.position, crop.size)
		portraits.append(portrait)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var center := Vector2(718, 266)
	draw_circle(center, 149, Color("47664d42"))
	draw_arc(center, 146, -0.8, 4.5, 90, Color("e4c18266"), 1, true)
	draw_arc(center, 157, 1.2, 3.8, 60, Color("91b39142"), 1, true)
	for i in range(8):
		var angle: float = i * TAU / 8 + time * 0.035
		var at: Vector2 = center + Vector2(cos(angle), sin(angle)) * 145
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(3, 0), at + Vector2(0, 4), at + Vector2(-3, 0)]), Color("edc783"))
	draw_set_transform(Vector2.ZERO)
	# Enlarged pixel sprite retains the same silhouette as the playable fox.
	if fox:
		var frame: int = int(time * fox.get_animation_speed("idle")) % fox.get_frame_count("idle")
		draw_texture_rect(portraits[frame], Rect2(585, 105, 266, 304), false)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(617, 423), "CARRY A LITTLE LIGHT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("edcc92"))
	draw_string(font, Vector2(652, 447), "01  /  LANTERNWOOD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a2bba4"))
