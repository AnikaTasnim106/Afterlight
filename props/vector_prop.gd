@tool
class_name VectorProp
extends Node2D
## One furniture/decor item drawn as flat vector art.
## Origin = bottom-centre where the item touches the floor (or the wall
## anchor point for wall items). Change `kind`, `size` and colours in the
## inspector; it redraws live.

@export_enum("sofa", "coffee_table", "floor_lamp", "bookshelf", "plant", "frame", "front_door",
	"shoe_rack", "desk", "chair", "fridge", "counter", "wall_clock", "radiator", "rug", "coat_hooks",
	"pinboard", "switch_panel", "doorway", "side_table", "shelf_wall", "ceiling_light", "floor_sign",
	"notice_board", "elevator", "bicycle", "trash_bags", "storage_box", "extinguisher", "roof_hut",
	"ac_unit", "water_tank", "roof_rail", "small_window", "stair_number", "debris", "bag", "helipad", "tent", "fence", "floodlight", "crate", "truck", "table", "cot", "generator", "barrier", "flagpole", "car", "bus", "traffic_light", "bus_stop", "shelf", "shop_counter", "cooler", "train", "tunnel_light", "subway_sign", "subway_stairs", "boat", "fuel_can", "shed", "pier_post", "crane", "lab_bench", "terminal", "cart", "hospital_bed", "antenna", "relay_box", "hatch_ladder", "guitar_stand") var kind := "sofa":
	set(v):
		kind = v
		queue_redraw()
@export var size := Vector2(400, 200):
	set(v):
		size = v
		queue_redraw()
@export var main_color := Color("4f6478"):
	set(v):
		main_color = v
		queue_redraw()
@export var accent_color := Color("e3a03c"):
	set(v):
		accent_color = v
		queue_redraw()
@export var seed_value := 1
## Free text used by some props (door number, frame subject...)
@export var label := ""

const WOOD := Color("6e4a33")
const WOOD_DARK := Color("4b3224")
const METAL := Color("3a3d44")
const CREAM := Color("e9dfcf")
const INK := Color("1d1a20")
const TEAL := Color("2bb3a7")

var _t := 0.0


func _process(dt: float) -> void:
	if kind in ["wall_clock", "desk", "ceiling_light", "ac_unit", "floodlight", "flagpole", "generator", "car", "traffic_light", "tunnel_light", "boat", "lab_bench", "terminal", "antenna", "relay_box"]:
		_t += dt
		queue_redraw()


func _draw() -> void:
	match kind:
		"sofa": _sofa()
		"coffee_table": _coffee_table()
		"floor_lamp": _floor_lamp()
		"bookshelf": _bookshelf()
		"plant": _plant()
		"frame": _frame()
		"front_door": _front_door()
		"shoe_rack": _shoe_rack()
		"desk": _desk()
		"chair": _chair()
		"fridge": _fridge()
		"counter": _counter()
		"wall_clock": _wall_clock()
		"radiator": _radiator()
		"rug": _rug()
		"coat_hooks": _coat_hooks()
		"pinboard": _pinboard()
		"switch_panel": _switch_panel()
		"doorway": _doorway()
		"side_table": _side_table()
		"shelf_wall": _shelf_wall()
		"ceiling_light": _ceiling_light()
		"floor_sign": _floor_sign()
		"notice_board": _notice_board()
		"elevator": _elevator()
		"bicycle": _bicycle()
		"trash_bags": _trash_bags()
		"storage_box": _storage_box()
		"extinguisher": _extinguisher()
		"roof_hut": _roof_hut()
		"ac_unit": _ac_unit()
		"water_tank": _water_tank()
		"roof_rail": _roof_rail()
		"small_window": _small_window()
		"stair_number": _stair_number()
		"debris": _debris()
		"bag": _bag()
		"helipad": _helipad()
		"tent": _tent()
		"fence": _fence()
		"floodlight": _floodlight()
		"crate": _crate()
		"truck": _truck()
		"table": _table()
		"cot": _cot()
		"generator": _generator()
		"barrier": _barrier()
		"flagpole": _flagpole()
		"car": _car()
		"bus": _bus()
		"traffic_light": _traffic_light()
		"bus_stop": _bus_stop()
		"shelf": _shelf()
		"shop_counter": _shop_counter()
		"cooler": _cooler()
		"train": _train()
		"tunnel_light": _tunnel_light()
		"subway_sign": _subway_sign()
		"subway_stairs": _subway_stairs()
		"boat": _boat()
		"fuel_can": _fuel_can()
		"shed": _shed()
		"pier_post": _pier_post()
		"crane": _crane()
		"lab_bench": _lab_bench()
		"terminal": _terminal()
		"cart": _cart()
		"hospital_bed": _hospital_bed()
		"antenna": _antenna()
		"relay_box": _relay_box()
		"hatch_ladder": _hatch_ladder()
		"guitar_stand": _guitar_stand()


func _sofa() -> void:
	var w := size.x
	var h := size.y
	var c := main_color
	var dark := Vec.shade(c, 0.22)
	Vec.ellipse(self, Vector2(0, -2), w * 0.52, 14, Color(0, 0, 0, 0.3))
	# legs
	for x in [-w * 0.42, w * 0.42]:
		Vec.rrect(self, Rect2(x - 8, -22, 16, 22), 3, WOOD_DARK)
	# back
	Vec.rrect(self, Rect2(-w * 0.46, -h, w * 0.92, h * 0.62), 26, dark)
	# back cushions
	for i in 3:
		var cw := w * 0.84 / 3.0
		var x0 := -w * 0.42 + i * cw
		Vec.rrect(self, Rect2(x0 + 3, -h + 14, cw - 6, h * 0.48), 20, Vec.shade(c, 0.08))
	# seat
	Vec.rrect(self, Rect2(-w * 0.46, -h * 0.5, w * 0.92, h * 0.34), 16, c)
	draw_line(Vector2(-w * 0.14, -h * 0.48), Vector2(-w * 0.14, -h * 0.2), dark, 3.0)
	draw_line(Vector2(w * 0.14, -h * 0.48), Vector2(w * 0.14, -h * 0.2), dark, 3.0)
	Vec.rrect(self, Rect2(-w * 0.46, -h * 0.22, w * 0.92, h * 0.12), 8, dark)
	# arms
	for sgn in [-1.0, 1.0]:
		var ax: float = sgn * w * 0.5 - (0.0 if sgn > 0 else -0.0)
		Vec.rrect(self, Rect2(ax - w * 0.07, -h * 0.72, w * 0.14, h * 0.64), 24, Vec.shade(c, -0.04))
		Vec.rrect(self, Rect2(ax - w * 0.07, -h * 0.72, w * 0.14, h * 0.16), 24, Vec.shade(c, -0.12))
	# pillows + blanket
	Vec.fill(self, Vec.xform(Vec.rrect_pts(Rect2(-40, -40, 80, 80), 22), Vector2(-w * 0.32, -h * 0.58), -0.18, 1.0), accent_color)
	Vec.fill(self, Vec.xform(Vec.rrect_pts(Rect2(-34, -34, 68, 68), 18), Vector2(w * 0.3, -h * 0.56), 0.15, 1.0), CREAM)
	var blanket := PackedVector2Array([Vector2(w * 0.05, -h * 0.5), Vector2(w * 0.3, -h * 0.52), Vector2(w * 0.34, -h * 0.12), Vector2(w * 0.22, -h * 0.02), Vector2(w * 0.12, -h * 0.1)])
	Vec.fill(self, blanket, Color("b4553f"))
	for i in 3:
		var yy := -h * (0.42 - i * 0.12)
		draw_line(Vector2(w * 0.08 + i * 6, yy), Vector2(w * 0.31, yy - 2), Color("d97a5a"), 3.0)


func _coffee_table() -> void:
	var w := size.x
	var h := size.y
	Vec.ellipse(self, Vector2(0, -2), w * 0.5, 10, Color(0, 0, 0, 0.3))
	for x in [-w * 0.4, w * 0.4]:
		Vec.rrect(self, Rect2(x - 7, -h + 10, 14, h - 10), 3, WOOD_DARK)
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, 18), 6, WOOD)
	Vec.rrect(self, Rect2(-w * 0.5, -h + 14, w, 6), 3, WOOD_DARK)
	Vec.rrect(self, Rect2(-w * 0.42, -h * 0.4, w * 0.84, 8), 3, WOOD_DARK)
	# items: mugs, snack bowl, remote, a book
	var top := -h
	Vec.rrect(self, Rect2(-w * 0.36, top - 30, 24, 30), 4, CREAM)
	Vec.stroke(self, PackedVector2Array([Vector2(-w * 0.36 + 24, top - 24), Vector2(-w * 0.36 + 33, top - 20), Vector2(-w * 0.36 + 33, top - 10), Vector2(-w * 0.36 + 24, top - 7)]), CREAM, 4.0)
	Vec.rrect(self, Rect2(-w * 0.24, top - 26, 22, 26), 4, TEAL)
	var bowl := PackedVector2Array([Vector2(-10, top - 26), Vector2(70, top - 26), Vector2(56, top), Vector2(4, top)])
	Vec.fill(self, bowl, Color("c9704a"))
	for i in 5:
		Vec.circle(self, Vector2(6 + i * 13, top - 28 - (i % 2) * 5), 9, Color("e7c16a"))
	Vec.rrect(self, Rect2(w * 0.2, top - 8, 54, 8), 3, INK)
	Vec.rrect(self, Rect2(w * 0.3, top - 18, 70, 10), 2, Color("6c8fa3"))


