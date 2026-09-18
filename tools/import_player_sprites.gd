extends SceneTree

# User-provided art is copied intact. These anchors normalize different crop sizes
# around the pelvis and soles without changing the supplied head/body proportions.
const CELL := 160
const COLUMNS := 8
const ANCHOR := Vector2(100, 145)
const SOURCES := {
	"00": ["fox_r00_c00", Vector2(46, 86)],
	"01": ["fox_r00_c01", Vector2(45, 86)],
	"02": ["fox_r00_c02", Vector2(46, 85)],
	"03": ["fox_r00_c03", Vector2(50, 86)],
	"05": ["fox_r00_c05", Vector2(45, 86)],
	"06": ["fox_r00_c06", Vector2(47, 86)],
	"07": ["fox_r00_c07", Vector2(47, 83)],
	"08": ["fox_r00_c08", Vector2(46, 82)],
	"09": ["fox_r00_c09", Vector2(58, 78)],
	"10": ["fox_r00_c10", Vector2(63, 67)],
	"11": ["fox_r00_c11", Vector2(65, 71)],
	"14": ["fox_r00_c14", Vector2(92, 69)],
	"crouch": ["fox_r01_c00", Vector2(47, 74)]
}
const SPEC := [
	["idle", 8.0, true, ["00", "01", "02", "03", "05", "02", "01", "00"]],
	["walk", 9.0, true, ["06", "07", "08", "07"]],
	["run", 12.0, true, ["09", "10", "11", "10"]],
	["jump", 16.0, false, ["crouch", "crouch", "crouch", "crouch"]],
	["fall", 9.0, true, ["07", "07", "07", "07"]],
	["dash", 23.0, false, ["14", "14", "14", "14"]],
	["hurt", 18.0, false, ["03", "03", "03", "03"]],
	["death", 12.0, false, ["00", "00", "00", "00", "00", "00", "00", "00"]],
	["land", 25.0, false, ["crouch", "crouch", "07", "00"]]
]

func _initialize() -> void:
	generate.call_deferred()

func aligned(source: String) -> Image:
	var descriptor: Array = SOURCES[source]
	var path: String = ProjectSettings.globalize_path("res://assets/sprites/source_fox/" + descriptor[0] + ".png")
	var image := Image.load_from_file(path)
	image.convert(Image.FORMAT_RGBA8)
	clean_matte_edge(image)
	var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	cell.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(ANCHOR - descriptor[1]))
	return cell

func clean_matte_edge(image: Image) -> void:
	# Some supplied cuts retain a pale neutral matte outside their dark outline.
	# Remove only exterior-connected neutral edge pixels; warm fur/cloth is retained.
	for _pass in range(2):
		var clear: Array[Vector2i] = []
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color: Color = image.get_pixel(x, y)
				var light: float = maxf(color.r, maxf(color.g, color.b))
				var chroma: float = light - minf(color.r, minf(color.g, color.b))
				if color.a == 0 or chroma >= 0.09 or light < 0.32:
					continue
				for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = Vector2i(x, y) + step
					if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= image.get_width() or neighbor.y >= image.get_height() or image.get_pixelv(neighbor).a == 0:
						clear.append(Vector2i(x, y))
						break
		for at in clear:
			image.set_pixelv(at, Color.TRANSPARENT)

