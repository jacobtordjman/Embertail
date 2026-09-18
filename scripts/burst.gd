extends Node2D

var kind: String = "coin"
var age: float = 0.0
var lifespan: float = 0.55
var motes: Array = []

func _ready() -> void:
	z_index = 20
	var number: int = 18 if kind in ["enemy", "checkpoint", "death"] else 9
	if kind == "run":
		number = 3
		lifespan = 0.28
	for i in range(number):
		var angle: float = randf_range(-PI, 0) if kind in ["land", "run"] else randf() * TAU
		motes.append([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * randf_range(25, 110), randf_range(2, 5)])

func _process(delta: float) -> void:
	age += delta
	if age >= lifespan:
		queue_free()
		return
	for mote in motes:
		mote[0] += mote[1] * delta
		mote[1].y += delta * 110
	queue_redraw()

func _draw() -> void:
	var tint := Color("ffcf70")
	if kind in ["land", "run"]:
		tint = Color("d7d3ad")
	elif kind in ["enemy", "dash"]:
		tint = Color("78dfc1")
	elif kind in ["hurt", "death"]:
		tint = Color("f48b68")
	tint.a = 1.0 - age / lifespan
	for mote in motes:
		var size: float = mote[2] * (1.0 - age / lifespan * 0.7)
		draw_rect(Rect2(mote[0] - Vector2.ONE * size * 0.5, Vector2.ONE * size), tint)