func _floor_lamp() -> void:
	var h := size.y
	Vec.ellipse(self, Vector2(0, -6), 42, 9, METAL)
	Vec.line(self, Vector2(0, -8), Vector2(0, -h + 60), METAL, 6.0)
	var shade := PackedVector2Array([Vector2(-44, -h), Vector2(44, -h), Vector2(66, -h + 92), Vector2(-66, -h + 92)])
	Vec.glow(self, Vector2(0, -h + 120), 150, Color(1.6, 1.15, 0.6, 0.55), 0.7)
	Vec.fill(self, shade, Color("efd9b0"))
	Vec.fill(self, PackedVector2Array([Vector2(-66, -h + 82), Vector2(66, -h + 82), Vector2(66, -h + 92), Vector2(-66, -h + 92)]), Color("d9b98a"))
	# hot bulb (HDR -> bloom)
	Vec.ellipse(self, Vector2(0, -h + 96), 30, 7, Color(2.6, 1.75, 0.8))


func _bookshelf() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, h), 4, WOOD_DARK)
	Vec.rect(self, Rect2(-w * 0.5 + 10, -h + 10, w - 20, h - 20), Vec.shade(WOOD_DARK, 0.35))
	var shelves := 5
	var sh := (h - 20) / shelves
	var palette := [Color("8f4a3c"), Color("b88a45"), Color("4a5a6b"), Color("3f7a74"), Color("cfc4b2"), Color("5e4650"), Color("6f7a52"), Color("3b3f4a")]
	for s in shelves:
		var y := -h + 10 + (s + 1) * sh
		Vec.rect(self, Rect2(-w * 0.5 + 6, y - 8, w - 12, 10), WOOD)
		var x := -w * 0.5 + 16
		while x < w * 0.5 - 30:
			if rng.randf() < 0.12 and s != 0:
				# object instead of book
				var kindo := rng.randi() % 3
				if kindo == 0:
					Vec.rrect(self, Rect2(x, y - 8 - 46, 34, 46), 3, Color("a8b4b8"))
					Vec.rect(self, Rect2(x + 5, y - 8 - 41, 24, 30), Color("5f7a86"))
				elif kindo == 1:
					Vec.rrect(self, Rect2(x + 2, y - 8 - 22, 28, 22), 5, Color("c9704a"))
					for k in 3:
						Vec.ellipse(self, Vector2(x + 8 + k * 8, y - 8 - 32 - k * 4), 7, 12, Color("5f8a4f"), 0.4 * (k - 1))
				else:
					Vec.circle(self, Vector2(x + 16, y - 8 - 18), 16, Color("d9cbb8"))
				x += 44
				continue
			var bw := rng.randf_range(14, 26)
			var bh := rng.randf_range(sh * 0.55, sh * 0.82)
			var col: Color = palette[rng.randi() % palette.size()]
			if rng.randf() < 0.15:
				Vec.fill(self, Vec.xform(PackedVector2Array(Vec.rrect_pts(Rect2(0, -bh, bw, bh), 2)), Vector2(x + 4, y - 8), 0.22, 1.0), col)
				x += bw + 14
			else:
				Vec.rrect(self, Rect2(x, y - 8 - bh, bw, bh), 2, col)
				Vec.rect(self, Rect2(x + 3, y - 8 - bh + 10, bw - 6, 4), Vec.shade(col, 0.25))
				x += bw + 2


func _plant() -> void:
	var h := size.y
	var pot := PackedVector2Array([Vector2(-34, -70), Vector2(34, -70), Vector2(26, 0), Vector2(-26, 0)])
	Vec.ellipse(self, Vector2(0, -2), 36, 7, Color(0, 0, 0, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 9:
		var a := lerpf(-1.1, 1.1, float(i) / 8.0) + rng.randf_range(-0.12, 0.12)
		var l := rng.randf_range(h * 0.45, h * 0.85)
		var tip := Vector2(sin(a) * l * 0.6, -70 - cos(a) * l)
		var mid := Vector2(0, -70).lerp(tip, 0.55)
		Vec.ellipse(self, mid, l * 0.16, l * 0.4, Color("4e7a46") if i % 2 == 0 else Color("3f6a3c"), a)
	Vec.fill(self, pot, main_color)
	Vec.rect(self, Rect2(-36, -72, 72, 12), Vec.shade(main_color, 0.15))


func _frame() -> void:
	var w := size.x
	var h := size.y
	Vec.rrect(self, Rect2(-w * 0.5 - 4, -h * 0.5 + 6, w + 8, h + 4), 4, Color(0, 0, 0, 0.3))
	Vec.rrect(self, Rect2(-w * 0.5, -h * 0.5, w, h), 3, main_color)
	var inner := Rect2(-w * 0.5 + 10, -h * 0.5 + 10, w - 20, h - 20)
	Vec.rect(self, inner, CREAM)
	match label:
		"siblings":
			Vec.vgrad(self, inner, Color("8fc3d6"), Color("e8d39a"))
			Vec.rect(self, Rect2(inner.position.x, inner.end.y - inner.size.y * 0.25, inner.size.x, inner.size.y * 0.25), Color("d9b77a"))
			# two little figures: tall dark jacket + small yellow
			var base := inner.end.y - inner.size.y * 0.12
			var cx := inner.get_center().x
			Vec.capsule(self, Vector2(cx - 18, base - 10), Vector2(cx - 18, base - 52), 11, 13, Color("2e3947"))
			Vec.circle(self, Vector2(cx - 18, base - 66), 12, Color("c98f6b"))
			Vec.fill(self, Vec.ellipse_pts(Vector2(cx - 18, base - 74), 13, 7), Color("1c1820"))
			Vec.capsule(self, Vector2(cx + 14, base - 8), Vector2(cx + 14, base - 36), 10, 11, Color("e2a33b"))
			Vec.circle(self, Vector2(cx + 14, base - 48), 11, Color("d19a76"))
			Vec.fill(self, Vec.ellipse_pts(Vector2(cx + 14, base - 53), 12, 8), Color("2a1c1c"))
		"parents":
			Vec.vgrad(self, inner, Color("c9a27a"), Color("8a6a52"))
			var cx2 := inner.get_center().x
			for k in [-1.0, 1.0]:
				Vec.circle(self, Vector2(cx2 + k * 16, inner.get_center().y - 4), 13, Color("c98f6b"))
				Vec.capsule(self, Vector2(cx2 + k * 16, inner.end.y), Vector2(cx2 + k * 16, inner.get_center().y + 16), 15, 15, Color("6b4e57") if k < 0 else Color("4f6478"))
		_:
			Vec.vgrad(self, inner, Color("496b86"), Color("d98a5a"))
			Vec.fill(self, PackedVector2Array([Vector2(inner.position.x, inner.end.y), Vector2(inner.position.x + inner.size.x * 0.4, inner.position.y + inner.size.y * 0.4), Vector2(inner.end.x, inner.end.y)]), Color("2f4a5a"))


func _front_door() -> void:
	var w := size.x
	var h := size.y
	if label.ends_with("_open"):
		Vec.rect(self, Rect2(-w * 0.5 - 16, -h - 16, w + 32, h + 16), Vec.shade(CREAM, 0.15))
		Vec.vgrad(self, Rect2(-w * 0.5, -h, w, h), Color("0e0d12"), Color("201c22"))
		Vec.fill(self, PackedVector2Array([Vector2(w * 0.5, -h), Vector2(w * 0.5 + w * 0.32, -h + 30), Vector2(w * 0.5 + w * 0.32, -10), Vector2(w * 0.5, 0)]), Vec.shade(main_color, 0.15))
		Vec.circle(self, Vector2(w * 0.5 + w * 0.26, -h * 0.47), 9, Color("c9a250"))
		Vec.rrect(self, Rect2(-28, -h + 18, 56, 22), 4, Color("c9a250"))
		_door_number(label.trim_suffix("_open"), h)
		return
	Vec.rect(self, Rect2(-w * 0.5 - 16, -h - 16, w + 32, h + 16), Vec.shade(CREAM, 0.15))
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), main_color)
	for i in 2:
		Vec.stroke(self, Vec.rrect_pts(Rect2(-w * 0.36, -h + 40 + i * h * 0.45, w * 0.72, h * 0.36), 4), Vec.shade(main_color, 0.2), 4.0)
	# number plate + peephole
	Vec.rrect(self, Rect2(-28, -h + 18, 56, 22), 4, Color("c9a250"))
	_door_number(label, h)
	Vec.circle(self, Vector2(0, -h * 0.68), 6, METAL)
	# handle, deadbolt, chain
	var hx := w * 0.36
	Vec.circle(self, Vector2(hx, -h * 0.47), 13, Color("c9a250"))
	Vec.rrect(self, Rect2(hx - 22, -h * 0.47 - 4, 26, 8), 4, Color("c9a250"))
	Vec.circle(self, Vector2(hx, -h * 0.57), 10, Color("b08a3e"))
	Vec.rect(self, Rect2(hx - 2, -h * 0.57 - 7, 4, 14), Vec.shade(Color("b08a3e"), 0.4))
	var chain := Vec.qbez(Vector2(hx - 4, -h * 0.66), Vector2(hx + 14, -h * 0.6), Vector2(hx + 26, -h * 0.66), 6)
	Vec.stroke(self, chain, Color("b5b5b5"), 3.0)
	# light under the door from the corridor
	Vec.rect(self, Rect2(-w * 0.5, -4, w, 4), Color(1.4, 1.2, 0.8, 0.8))


func _shoe_rack() -> void:
	var w := size.x
	Vec.rrect(self, Rect2(-w * 0.5, -70, w, 70), 3, WOOD)
	Vec.rect(self, Rect2(-w * 0.5 + 6, -40, w - 12, 5), WOOD_DARK)
	var cols := [Color("e8e4dc"), Color("4e3626"), Color("b4553f"), Color("2bb3a7")]
	for i in 4:
		var x := -w * 0.4 + i * w * 0.22
		Vec.rrect(self, Rect2(x, -90 + (i % 2) * 48, 44, 18), 8, cols[i])


