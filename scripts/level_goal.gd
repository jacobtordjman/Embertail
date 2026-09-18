extends Area2D

var elapsed: float = 0.0
var reached: bool = false

func _ready() -> void:
	add_to_group("goals")
	body_entered.connect(_touch)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _touch(body: Node2D) -> void:
	if reached or not body.is_in_group("player") or bool(body.get("dead")):
		return
	reached = true
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null:
		game.call("complete_level")

func _draw() -> void:
	var pulse: float = 0.5 + sin(elapsed * 2.4) * 0.08
	draw_circle(Vector2(0, -65), 68.0, Color(0.36, 0.89, 0.77, 0.055))
	draw_circle(Vector2(0, -65), 51.0, Color(0.36, 0.89, 0.77, 0.07))
	draw_rect(Rect2(-45, -13, 90, 13), Color("3c4055"))
	draw_rect(Rect2(-40, -17, 80, 6), Color("a09285"))
	draw_rect(Rect2(-35, -112, 70, 95), Color("163f4b"))
	draw_rect(Rect2(-28, -105, 56, 87), Color(0.13, 0.43, 0.45, pulse))
	for i in range(6):
		var y: float = -105.0 + fmod(elapsed * 16.0 + float(i) * 17.0, 86.0)
		draw_line(Vector2(-25, y), Vector2(25, y), Color(0.5, 1.0, 0.81, 0.11), 2.0)
	for side in [-1.0, 1.0]:
		var x: float = float(side) * 38.0
		draw_rect(Rect2(x - 7, -112, 14, 97), Color("514c63"))
		draw_rect(Rect2(x - 5, -108, 4, 87), Color("8e7a79"))
		for row in range(4):
			draw_rect(Rect2(x - 7, -32 - row * 23, 14, 3), Color("c8a176"))
		draw_circle(Vector2(x, -120), 6.0, Color("edc47e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-51, -113), Vector2(0, -138), Vector2(51, -113)]), Color("624258"))
	draw_line(Vector2(-51, -113), Vector2(0, -138), Color("f0bb72"), 3.0)
	draw_line(Vector2(0, -138), Vector2(51, -113), Color("f0bb72"), 3.0)
	draw_line(Vector2(-49, -111), Vector2(49, -111), Color("d39161"), 4.0)
	var center := Vector2(0, -68 + sin(elapsed * 2.0) * 4.0)
	draw_circle(center, 18.0, Color(0.63, 1.0, 0.81, 0.12))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -16), center + Vector2(10, 0), center + Vector2(0, 16), center + Vector2(-10, 0)]), Color("f8d58b"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -10), center + Vector2(5, 0), center + Vector2(0, 10), center + Vector2(-5, 0)]), Color("fff3bf"))
	for i in range(8):
		var phase: float = elapsed * 0.5 + float(i) * 0.8
		var mote := Vector2(sin(phase * 2.2) * 26.0, -23.0 - fmod(phase * 27.0, 77.0))
		draw_circle(mote, 1.3, Color(0.9, 1.0, 0.78, 0.65))
