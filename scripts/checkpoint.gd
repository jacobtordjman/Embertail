extends Area2D

@export var activated: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_touch)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _touch(body: Node2D) -> void:
	if body.is_in_group("player") and not bool(body.get("dead")):
		activate()

func activate() -> void:
	if activated:
		return
	activated = true
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null:
		game.call("activate_checkpoint", global_position)

func _draw() -> void:
	var light: Color = Color("ffd68c") if activated else Color("beae99")
	var pulse: float = 0.5 + sin(elapsed * 3.0) * 0.15
	if activated:
		draw_circle(Vector2(0, -55), 35.0 + sin(elapsed * 2.0) * 3.0, Color(1.0, 0.64, 0.24, 0.07))
		draw_circle(Vector2(0, -55), 23.0, Color(1.0, 0.73, 0.38, 0.10))
	draw_rect(Rect2(-16, -7, 32, 7), Color("493a4d"))
	draw_rect(Rect2(-12, -11, 24, 5), Color("ad7961"))
	draw_rect(Rect2(-4, -45, 8, 35), Color("623d51"))
	draw_rect(Rect2(-2, -42, 2, 29), Color("b27a65"))
	draw_rect(Rect2(-14, -70, 28, 29), Color("412e43"))
	draw_rect(Rect2(-11, -67, 22, 22), Color("93604e") if not activated else Color("d18b4b"))
	draw_rect(Rect2(-8, -65, 16, 18), light)
	draw_line(Vector2(-1, -67), Vector2(-1, -44), Color("5e3b46"), 2.0)
	draw_line(Vector2(-12, -55), Vector2(12, -55), Color("5e3b46"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -70), Vector2(0, -80), Vector2(20, -70)]), Color("703e50"))
	draw_line(Vector2(-20, -70), Vector2(20, -70), Color("e4a16e"), 3.0)
	draw_circle(Vector2(0, -81), 3.0, Color("e4a16e"))
	if activated:
		for i in range(4):
			var phase: float = elapsed * 0.7 + float(i) * 1.5
			var mote := Vector2(sin(phase * 1.7) * 24.0, -42.0 - fmod(phase * 14.0, 46.0))
			draw_circle(mote, 1.5, Color(1.0, 0.83, 0.52, pulse))