func _desk() -> void:
	var w := size.x
	var h := size.y
	Vec.ellipse(self, Vector2(0, -2), w * 0.5, 10, Color(0, 0, 0, 0.3))
	Vec.rect(self, Rect2(-w * 0.5 + 8, -h, 14, h), WOOD_DARK)
	Vec.rrect(self, Rect2(w * 0.12, -h + 16, w * 0.36, h - 16), 3, WOOD)
	for i in 3:
		Vec.rect(self, Rect2(w * 0.14, -h + 30 + i * (h - 30) / 3.0, w * 0.32, 3), WOOD_DARK)
		Vec.rrect(self, Rect2(w * 0.27, -h + 44 + i * (h - 30) / 3.0, 26, 6), 3, METAL)
	Vec.rrect(self, Rect2(-w * 0.52, -h - 16, w * 1.04, 20), 4, Color("8a5f42"))
	var top := -h - 16
	# ham radio receiver
	Vec.rrect(self, Rect2(-w * 0.38, top - 74, 150, 74), 6, Color("2f3238"))
	var lcd := Rect2(-w * 0.38 + 12, top - 62, 76, 26)
	Vec.rrect(self, lcd, 3, Color(0.3, 1.25, 0.75))
	Vec.glow(self, lcd.get_center(), 90, Color(0.3, 1.0, 0.7, 0.25))
	# moving signal bars on the LCD
	for i in 8:
		var bh := (0.3 + 0.7 * absf(sin(_t * 3.0 + i * 0.9))) * 18.0
		Vec.rect(self, Rect2(lcd.position.x + 6 + i * 8, lcd.end.y - 4 - bh, 5, bh), Color(0.05, 0.2, 0.12))
	for i in 3:
		Vec.circle(self, Vector2(-w * 0.38 + 112, top - 54 + i * 0), 0.1, INK)
	Vec.circle(self, Vector2(-w * 0.38 + 116, top - 46), 15, METAL)
	Vec.circle(self, Vector2(-w * 0.38 + 116, top - 46), 6, Color("1a1b1f"))
	for i in 4:
		Vec.circle(self, Vector2(-w * 0.38 + 20 + i * 18, top - 18), 5, accent_color if i == 1 else METAL)
	Vec.line(self, Vector2(-w * 0.38 + 140, top - 74), Vector2(-w * 0.38 + 168, top - 200), METAL, 4.0)
	# laptop
	var lp := Vector2(w * 0.1, top)
	Vec.fill(self, PackedVector2Array([lp + Vector2(0, 0), lp + Vector2(120, 0), lp + Vector2(112, -6), lp + Vector2(6, -6)]), Color("9aa3ad"))
	Vec.fill(self, PackedVector2Array([lp + Vector2(14, -6), lp + Vector2(108, -6), lp + Vector2(122, -84), lp + Vector2(24, -84)]), Color("7d8690"))
	Vec.fill(self, PackedVector2Array([lp + Vector2(20, -12), lp + Vector2(103, -12), lp + Vector2(115, -78), lp + Vector2(29, -78)]), Color(0.2, 0.45, 0.7))
	# waveform on laptop
	var wave := PackedVector2Array()
	for i in 20:
		var x := float(i) / 19.0
		wave.append(lp + Vector2(lerpf(28.0, 108.0, x), -44 + sin(_t * 6.0 + i * 1.3) * 10.0 * (0.4 + 0.6 * Vec.hash01(i))))
	Vec.stroke(self, wave, Color(0.4, 1.3, 1.2), 2.0)
	# soldering iron + parts
	Vec.rrect(self, Rect2(w * 0.36, top - 20, 40, 20), 4, accent_color)
	Vec.line(self, Vector2(w * 0.38, top - 20), Vector2(w * 0.46, top - 60), METAL, 5.0)
	for i in 6:
		Vec.circle(self, Vector2(-w * 0.05 + i * 11, top - 4), 3.0, [Color("c0503a"), TEAL, Color("e3a03c")][i % 3])


func _chair() -> void:
	var h := size.y
	Vec.ellipse(self, Vector2(0, -4), 40, 8, Color(0, 0, 0, 0.3))
	Vec.line(self, Vector2(0, -6), Vector2(0, -h * 0.45), METAL, 8.0)
	for k in [-1.0, 1.0]:
		Vec.line(self, Vector2(0, -8), Vector2(k * 36, -2), METAL, 6.0)
		Vec.circle(self, Vector2(k * 36, -4), 6, INK)
	Vec.rrect(self, Rect2(-44, -h * 0.5, 88, 22), 8, main_color)
	Vec.rrect(self, Rect2(-46, -h, 22, h * 0.52), 9, Vec.shade(main_color, 0.12))


func _fridge() -> void:
	var w := size.x
	var h := size.y
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, h), 14, Color("d9dde0"))
	Vec.rect(self, Rect2(-w * 0.5, -h * 0.66, w, 5), Color("a9b0b5"))
	Vec.rrect(self, Rect2(w * 0.3, -h * 0.62, 10, 90), 5, Color("9aa1a6"))
	Vec.rrect(self, Rect2(w * 0.3, -h * 0.94, 10, 60), 5, Color("9aa1a6"))
	# magnets + kid drawing + emergency number list
	Vec.rect(self, Rect2(-w * 0.36, -h * 0.58, 66, 80), Color("f4efe4"))
	Vec.stroke(self, PackedVector2Array([Vector2(-w * 0.33, -h * 0.5), Vector2(-w * 0.25, -h * 0.55), Vector2(-w * 0.17, -h * 0.49)]), Color("2bb3a7"), 3.0)
	Vec.circle(self, Vector2(-w * 0.3, -h * 0.4), 9, Color("e3a03c"))
	Vec.rect(self, Rect2(-w * 0.1, -h * 0.9, 56, 70), Color("fff8e6"))
	for i in 5:
		Vec.rect(self, Rect2(-w * 0.08, -h * 0.88 + 12 + i * 11, 40 - (i % 2) * 12, 3), Color("8a8a8a"))
	for p in [Vector2(-w * 0.32, -h * 0.6), Vector2(-w * 0.07, -h * 0.91)]:
		Vec.circle(self, p, 6, Color("c0503a"))
	if label == "rules":
		# the City Emergency Notice, pinned up for good
		var r := Rect2(-w * 0.12, -h * 0.6, w * 0.5, 120)
		Vec.rect(self, r, Color("f6f1e4"))
		Vec.rect(self, Rect2(r.position, Vector2(r.size.x, 18)), Color("b8322a"))
		for i in 6:
			Vec.circle(self, r.position + Vector2(12, 32 + i * 14), 4, Color("b8322a"))
			Vec.rect(self, Rect2(r.position + Vector2(22, 30 + i * 14), Vector2(r.size.x * (0.5 + 0.08 * (i % 3)), 3)), Color("6a6a6a"))
		Vec.circle(self, r.position + Vector2(r.size.x * 0.5, 2), 6, Color("2bb3a7"))


func _counter() -> void:
	var w := size.x
	var h := size.y
	# upper cabinets on the wall
	Vec.rect(self, Rect2(-w * 0.5, -h - 330, w, 160), Vec.shade(main_color, 0.05))
	for i in 3:
		Vec.stroke(self, Vec.rrect_pts(Rect2(-w * 0.5 + 10 + i * w / 3.0, -h - 320, w / 3.0 - 20, 140), 4), Vec.shade(main_color, 0.2), 3.0)
	# backsplash tiles
	Vec.rect(self, Rect2(-w * 0.5, -h - 170, w, 170), Color("c9cfc8"))
	for i in int(w / 40.0):
		draw_line(Vector2(-w * 0.5 + i * 40.0, -h - 170), Vector2(-w * 0.5 + i * 40.0, -h), Color("aeb5ad"), 2.0)
	for j in 4:
		draw_line(Vector2(-w * 0.5, -h - 170 + j * 42.0), Vector2(w * 0.5, -h - 170 + j * 42.0), Color("aeb5ad"), 2.0)
	# base cabinets
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), main_color)
	for i in 3:
		Vec.stroke(self, Vec.rrect_pts(Rect2(-w * 0.5 + 10 + i * w / 3.0, -h + 34, w / 3.0 - 20, h - 50), 4), Vec.shade(main_color, 0.2), 3.0)
		Vec.rrect(self, Rect2(-w * 0.5 + i * w / 3.0 + w / 6.0 - 16, -h + 50, 32, 6), 3, METAL)
	Vec.rrect(self, Rect2(-w * 0.52, -h - 6, w * 1.04, 22), 3, Color("e7e1d6"))
	# kettle, microwave, dish rack
	var top := -h - 6
	Vec.rrect(self, Rect2(-w * 0.42, top - 90, 150, 90), 8, Color("3a3d44"))
	Vec.rrect(self, Rect2(-w * 0.42 + 10, top - 80, 100, 70), 4, Color("1b1d22"))
	Vec.rect(self, Rect2(-w * 0.42 + 120, top - 70, 18, 8), Color(0.3, 1.2, 0.6))
	Vec.ellipse(self, Vector2(w * 0.12, top - 34), 30, 34, accent_color)
	Vec.rrect(self, Rect2(w * 0.12 - 20, top - 72, 40, 8), 4, Vec.shade(accent_color, 0.3))
	for i in 4:
		Vec.ellipse(self, Vector2(w * 0.3 + i * 16, top - 30), 7, 28, Color("e9dfcf"))


func _wall_clock() -> void:
	var r := size.x * 0.5
	Vec.circle(self, Vector2(0, 4), r + 4, Color(0, 0, 0, 0.3))
	Vec.circle(self, Vector2.ZERO, r, main_color)
	Vec.circle(self, Vector2.ZERO, r - 8, CREAM)
	for i in 12:
		var a := TAU * i / 12.0
		Vec.line(self, Vector2.from_angle(a) * (r - 14), Vector2.from_angle(a) * (r - 20), INK, 3.0)
	# 7:42 and ticking
	var minutes := 42.0 + _t / 60.0
	var hours := 7.0 + minutes / 60.0
	Vec.line(self, Vector2.ZERO, Vector2.from_angle(hours / 12.0 * TAU - PI / 2) * r * 0.45, INK, 5.0)
	Vec.line(self, Vector2.ZERO, Vector2.from_angle(minutes / 60.0 * TAU - PI / 2) * r * 0.7, INK, 3.0)
	Vec.line(self, Vector2.ZERO, Vector2.from_angle(floor(_t) / 60.0 * TAU - PI / 2) * r * 0.75, Color("c0503a"), 1.5)
	Vec.circle(self, Vector2.ZERO, 4, INK)


