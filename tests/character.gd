extends SceneTree

var game: Node
var checks: int = 0
var failures: int = 0
var landing_sounds: int = 0

func _initialize() -> void:
	run_checks.call_deferred()

func frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		push_error("FAIL " + description)

func release() -> void:
	for action in ["move_left", "move_right", "jump", "run", "dash"]:
		Input.action_release(action)

func place(at: Vector2) -> void:
	release()
	game.player.respawn(at)
	game.player.invincible = 0.0
	await frames(2)

func wall(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	game.level.add_child(body)
	return body

func run_checks() -> void:
	print("EMBERTRAIL CHARACTER REFINEMENT CHECKS")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	game.start_game()
	await frames(5)
	var player: EmberPlayer = game.player
	player.sound_requested.connect(func(kind: String):
		if kind == "land": landing_sounds += 1)
	var animations: SpriteFrames = player.sprite.sprite_frames
	var sheet: Image = load("res://assets/sprites/player.png").get_image()
	check(sheet.get_size() == Vector2i(1280, 1600), "supplied sprites use consistently padded 160px cells")
	var total_frames: int = 0
	var valid_cells: bool = true
	var no_clipping: bool = true
	var distinct_states: bool = true
	# Grounded states must share one floor line; a state whose feet wander would
	# make the character pop vertically as it switches pose.
	var grounded_states: Array[String] = ["idle", "walk", "run", "land", "hurt", "death"]
	var grounded_aligned: bool = true
	var library: Dictionary = {}
	for name in animations.get_animation_names():
		var fingerprints: Dictionary = {}
		var lowest: int = 0
		var highest: int = 160
		for index in range(animations.get_frame_count(name)):
			var texture: AtlasTexture = animations.get_frame_texture(name, index)
			var region := Rect2i(texture.region)
			valid_cells = valid_cells and region.size == Vector2i(160, 160) and Rect2i(0, 0, 1280, 1600).encloses(region)
			var cell: Image = sheet.get_region(region)
			var used: Rect2i = cell.get_used_rect()
			no_clipping = no_clipping and used.position.x > 0 and used.position.y > 0 and used.end.x < 160 and used.end.y < 160
			fingerprints[hash(cell.get_data())] = true
			library[hash(cell.get_data())] = true
			lowest = maxi(lowest, used.end.y)
			highest = mini(highest, used.end.y)
			total_frames += 1
		# Two-frame states cannot show three poses; require every frame distinct.
		distinct_states = distinct_states and fingerprints.size() >= mini(3, animations.get_frame_count(name))
		if name in grounded_states:
			grounded_aligned = grounded_aligned and lowest - highest <= 3
	check(total_frames == 42 and valid_cells, "all 42 playback frames have valid atlas regions")
	check(no_clipping, "ears, paws and tails remain inside every animation cell")
	check(distinct_states, "every state contains distinct poses instead of repeated still frames")
	check(grounded_aligned, "grounded states keep their feet on a shared floor line")
	# The expansion replaced whole-image tilts with separately drawn source art,
	# so the atlas must hold materially more unique cells than states.
	check(library.size() >= 24, "atlas holds at least 24 distinct poses rather than repeated transforms")
	check(animations.has_animation("land") and not animations.get_animation_loop("land"), "landing has a dedicated non-looping recovery")
	check(animations.get_frame_count("run") == 4 and animations.get_animation_loop("run"), "supplied running poses play as a continuous cycle")
	check(not animations.get_animation_loop("death"), "death settles without looping")
	check(animations.has_animation("walk") and animations.get_frame_count("walk") == 4, "upright walking has a separate supplied pose cycle")
	check(animations.has_animation("apex") and animations.get_animation_loop("apex"), "the arc has a dedicated looping apex state")
	check(not animations.get_animation_loop("jump"), "the ascent plays once instead of cycling in the air")

	# Ascent, apex and descent must be selected by vertical speed, and the take-off
	# pose must appear on the same frame the impulse lands.
	await place(Vector2(150, 465))
	await frames(6)
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	check(player.velocity.y < -player.APEX_SPEED and player.sprite.animation == "jump", "take-off shows the ascent pose immediately")
	var saw_apex: bool = false
	var saw_fall: bool = false
	var airborne_frames: int = 0
	while not player.is_on_floor() and airborne_frames < 120:
		await frames(1)
		airborne_frames += 1
		if player.sprite.animation == "apex":
			saw_apex = true
		elif player.sprite.animation == "fall":
			saw_fall = true and saw_apex
	check(saw_apex, "a weightless apex pose plays near the top of the arc")
	check(saw_fall, "the descent pose follows the apex rather than replacing it")

	await place(Vector2(150, 465))
	await frames(5)
	Input.action_press("move_right")
	Input.action_press("run")
	var acceleration_frames: int = 0
	while player.velocity.x < 334.0 and acceleration_frames < 30:
		await frames(1)
		acceleration_frames += 1
	check(player.sprite.animation == &"run", "running selects the supplied leaning run cycle")
	print("MEASURE full-run frames=", acceleration_frames)
	check(acceleration_frames <= 11 and acceleration_frames >= 5, "run accelerates quickly without snapping to full speed")
	Input.action_release("run")
	await frames(10)
	check(player.sprite.animation == &"walk", "walking selects the upright cycle")
	Input.action_press("run")
	await frames(10)
	var stop_x: float = player.position.x
	release()
	await frames(10)
	print("MEASURE stop distance=", snappedf(player.position.x - stop_x, 0.1))
	check(absf(player.velocity.x) < 0.1 and player.position.x - stop_x < 28.0, "released run stops inside 28px")
	Input.action_press("move_right")
	Input.action_press("run")
	await frames(11)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(8)
	check(player.velocity.x < 0.0 and player.facing < 0.0, "direction reversal responds within eight physics frames")
	check(player.sprite.position.x > 0, "mirrored art keeps its feet centered on the collision body")

	await place(Vector2(150, 465))
	await frames(5)
	Input.action_press("move_right")
	Input.action_press("dash")
	await frames(3)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(3)
	check(player.is_dashing() and player.velocity.x > 550 and player.facing == 1.0, "dash commits to its initial direction through the burst")
	await frames(8)
	check(not player.is_dashing() and absf(player.velocity.x) <= 225.1, "dash hands off at movement speed without a long unprotected skid")
	check(player.sprite.animation != &"dash", "dash animation exits when the burst ends")

	await place(Vector2(150, 60))
	Input.action_press("dash")
	await frames(3)
	Input.action_release("dash")
	await frames(39)
	check(not player.is_on_floor() and player.dash_cooldown <= 0.0, "air-dash lock is tested after cooldown while still airborne")
	Input.action_press("dash")
	await frames(2)
	check(not player.is_dashing(), "air dash cannot repeat before touching ground")

	await place(Vector2(280, 465))
	var obstacle := wall(Vector2(330, 390), Vector2(2, 160))
	await frames(3)
	Input.action_press("move_right")
	Input.action_press("dash")
	await frames(9)
	check(player.position.x < 320.0 and not player.is_dashing(), "600px/s dash stops at a two-pixel wall without tunneling")
	obstacle.queue_free()
	await place(Vector2(150, 465))
	var ceiling := wall(Vector2(150, 365), Vector2(100, 8))
	await frames(3)
	Input.action_press("jump")
	var ceiling_contact: bool = false
	var minimum_y: float = 999.0
	for _i in range(55):
		await frames(1)
		minimum_y = minf(minimum_y, player.position.y)
		ceiling_contact = ceiling_contact or player.is_on_ceiling()
	check(ceiling_contact and minimum_y >= 412.5 and player.is_on_floor(), "head collision cancels ascent and returns cleanly to the ground")
	ceiling.queue_free()

	# A buffered tap must remain a short hop even when released before touchdown.
	await place(Vector2(150, 380))
	while player.position.y < 434.0:
		await frames(1)
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	var buffered_takeoff: bool = false
	var minimum_hop: float = 470.0
	for _i in range(55):
		await frames(1)
		if player.velocity.y < -100.0:
			buffered_takeoff = true
		if buffered_takeoff:
			minimum_hop = minf(minimum_hop, player.position.y)
	print("MEASURE buffered tap height=", snappedf(470.0 - minimum_hop, 0.1))
	check(buffered_takeoff and 470.0 - minimum_hop < 48.0, "releasing a buffered jump before landing preserves a short hop")

	await place(Vector2(150, 280))
	var floor_contact: bool = false
	for _i in range(60):
		await frames(1)
		if player.is_on_floor():
			floor_contact = true
			break
	check(floor_contact and player.sprite.animation == &"land", "hard landing plays the dedicated crouch/recovery frames")
	var audio_count: int = landing_sounds
	Input.action_press("jump")
	await frames(2)
	check(player.velocity.y < -480 and player.sprite.animation == &"jump", "landing recovery never locks out an immediate jump")
	check(landing_sounds == audio_count, "landing impact sound does not repeat while taking off")
	Input.action_release("jump")
	await frames(60)
	audio_count = landing_sounds
	await frames(25)
	check(landing_sounds == audio_count and player.sprite.animation == &"idle", "settled feet neither jitter into landing nor replay impact audio")

	# Both moderate and terminal-speed descents must produce a stomp, not damage.
	for start_y in [370.0, 70.0]:
		await place(Vector2(200, start_y))
		var enemy: Node2D = load("res://scenes/enemy.tscn").instantiate()
		enemy.position = Vector2(200, 467)
		enemy.patrol_left = 180
		enemy.patrol_right = 220
		enemy.speed = 0
		game.level.add_child(enemy)
		var bounced: bool = false
		for _i in range(90):
			await frames(1)
			if not is_instance_valid(enemy) and player.velocity.y < -200:
				bounced = true
				break
		check(bounced and player.health == 3, "swept stomp is reliable from starting height %.0f" % start_y)
		if is_instance_valid(enemy): enemy.queue_free()

	await place(Vector2(150, 465))
	Input.action_press("jump")
	await frames(10)
	player.bounce()
	Input.action_release("jump")
	await frames(2)
	check(player.velocity.y < -290, "jump release does not shorten an enemy rebound")
	release()
	player.kill()
	await frames(30)
	check(player.dead and player.sprite.animation == &"death", "death animation persists through the falling pose")
	await frames(20)
	check(not player.dead and player.health == 3 and player.sprite.animation != &"death", "respawn clears every action timer and returns to a live pose")
	print("CHARACTER RESULT: ", checks - failures, "/", checks, " passed; failures=", failures)
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	for _index in range(10):
		OS.delay_msec(20)
		await process_frame
	quit(0 if failures == 0 else 1)
