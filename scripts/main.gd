extends Node

const LEVEL = preload("res://levels/lanternwood.tscn")
const PLAYER = preload("res://scenes/player.tscn")
const HUD_SCENE = preload("res://ui/hud.tscn")
const MENUS_SCENE = preload("res://ui/menus.tscn")
const BACKDROP = preload("res://scripts/backdrop.gd")
const BURST = preload("res://scripts/burst.gd")

var state: String = "menu"
var level: Node2D
var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var menus: CanvasLayer
var backdrop: Node2D
var score: int = 0
var embers: int = 0
var lives: int = 3
var elapsed: float = 0.0
var checkpoint: Vector2 = Vector2(140, 465)
var shake_power: float = 0.0
var muted: bool = false
var music: AudioStreamPlayer
var sounds: Dictionary = {}
var capture_path: String = ""
var capture_frames: int = 0

func _ready() -> void:
	# All authored UI is English; initialize direction before positioning controls.
	TranslationServer.set_locale("en")
	add_to_group("game")
	configure_inputs()
	load_sounds()
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	backdrop = Node2D.new()
	backdrop.set_script(BACKDROP)
	layer.add_child(backdrop)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	menus = MENUS_SCENE.instantiate()
	add_child(menus)
	menus.action_selected.connect(_on_menu_action)
	create_world()
	player.set_control_enabled(false)
	hud.visible = false
	menus.show_screen("menu")
	for argument in OS.get_cmdline_user_args():
		if argument == "--preview":
			start_game()
		elif argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
		elif argument.begins_with("--preview-x="):
			player.position.x = float(argument.trim_prefix("--preview-x="))
			camera.position.x = player.position.x + 100
			camera.reset_smoothing()

