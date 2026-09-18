extends Area2D

var elapsed: float = 0.0
var collected: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("collectibles")
	elapsed = global_position.x * 0.017
	if ResourceLoader.exists("res://assets/sprites/coin.png"):
		sprite.texture = load("res://assets/sprites/coin.png")
	body_entered.connect(_collect)

func _process(delta: float) -> void:
	elapsed += delta
	sprite.position.y = sin(elapsed * 3.0) * 3.0
	sprite.frame = int(elapsed * 9.0) % 6
	if sprite.texture == null:
		queue_redraw()

func _collect(body: Node2D) -> void:
	if collected or not body.is_in_group("player") or bool(body.get("dead")):
		return
	collected = true
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null:
		game.call("collect_ember", global_position)
	queue_free()

func _draw() -> void:
	if is_instance_valid(sprite) and sprite.texture != null:
		return
	var center := Vector2(0.0, sin(elapsed * 3.0) * 3.0)
	draw_circle(center, 10.0, Color(1.0, 0.66, 0.24, 0.18))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -8), center + Vector2(6, 0), center + Vector2(0, 8), center + Vector2(-6, 0)]), Color("ffc66e"))
	draw_line(center + Vector2(0, -4), center + Vector2(0, 3), Color("fff1bd"), 2.0)
