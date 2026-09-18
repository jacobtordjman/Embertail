class_name EmberPlayer
extends CharacterBody2D

signal died
signal damaged(health: int)
signal effect_requested(kind: String, at: Vector2)
signal sound_requested(kind: String)

const WALK_SPEED := 225.0
const RUN_SPEED := 335.0
const GROUND_ACCELERATION := 2100.0
const TURN_ACCELERATION := 3200.0
const GROUND_FRICTION := 2500.0
const AIR_ACCELERATION := 1150.0
const AIR_FRICTION := 320.0
const JUMP_SPEED := -565.0
const GRAVITY := 1450.0
const FALL_GRAVITY := 1900.0
const RELEASE_SPEED := -270.0
const MAX_FALL_SPEED := 780.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.14
const DASH_SPEED := 600.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.65
const FALL_LIMIT := 850.0
# Vertical speed band that reads as the weightless top of an arc. Ascent, apex
# and descent are separate states so the airborne pose does not flip on the sign
# of velocity.y alone. Gravity moves velocity.y in one direction during free
# flight, so the two thresholds cannot oscillate frame to frame.
const APEX_SPEED := 90.0
const SPRITE_SCALE := 0.75
const SPRITE_ORIGIN := Vector2(-15.0, -48.75)

@onready var sprite: AnimatedSprite2D = $Sprite

