@tool
class_name SkyBG
extends Node2D
## Open-air city backdrop for the rooftop: hazy morning sky, layered skyline
## with parallax, smoke columns, distant helicopters.

@export var width := 4200.0
@export var height := 1500.0
@export var horizon := 0.0
## 0 = hazy morning, 1 = deep night (windows lit). Tweened for dawn.
@export_range(0.0, 1.0) var night := 0.0

var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _px(depth: float) -> float:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	return 0.0 if cam == null else (cam.get_screen_center_position().x - global_position.x) * depth


func _draw() -> void:
	var top := horizon - height
	var c_top := Color("6d7b8c").lerp(Color("0b1222"), night)
	var c_mid := Color("b8a99a").lerp(Color("232b45"), night)
	var c_low := Color("d7a37c").lerp(Color("4d3b52"), night)
	Vec.vgrad(self, Rect2(-400, top, width + 800, height * 0.7), c_top, c_mid)
	Vec.vgrad(self, Rect2(-400, top + height * 0.7, width + 800, height * 0.3), c_mid, c_low)
	if night > 0.3:
		for k in 60:
			var sp := Vector2(Vec.hash01(k * 3.1) * width, top + Vec.hash01(k * 7.7) * height * 0.55)
			Vec.circle(self, sp + Vector2(_px(0.01), 0), 2.0, Color(1, 1, 1, (night - 0.3) * 0.9 * (0.6 + 0.4 * sin(_t * 2.0 + k))))
	Vec.glow(self, Vector2(width * 0.7 + _px(0.02), top + height * 0.35 + night * 500.0), 300, Color(1.3, 1.1, 0.8, 0.35 * (1.0 - night)))
	_layer(horizon - 120, 520, Color("7d8592"), 0.85, 3.0)
	for i in 3:
		var sx := 600.0 + i * 1300.0 + _px(0.8)
		Vec.glow(self, Vector2(sx, horizon - 160), 220, Color(1.4, 0.6, 0.3, 0.35), 0.5)
		for k in 10:
			var age := fposmod(_t * 0.05 + k / 10.0 + i * 0.3, 1.0)
			Vec.circle(self, Vector2(sx + sin(age * 3.0 + k) * 30.0 + age * 160.0, horizon - 160 - age * 900.0), lerpf(40.0, 160.0, age), Color(0.3, 0.29, 0.31, (1.0 - age) * 0.5))
	_layer(horizon - 40, 700, Color("5c6370"), 0.7, 11.0)
	# distant helicopter
	var hx := fposmod(_t * 50.0, width + 800.0) - 400.0
	Vec.ellipse(self, Vector2(hx, top + 380), 22, 8, Color("2b2f36"))
	Vec.line(self, Vector2(hx - 34, top + 370), Vector2(hx + 34, top + 370), Color(0.15, 0.17, 0.2, 0.6), 2.0)


func _layer(base: float, maxh: float, col: Color, depth: float, seed_off: float) -> void:
	var x := -400.0 - fposmod(_px(1.0 - depth), 90.0)
	var i := 0
	while x < width + 400.0:
		var bw := 70.0 + Vec.hash01(i + seed_off) * 140.0
		var bh := maxh * (0.3 + 0.7 * Vec.hash01(i * 1.3 + seed_off))
		var cc := Vec.shade(col, 0.6 * night)
		Vec.rect(self, Rect2(x, base - bh, bw, bh + 400.0), cc)
		for r in int(bh / 40.0):
			for c in int(bw / 26.0):
				var hv := Vec.hash01(i * 97.0 + r * 13.0 + c + seed_off)
				if hv > 0.82:
					var wc := Vec.shade(cc, -0.18)
					if night > 0.2 and hv > 0.955:
						wc = Color(1.3, 1.0, 0.55).lerp(wc, 1.0 - night)
					Vec.rect(self, Rect2(x + 8 + c * 26.0, base - bh + 14 + r * 40.0, 10, 16), wc)
		x += bw + 6.0
		i += 1
