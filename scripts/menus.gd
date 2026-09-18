extends CanvasLayer

signal action_selected(action: String)

var root: Control
var content: VBoxContainer
var audio_button: Button
var current_screen: String = "menu"
var art: Node2D
var cream := Color("f8e9bd")
var sage := Color("b4cbb1")

func _ready() -> void:
	root = Control.new()
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

func show_screen(screen: String, stats: Dictionary = {}) -> void:
	current_screen = screen
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	root.show()
	var shade := ColorRect.new()
	shade.color = Color("122f2bef") if screen != "menu" else Color("12332bcf")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	art = Node2D.new()
	art.set_script(load("res://scripts/menu_art.gd"))
	root.add_child(art)
	var badge := make_label("A FOX-SPIRIT ADVENTURE", 12, Color("e4c182"))
	badge.position = Vector2(65, 47)
	root.add_child(badge)
	content = VBoxContainer.new()
	content.position = Vector2(62, 85)
	content.size = Vector2(454, 408)
	content.add_theme_constant_override("separation", 10)
	root.add_child(content)
	var heading: String = "EMBERTRAIL"
	var subtitle: String = "T H E   L A S T   L A N T E R N"
	var description: String = "The woodland has lost its glow.\nFollow the embers. Bring the light home."
	match screen:
		"paused":
			heading = "TAKE A\nBREATHER."
			subtitle = "THE WOODLAND CAN WAIT"
			description = "Your lantern is safe here."
		"game_over":
			heading = "A LIGHT\nCAN RETURN."
			subtitle = "EVERY SPARK GETS ANOTHER CHANCE"
			description = "Your journey: %d embers · %s points\nA fresh trail is waiting." % [stats.get("embers", 0), stats.get("score", 0)]
		"complete":
			heading = "THE WOOD\nAWAKENS."
			subtitle = "YOU BROUGHT THE LIGHT HOME"
			var seconds: int = int(stats.get("time", 0))
			description = "%d EMBERS     %06d POINTS\n%02d:%02d  ·  %d lives carried home" % [stats.get("embers", 0), stats.get("score", 0), seconds / 60, seconds % 60, stats.get("lives", 0)]
	var title := make_label(heading, 55 if screen == "menu" else 43, cream)
	title.add_theme_constant_override("line_spacing", -10)
	content.add_child(title)
	content.add_child(make_label(subtitle, 12, Color("efb870")))
	var separator := Control.new()
	separator.custom_minimum_size = Vector2(0, 4)
	content.add_child(separator)
	var body := make_label(description, 16, sage)
	body.add_theme_constant_override("line_spacing", 5)
	content.add_child(body)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content.add_child(spacer)
	var first: Button
	if screen == "menu":
		first = add_button("ENTER THE WOOD   →", "start", true)
		add_button("QUIT", "quit", false)
	elif screen == "paused":
		first = add_button("CONTINUE THE TRAIL   →", "resume", true)
		add_button("RESTART JOURNEY", "restart", false)
		add_button("MAIN MENU", "menu", false)
	else:
		first = add_button("WALK THE TRAIL AGAIN   →", "restart", true)
		add_button("MAIN MENU", "menu", false)
	first.grab_focus.call_deferred()
	audio_button = Button.new()
	audio_button.position = Vector2(779, 37)
	audio_button.size = Vector2(123, 30)
	audio_button.text = "M  SOUND ON"
	audio_button.flat = true
	audio_button.add_theme_font_size_override("font_size", 11)
	audio_button.add_theme_color_override("font_color", sage)
	audio_button.pressed.connect(func(): action_selected.emit("mute"))
	root.add_child(audio_button)
	var game := get_tree().get_first_node_in_group("game")
	if game:
		update_audio(game.muted)
	var bottom := make_label("A / D   MOVE       SPACE   JUMP       SHIFT   RUN       X   DASH       ESC   PAUSE", 11, sage)
	bottom.position = Vector2(65, 506)
	root.add_child(bottom)

func add_button(text: String, action: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 43 if primary else 32)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 14 if primary else 12)
	button.add_theme_color_override("font_color", Color("243d34") if primary else sage)
	button.add_theme_color_override("font_hover_color", Color("243d34") if primary else cream)
	button.add_theme_color_override("font_focus_color", Color("243d34") if primary else cream)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("efcb88") if primary else Color(0.14, 0.27, 0.23, 0.7)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("ffe2a8") if primary else Color("416152")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("fff0b8")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func(): action_selected.emit(action))
	content.add_child(button)
	return button

func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func hide_screen() -> void:
	root.hide()

func update_audio(muted: bool) -> void:
	if is_instance_valid(audio_button):
		audio_button.text = "M  SOUND OFF" if muted else "M  SOUND ON"
