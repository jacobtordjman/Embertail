extends SceneTree

var sprites: Array[AnimatedSprite2D] = []
var animation_names: Array[String] = ["idle", "walk", "run", "jump", "fall", "land", "dash", "hurt", "death"]
var ticks: int = 0
var elapsed: float = 0.0

func _initialize() -> void:
	setup.call_deferred()

func label(parent: Node, words: String, at: Vector2, size: int, color: Color) -> void:
	var node := Label.new()
	node.layout_direction = Control.LAYOUT_DIRECTION_LTR
	node.text = words
	node.position = at
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)

func setup() -> void:
	TranslationServer.set_locale("en")
	var ui := Control.new()
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color("182c2c")
	bg.size = Vector2(960, 540)
	ui.add_child(bg)
	label(ui, "EMBERTRAIL  /  CHARACTER MOTION STUDY", Vector2(24, 17), 22, Color("f8e9bd"))
	label(ui, "13 supplied sprites · original idle/walk/run/dash art · derived transition poses", Vector2(25, 46), 12, Color("b4cbb1"))
	var atlas: SpriteFrames = load("res://assets/sprites/player_frames.tres")
	for index in range(9):
		var panel := Panel.new()
		panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
		panel.position = Vector2(24 + index % 3 * 312, 77 + int(index / 3) * 145)
		panel.size = Vector2(288, 136)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2a4640")
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)
		ui.add_child(panel)
		var name: String = animation_names[index]
		label(panel, name.to_upper(), Vector2(12, 9), 12, Color("edcc92"))
		var sprite := AnimatedSprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.sprite_frames = atlas
		sprite.animation = name
		sprite.position = Vector2(150, 43)
		sprite.scale = Vector2.ONE * 1.3
		panel.add_child(sprite)
		sprites.append(sprite)
		label(panel, "%d FRAMES" % atlas.get_frame_count(name), Vector2(12, 113), 10, Color("a2bba4"))
	label(ui, "Review tool only: one-shot animations repeat here for inspection.", Vector2(24, 519), 10, Color("a2bba4"))

func _process(delta: float) -> bool:
	elapsed += delta
	ticks += 1
	for sprite in sprites:
		var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
		var speed: float = sprite.sprite_frames.get_animation_speed(sprite.animation)
		var duration: float = float(count) / speed
		var pause: float = 0.0 if sprite.sprite_frames.get_animation_loop(sprite.animation) else 0.28
		sprite.frame = mini(count - 1, int(fposmod(elapsed, duration + pause) * speed))
	if ticks == 180:
		finish.call_deferred()
	return false

func finish() -> void:
	await RenderingServer.frame_post_draw
	var error: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/character/animation-review.png"))
	print("CHARACTER REVIEW screenshot saved; result=", error)
	quit(error)
