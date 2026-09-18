extends SceneTree

# A real route-driving player: input actions only, with no teleports, health
# overrides, collision bypasses, direct interaction calls or skipped sections.
var game: Node
var jump_frames: int = 0
var dash_frames: int = 0
var jumps: int = 0
var dashes: int = 0
var distance_bucket: int = -1
var farthest_x: float = 0.0
var died_during_route: bool = false

func _initialize() -> void:
	run_route.call_deferred()

func run_route() -> void:
	print("EMBERTRAIL PHYSICAL FULL-LEVEL TRAVERSAL")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	for _frame in range(9000):
		await process_frame
		if game.state != "playing":
			break
		var player: CharacterBody2D = game.player
		if player.dead:
			died_during_route = true
			Input.action_release("jump")
			Input.action_release("dash")
			continue
		Input.action_press("move_right")
		Input.action_press("run")
		farthest_x = maxf(farthest_x, player.position.x)
		var bucket: int = int(player.position.x / 500.0)
		if bucket != distance_bucket:
			distance_bucket = bucket
			print("ROUTE x=", int(player.position.x), " y=", int(player.position.y), " health=", player.health, " lives=", game.lives)
		if jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				Input.action_release("jump")
		if dash_frames > 0:
			dash_frames -= 1
			if dash_frames == 0:
				Input.action_release("dash")
		var gap_distance: float = 9999.0
		for ground in game.level.grounds:
			var distance: float = ground.end.x - player.position.x
			if distance > -10.0 and ground.end.x < 6240.0:
				gap_distance = minf(gap_distance, distance)
		var hazard_distance: float = 9999.0
		for hazard in get_nodes_in_group("hazards"):
			var distance: float = hazard.position.x - player.position.x
			if distance > -5.0:
				hazard_distance = minf(hazard_distance, distance)
		var enemy_distance: float = 9999.0
		for enemy in get_nodes_in_group("enemies"):
			var distance: float = enemy.position.x - player.position.x
			if distance > 0.0 and absf(enemy.position.y - player.position.y) < 45.0:
				enemy_distance = minf(enemy_distance, distance)
		if player.is_on_floor() and jump_frames == 0:
			if gap_distance < 72.0 or hazard_distance < 100.0:
				Input.action_press("jump")
				jump_frames = 40
				jumps += 1
			elif enemy_distance < 80.0:
				if gap_distance > 200.0 and hazard_distance > 160.0 and player.get("_dash_cooldown") <= 0.0:
					Input.action_press("dash")
					dash_frames = 3
					dashes += 1
				else:
					Input.action_press("jump")
					jump_frames = 40
					jumps += 1
	for action in ["move_right", "run", "jump", "dash"]:
		Input.action_release(action)
	var completed: bool = game.state == "complete"
	var checkpoints_lit: int = 0
	for checkpoint in get_nodes_in_group("checkpoints"):
		if checkpoint.activated:
			checkpoints_lit += 1
	print("ROUTE RESULT state=", game.state, " farthest_x=", int(farthest_x), " embers=", game.embers, " checkpoints=", checkpoints_lit, " jumps=", jumps, " dashes=", dashes, " lives=", game.lives, " elapsed=", snappedf(game.elapsed, 0.01))
	var passed: bool = completed and farthest_x > 5900.0 and game.embers > 0 and checkpoints_lit == 2 and jumps >= 4
	if not passed:
		push_error("FAIL physical route did not complete every required section")
	else:
		print("PASS full level completed through actual player input and collisions")
	paused = false
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	for _index in range(10):
		OS.delay_msec(20)
		await process_frame
	quit(0 if passed else 1)