func configure_inputs() -> void:
	bind_keys("move_left", [KEY_A, KEY_LEFT])
	bind_keys("move_right", [KEY_D, KEY_RIGHT])
	bind_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	bind_keys("run", [KEY_SHIFT])
	bind_keys("dash", [KEY_X, KEY_J])
	bind_keys("pause", [KEY_ESCAPE, KEY_P])
	bind_keys("restart", [KEY_R])
	bind_keys("mute", [KEY_M])
	bind_keys("fullscreen", [KEY_F11])
	for pair in [["jump", JOY_BUTTON_A], ["dash", JOY_BUTTON_X], ["run", JOY_BUTTON_RIGHT_SHOULDER], ["pause", JOY_BUTTON_START]]:
		var button := InputEventJoypadButton.new()
		button.button_index = pair[1]
		InputMap.action_add_event(pair[0], button)
	for pair in [["move_left", -1.0], ["move_right", 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = pair[1]
		InputMap.action_add_event(pair[0], axis)

func bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func create_world() -> void:
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = LEVEL.instantiate()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	player = PLAYER.instantiate()
	player.position = checkpoint
	level.add_child(player)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.effect_requested.connect(burst)
	player.sound_requested.connect(play_sound)
	camera = Camera2D.new()
	camera.position = Vector2(480, 270)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_left = 0
	camera.limit_right = 6240
	camera.limit_top = 0
	camera.limit_bottom = 540
	camera.limit_smoothed = true
	level.add_child(camera)
	camera.make_current()
	camera.reset_smoothing()

func start_game() -> void:
	get_tree().paused = false
	score = 0
	embers = 0
	lives = 3
	elapsed = 0.0
	checkpoint = Vector2(140, 465)
	create_world()
	state = "playing"
	menus.hide_screen()
	hud.visible = true
	player.set_control_enabled(true)
	hud.notify("LANTERNWOOD  /  Follow the embers. Wake the last lantern.", 4.0)

func _process(delta: float) -> void:
	if state == "playing":
		elapsed += delta
		var look_ahead: float = clampf(player.velocity.x * 0.28, -65.0, 105.0)
		camera.position = Vector2(clampf(player.position.x + look_ahead, 480.0, 5760.0), 270)
		shake_power = move_toward(shake_power, 0.0, delta * 24.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_power
	if is_instance_valid(camera):
		backdrop.scroll_x = camera.get_screen_center_position().x - 480.0
	if is_instance_valid(player):
		hud.update_values(player.health, lives, score, embers, elapsed, player.position.x / 6020.0, player.dash_cooldown)
	if capture_path != "":
		capture_frames += 1
		if capture_frames == 90:
			capture_frame.call_deferred()

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	var result: int = get_viewport().get_texture().get_image().save_png(capture_path)
	print("SCREENSHOT ", capture_path, " result=", result)
	get_tree().quit(result)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == "playing":
			pause_game()
		elif state == "paused":
			resume_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and state != "menu":
		start_game()
	elif event.is_action_pressed("mute"):
		toggle_mute()
	elif event.is_action_pressed("fullscreen"):
		var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func pause_game() -> void:
	state = "paused"
	get_tree().paused = true
	menus.show_screen("paused")

func resume_game() -> void:
	state = "playing"
	menus.hide_screen()
	get_tree().paused = false

func _on_menu_action(action: String) -> void:
	match action:
		"start", "restart": start_game()
		"resume": resume_game()
		"menu":
			get_tree().paused = false
			state = "menu"
			player.set_control_enabled(false)
			hud.visible = false
			menus.show_screen("menu")
		"mute": toggle_mute()
		"quit": get_tree().quit()

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	menus.update_audio(muted)

func add_score(amount: int) -> void:
	score += amount

func collect_ember(at: Vector2) -> void:
	embers += 1
	score += 100
	burst("coin", at)
	play_sound("coin")

func activate_checkpoint(at: Vector2) -> void:
	checkpoint = Vector2(at.x, at.y - 4)
	player.health = 3
	burst("checkpoint", at + Vector2(0, -40))
	play_sound("checkpoint")
	hud.notify("LANTERN LIT  /  Health restored · return here if you fall", 3.5)

func complete_level() -> void:
	if state != "playing":
		return
	state = "complete"
	player.set_control_enabled(false)
	score += lives * 500 + maxi(0, 3000 - int(elapsed) * 10)
	play_sound("complete")
	burst("checkpoint", player.position + Vector2(0, -40))
	menus.show_screen("complete", {"score": score, "embers": embers, "time": elapsed, "lives": lives})
	get_tree().paused = true

func _on_player_damaged(_health: int) -> void:
	shake(5.0)

func _on_player_died() -> void:
	if state != "playing":
		return
	lives -= 1
	if lives <= 0:
		state = "game_over"
		menus.show_screen("game_over", {"score": score, "embers": embers, "time": elapsed})
		get_tree().paused = true
	else:
		player.respawn(checkpoint)
		camera.position = Vector2(clampf(checkpoint.x, 480, 5760), 270)
		camera.offset = Vector2.ZERO
		camera.reset_smoothing()
		hud.notify("The lantern guides you back.  %d lives remain." % lives, 2.5)

func shake(amount: float) -> void:
	shake_power = maxf(shake_power, amount)

func burst(kind: String, at: Vector2) -> void:
	if not is_instance_valid(level):
		return
	var effect := Node2D.new()
	effect.set_script(BURST)
	effect.position = at
	effect.kind = kind
	level.add_child(effect)

func load_sounds() -> void:
	for name in ["jump", "coin", "hurt", "enemy", "checkpoint", "complete", "dash", "land"]:
		var path: String = "res://assets/audio/%s.wav" % name
		if ResourceLoader.exists(path):
			sounds[name] = load(path)
	music = AudioStreamPlayer.new()
	add_child(music)
	if ResourceLoader.exists("res://assets/audio/music.wav"):
		var stream: AudioStreamWAV = load("res://assets/audio/music.wav").duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		music.stream = stream
		music.volume_db = -15
		music.play()

func play_sound(kind: String) -> void:
	if not sounds.has(kind):
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = sounds[kind]
	voice.volume_db = -10 if kind == "land" else -6
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

func _exit_tree() -> void:
	# Release looping WAV playback before the audio mixer shuts down.
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
	OS.delay_msec(80)