func _radiator() -> void:
	var w := size.x
	var h := size.y
	for i in int(w / 22.0):
		Vec.rrect(self, Rect2(-w * 0.5 + i * 22, -h, 18, h - 10), 8, Color("cfd2cf"))
	Vec.rect(self, Rect2(-w * 0.5, -h + 14, w - 4, 6), Color("b4b8b4"))


func _rug() -> void:
	var w := size.x
	var h := size.y
	var pts := PackedVector2Array([Vector2(-w * 0.42, -h), Vector2(w * 0.42, -h), Vector2(w * 0.5, 0), Vector2(-w * 0.5, 0)])
	Vec.fill(self, pts, main_color)
	var inner := PackedVector2Array([Vector2(-w * 0.36, -h * 0.82), Vector2(w * 0.36, -h * 0.82), Vector2(w * 0.42, -h * 0.16), Vector2(-w * 0.42, -h * 0.16)])
	Vec.stroke(self, inner + PackedVector2Array([inner[0]]), accent_color, 4.0)
	for i in 5:
		var x := lerpf(-w * 0.3, w * 0.3, float(i) / 4.0)
		Vec.fill(self, PackedVector2Array([Vector2(x, -h * 0.66), Vector2(x + 16, -h * 0.5), Vector2(x, -h * 0.34), Vector2(x - 16, -h * 0.5)]), accent_color)


func _coat_hooks() -> void:
	var w := size.x
	Vec.rrect(self, Rect2(-w * 0.5, -10, w, 20), 4, WOOD)
	for i in 3:
		var x := -w * 0.32 + i * w * 0.32
		Vec.circle(self, Vector2(x, 0), 6, METAL)
	# June's yellow raincoat + backpack
	var coat := PackedVector2Array([Vector2(-w * 0.32 - 8, 4), Vector2(-w * 0.32 + 8, 4), Vector2(-w * 0.32 + 40, 170), Vector2(-w * 0.32 - 40, 170)])
	Vec.fill(self, coat, Color("e2c13b"))
	Vec.line(self, Vector2(-w * 0.32, 20), Vector2(-w * 0.32, 168), Color("c4a12a"), 3.0)
	Vec.rrect(self, Rect2(w * 0.32 - 36, 10, 72, 96), 14, Color("4f6478"))
	Vec.rrect(self, Rect2(w * 0.32 - 26, 46, 52, 36), 8, Color("3f5266"))
	Vec.stroke(self, PackedVector2Array([Vector2(w * 0.32 - 20, 12), Vector2(w * 0.32, -2), Vector2(w * 0.32 + 20, 12)]), Color("3f5266"), 4.0)


func _pinboard() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h * 0.5, w, h), WOOD)
	Vec.rect(self, Rect2(-w * 0.5 + 8, -h * 0.5 + 8, w - 16, h - 16), Color("b88b5a"))
	var notes := [[Vector2(-0.3, -0.2), Color("fff1a8")], [Vector2(0.05, -0.25), Color("bfe6de")], [Vector2(0.28, 0.1), Color("fff8e6")], [Vector2(-0.18, 0.2), Color("f6c4a8")]]
	for n in notes:
		var p: Vector2 = n[0] * size
		Vec.fill(self, Vec.xform(PackedVector2Array([Vector2(-30, -26), Vector2(30, -26), Vector2(30, 26), Vector2(-30, 26)]), p, (n[0].x) * 0.4, 1.0), n[1])
		for k in 3:
			Vec.line(self, p + Vector2(-20, -10 + k * 9), p + Vector2(16 - k * 6, -10 + k * 9), Color("6b6b6b"), 2.0)
		Vec.circle(self, p + Vector2(0, -22), 4, Color("c0503a"))
	# string between notes (June's frequency hunt)
	Vec.stroke(self, PackedVector2Array([notes[0][0] * size, notes[1][0] * size, notes[2][0] * size]), Color("c0503a"), 1.5)


func _switch_panel() -> void:
	Vec.rrect(self, Rect2(-46, -70, 92, 140), 6, Color("d9d6cf"))
	Vec.rrect(self, Rect2(-34, -56, 68, 40), 4, Color("2a2d33"))
	Vec.rect(self, Rect2(-28, -50, 56, 28), Color(0.25, 0.4, 0.55))
	for i in 4:
		Vec.rrect(self, Rect2(-30 + (i % 2) * 34, 0 + (i / 2) * 30, 26, 22), 4, Color("b9b4aa"))


func _doorway() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5 - 14, -h - 14, w + 28, h + 14), Vec.shade(CREAM, 0.12))
	Vec.vgrad(self, Rect2(-w * 0.5, -h, w, h), Color("1a1820"), Color("2b2630"))


func _side_table() -> void:
	var w := size.x
	var h := size.y
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, 14), 4, WOOD)
	Vec.rect(self, Rect2(-w * 0.4, -h + 14, w * 0.8, h - 14), Vec.shade(WOOD, 0.2))
	Vec.rrect(self, Rect2(-w * 0.32, -h + 40, w * 0.64, 8), 3, Color("c9a250"))
	# phone charger + photo
	Vec.rrect(self, Rect2(-w * 0.3, -h - 46, 40, 46), 3, Color("e9dfcf"))
	Vec.rect(self, Rect2(-w * 0.3 + 5, -h - 41, 30, 30), Color("8fc3d6"))


func _shelf_wall() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -6, w, 12), WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := -w * 0.45
	while x < w * 0.4:
		var k := rng.randi() % 3
		if k == 0:
			Vec.rrect(self, Rect2(x, -46, 28, 40), 4, Color("e9dfcf"))
			Vec.circle(self, Vector2(x + 14, -56), 14, Color("5f8a4f"))
			x += 40
		elif k == 1:
			for i in 3:
				Vec.rrect(self, Rect2(x + i * 16, -50, 14, 44), 2, [Color("b4553f"), Color("4f6478"), Color("e3a03c")][i])
			x += 56
		else:
			Vec.rrect(self, Rect2(x, -30, 44, 24), 4, Color("2bb3a7"))
			x += 54


func _door_number(t: String, h: float) -> void:
	if t == "":
		return
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-18, -h + 37), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("2a2018"))


func _ceiling_light() -> void:
	var on := 1.0
	if seed_value > 1:
		var ph := fposmod(_t * 0.7 + seed_value, 4.0)
		on = 0.15 if (ph < 0.12 or (ph > 0.3 and ph < 0.36)) else 1.0
	Vec.rect(self, Rect2(-size.x * 0.5, 0, size.x, 14), Color("cfd2cf"))
	Vec.rect(self, Rect2(-size.x * 0.45, 14, size.x * 0.9, 8), Color(1.9 * on + 0.3, 1.9 * on + 0.3, 1.7 * on + 0.3))
	if on > 0.5:
		Vec.glow(self, Vector2(0, 40), size.x * 1.2, Color(1.0, 0.98, 0.85, 0.22), 0.6)


func _floor_sign() -> void:
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	Vec.rect(self, Rect2(-120, -150, 240, 300), Color(main_color, 0.9))
	draw_string(f, Vector2(-70, 90), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 220, accent_color)
	draw_string(f, Vector2(-100, -104), "FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, accent_color)


func _stair_number() -> void:
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	draw_string(f, Vector2(0, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y), Color(accent_color, 0.75))
	Vec.rect(self, Rect2(0, 14, size.y * 0.5 * label.length(), 10), Color(accent_color, 0.6))


func _notice_board() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h * 0.5, w, h), WOOD_DARK)
	Vec.rect(self, Rect2(-w * 0.5 + 8, -h * 0.5 + 8, w - 16, h - 16), Color("c7a774"))
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	Vec.rect(self, Rect2(-w * 0.4, -h * 0.4, w * 0.5, h * 0.5), Color("fff8e6"))
	draw_string(f, Vector2(-w * 0.38, -h * 0.4 + 30), label if label != "" else "NOTICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("b8261d"))
	for k in 4:
		Vec.rect(self, Rect2(-w * 0.38, -h * 0.4 + 44 + k * 14, w * 0.42 - (k % 2) * 30, 4), Color("8a8a8a"))
	Vec.fill(self, Vec.xform(PackedVector2Array([Vector2(-30, -24), Vector2(30, -24), Vector2(30, 24), Vector2(-30, 24)]), Vector2(w * 0.27, h * 0.12), 0.15, 1.0), Color("bfe6de"))


func _elevator() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5 - 20, -h - 20, w + 40, h + 20), Color("8f9497"))
	Vec.rect(self, Rect2(-w * 0.5, -h, w * 0.5 - 2, h), Color("b9bec1"))
	Vec.rect(self, Rect2(2, -h, w * 0.5 - 2, h), Color("b9bec1"))
	Vec.rect(self, Rect2(-w * 0.35, -h * 0.6, w * 0.7, 90), Color("f3eee6"))
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	draw_string(f, Vector2(-w * 0.32, -h * 0.6 + 40), "OUT OF", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("b8261d"))
	draw_string(f, Vector2(-w * 0.32, -h * 0.6 + 78), "ORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("b8261d"))
	Vec.rrect(self, Rect2(w * 0.5 + 30, -h * 0.55, 30, 70), 6, Color("3a3d44"))
	Vec.circle(self, Vector2(w * 0.5 + 45, -h * 0.55 + 20), 8, Color(1.5, 0.4, 0.3))


func _bicycle() -> void:
	for x in [-60.0, 60.0]:
		draw_arc(Vector2(x, -46), 44, 0, TAU, 32, Color("2a2c31"), 6.0, true)
		draw_arc(Vector2(x, -46), 6, 0, TAU, 12, Color("2a2c31"), 4.0, true)
	var c := main_color
	Vec.line(self, Vector2(-60, -46), Vector2(-10, -46), c, 6.0)
	Vec.line(self, Vector2(-10, -46), Vector2(-30, -110), c, 6.0)
	Vec.line(self, Vector2(-30, -110), Vector2(40, -105), c, 6.0)
	Vec.line(self, Vector2(40, -105), Vector2(-10, -46), c, 6.0)
	Vec.line(self, Vector2(40, -105), Vector2(60, -46), c, 6.0)
	Vec.line(self, Vector2(-60, -46), Vector2(-30, -110), c, 6.0)
	Vec.rrect(self, Rect2(-46, -126, 34, 10), 4, INK)
	Vec.line(self, Vector2(40, -105), Vector2(46, -136), Color("2a2c31"), 5.0)
	Vec.line(self, Vector2(32, -138), Vector2(62, -138), Color("2a2c31"), 5.0)


func _trash_bags() -> void:
	Vec.ellipse(self, Vector2(-30, -40), 46, 42, Color("1d1f22"))
	Vec.ellipse(self, Vector2(30, -34), 40, 36, Color("272a2e"))
	Vec.fill(self, PackedVector2Array([Vector2(-34, -82), Vector2(-26, -82), Vector2(-22, -100), Vector2(-38, -100)]), Color("1d1f22"))
	Vec.line(self, Vector2(-50, -50), Vector2(-20, -30), Color(1, 1, 1, 0.12), 3.0)


func _storage_box() -> void:
	var w := size.x
	var h := size.y
	Vec.ellipse(self, Vector2(0, -2), w * 0.55, 8, Color(0, 0, 0, 0.3))
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, h), 6, WOOD)
	Vec.rrect(self, Rect2(-w * 0.52, -h - 8, w * 1.04, 22), 6, Vec.shade(WOOD, -0.1))
	Vec.rect(self, Rect2(-w * 0.5, -h * 0.55, w, 6), WOOD_DARK)
	Vec.rrect(self, Rect2(-14, -h + 6, 28, 22), 4, Color("c9a250"))


