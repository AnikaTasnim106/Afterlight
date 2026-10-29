@tool
class_name StreetBG
extends Node2D
## Downtown backdrop: building facades with shopfronts and signs, broken
## windows, smoke, an overcast dusk sky. `dusk` 0..1 darkens it.

@export var width := 9200.0
@export_range(0.0, 1.0) var dusk := 0.3
@export var signs := PackedStringArray(["LUCKY'S DINER", "BOOKS & MORE", "MAIN ST PHARMACY", "HOTEL ROYAL", "LAUNDRY", "PAWN", "CITY BANK", "NOODLE BAR"])

var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	var d := dusk
	Vec.vgrad(self, Rect2(-400, -2200, width + 800, 1600), Color("8d97a3").lerp(Color("232838"), d), Color("c9b5a0").lerp(Color("5a3f3e"), d))
	# far towers
	var x := -400.0
	var i := 0
	while x < width + 400:
		var bw := 160.0 + Vec.hash01(i + 50.0) * 220.0
		var bh := 900.0 + Vec.hash01(i * 3.1) * 700.0
		Vec.rect(self, Rect2(x, -bh, bw, bh), Color("7b8290").lerp(Color("1c202c"), d))
		x += bw + 30.0
		i += 1
	for k in 4:
		var sx := 700.0 + k * 2300.0
		for j in 8:
			var age := fposmod(_t * 0.04 + j / 8.0 + k * 0.23, 1.0)
			Vec.circle(self, Vector2(sx + age * 220.0, -700 - age * 1200.0), lerpf(50.0, 200.0, age), Color(0.28, 0.27, 0.3, (1.0 - age) * 0.45))
	# street-level facades
	x = -300.0
	i = 0
	while x < width + 300:
		var bw := 600.0 + Vec.hash01(i + 7.0) * 300.0
		var bh := 700.0 + Vec.hash01(i * 1.7 + 3.0) * 300.0
		var col: Color = [Color("8a6f5c"), Color("6f7b80"), Color("8c8577"), Color("6b5b6e"), Color("7a6a55")][i % 5]
		col = col.lerp(Vec.shade(col, 0.6), d)
		Vec.rect(self, Rect2(x, -bh, bw, bh), col)
		# upper windows
		for r in 3:
			for c in int(bw / 120.0):
				var wr := Rect2(x + 40 + c * 120, -bh + 60 + r * 150, 70, 100)
				var broken := Vec.hash01(i * 31.0 + r * 7.0 + c) > 0.8
				Vec.rect(self, wr, Color(0.2, 0.24, 0.3) if not broken else Color(0.08, 0.08, 0.1))
				if Vec.hash01(i * 13.0 + r + c * 3.0) > 0.85 and d > 0.4:
					Vec.rect(self, wr, Color(1.1, 0.8, 0.45, 0.6))
		# shopfront
		Vec.rect(self, Rect2(x + 20, -300, bw - 40, 300), Vec.shade(col, 0.35))
		Vec.rect(self, Rect2(x + 60, -260, bw - 220, 220), Color(0.18, 0.2, 0.24))
		Vec.rect(self, Rect2(x + bw - 140, -280, 90, 280), Color(0.12, 0.12, 0.14))
		var sign: String = signs[i % signs.size()]
		Vec.rect(self, Rect2(x + 40, -380, bw - 80, 64), Color("1d1c20"))
		draw_string(f, Vector2(x + 60, -332), sign, HORIZONTAL_ALIGNMENT_LEFT, bw - 120, 44, Color("e9a640") if i % 2 == 0 else Color("f1ece2"))
		x += bw + 10.0
		i += 1
	# sidewalk
	Vec.rect(self, Rect2(-400, -30, width + 800, 30), Color("8a8580").lerp(Color("3a3836"), d))
