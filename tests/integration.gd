extends SceneTree

var game: Node
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	run_checks.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func release_controls() -> void:
	for action in ["move_left", "move_right", "jump", "run", "dash", "restart", "pause"]:
		Input.action_release(action)

func place_player(at: Vector2) -> void:
	release_controls()
	game.player.respawn(at)
	game.player.invincible = 0.0
	await frames(5)

func jump_height(held_frames: int) -> float:
	await place_player(Vector2(140, 465))
	var baseline: float = game.player.position.y
	var minimum: float = baseline
	Input.action_press("jump")
	for index in range(70):
		if index == held_frames:
			Input.action_release("jump")
		await frames(1)
		minimum = minf(minimum, game.player.position.y)
	return baseline - minimum

func dispatch_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)


func validate_menu_layout(screen: String) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(960, 540))
	var buttons: Array[Node] = game.menus.root.find_children("*", "Button", true, false)
	for button in buttons:
		if button.is_visible_in_tree():
			check(bounds.encloses(button.get_global_rect()), screen + " button stays on screen: " + button.text)
	check(bounds.encloses(game.menus.content.get_global_rect()), screen + " menu content fits the viewport")
	var title: Label = game.menus.content.get_child(0)
	check(title.get_combined_minimum_size().x <= game.menus.content.size.x + 0.1 and bounds.encloses(title.get_global_rect()), screen + " title fits its container")

func dispatch_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)

func click_control(control: Control) -> void:
	var location: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = location
	root.push_input(motion, true)
	for pressed_state in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = location
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed_state
		root.push_input(event, true)
		await frames(2)

func new_enemy(at: Vector2) -> Node2D:
	var enemy: Node2D = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = at
	enemy.patrol_left = at.x - 20
	enemy.patrol_right = at.x + 20
	enemy.speed = 0.0
	game.level.add_child(enemy)
	return enemy