func _extinguisher() -> void:
	Vec.rrect(self, Rect2(-22, -130, 44, 110), 18, Color("c0342a"))
	Vec.rect(self, Rect2(-12, -150, 24, 22), Color("2a2c31"))
	Vec.stroke(self, Vec.qbez(Vector2(10, -142), Vector2(40, -120), Vector2(26, -70), 6), Color("2a2c31"), 5.0)
	Vec.rect(self, Rect2(-16, -100, 32, 30), Color("f3eee6"))


func _roof_hut() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), main_color)
	Vec.rect(self, Rect2(-w * 0.55, -h - 24, w * 1.1, 30), Vec.shade(main_color, 0.25))
	# door (label "open" shows it ajar)
	var dw := 170.0
	var dh := 480.0
	if label == "open":
		Vec.rect(self, Rect2(w * 0.5 - dw - 40, -dh, dw, dh), Color("0c0b0f"))
		Vec.fill(self, PackedVector2Array([Vector2(w * 0.5 - 40, -dh), Vector2(w * 0.5 + 30, -dh + 20), Vector2(w * 0.5 + 30, -6), Vector2(w * 0.5 - 40, 0)]), Color("5d6266"))
	else:
		Vec.rect(self, Rect2(w * 0.5 - dw - 40, -dh, dw, dh), Color("5d6266"))
		Vec.circle(self, Vector2(w * 0.5 - 70, -dh * 0.5), 9, Color("c9a250"))
		if label == "barred":
			for k in 3:
				var yy := -dh * 0.5 + (k - 1) * 22.0
				Vec.line(self, Vector2(w * 0.5 - dw - 60, yy), Vector2(w * 0.5 - 20, yy + 6), Color("c0342a"), 9.0)
			Vec.rect(self, Rect2(w * 0.5 - dw - 66, -dh * 0.5 - 40, 16, 80), Color("8a8f92"))
	Vec.rect(self, Rect2(w * 0.5 - dw - 40, -dh - 40, dw, 26), Color("2e7d4f"))
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(w * 0.5 - dw - 24, -dh - 20), "EXIT · ROOF", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	Vec.glow(self, Vector2(w * 0.5 - dw * 0.5 - 40, -dh - 70), 120, Color(1.2, 1.0, 0.7, 0.35))
	Vec.rect(self, Rect2(w * 0.5 - dw * 0.5 - 70, -dh - 80, 60, 14), Color(1.8, 1.6, 1.2))


func _ac_unit() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), Color("9aa1a4"))
	Vec.rect(self, Rect2(-w * 0.5, -h, w, 12), Color("b6bcbf"))
	var c := Vector2(-w * 0.18, -h * 0.5)
	Vec.circle(self, c, h * 0.36, Color("6c7376"))
	for i in 4:
		var a := _t * 8.0 + i * PI * 0.5
		Vec.line(self, c, c + Vector2.from_angle(a) * h * 0.32, Color("3a3f42"), 8.0)
	for i in 6:
		Vec.rect(self, Rect2(w * 0.12, -h + 24 + i * 16, w * 0.32, 6), Color("7c8386"))


func _water_tank() -> void:
	var w := size.x
	var h := size.y
	for x in [-w * 0.35, w * 0.35]:
		Vec.line(self, Vector2(x, 0), Vector2(x * 0.8, -h * 0.4), Color("3a3d44"), 8.0)
	Vec.line(self, Vector2(-w * 0.35, -h * 0.2), Vector2(w * 0.35, -h * 0.2), Color("3a3d44"), 5.0)
	Vec.rrect(self, Rect2(-w * 0.45, -h, w * 0.9, h * 0.62), 14, main_color)
	for i in 4:
		Vec.rect(self, Rect2(-w * 0.45, -h + 20 + i * h * 0.14, w * 0.9, 5), Vec.shade(main_color, 0.2))
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.48, -h), Vector2(0, -h - 50), Vector2(w * 0.48, -h)]), Vec.shade(main_color, 0.3))


func _roof_rail() -> void:
	var w := size.x
	Vec.line(self, Vector2(0, -120), Vector2(w, -120), Color("8a8f92"), 6.0)
	Vec.line(self, Vector2(0, -60), Vector2(w, -60), Color("8a8f92"), 4.0)
	var x := 0.0
	while x <= w:
		Vec.line(self, Vector2(x, 0), Vector2(x, -120), Color("7a7f82"), 5.0)
		x += 120.0


func _small_window() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5 - 12, -h - 12, w + 24, h + 24), Color("d9d2c5"))
	Vec.vgrad(self, Rect2(-w * 0.5, -h, w, h), Color("0c1222") if seed_value != 2 else Color("8fb0c8"), Color("3a2a2e") if seed_value != 2 else Color("e0c9a6"))
	for i in 6:
		var bx := -w * 0.5 + i * w / 6.0
		var bh := h * (0.3 + Vec.hash01(i + seed_value) * 0.4)
		Vec.rect(self, Rect2(bx, -bh, w / 6.0 - 4, bh), Color("141824") if seed_value != 2 else Color("8a8f98"))
	Vec.rect(self, Rect2(-4, -h, 8, h), Color("d9d2c5"))


func _debris() -> void:
	Vec.fill(self, PackedVector2Array([Vector2(-80, 0), Vector2(-60, -30), Vector2(-10, -24), Vector2(10, -50), Vector2(60, -36), Vector2(90, 0)]), Color("6b6867"))
	Vec.rect(self, Rect2(-40, -70, 120, 14), WOOD)
	Vec.circle(self, Vector2(40, -20), 14, Color("5a5756"))


func _bag() -> void:
	Vec.rrect(self, Rect2(-40, -60, 80, 60), 14, main_color)
	Vec.rrect(self, Rect2(-28, -40, 56, 26), 8, Vec.shade(main_color, 0.15))
	Vec.stroke(self, Vec.qbez(Vector2(-24, -60), Vector2(0, -90), Vector2(24, -60), 6), Vec.shade(main_color, 0.2), 5.0)


func _helipad() -> void:
	var w := size.x
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.42, -40), Vector2(-w * 0.42, -40)]), Color(0.9, 0.86, 0.3, 0.18))
	Vec.stroke(self, PackedVector2Array([Vector2(-w * 0.46, -2), Vector2(w * 0.46, -2), Vector2(w * 0.39, -38), Vector2(-w * 0.39, -38), Vector2(-w * 0.46, -2)]), Color(0.95, 0.9, 0.4, 0.7), 4.0)
	Vec.fill(self, PackedVector2Array([Vector2(-60, -6), Vector2(-40, -6), Vector2(-36, -34), Vector2(-54, -34)]), Color(0.95, 0.95, 0.92, 0.8))
	Vec.fill(self, PackedVector2Array([Vector2(40, -6), Vector2(60, -6), Vector2(54, -34), Vector2(36, -34)]), Color(0.95, 0.95, 0.92, 0.8))
	Vec.fill(self, PackedVector2Array([Vector2(-44, -18), Vector2(44, -18), Vector2(43, -24), Vector2(-43, -24)]), Color(0.95, 0.95, 0.92, 0.8))


