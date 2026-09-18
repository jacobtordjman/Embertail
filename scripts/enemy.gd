extends CharacterBody2D

@export var patrol_left: float = -1.0
@export var patrol_right: float = -1.0
@export var speed: float = 48.0

var direction: float = -1.0
var defeated: bool = false
var animation_time: float = 0.0
var turn_cooldown: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var contact: Area2D = $Contact

func _ready() -> void:
	add_to_group("enemies")
	if patrol_left < 0.0:
		patrol_left = global_position.x - 90.0
	if patrol_right < 0.0:
		patrol_right = global_position.x + 90.0
	if ResourceLoader.exists("res://assets/sprites/enemy.png"):
		sprite.texture = load("res://assets/sprites/enemy.png")
	contact.body_entered.connect(_touch_player)

func _physics_process(delta: float) -> void:
	if defeated:
		return
	animation_time += delta
	turn_cooldown = maxf(0.0, turn_cooldown - delta)
	if global_position.x <= patrol_left:
		direction = 1.0
	elif global_position.x >= patrol_right:
		direction = -1.0
	if is_on_floor() and turn_cooldown <= 0.0:
		var ahead: Vector2 = global_position + Vector2(direction * 25.0, -14.0)
		var query := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0.0, 40.0), 1)
		query.exclude = [get_rid()]
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			direction *= -1.0
			turn_cooldown = 0.15
	velocity.x = direction * speed
	velocity.y = minf(velocity.y + 1300.0 * delta, 700.0)
	move_and_slide()
	if is_on_wall() and turn_cooldown <= 0.0:
		direction *= -1.0
		turn_cooldown = 0.15
	sprite.flip_h = direction < 0.0
	sprite.frame = int(animation_time * 8.0) % 4
	for body in contact.get_overlapping_bodies():
		_touch_player(body)
		if defeated:
			break
	if global_position.y > 1200.0:
		queue_free()
	if sprite.texture == null:
		queue_redraw()

func _touch_player(body: Node2D) -> void:
	if defeated or not body.is_in_group("player") or bool(body.get("dead")):
		return
	if body.has_method("is_dashing") and bool(body.call("is_dashing")):
		defeat()
		return
	if body.has_method("can_stomp") and bool(body.call("can_stomp", global_position.y - 30.0)):
		defeat()
		body.global_position.y = minf(body.global_position.y, global_position.y - 29.0)
		body.call("bounce")
	else:
		body.call("take_damage", 1, global_position)

func defeat() -> void:
	if defeated:
		return
	defeated = true
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null:
		game.call("add_score", 100)
		game.call("burst", "enemy", global_position - Vector2(0.0, 16.0))
		game.call("play_sound", "enemy")
		game.call("shake", 2.0)
	queue_free()

func _draw() -> void:
	if is_instance_valid(sprite) and sprite.texture != null:
		return
	draw_circle(Vector2(0.0, -13.0), 16.0, Color("213f41"))
	draw_circle(Vector2(0.0, -16.0), 12.0, Color("799b53"))
	draw_line(Vector2(0.0, -28.0), Vector2(0.0, -5.0), Color("b9c87a"), 3.0)
	draw_circle(Vector2(direction * 11.0, -19.0), 3.0, Color("ffe39b"))