func run_checks() -> void:
	print("EMBERTRAIL BEHAVIORAL INTEGRATION CHECKS")
	for path in ["scenes/main.tscn", "scenes/player.tscn", "scenes/enemy.tscn", "scenes/collectible.tscn", "scenes/hazard.tscn", "scenes/checkpoint.tscn", "scenes/level_goal.tscn", "levels/lanternwood.tscn", "ui/hud.tscn", "ui/menus.tscn"]:
		check(load("res://" + path) is PackedScene, "scene loads: " + path)
	for name in ["jump", "coin", "hurt", "enemy", "checkpoint", "complete", "dash", "land", "music"]:
		check(load("res://assets/audio/" + name + ".wav") is AudioStreamWAV, "audio loads: " + name)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	check(game.state == "menu" and not game.hud.visible, "launch opens main menu")
	validate_menu_layout("main")
	for action in ["move_left", "move_right", "jump", "run", "dash", "pause", "restart", "mute", "fullscreen"]:
		check(InputMap.has_action(action), "input action registered: " + action)
	await dispatch_key(KEY_ENTER)
	check(game.state == "playing", "Enter activates the focused start button")
	if game.state != "playing":
		game.start_game()
	await frames(12)
	check(game.state == "playing" and game.hud.visible and game.lives == 3, "start enters level with HUD and three lives")
	check(game.player.is_on_floor() and absf(game.player.position.y - 470.0) < 1.0, "player settles on solid terrain")
	var screen_bounds := Rect2(Vector2.ZERO, Vector2(960, 540))
	for control in [game.hud.score_label, game.hud.timer_label, game.hud.coin_label, game.hud.dash_label, game.hud.progress]:
		check(screen_bounds.encloses(control.get_global_rect()), "HUD value stays within the viewport: " + control.name)
	for animation in ["idle", "run", "jump", "fall", "dash", "hurt", "death", "land"]:
		check(game.player.sprite.sprite_frames.get_frame_count(animation) >= 4, "authored animation frames: " + animation)

	Input.action_press("move_right")
	await frames(2)
	check(game.player.velocity.x > 0.0 and game.player.velocity.x < 225.0, "horizontal acceleration is gradual")
	await frames(12)
	check(absf(game.player.velocity.x - 225.0) < 1.0, "walk reaches designed speed")
	Input.action_press("run")
	await frames(10)
	check(absf(game.player.velocity.x - 335.0) < 1.0, "run is faster than walking")
	release_controls()
	await frames(12)
	check(absf(game.player.velocity.x) < 0.1, "ground friction stops released movement")

	var low: float = await jump_height(2)
	var high: float = await jump_height(35)
	print("MEASURE jump heights tap=", snappedf(low, 0.1), " hold=", snappedf(high, 0.1))
	check(low > 20.0 and high > low + 30.0 and high > 75.0, "holding jump produces a materially higher arc")
	check(game.player.is_on_floor(), "jump returns to ground cleanly")
	await place_player(Vector2(440, 465))
	Input.action_press("jump")
	await frames(40)
	Input.action_release("jump")
	await frames(20)
	check(game.player.is_on_floor() and absf(game.player.position.y - 375.0) < 1.0, "first optional platform is reachable with a held jump")

	await place_player(Vector2(1090, 465))
	Input.action_press("move_right")
	Input.action_press("run")
	var left_floor: bool = false
	for _index in range(35):
		await frames(1)
		if not game.player.is_on_floor():
			left_floor = true
			break
	Input.action_press("jump")
	await frames(2)
	check(left_floor and game.player.velocity.y < -300.0, "coyote jump works immediately after leaving a ledge")
	release_controls()

	await place_player(Vector2(140, 280))
	var landing_soon: bool = false
	for _index in range(50):
		await frames(1)
		if game.player.position.y > 450.0 and not game.player.is_on_floor():
			landing_soon = true
			break
	Input.action_press("jump")
	var buffered_jump: bool = false
	for _index in range(9):
		await frames(1)
		if game.player.velocity.y < -300.0:
			buffered_jump = true
			break
	check(landing_soon and buffered_jump, "jump pressed before landing executes on contact")
	release_controls()

	await place_player(Vector2(140, 465))
	Input.action_press("dash")
	await frames(3)
	check(game.player.is_dashing() and game.player.velocity.x > 500.0, "dash launches a short speed burst")
	Input.action_release("dash")
	await frames(12)
	Input.action_press("dash")
	await frames(2)
	check(not game.player.is_dashing(), "dash cannot retrigger during cooldown")
	Input.action_release("dash")
	await frames(40)
	Input.action_press("dash")
	await frames(2)
	check(game.player.is_dashing(), "dash becomes available after cooldown")
	release_controls()

	await place_player(Vector2(140, 465))
	var frozen_position: Vector2 = game.player.position
	var frozen_time: float = game.elapsed
	await dispatch_action("pause")
	check(game.state == "paused" and paused, "pause input opens pause menu")
	validate_menu_layout("pause")
	Input.action_press("move_right")
	await frames(10)
	check(game.player.position.is_equal_approx(frozen_position) and absf(game.elapsed - frozen_time) < 0.05, "pause freezes movement and timer")
	release_controls()
	await dispatch_action("pause")
	check(game.state == "playing" and not paused, "pause input resumes gameplay")
	await dispatch_action("pause")
	var resume_button: Button = game.menus.content.find_children("*", "Button", true, false)[0]
	await click_control(resume_button)
	check(game.state == "playing" and not paused, "mouse click activates the visible resume button")
	if game.state == "paused":
		game.resume_game()

	var before_score: int = game.score
	var before_embers: int = game.embers
	var collectible: Node2D = load("res://scenes/collectible.tscn").instantiate()
	collectible.position = Vector2(200, 430)
	game.level.add_child(collectible)
	await place_player(Vector2(200, 465))
	await frames(8)
	check(game.embers > before_embers and game.score >= before_score + 100, "physical collectible overlap awards an ember and score")

	await place_player(Vector2(200, 465))
	var enemy: Node2D = new_enemy(Vector2(200, 467))
	await frames(4)
	check(game.player.health == 2 and game.player.invincible > 0.0, "enemy contact causes damage and brief invulnerability")
	if is_instance_valid(enemy):
		enemy.queue_free()
	await frames(2)
	await place_player(Vector2(200, 465))
	enemy = new_enemy(Vector2(260, 467))
	before_score = game.score
	Input.action_press("move_right")
	Input.action_press("dash")
	await frames(12)
	check(not is_instance_valid(enemy) and game.score >= before_score + 100 and game.player.health == 3, "dash physically defeats an enemy without contact damage")
	release_controls()

	await place_player(Vector2(200, 370))
	enemy = new_enemy(Vector2(200, 467))
	before_score = game.score
	var bounced: bool = false
	for _index in range(40):
		await frames(1)
		if not is_instance_valid(enemy) and game.player.velocity.y < -100.0:
			bounced = true
			break
	check(bounced and game.score >= before_score + 100, "falling onto enemy defeats it and bounces the player")
	if is_instance_valid(enemy):
		enemy.queue_free()
	await place_player(Vector2(750, 465))
	await frames(3)
	check(game.player.health == 2, "spike area inflicts damage through physical overlap")

	await place_player(Vector2(2030, 465))
	game.player.health = 1
	Input.action_press("move_right")
	await frames(24)
	release_controls()
	check(game.checkpoint.x == 2080.0 and game.player.health == 3, "walking through checkpoint restores health and saves respawn position")

	for remaining in [2, 1, 0]:
		release_controls()
		game.player.position = Vector2(1190, 880)
		game.player.velocity = Vector2.ZERO
		game.player.invincible = 0.0
		var prior_lives: int = game.lives
		await frames(4)
		check(game.player.dead and game.lives == prior_lives, "pit death has an animation delay before life loss")
		await frames(50)
		check(game.lives == remaining, "pit death deducts one life (%d remaining)" % remaining)
		if remaining > 0:
			check(not game.player.dead and game.player.health == 3 and absf(game.player.position.x - 2080.0) < 1.0, "death respawns at active checkpoint with full health")
	check(game.state == "game_over" and paused, "third death opens game over")
	validate_menu_layout("game over")
	await dispatch_action("restart")
	check(game.state == "playing" and not paused and game.lives == 3 and game.score == 0 and game.checkpoint.x == 140.0, "restart input resets game after loss")

	await place_player(Vector2(5940, 465))
	Input.action_press("move_right")
	await frames(35)
	release_controls()
	check(game.state == "complete" and paused, "walking into the final shrine opens level complete")
	validate_menu_layout("complete")
	check(game.score >= 1500, "completion awards remaining-life bonus")
	await dispatch_action("restart")
	check(game.state == "playing" and not paused and game.player.health == 3, "restart also works after completion")
	release_controls()
	print("INTEGRATION RESULT: ", checks - failures, "/", checks, " passed; failures=", failures)
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	for _index in range(10):
		OS.delay_msec(20)
		await process_frame
	quit(0 if failures == 0 else 1)