func _tent() -> void:
	var w := size.x
	var h := size.y
	var c := main_color
	Vec.ellipse(self, Vector2(0, -2), w * 0.55, 12, Color(0, 0, 0, 0.3))
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.42, -h * 0.7), Vector2(0, -h), Vector2(w * 0.42, -h * 0.7), Vector2(w * 0.5, 0)]), c)
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.42, -h * 0.7), Vector2(-w * 0.2, -h * 0.85), Vector2(-w * 0.26, 0)]), Vec.shade(c, 0.15))
	# open flap / doorway
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.14, 0), Vector2(0, -h * 0.62), Vector2(w * 0.14, 0)]), Color("1a1714"))
	Vec.line(self, Vector2(0, -h), Vector2(0, -h - 30), Color("3a3d44"), 5.0)
	if label != "":
		Vec.rect(self, Rect2(-w * 0.3, -h * 0.82, w * 0.6, 40), Color("f1ece2"))
		draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.27, -h * 0.82 + 31), label, HORIZONTAL_ALIGNMENT_LEFT, w * 0.54, 28, Color("b8261d") if label.begins_with("MED") else Color("23251c"))
	for k in [-0.5, 0.5]:
		Vec.line(self, Vector2(w * k, 0), Vector2(w * k * 1.2, 14), Color(0.9, 0.9, 0.85, 0.5), 2.0)


func _fence() -> void:
	var w := size.x
	var h := size.y
	var broken := label == "broken"
	var x := 0.0
	while x <= w:
		var lean := (x / w - 0.5) * 0.5 if broken else 0.0
		Vec.line(self, Vector2(x, 0), Vector2(x + lean * h, -h), Color("6c7073"), 6.0)
		x += 160.0
	if not broken:
		var y := -h
		while y < 0:
			Vec.line(self, Vector2(0, y), Vector2(w, y), Color(0.75, 0.78, 0.8, 0.18), 2.0)
			y += 24.0
		var gx := 0.0
		while gx < w:
			Vec.line(self, Vector2(gx, 0), Vector2(gx + 24, -h), Color(0.75, 0.78, 0.8, 0.12), 1.5)
			Vec.line(self, Vector2(gx + 24, 0), Vector2(gx, -h), Color(0.75, 0.78, 0.8, 0.12), 1.5)
			gx += 24.0
		Vec.stroke(self, Vec.qbez(Vector2(0, -h - 10), Vector2(w * 0.5, -h - 30), Vector2(w, -h - 10), 16), Color("8a8f92"), 2.0)
	else:
		Vec.fill(self, PackedVector2Array([Vector2(w * 0.1, 0), Vector2(w * 0.9, 0), Vector2(w * 0.7, -h * 0.25), Vector2(w * 0.2, -h * 0.35)]), Color(0.75, 0.78, 0.8, 0.15))


func _floodlight() -> void:
	var h := size.y
	var on := seed_value != 0
	Vec.line(self, Vector2(-30, 0), Vector2(-8, -h), Color("4a4d52"), 7.0)
	Vec.line(self, Vector2(30, 0), Vector2(8, -h), Color("4a4d52"), 7.0)
	for k in 5:
		var y := -h * (k + 1) / 6.0
		Vec.line(self, Vector2(-30 + 22 * (k + 1) / 6.0, y), Vector2(30 - 22 * (k + 1) / 6.0, y), Color("4a4d52"), 3.0)
	Vec.rect(self, Rect2(-70, -h - 50, 140, 50), Color("2a2c31"))
	for i in 3:
		Vec.rect(self, Rect2(-62 + i * 44, -h - 44, 36, 36), Color(3.0, 2.8, 2.4) if on else Color(0.4, 0.4, 0.38))
	if on:
		Vec.glow(self, Vector2(0, -h - 25), 260, Color(1.2, 1.15, 1.0, 0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(-60, -h), Vector2(60, -h), Vector2(420, 0), Vector2(-420, 0)]), Color(1, 1, 0.9, 0.05))


func _crate() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), Color("6b5a3a"))
	Vec.stroke(self, PackedVector2Array([Vector2(-w * 0.5, -h), Vector2(w * 0.5, 0)]), Color("4b3e28"), 5.0)
	Vec.stroke(self, Vec.rrect_pts(Rect2(-w * 0.5 + 4, -h + 4, w - 8, h - 8), 2), Color("4b3e28"), 4.0)
	if label != "":
		draw_string(preload("res://assets/fonts/ShareTechMono-Regular.ttf"), Vector2(-w * 0.4, -h * 0.45), label, HORIZONTAL_ALIGNMENT_LEFT, w * 0.8, 20, Color("e9dfcf"))


func _truck() -> void:
	var w := size.x
	var c := main_color
	Vec.ellipse(self, Vector2(0, -2), w * 0.52, 14, Color(0, 0, 0, 0.35))
	# cargo bed with canvas
	Vec.rrect(self, Rect2(-w * 0.5, -330, w * 0.66, 230), 18, Vec.shade(c, -0.05))
	for k in 4:
		Vec.line(self, Vector2(-w * 0.5 + 40 + k * w * 0.16, -326), Vector2(-w * 0.5 + 40 + k * w * 0.16, -104), Vec.shade(c, 0.2), 3.0)
	Vec.rect(self, Rect2(-w * 0.5, -110, w * 0.66, 30), Vec.shade(c, 0.25))
	# cab
	Vec.fill(self, PackedVector2Array([Vector2(w * 0.17, -80), Vector2(w * 0.17, -280), Vector2(w * 0.36, -280), Vector2(w * 0.48, -170), Vector2(w * 0.5, -80)]), c)
	Vec.fill(self, PackedVector2Array([Vector2(w * 0.24, -260), Vector2(w * 0.35, -260), Vector2(w * 0.44, -180), Vector2(w * 0.24, -180)]), Color(0.45, 0.6, 0.7))
	Vec.rect(self, Rect2(w * 0.46, -120, 20, 26), Color(2.0, 1.8, 1.2) if seed_value > 1 else Color("c9c2a5"))
	for x in [-w * 0.36, -w * 0.08, w * 0.36]:
		Vec.circle(self, Vector2(x, -46), 46, Color("16171a"))
		Vec.circle(self, Vector2(x, -46), 20, Color("55585d"))
	if label != "":
		draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.4, -200), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.9, 0.88, 0.8, 0.8))


func _table() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -100, w, 14), Color("c9c2b5"))
	for x in [-w * 0.45, w * 0.45]:
		Vec.line(self, Vector2(x, -88), Vector2(x, 0), Color("6c7073"), 5.0)
	# laptop + papers + radio
	Vec.fill(self, PackedVector2Array([Vector2(-60, -100), Vector2(40, -100), Vector2(48, -170), Vector2(-52, -170)]), Color("3a3d44"))
	Vec.fill(self, PackedVector2Array([Vector2(-52, -106), Vector2(34, -106), Vector2(40, -164), Vector2(-46, -164)]), Color(0.35, 0.65, 0.9))
	for i in 3:
		Vec.fill(self, Vec.xform(PackedVector2Array([Vector2(-30, -6), Vector2(30, -6), Vector2(30, 0), Vector2(-30, 0)]), Vector2(w * 0.25, -100 - i * 4), 0.05 * i, 1.0), Color("f3eee6"))
	Vec.rrect(self, Rect2(w * 0.32, -150, 30, 50), 5, Color("3a3d44"))


func _cot() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -70, w, 18), Color("4f6448"))
	Vec.line(self, Vector2(-w * 0.45, -52), Vector2(-w * 0.4, 0), Color("6c7073"), 4.0)
	Vec.line(self, Vector2(-w * 0.4, -52), Vector2(-w * 0.45, 0), Color("6c7073"), 4.0)
	Vec.line(self, Vector2(w * 0.45, -52), Vector2(w * 0.4, 0), Color("6c7073"), 4.0)
	Vec.line(self, Vector2(w * 0.4, -52), Vector2(w * 0.45, 0), Color("6c7073"), 4.0)
	Vec.rrect(self, Rect2(-w * 0.48, -88, w * 0.3, 22), 10, Color("e9e4da"))
	if label == "blanket":
		Vec.rrect(self, Rect2(-w * 0.2, -86, w * 0.68, 24), 8, Color("6b4e57"))


func _generator() -> void:
	Vec.rrect(self, Rect2(-90, -120, 180, 120), 8, Color("c9a23c"))
	Vec.rect(self, Rect2(-70, -100, 80, 60), Color("2a2c31"))
	for i in 5:
		Vec.rect(self, Rect2(30, -104 + i * 18, 44, 6), Color("8a6f2a"))
	var on := fposmod(_t, 1.0) < 0.5
	Vec.circle(self, Vector2(-40, -110), 6, Color(0.3, 2.0, 0.5) if on else Color(0.1, 0.4, 0.15))
	Vec.line(self, Vector2(90, -20), Vector2(160, -6), Color("1d1f22"), 4.0)


func _barrier() -> void:
	var w := size.x
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.4, -40), Vector2(-w * 0.2, -110), Vector2(w * 0.2, -110), Vector2(w * 0.4, -40), Vector2(w * 0.5, 0)]), Color("9a9590"))
	Vec.rect(self, Rect2(-w * 0.2, -96, w * 0.4, 12), Color("c0342a"))
	Vec.rect(self, Rect2(-w * 0.2, -70, w * 0.4, 12), Color("e9e4da"))


func _flagpole() -> void:
	var h := size.y
	Vec.line(self, Vector2(0, 0), Vector2(0, -h), Color("8a8f92"), 5.0)
	var wave := PackedVector2Array()
	for i in 9:
		var x := i * 18.0
		wave.append(Vector2(x, -h + 6 + sin(_t * 4.0 - i * 0.7) * 6.0))
	for i in range(8, -1, -1):
		wave.append(Vector2(i * 18.0, -h + 76 + sin(_t * 4.0 - i * 0.7) * 6.0))
	Vec.fill(self, wave, main_color)
	Vec.circle(self, Vector2(70, -h + 42 + sin(_t * 4.0 - 2.7) * 6.0), 14, Color("f1ece2"))


## Set by the level when a car alarm is going off.
var alarm_on := false


