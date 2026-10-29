@tool
class_name StadiumBG
extends Node2D
## Backdrop for Relief Zone Bravo: sky (day/dusk/night), the stadium bowl,
## its floodlight towers, and the city beyond. `night` 0..1.

@export var width := 7400.0
@export_range(0.0, 1.0) var night := 0.0:
	set(v):
		night = v
		queue_redraw()
@export_range(0.0, 1.0) var fire := 0.0

var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _px(depth: float) -> float:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	return 0.0 if cam == null else (cam.get_screen_center_position().x - global_position.x) * depth


func _draw() -> void:
	var n := night
	var top := -1700.0
	Vec.vgrad(self, Rect2(-600, top, width + 1200, 1100), Color("7d94ad").lerp(Color("0a0e1c"), n), Color("d8c7ad").lerp(Color("2a2135"), n))
	Vec.vgrad(self, Rect2(-600, top + 1100, width + 1200, 700), Color("d8c7ad").lerp(Color("2a2135"), n), Color("e4b48a").lerp(Color(0.5 + fire * 0.4, 0.22, 0.2), n))
	# far city
	var x := -600.0 + _px(0.9) * 0.0 - fposmod(_px(0.1), 120.0)
	var i := 0
	while x < width + 600:
		var bw := 90.0 + Vec.hash01(i) * 150.0
		var bh := 180.0 + Vec.hash01(i * 2.3) * 360.0
		Vec.rect(self, Rect2(x, -260 - bh, bw, bh + 100), Color("8c96a3").lerp(Color("141824"), n))
		if n > 0.4:
			for k in 6:
				if Vec.hash01(i * 11.0 + k) > 0.7:
					Vec.rect(self, Rect2(x + 10 + (k % 3) * 26, -260 - bh + 20 + (k / 3) * 40, 10, 14), Color(1.2, 0.9, 0.5, 0.6 * n))
		x += bw + 8.0
		i += 1
	# stadium bowl (stands) behind the camp
	var sb := Color("8a8580").lerp(Color("1d1c22"), n)
	Vec.fill(self, PackedVector2Array([Vector2(-600, -160), Vector2(-600, -620), Vector2(600, -720), Vector2(width * 0.5, -760), Vector2(width - 600, -720), Vector2(width + 600, -620), Vector2(width + 600, -160)]), sb)
	for r in 9:
		var y := -620.0 + r * 50.0
		Vec.line(self, Vector2(-600, y + 10), Vector2(width + 600, y), Vec.shade(sb, 0.18), 3.0)
	var sx := 0.0
	while sx < width:
		Vec.rect(self, Rect2(sx, -700, 14, 540), Vec.shade(sb, 0.25))
		sx += 300.0
	# floodlight towers on the rim
	for k in 5:
		var tx := 400.0 + k * (width - 800.0) / 4.0
		Vec.line(self, Vector2(tx, -720), Vector2(tx, -1250), Color("4a4d52").lerp(Color("15161a"), n), 10.0)
		Vec.rect(self, Rect2(tx - 80, -1310, 160, 60), Color("2a2c31"))
		if n > 0.3:
			for b in 4:
				Vec.rect(self, Rect2(tx - 72 + b * 38, -1302, 30, 44), Color(3.0, 2.8, 2.4))
			Vec.glow(self, Vector2(tx, -1280), 380, Color(1.1, 1.05, 0.95, 0.3 * n))
	# smoke from the city
	for k in 3:
		var smx := 900.0 + k * 2500.0
		for j in 8:
			var age := fposmod(_t * 0.04 + j / 8.0 + k * 0.2, 1.0)
			Vec.circle(self, Vector2(smx + age * 200.0, -300 - age * 1100.0), lerpf(40.0, 180.0, age), Color(0.3, 0.29, 0.31, (1.0 - age) * 0.35))
