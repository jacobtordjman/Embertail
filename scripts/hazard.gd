extends Area2D

@export var width: float = 96.0

func _ready() -> void:
	add_to_group("hazards")
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width - 4.0, 12.0)
	$CollisionShape2D.shape = rectangle
	$CollisionShape2D.position = Vector2(width * 0.5, -6.0)
	body_entered.connect(_hurt)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_hurt(body)

func _hurt(body: Node2D) -> void:
	if body.is_in_group("player") and not bool(body.get("dead")):
		body.call("take_damage", 1, Vector2(body.global_position.x, global_position.y + 20.0))

func _draw() -> void:
	draw_rect(Rect2(0, -4, width, 5), Color("42374a"))
	var count: int = maxi(1, int(width / 16.0))
	var step: float = width / float(count)
	for i in range(count):
		var x: float = float(i) * step
		draw_colored_polygon(PackedVector2Array([Vector2(x + 1, 0), Vector2(x + step * 0.5, -17), Vector2(x + step - 1, 0)]), Color("dd7b73"))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 3, -2), Vector2(x + step * 0.5, -14), Vector2(x + step * 0.5, -2)]), Color("ffcaac"))