func _car() -> void:
	var w := size.x
	var c := main_color
	Vec.ellipse(self, Vector2(0, -2), w * 0.52, 12, Color(0, 0, 0, 0.35))
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.5, -40), Vector2(-w * 0.48, -110), Vector2(-w * 0.3, -120), Vector2(-w * 0.18, -190), Vector2(w * 0.2, -190), Vector2(w * 0.34, -122), Vector2(w * 0.5, -110), Vector2(w * 0.5, -40)]), c)
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.14, -180), Vector2(w * 0.02, -180), Vector2(w * 0.02, -124), Vector2(-w * 0.26, -124)]), Color(0.35, 0.45, 0.55))
	Vec.fill(self, PackedVector2Array([Vector2(w * 0.06, -180), Vector2(w * 0.18, -180), Vector2(w * 0.3, -124), Vector2(w * 0.06, -124)]), Color(0.35, 0.45, 0.55))
	if label.contains("broken"):
		Vec.stroke(self, PackedVector2Array([Vector2(-w * 0.1, -176), Vector2(-w * 0.05, -150), Vector2(-w * 0.12, -130)]), Color(1, 1, 1, 0.6), 2.0)
	Vec.rect(self, Rect2(-w * 0.5, -62, w, 16), Vec.shade(c, 0.25))
	for x in [-w * 0.3, w * 0.3]:
		Vec.circle(self, Vector2(x, -36), 36, Color("16171a"))
		Vec.circle(self, Vector2(x, -36), 15, Color("6a6d72"))
	if label.contains("alarm"):
		var blink := alarm_on and fposmod(_t, 0.4) < 0.2
		Vec.circle(self, Vector2(w * 0.47, -96), 9, Color(3.0, 2.0, 0.6) if blink else Color(0.6, 0.15, 0.1))
		if not alarm_on and fposmod(_t, 1.6) < 0.1:
			Vec.circle(self, Vector2(-w * 0.1, -150), 4, Color(2.5, 0.3, 0.3))
		if alarm_on:
			Vec.glow(self, Vector2(0, -100), w * 0.8, Color(1.6, 1.1, 0.4, 0.35 if blink else 0.1))


func _bus() -> void:
	var w := size.x
	Vec.ellipse(self, Vector2(0, -2), w * 0.52, 14, Color(0, 0, 0, 0.35))
	Vec.rrect(self, Rect2(-w * 0.5, -360, w, 300), 26, main_color)
	Vec.rect(self, Rect2(-w * 0.5, -120, w, 26), Vec.shade(main_color, 0.25))
	var x := -w * 0.45
	while x < w * 0.42:
		Vec.rrect(self, Rect2(x, -330, w * 0.1, 120), 8, Color(0.3, 0.38, 0.45))
		x += w * 0.125
	Vec.rect(self, Rect2(w * 0.3, -330, w * 0.12, 260), Color(0.25, 0.3, 0.35))
	for xx in [-w * 0.32, w * 0.3]:
		Vec.circle(self, Vector2(xx, -50), 46, Color("16171a"))
		Vec.circle(self, Vector2(xx, -50), 18, Color("6a6d72"))
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.4, -150), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 1, 1, 0.8))


func _traffic_light() -> void:
	Vec.line(self, Vector2(0, 0), Vector2(0, -520), Color("3a3d44"), 8.0)
	Vec.rrect(self, Rect2(-24, -640, 48, 130), 8, Color("23252a"))
	var ph := int(fposmod(_t, 3.0))
	var cols := [Color(2.6, 0.4, 0.3), Color(2.4, 1.8, 0.4), Color(0.4, 2.4, 0.8)]
	for i in 3:
		Vec.circle(self, Vector2(0, -616 + i * 40), 14, cols[i] if i == ph else Color(0.2, 0.2, 0.2))


func _bus_stop() -> void:
	Vec.line(self, Vector2(-120, 0), Vector2(-120, -300), Color("6c7073"), 6.0)
	Vec.line(self, Vector2(120, 0), Vector2(120, -300), Color("6c7073"), 6.0)
	Vec.rect(self, Rect2(-140, -320, 280, 24), Color("4a4d52"))
	Vec.rect(self, Rect2(-110, -290, 220, 200), Color(0.5, 0.6, 0.7, 0.25))
	Vec.rect(self, Rect2(-100, -80, 200, 14), Color("8a6f4a"))
	Vec.rect(self, Rect2(-80, -270, 70, 110), Color("e3a03c"))


func _shelf() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), Color("cfd2cf"))
	for r in 4:
		var y := -h + 30 + r * (h - 40) / 4.0
		Vec.rect(self, Rect2(-w * 0.5, y + (h - 40) / 4.0 - 8, w, 8), Color("9aa1a4"))
		var x := -w * 0.45
		while x < w * 0.42:
			if rng.randf() < (0.35 if label == "looted" else 0.85):
				var bw := rng.randf_range(16, 30)
				var bh := rng.randf_range(24, 50)
				Vec.rrect(self, Rect2(x, y + (h - 40) / 4.0 - 8 - bh, bw, bh), 3, [Color("e9e4da"), Color("c0503a"), Color("4f8fb0"), Color("e3a03c"), Color("7fb069")][rng.randi() % 5])
			x += 34.0
	if label == "looted":
		Vec.rrect(self, Rect2(-w * 0.3, -14, 40, 14), 4, Color("e9e4da"))
		Vec.rrect(self, Rect2(w * 0.1, -10, 30, 10), 3, Color("c0503a"))


func _shop_counter() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -130, w, 130), Color("6e4a33"))
	Vec.rect(self, Rect2(-w * 0.52, -140, w * 1.04, 16), Color("d9cbb8"))
	Vec.rrect(self, Rect2(-w * 0.3, -200, 90, 60), 6, Color("2a2c31"))
	Vec.rect(self, Rect2(-w * 0.28, -194, 80, 40), Color(0.2, 0.5, 0.3))
	Vec.rect(self, Rect2(w * 0.1, -168, 70, 28), Color("e9e4da"))


func _cooler() -> void:
	var w := size.x
	var h := size.y
	Vec.rrect(self, Rect2(-w * 0.5, -h, w, h), 8, Color("dfe3e6"))
	Vec.rect(self, Rect2(-w * 0.44, -h + 20, w * 0.88, h - 60), Color(0.55, 0.75, 0.9, 0.5))
	for r in 3:
		Vec.rect(self, Rect2(-w * 0.42, -h + 40 + r * (h - 80) / 3.0, w * 0.84, 5), Color("aab3b8"))
	if label != "empty":
		for i in 6:
			Vec.rrect(self, Rect2(-w * 0.38 + (i % 3) * w * 0.26, -h + 60 + (i / 3) * (h - 80) / 3.0, w * 0.2, 28), 4, Color(0.75, 0.9, 1.0))
	Vec.glow(self, Vector2(0, -h * 0.5), w * 0.8, Color(0.6, 0.9, 1.2, 0.2))


func _train() -> void:
	var w := size.x
	Vec.rrect(self, Rect2(-w * 0.5, -420, w, 380), 30, Color("9aa3ad"))
	Vec.rect(self, Rect2(-w * 0.5, -160, w, 30), Color("c0503a"))
	var x := -w * 0.45
	var i := 0
	while x < w * 0.42:
		if i % 3 == 1:
			Vec.rect(self, Rect2(x, -380, w * 0.09, 300), Color("1a1c20") if label == "open" else Color(0.25, 0.3, 0.35))
		else:
			Vec.rrect(self, Rect2(x, -380, w * 0.09, 140), 10, Color(0.25, 0.3, 0.35))
		x += w * 0.115
		i += 1
	for xx in [-w * 0.35, -w * 0.25, w * 0.25, w * 0.35]:
		Vec.circle(self, Vector2(xx, -28), 26, Color("1d1f22"))


func _tunnel_light() -> void:
	var on := seed_value <= 1 or fposmod(_t * 1.3 + seed_value, 2.5) > 0.3
	Vec.rect(self, Rect2(-40, 0, 80, 20), Color("2a2c31"))
	Vec.rect(self, Rect2(-32, 6, 64, 10), Color(2.6, 1.0, 0.5) if on else Color(0.3, 0.15, 0.1))
	if on:
		Vec.glow(self, Vector2(0, 30), 220, Color(1.4, 0.7, 0.35, 0.3), 0.7)


func _subway_sign() -> void:
	var w := size.x
	Vec.rrect(self, Rect2(-w * 0.5, -40, w, 80), 8, Color("1d3557"))
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.45, 18), label, HORIZONTAL_ALIGNMENT_LEFT, w * 0.9, 46, Color("f1ece2"))


func _subway_stairs() -> void:
	Vec.rect(self, Rect2(-200, -320, 400, 320), Color("2a2c31"))
	for i in 8:
		Vec.rect(self, Rect2(-180 + i * 10, -300 + i * 36, 360 - i * 20, 14), Color("5a5d62"))
	Vec.rect(self, Rect2(-220, -360, 440, 50), Color("1d3557"))
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-150, -322), "SUBWAY  ·  LINE 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f1ece2"))
	Vec.circle(self, Vector2(180, -335), 18, Color(2.4, 0.4, 0.3))


func _boat() -> void:
	var w := size.x
	var bob := sin(_t * 1.6 + seed_value) * 4.0
	draw_set_transform(Vector2(0, bob))
	var hull := PackedVector2Array([Vector2(-w * 0.5, -120), Vector2(w * 0.5, -120), Vector2(w * 0.42, 0), Vector2(-w * 0.38, 0)])
	Vec.fill(self, hull, main_color)
	Vec.rect(self, Rect2(-w * 0.5, -120, w, 16), Color("e9e4da"))
	Vec.rect(self, Rect2(-w * 0.4, -40, w * 0.8, 10), Vec.shade(main_color, 0.25))
	if label != "small":
		Vec.rrect(self, Rect2(-w * 0.1, -300, w * 0.32, 180), 10, Color("e9e4da"))
		Vec.rect(self, Rect2(-w * 0.06, -280, w * 0.24, 70), Color(0.35, 0.5, 0.62))
		Vec.line(self, Vector2(w * 0.05, -300), Vector2(w * 0.05, -420), Color("3a3d44"), 4.0)
	if label != "" and label != "small":
		draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.42, -60), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("e9e4da"))
	draw_set_transform(Vector2.ZERO)
	_t += 0.0