func pose(source: String, animation: String, index: int) -> Image:
	var image: Image = aligned(source)
	var angle: float = 0.0
	var offset := Vector2.ZERO
	match animation:
		"jump":
			angle = deg_to_rad([-5.0, -2.0, 1.0, 3.0][index])
			offset.y = [-1.0, -2.0, -1.0, 0.0][index]
		"fall":
			angle = deg_to_rad([-3.0, -1.0, 1.0, 0.0][index])
		"dash":
			offset = Vector2([0, 1, 2, 0][index], [0, -1, 0, 0][index])
		"hurt":
			angle = deg_to_rad([-18.0, -14.0, -10.0, -6.0][index])
		"death":
			angle = deg_to_rad([0.0, -12.0, -28.0, -48.0, -67.0, -83.0, -87.0, -88.0][index])
		"land":
			offset.y = [0, 1, 0, 0][index]
	if is_zero_approx(angle) and offset == Vector2.ZERO:
		return image
	var pivot := Vector2(100, 117)
	var result := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	# The death silhouette rests on the same floor baseline at every angle.
	if animation == "death":
		var highest_y: float = 0.0
		var minimum_x: float = CELL
		var maximum_x: float = 0.0
		for y in range(CELL):
			for x in range(CELL):
				if image.get_pixel(x, y).a > 0.0:
					var point: Vector2 = (Vector2(x, y) - pivot).rotated(angle) + pivot
					highest_y = maxf(highest_y, point.y)
					minimum_x = minf(minimum_x, point.x)
					maximum_x = maxf(maximum_x, point.x)
		offset.y = ANCHOR.y - highest_y
		offset.x = maxf(0.0, 3.0 - minimum_x) - maxf(0.0, maximum_x - 156.0)
	for y in range(CELL):
		for x in range(CELL):
			var from: Vector2 = (Vector2(x, y) - pivot - offset).rotated(-angle) + pivot
			var pixel := Vector2i(roundi(from.x), roundi(from.y))
			if pixel.x >= 0 and pixel.y >= 0 and pixel.x < CELL and pixel.y < CELL:
				result.set_pixel(x, y, image.get_pixelv(pixel))
	return result

func generate() -> void:
	var atlas := Image.create(CELL * COLUMNS, CELL * SPEC.size(), false, Image.FORMAT_RGBA8)
	var poses: Dictionary = {}
	for row in range(SPEC.size()):
		var spec: Array = SPEC[row]
		var keys: Array = spec[3]
		for column in range(COLUMNS):
			var index: int = mini(column, keys.size() - 1)
			var cell: Image = pose(keys[index], spec[0], index)
			atlas.blit_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i(column * CELL, row * CELL))
			poses[str(spec[0]) + str(index)] = cell
	var atlas_path := ProjectSettings.globalize_path("res://assets/sprites/player.png")
	var error: int = atlas.save_png(atlas_path)
	if error != OK:
		push_error("Cannot save player atlas")
		quit(error)
		return
	# Write explicit external atlas references so regeneration works before import.
	var output := '[gd_resource type="SpriteFrames" format=3]\n\n[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="1"]\n'
	for row in range(SPEC.size()):
		for column in range(SPEC[row][3].size()):
			var id: String = str(SPEC[row][0]) + str(column)
			output += '\n[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1")\nregion = Rect2(%d, %d, %d, %d)\n' % [id, column * CELL, row * CELL, CELL, CELL]
	output += '\n[resource]\nmetadata/frame_size = 160\nmetadata/columns = 8\nmetadata/feet_anchor = Vector2(100, 145)\nmetadata/portrait_region = Rect2(46, 53, 84, 96)\nanimations = [\n'
	for row in range(SPEC.size()):
		var spec: Array = SPEC[row]
		output += '{"frames": [\n'
		for index in range(spec[3].size()):
			output += '{"duration": 1.0, "texture": SubResource("%s%d")}%s\n' % [spec[0], index, ',' if index < spec[3].size() - 1 else '']
		output += '], "loop": %s, "name": &"%s", "speed": %.1f}%s\n' % ['true' if spec[2] else 'false', spec[0], spec[1], ',' if row < SPEC.size() - 1 else '']
	output += ']\n'
	var file := FileAccess.open("res://assets/sprites/player_frames.tres", FileAccess.WRITE)
	file.store_string(output)
	file.close()
	var preview: Image = poses["idle0"].get_region(Rect2i(46, 53, 84, 96))
	preview.resize(420, 480, Image.INTERPOLATE_NEAREST)
	var board := Image.create(420, 480, false, Image.FORMAT_RGBA8)
	board.fill(Color("243b37"))
	board.blend_rect(preview, Rect2i(0, 0, 420, 480), Vector2i.ZERO)
	board.save_png(ProjectSettings.globalize_path("res://docs/character/supplied/idle-detail.png"))
	print("Imported 13 original user sprites: 44 playback frames, 9 states, feet aligned; missing actions derived from supplied art.")
	quit()