var previous_feet_position: Vector2
var _fall_speed_before_move: float = 0.0
var health: int = 3
var dead: bool = false
var invincible: float = 0.0
var facing: float = 1.0
var control_enabled: bool = true
var dash_cooldown: float:
	get:
		return _dash_cooldown

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _buffer_released: bool = false
var _jump_can_cut: bool = false
var _dash_time: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_active_this_tick: bool = false
var _air_dash_used: bool = false
var _hurt_time: float = 0.0
var _knockback_time: float = 0.0
var _landing_time: float = 0.0
var _death_time: float = 0.0
var _death_announced: bool = false
var _dust_time: float = 0.0
var _trail_time: float = 0.0
var _spring: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("player")
	previous_feet_position = global_position
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(46.0)
	safe_margin = 0.04
	max_slides = 5
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	previous_feet_position = global_position
	invincible = maxf(0.0, invincible - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_knockback_time = maxf(0.0, _knockback_time - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_landing_time = maxf(0.0, _landing_time - delta)
	_dust_time = maxf(0.0, _dust_time - delta)
	_trail_time = maxf(0.0, _trail_time - delta)
	_dash_active_this_tick = false

	if dead:
		_death_time -= delta
		velocity.y = minf(velocity.y + FALL_GRAVITY * delta, MAX_FALL_SPEED)
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
		move_and_slide()
		_update_visuals(delta)
		if _death_time <= 0.0 and not _death_announced:
			_death_announced = true
			died.emit()
		return
	if global_position.y > FALL_LIMIT:
		kill()
		return

	# A buffered landing jump already has upward velocity while the previous
	# move_and_slide() still reports floor contact. Do not refresh coyote twice.
	var grounded: bool = is_on_floor() and velocity.y >= 0.0
	if grounded:
		_coyote = COYOTE_TIME
		_air_dash_used = false
	else:
		_coyote = maxf(0.0, _coyote - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	var direction: float = Input.get_axis("move_left", "move_right") if control_enabled else 0.0
	var speed: float = RUN_SPEED if control_enabled and Input.is_action_pressed("run") else WALK_SPEED
	if control_enabled:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = JUMP_BUFFER
			_buffer_released = false
		if Input.is_action_just_released("jump"):
			_buffer_released = true
			if _jump_can_cut and velocity.y < RELEASE_SPEED:
				velocity.y = RELEASE_SPEED
			_jump_can_cut = false
		if absf(direction) > 0.1 and _dash_time <= 0.0:
			facing = signf(direction)
		if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and not _air_dash_used and _knockback_time <= 0.0:
			_start_dash()

	if _dash_time > 0.0:
		_dash_active_this_tick = true
		_dash_time = maxf(0.0, _dash_time - delta)
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		if _trail_time <= 0.0:
			_trail_time = 0.035
			effect_requested.emit("dash", global_position + Vector2(0.0, -23.0))
	else:
		var gravity: float = FALL_GRAVITY if velocity.y > 0.0 else GRAVITY
		if _jump_can_cut and absf(velocity.y) < 85.0:
			gravity *= 0.72
		velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
		if _knockback_time <= 0.0:
			var acceleration: float = GROUND_ACCELERATION if grounded else AIR_ACCELERATION
			if grounded and direction * velocity.x < 0.0:
				acceleration = TURN_ACCELERATION
			var friction: float = GROUND_FRICTION if grounded else AIR_FRICTION
			velocity.x = move_toward(velocity.x, direction * speed, (acceleration if absf(direction) > 0.1 else friction) * delta)
		if control_enabled and _jump_buffer > 0.0 and _coyote > 0.0 and _knockback_time <= 0.0:
			_perform_jump()

	var incoming_y: float = velocity.y
	_fall_speed_before_move = incoming_y
	move_and_slide()
	if is_on_wall() and _dash_active_this_tick:
		_dash_time = 0.0
		_dash_active_this_tick = false
		velocity.x = 0.0
	elif _dash_active_this_tick and _dash_time <= 0.0:
		# End the burst at ordinary movement speed, without an unprotected skid.
		velocity.x = direction * speed
	if is_on_ceiling():
		_jump_can_cut = false
	if not grounded and is_on_floor() and incoming_y > 100.0:
		_landing_time = 0.16
		_spring = Vector2(1.035, 0.965)
		effect_requested.emit("land", global_position)
		sound_requested.emit("land")
		_air_dash_used = false
		if control_enabled and _jump_buffer > 0.0 and _knockback_time <= 0.0 and not _dash_active_this_tick:
			_perform_jump()
	if is_on_floor() and absf(velocity.x) > 100.0 and _dust_time <= 0.0:
		_dust_time = 0.12 if absf(velocity.x) > WALK_SPEED else 0.19
		effect_requested.emit("run", global_position + Vector2(-facing * 6.0, -2.0))
	_update_visuals(delta)

func _perform_jump() -> void:
	velocity.y = RELEASE_SPEED if _buffer_released else JUMP_SPEED
	_jump_can_cut = not _buffer_released
	_jump_buffer = 0.0
	_coyote = 0.0
	_landing_time = 0.0
	_spring = Vector2(0.985, 1.015)
	sound_requested.emit("jump")
	effect_requested.emit("jump", global_position)

func _start_dash() -> void:
	_dash_time = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN
	_air_dash_used = true
	_landing_time = 0.0
	_jump_can_cut = false
	sound_requested.emit("dash")
	effect_requested.emit("dash", global_position + Vector2(0.0, -23.0))

func is_dashing() -> bool:
	return (_dash_time > 0.0 or _dash_active_this_tick) and not dead

func take_damage(amount: int, source: Vector2) -> void:
	if dead or invincible > 0.0 or amount <= 0:
		return
	if amount >= health:
		kill()
		return
	health -= amount
	invincible = 1.2
	_hurt_time = 0.24
	_knockback_time = 0.18
	_dash_time = 0.0
	_dash_active_this_tick = false
	_jump_can_cut = false
	_landing_time = 0.0
	var away: float = signf(global_position.x - source.x)
	if is_zero_approx(away):
		away = -facing
	velocity = Vector2(away * 245.0, -265.0)
	damaged.emit(health)
	sound_requested.emit("hurt")
	effect_requested.emit("hurt", global_position + Vector2(0.0, -22.0))

func kill() -> void:
	if dead:
		return
	health = 0
	dead = true
	control_enabled = false
	_dash_time = 0.0
	_dash_active_this_tick = false
	_death_time = 0.74
	_death_announced = false
	velocity = Vector2(0.0, -180.0)
	invincible = 0.0
	_spring = Vector2.ONE
	damaged.emit(health)
	sound_requested.emit("hurt")
	effect_requested.emit("death", global_position + Vector2(0.0, -22.0))
	sprite.play("death")

func respawn(at: Vector2) -> void:
	global_position = at
	previous_feet_position = at
	_fall_speed_before_move = 0.0
	velocity = Vector2.ZERO
	health = 3
	dead = false
	control_enabled = true
	invincible = 1.2
	_coyote = 0.0
	_jump_buffer = 0.0
	_buffer_released = false
	_jump_can_cut = false
	_dash_time = 0.0
	_dash_cooldown = 0.0
	_dash_active_this_tick = false
	_air_dash_used = false
	_hurt_time = 0.0
	_knockback_time = 0.0
	_landing_time = 0.0
	_death_time = 0.0
	_death_announced = false
	_spring = Vector2.ONE
	sprite.play("idle")
	damaged.emit(health)
	reset_physics_interpolation()

func can_stomp(enemy_top: float) -> bool:
	# Area overlaps arrive after the movement step. Use the swept foot position
	# so a fast fall cannot turn a clean top hit into side damage.
	return (_fall_speed_before_move > 20.0 and previous_feet_position.y <= enemy_top + 9.0) or (velocity.y > 20.0 and global_position.y <= enemy_top + 18.0)

func bounce() -> void:
	if dead:
		return
	_dash_time = 0.0
	_dash_active_this_tick = false
	velocity.y = -365.0
	_fall_speed_before_move = 0.0
	_coyote = 0.0
	_air_dash_used = false
	_jump_can_cut = false
	_landing_time = 0.0
	sound_requested.emit("jump")

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		_jump_buffer = 0.0
		_dash_time = 0.0
		_dash_active_this_tick = false
		velocity.x = 0.0

func _update_visuals(delta: float) -> void:
	var animation_name: String = "idle"
	if dead:
		animation_name = "death"
	elif _hurt_time > 0.0:
		animation_name = "hurt"
	elif is_dashing():
		animation_name = "dash"
	elif velocity.y < -APEX_SPEED:
		# Checked before the floor test so the take-off pose appears on the same
		# frame the impulse is applied, while move_and_slide still reports floor.
		animation_name = "jump"
	elif not is_on_floor():
		animation_name = "apex" if velocity.y < APEX_SPEED else "fall"
	elif _landing_time > 0.0 and absf(velocity.x) < 50.0:
		animation_name = "land"
	elif absf(velocity.x) > 12.0:
		animation_name = "run" if absf(velocity.x) > WALK_SPEED + 8.0 else "walk"
	if sprite.animation != animation_name:
		sprite.play(animation_name)
	sprite.speed_scale = clampf(absf(velocity.x) / 200.0, 0.45, 1.75) if animation_name in ["walk", "run"] else 1.0
	sprite.flip_h = facing < 0.0
	_spring = _spring.lerp(Vector2.ONE, minf(1.0, delta * 18.0))
	sprite.scale = _spring * SPRITE_SCALE
	sprite.position = Vector2(SPRITE_ORIGIN.x * facing, SPRITE_ORIGIN.y) * _spring
	var alpha: float = 0.42 if invincible > 0.0 and int(invincible * 15.0) % 2 == 0 else 1.0
	sprite.modulate = Color(1.0, 0.72, 0.65, alpha) if _hurt_time > 0.0 else Color(1.0, 1.0, 1.0, alpha)