func _fuel_can() -> void:
	Vec.rrect(self, Rect2(-24, -64, 48, 64), 6, Color("c0342a"))
	Vec.rect(self, Rect2(-14, -76, 18, 14), Color("2a2c31"))
	Vec.line(self, Vector2(-20, -56), Vector2(20, -8), Color("8a2420"), 3.0)
	Vec.line(self, Vector2(20, -56), Vector2(-20, -8), Color("8a2420"), 3.0)


func _shed() -> void:
	var w := size.x
	var h := size.y
	Vec.rect(self, Rect2(-w * 0.5, -h, w, h), main_color)
	for k in int(w / 30.0):
		Vec.line(self, Vector2(-w * 0.5 + k * 30, -h), Vector2(-w * 0.5 + k * 30, 0), Vec.shade(main_color, 0.15), 2.0)
	Vec.fill(self, PackedVector2Array([Vector2(-w * 0.56, -h), Vector2(0, -h - 90), Vector2(w * 0.56, -h)]), Vec.shade(main_color, 0.3))
	Vec.rect(self, Rect2(-60, -230, 120, 230), Color("2a2622"))
	if label != "":
		Vec.rect(self, Rect2(-w * 0.35, -h + 20, w * 0.7, 46), Color("f1ece2"))
		draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-w * 0.33, -h + 56), label, HORIZONTAL_ALIGNMENT_LEFT, w * 0.66, 34, Color("23251c"))


func _pier_post() -> void:
	Vec.rect(self, Rect2(-14, -80, 28, 260), Color("5a4532"))
	Vec.rect(self, Rect2(-18, -86, 36, 10), Color("3f3023"))
	Vec.stroke(self, Vec.qbez(Vector2(10, -60), Vector2(60, -20), Vector2(110, -50), 8), Color("c9b48a"), 3.0)


func _crane() -> void:
	var h := size.y
	Vec.line(self, Vector2(0, 0), Vector2(0, -h), Color("c9a23c"), 14.0)
	Vec.line(self, Vector2(-40, -h), Vector2(500, -h), Color("c9a23c"), 10.0)
	for k in 6:
		Vec.line(self, Vector2(k * 80, -h), Vector2(k * 80 + 40, -h + 40), Color("c9a23c"), 4.0)
	Vec.line(self, Vector2(440, -h), Vector2(440, -h + 300), Color("3a3d44"), 2.0)
	Vec.rect(self, Rect2(420, -h + 300, 40, 30), Color("3a3d44"))


func _lab_bench() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -110, w, 110), Color("dfe3e6"))
	Vec.rect(self, Rect2(-w * 0.52, -120, w * 1.04, 14), Color("2a2c31"))
	# centrifuge, flasks, microscope
	Vec.rrect(self, Rect2(-w * 0.42, -200, 120, 80), 12, Color("c9ccd1"))
	Vec.circle(self, Vector2(-w * 0.42 + 60, -170), 26, Color("8f949b"))
	Vec.line(self, Vector2(-w * 0.42 + 60, -170), Vector2(-w * 0.42 + 60, -170) + Vector2.from_angle(_t * 12.0) * 22.0, Color("2a2c31"), 3.0)
	for i in 4:
		var fx := -w * 0.05 + i * 40
		Vec.fill(self, PackedVector2Array([Vector2(fx - 12, -120), Vector2(fx + 12, -120), Vector2(fx + 6, -160), Vector2(fx + 6, -190), Vector2(fx - 6, -190), Vector2(fx - 6, -160)]), Color(0.75, 0.9, 1.0, 0.6))
		Vec.fill(self, PackedVector2Array([Vector2(fx - 11, -122), Vector2(fx + 11, -122), Vector2(fx + 7, -140), Vector2(fx - 7, -140)]), [Color(0.4, 1.4, 0.9), Color(1.2, 0.5, 0.4), Color(0.5, 0.7, 1.4), Color(1.3, 1.1, 0.4)][i])
	Vec.line(self, Vector2(w * 0.32, -120), Vector2(w * 0.32, -230), Color("3a3d44"), 8.0)
	Vec.circle(self, Vector2(w * 0.32, -240), 16, Color("3a3d44"))


func _terminal() -> void:
	Vec.rect(self, Rect2(-120, -100, 240, 100), Color("c9c2b5"))
	Vec.rrect(self, Rect2(-80, -230, 160, 110), 6, Color("2a2c31"))
	var flick := 0.9 + 0.1 * sin(_t * 20.0)
	Vec.rect(self, Rect2(-70, -222, 140, 90), Color(0.3, 0.8, 1.2) * flick)
	for i in 5:
		Vec.rect(self, Rect2(-60, -212 + i * 16, 60 + Vec.hash01(i) * 60.0, 6), Color(0.1, 0.25, 0.4))
	Vec.rect(self, Rect2(-10, -120, 20, 20), Color("2a2c31"))


func _cart() -> void:
	Vec.rect(self, Rect2(-90, -150, 180, 12), Color("cfd2cf"))
	Vec.rect(self, Rect2(-90, -80, 180, 12), Color("cfd2cf"))
	for x in [-80.0, 80.0]:
		Vec.line(self, Vector2(x, -150), Vector2(x, -12), Color("9aa1a4"), 5.0)
		Vec.circle(self, Vector2(x, -8), 8, Color("2a2c31"))
	Vec.rrect(self, Rect2(-70, -196, 60, 46), 4, Color("e9e4da"))
	Vec.rrect(self, Rect2(10, -180, 50, 30), 4, Color("8fd3ff"))


func _hospital_bed() -> void:
	var w := size.x
	Vec.rect(self, Rect2(-w * 0.5, -110, w, 24), Color("cfd2cf"))
	Vec.rect(self, Rect2(-w * 0.5, -150, 14, 150), Color("9aa1a4"))
	Vec.rect(self, Rect2(w * 0.5 - 14, -130, 14, 130), Color("9aa1a4"))
	Vec.rrect(self, Rect2(-w * 0.46, -136, w * 0.25, 26), 10, Color("ffffff"))
	Vec.rrect(self, Rect2(-w * 0.2, -132, w * 0.66, 26), 8, Color("8fb7c9"))
	for x in [-w * 0.4, w * 0.4]:
		Vec.circle(self, Vector2(x, -8), 9, Color("2a2c31"))


## 0..1 broadcast strength (antenna glow), set by the level.
var power := 0.0


func _antenna() -> void:
	var h := size.y
	Vec.line(self, Vector2(-60, 0), Vector2(-10, -h), Color("8a8f92"), 10.0)
	Vec.line(self, Vector2(60, 0), Vector2(10, -h), Color("8a8f92"), 10.0)
	for k in 10:
		var y := -h * (k + 1) / 11.0
		var half := 60.0 - 50.0 * (k + 1) / 11.0
		Vec.line(self, Vector2(-half, y), Vector2(half, y), Color("7a7f82"), 4.0)
		if k % 2 == 0:
			Vec.line(self, Vector2(-half, y), Vector2(half, y - h / 11.0), Color("7a7f82"), 3.0)
	for k in 3:
		var y := -h * (0.55 + k * 0.15)
		Vec.rrect(self, Rect2(-70, y - 20, 140, 40), 6, Color("e9e4da"))
	var blink := fposmod(_t * (1.0 + power * 4.0), 1.0) < 0.3
	Vec.circle(self, Vector2(0, -h - 10), 10, Color(3.0, 0.5, 0.3) if blink else Color(0.5, 0.1, 0.1))
	if power > 0.05:
		for r in 3:
			var rr := fposmod(_t * 220.0 + r * 160.0, 480.0)
			draw_arc(Vector2(0, -h), rr, -PI * 0.9, -PI * 0.1, 32, Color(0.5, 1.2, 1.0, (1.0 - rr / 480.0) * 0.5 * power), 4.0, true)


func _relay_box() -> void:
	Vec.rrect(self, Rect2(-50, -170, 100, 150), 6, Color("8a8f92"))
	Vec.line(self, Vector2(0, -20), Vector2(0, 0), Color("4a4d52"), 8.0)
	var ok := label == "ok"
	Vec.circle(self, Vector2(-20, -140), 8, Color(0.4, 2.0, 0.6) if ok else (Color(2.6, 0.5, 0.3) if fposmod(_t, 0.6) < 0.3 else Color(0.5, 0.1, 0.1)))
	Vec.rect(self, Rect2(-36, -110, 72, 60), Color("2a2c31"))
	Vec.line(self, Vector2(-28, -80), Vector2(28, -80) if ok else Vector2(20, -100), Color(0.4, 1.4, 0.9), 3.0)


func _hatch_ladder() -> void:
	Vec.rect(self, Rect2(-90, -20, 180, 20), Color("5d6266"))
	Vec.line(self, Vector2(-60, -20), Vector2(-60, -200), Color("7a7f82"), 6.0)
	Vec.line(self, Vector2(60, -20), Vector2(60, -200), Color("7a7f82"), 6.0)
	Vec.stroke(self, Vec.qbez(Vector2(-60, -200), Vector2(0, -260), Vector2(60, -200), 8), Color("7a7f82"), 6.0)


func _guitar_stand() -> void:
	Vec.ellipse(self, Vector2(0, -70), 46, 60, Color("b5703a"))
	Vec.ellipse(self, Vector2(0, -130), 34, 40, Color("b5703a"))
	Vec.circle(self, Vector2(0, -90), 14, Color("2a1f18"))
	Vec.rect(self, Rect2(-6, -300, 12, 160), Color("3a2a1e"))
	Vec.rect(self, Rect2(-12, -320, 24, 30), Color("2a1f18"))
