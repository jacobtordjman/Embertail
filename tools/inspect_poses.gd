extends SceneTree

# Review-only: magnify chosen source crops side by side so poses can be judged
# before they are adopted. Pass crop names after `--`, for example:
#   godot --headless --path . --script res://tools/inspect_poses.gd -- \
#       --out=/tmp/board.png fox_r00_c09 fox_r00_c10 fox_r00_c11
# Looks in assets/sprites/source_fox first, then source_art/cuts.

const ZOOM := 3
const CELL_W := 210
const CELL_H := 130
const PAD := 12

func _initialize() -> void:
	build.call_deferred()

func locate(name: String) -> String:
	for base in ["res://assets/sprites/source_fox/", "res://source_art/cuts/"]:
		var path: String = ProjectSettings.globalize_path(base + name + ".png")
		if FileAccess.file_exists(path):
			return path
	return ""

func build() -> void:
	var names: Array[String] = []
	var out: String = "/tmp/pose-board.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out = argument.trim_prefix("--out=")
		elif not argument.begins_with("--"):
			names.append(argument)
	if names.is_empty():
		print("no crop names given")
		quit(1)
		return
	var board := Image.create(CELL_W * ZOOM * names.size(), CELL_H * ZOOM, false, Image.FORMAT_RGBA8)
	board.fill(Color("1b2430"))
	for i in range(names.size()):
		var path: String = locate(names[i])
		if path.is_empty():
			print("missing: ", names[i])
			continue
		var img := Image.load_from_file(path)
		img.convert(Image.FORMAT_RGBA8)
		img.resize(img.get_width() * ZOOM, img.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
		var cx: int = i * CELL_W * ZOOM
		var ox: int = cx + maxi(0, (CELL_W * ZOOM - img.get_width()) / 2)
		var oy: int = maxi(0, CELL_H * ZOOM - PAD - img.get_height())
		board.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(ox, oy))
		for y in range(board.get_height()):
			board.set_pixel(cx, y, Color("46607a"))
		for x in range(cx + 2, mini(cx + CELL_W * ZOOM - 2, board.get_width())):
			board.set_pixel(x, CELL_H * ZOOM - PAD + 2, Color("8fb4d4"))
	board.save_png(out)
	print("wrote %s with %d poses: %s" % [out, names.size(), ", ".join(names)])
	quit()
