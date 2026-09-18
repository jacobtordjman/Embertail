extends SceneTree

# Evaluation harness for the build-test-evaluate loop. Drives the real controller
# with real input actions and reports motion-quality metrics that the assertion
# suites do not cover: locomotion cadence against distance travelled, animation
# thrash, state coverage and the ordering of the airborne arc.
# It measures and prints; it never asserts and never edits project files.

var game: Node
var player: EmberPlayer

var timeline: Array = []
var current: String = ""
var held: int = 0

# Cadence accumulators, gathered only on frames that are unambiguously steady
# locomotion so a collision, knockback or slope cannot pollute the average.
var cadence := {}

# Route state, mirroring tests/traversal.gd so the evaluation covers the real level.
var jump_frames: int = 0
var dash_frames: int = 0

func _initialize() -> void:
	run_eval.call_deferred()

func step() -> void:
	await process_frame
	var name: String = str(player.sprite.animation)
	if name != current:
		if current != "":
			timeline.append([current, held])
		current = name
		held = 1
	else:
		held += 1

func hold(count: int) -> void:
	for _i in range(count):
		await step()

func release() -> void:
	for action in ["move_left", "move_right", "jump", "run", "dash"]:
		Input.action_release(action)

func note_cadence() -> void:
	# Qualifying frame: grounded, undamaged, in a locomotion state, at a speed
	# that is not still accelerating. Track distance and cycle wraps per state.
	var name: String = str(player.sprite.animation)
	if name != "walk" and name != "run":
		return
	if not player.is_on_floor() or player._hurt_time > 0.0 or player.is_dashing():
		return
	var entry: Dictionary = cadence.get(name, {"dist": 0.0, "wraps": 0, "frames": 0, "prev": -1, "vmin": 1e9, "vmax": -1e9})
	var speed: float = absf(player.velocity.x)
	entry["dist"] += speed / 60.0
	entry["frames"] += 1
	entry["vmin"] = minf(entry["vmin"], speed)
	entry["vmax"] = maxf(entry["vmax"], speed)
	var frame: int = player.sprite.frame
	if entry["prev"] >= 0 and frame < entry["prev"]:
		entry["wraps"] += 1
	entry["prev"] = frame
	cadence[name] = entry

func arc_of(from: int) -> String:
	var parts: Array = []
	for i in range(from, timeline.size()):
		parts.append("%s:%df" % [timeline[i][0], timeline[i][1]])
	return " -> ".join(parts)

func run_eval() -> void:
	print("EMBERTRAIL MOTION EVALUATION")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	await process_frame
	player = game.player
	current = str(player.sprite.animation)

	# --- Airborne arc: held jump versus tapped jump -----------------------
	player.respawn(Vector2(300, 465))
	await hold(12)
	timeline.clear()
	current = ""
	held = 0
	Input.action_press("jump")
	await hold(20)
	Input.action_release("jump")
	var air: int = 0
	while air < 160 and not (player.is_on_floor() and air > 24):
		await step()
		air += 1
	await hold(20)
	timeline.append([current, held])
	print("ARC held jump   = ", arc_of(0))

	release()
	player.respawn(Vector2(300, 465))
	await hold(12)
	timeline.clear()
	current = ""
	held = 0
	Input.action_press("jump")
	await hold(1)
	Input.action_release("jump")
	air = 0
	while air < 160 and not (player.is_on_floor() and air > 14):
		await step()
		air += 1
	await hold(12)
	timeline.append([current, held])
	print("ARC tapped jump = ", arc_of(0))

	# --- Full level on the real route -------------------------------------
	release()
	game.start_game()
	await process_frame
	player = game.player
	timeline.clear()
	current = str(player.sprite.animation)
	held = 0
	var seen := {}
	var ticks: int = 0
	var deaths: int = 0
	while ticks < 9000 and game.state == "playing":
		await step()
		ticks += 1
		seen[current] = int(seen.get(current, 0)) + 1
		note_cadence()
		if player.dead:
			deaths += 1
			Input.action_release("jump")
			Input.action_release("dash")
			continue
		Input.action_press("move_right")
		Input.action_press("run")
		if jump_frames > 0:
			jump_frames -= 1
			if jump_frames == 0:
				Input.action_release("jump")
		if dash_frames > 0:
			dash_frames -= 1
			if dash_frames == 0:
				Input.action_release("dash")
		var gap: float = 9999.0
		for ground in game.level.grounds:
			var d: float = ground.end.x - player.position.x
			if d > -10.0 and ground.end.x < 6240.0:
				gap = minf(gap, d)
		var hazard: float = 9999.0
		for node in get_nodes_in_group("hazards"):
			var d: float = node.position.x - player.position.x
			if d > -5.0:
				hazard = minf(hazard, d)
		var enemy: float = 9999.0
		for node in get_nodes_in_group("enemies"):
			var d: float = node.position.x - player.position.x
			if d > 0.0 and absf(node.position.y - player.position.y) < 45.0:
				enemy = minf(enemy, d)
		if player.is_on_floor() and jump_frames == 0:
			if gap < 72.0 or hazard < 100.0:
				Input.action_press("jump")
				jump_frames = 40
			elif enemy < 80.0:
				if gap > 200.0 and hazard > 160.0 and player.dash_cooldown <= 0.0:
					Input.action_press("dash")
					dash_frames = 3
				else:
					Input.action_press("jump")
					jump_frames = 40
	timeline.append([current, held])
	release()

	print("ROUTE state=%s x=%d frames=%d deaths=%d" % [game.state, int(player.position.x), ticks, deaths])
	for name in cadence:
		var e: Dictionary = cadence[name]
		if e["wraps"] > 0:
			print("CADENCE %-4s travel/cycle=%5.1f px over %d cycles (%d frames, speed %.0f..%.0f)" % [
				name, e["dist"] / float(e["wraps"]), e["wraps"], e["frames"], e["vmin"], e["vmax"]])
	print("COVERAGE played = ", seen)
	var missing: Array = []
	for name in player.sprite.sprite_frames.get_animation_names():
		if not seen.has(name):
			missing.append(name)
	print("COVERAGE never played = ", missing)
	var flicker: Array = []
	for entry in timeline:
		if entry[1] <= 2:
			flicker.append("%s:%df" % [entry[0], entry[1]])
	print("THRASH sub-3-frame runs = %d over %d changes (%.2f changes/sec)" % [
		flicker.size(), timeline.size(), float(timeline.size()) / maxf(float(ticks) / 60.0, 0.001)])
	# Context matters: a one-frame state between two different states is a visible
	# pop, while one inside a legitimate transient is not. Print neighbours.
	for i in range(timeline.size()):
		if timeline[i][1] <= 2 and timeline[i][1] > 0:
			var before: String = "%s:%df" % [timeline[i - 1][0], timeline[i - 1][1]] if i > 0 else "start"
			var after: String = "%s:%df" % [timeline[i + 1][0], timeline[i + 1][1]] if i + 1 < timeline.size() else "end"
			print("  FLICKER %s  [%s:%df]  %s" % [before, timeline[i][0], timeline[i][1], after])
	quit()
