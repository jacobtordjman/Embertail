extends SceneTree

# Renders every state in the current SpriteFrames onto one board, with a shared
# floor line and body centre line so feet anchoring can be judged across states.
# The state list is read from the resource: it never needs editing when the
# animation set changes.

const BOARD := Vector2(960, 540)
const COLUMNS := 4
const PANEL := Vector2(224, 136)
const GAP := Vector2(12, 9)
const ORIGIN := Vector2(18, 74)
# Cell-space anchor from the importer, expressed relative to the 160px cell centre.
const CELL := 160.0
const ANCHOR := Vector2(100.0, 145.0)
const FLOOR_Y := 112.0
const CENTRE_X := 112.0

var sprites: Array[AnimatedSprite2D] = []
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

func guide(parent: Node, at: Vector2, size: Vector2, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = at
	line.size = size
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func setup() -> void:
	TranslationServer.set_locale("en")
	var ui := Control.new()
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color("182c2c")
	bg.size = BOARD
	ui.add_child(bg)
	var atlas: SpriteFrames = load("res://assets/sprites/player_frames.tres")
	var names: PackedStringArray = atlas.get_animation_names()
	label(ui, "EMBERTRAIL  /  CHARACTER MOTION STUDY", Vector2(20, 14), 21, Color("f8e9bd"))
	label(ui, "%d states from 27 supplied source poses · dashed line = feet anchor, tick = body centre" % names.size(),
		Vector2(21, 42), 11, Color("b4cbb1"))
	for index in range(names.size()):
		var name: String = names[index]
		var panel := Panel.new()
		panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
		panel.position = ORIGIN + Vector2((index % COLUMNS) * (PANEL.x + GAP.x), int(index / COLUMNS) * (PANEL.y + GAP.y))
		panel.size = PANEL
		panel.clip_contents = true
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2a4640")
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)
		ui.add_child(panel)
		# Floor line and centre tick: the reference the poses are judged against.
		guide(panel, Vector2(10, FLOOR_Y), Vector2(PANEL.x - 20, 1), Color(0.60, 0.76, 0.70, 0.55))
		guide(panel, Vector2(CENTRE_X, 24), Vector2(1, PANEL.y - 34), Color(0.60, 0.76, 0.70, 0.22))
		label(panel, name.to_upper(), Vector2(11, 7), 12, Color("edcc92"))
		var sprite := AnimatedSprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.sprite_frames = atlas
		sprite.animation = name
		# Place the cell so its feet anchor sits exactly on the floor line.
		sprite.position = Vector2(CENTRE_X - (ANCHOR.x - CELL / 2.0), FLOOR_Y - (ANCHOR.y - CELL / 2.0))
		panel.add_child(sprite)
		sprites.append(sprite)
		var loops: String = "loop" if atlas.get_animation_loop(name) else "once"
		label(panel, "%d frames · %.0f fps · %s" % [atlas.get_frame_count(name), atlas.get_animation_speed(name), loops],
			Vector2(11, PANEL.y - 20), 10, Color("a2bba4"))
	label(ui, "Review tool only: one-shot animations repeat here for inspection.", Vector2(20, BOARD.y - 19), 10, Color("a2bba4"))

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
