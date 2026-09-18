extends SceneTree

var game: Node

func _initialize() -> void:
	run_capture.call_deferred()

func frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func save_screen(name: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://docs/" + name + ".png")
	var result: int = root.get_texture().get_image().save_png(path)
	print("CAPTURE ", name, " result=", result)

func run_capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await save_screen("menu")
	game.start_game()
	await frames(160)
	await save_screen("gameplay")
	game.pause_game()
	await save_screen("pause")
	game.resume_game()
	for _death in range(3):
		game.player.kill()
		await frames(55)
	await save_screen("game_over")
	game.start_game()
	game.player.position = Vector2(5940, 465)
	Input.action_press("move_right")
	await frames(35)
	Input.action_release("move_right")
	await save_screen("complete")
	paused = false
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	for _index in range(10):
		OS.delay_msec(20)
		await process_frame
	quit()
