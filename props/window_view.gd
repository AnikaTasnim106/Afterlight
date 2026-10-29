@tool
class_name WindowView
extends Node2D
## Apartment window looking out over the city at night.
## The outside is a live, layered scene (parallax with the camera):
## skyline, lit windows, smoke, a helicopter with a searchlight, and a
## street far below with emergency vehicles and running people.
## `unrest` (0..1) controls how much chaos is visible — scripts raise it as
## the evening goes wrong.

@export var size := Vector2(520, 460):
	set(v):
		size = v
		_layout()
@export_range(0.0, 1.0) var unrest := 0.35
## 0 = night, 1 = overcast morning
@export_range(0.0, 1.0) var daylight := 0.0
@export var curtain_color := Color("6b3f3a")
@export var frame_color := Color("e4dccd")

var _mask: Node2D
var _city: _City
var _front: _Front


func _ready() -> void:
	for c in get_children():
		if c.has_meta("_generated"):
			c.queue_free()
	_mask = Node2D.new()
	_mask.set_meta("_generated", true)
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_mask.draw.connect(_draw_mask)
	add_child(_mask)
	_city = _City.new()
	_city.owner_view = self
	_mask.add_child(_city)
	_front = _Front.new()
	_front.set_meta("_generated", true)
	_front.owner_view = self
	add_child(_front)
	_layout()


func _layout() -> void:
	if _mask:
		_mask.queue_redraw()
	if _front:
		_front.queue_redraw()


func _draw_mask() -> void:
	_mask.draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), Color.WHITE)


func _process(_dt: float) -> void:
	if _city:
		_city.queue_redraw()


## Camera-relative parallax offset for a depth factor.
func parallax(depth: float) -> float:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam == null:
		return 0.0
	return (global_position.x - cam.get_screen_center_position().x) * depth


class _City extends Node2D:
	var owner_view: WindowView
	var t := 0.0

	func _process(dt: float) -> void:
		t += dt

	func _draw() -> void:
		var v := owner_view
		var w := v.size.x
		var h := v.size.y
		var u := v.unrest
		var day := v.daylight
		var top := -h
		# sky: navy to murky orange (fires on the horizon) / grey morning
		Vec.vgrad(self, Rect2(-w * 0.5, top, w, h * 0.62), Color("0b1020").lerp(Color("8a98a8"), day), Color("2a2437").lerp(Color("b9b4ad"), day))
		Vec.vgrad(self, Rect2(-w * 0.5, top + h * 0.62, w, h * 0.38), Color("2a2437").lerp(Color("b9b4ad"), day), Color(0.55 + 0.25 * u, 0.3, 0.22).lerp(Color(0.8, 0.66, 0.55), day))
		if day < 0.5:
			# moon
			Vec.glow(self, Vector2(-w * 0.28 + v.parallax(0.01), top + h * 0.16), 60, Color(0.9, 0.95, 1.2, 0.35))
			Vec.circle(self, Vector2(-w * 0.28 + v.parallax(0.01), top + h * 0.16), 16, Color(1.1, 1.1, 1.05))
		# far skyline
		_skyline(top + h * 0.6, h * 0.32, Color("1c2133").lerp(Color("737b86"), day), 0.03, 11.0, 0.25 * (1.0 - day), Color(1.2, 0.9, 0.55))
		# smoke columns with fire glow at base
		for i in 2:
			var sx := lerpf(-w * 0.15, w * 0.3, float(i)) + v.parallax(0.045)
			var base := top + h * 0.72
			Vec.glow(self, Vector2(sx, base), 120 * (0.5 + u), Color(1.6, 0.6, 0.25, 0.35 * u + 0.1), 0.6)
			for k in 9:
				var age := fposmod(t * 0.08 + k / 9.0 + i * 0.37, 1.0)
				var p := Vector2(sx + sin(age * 4.0 + k) * 14.0 + age * 70.0, base - age * h * 0.75)
				Vec.circle(self, p, lerpf(14.0, 62.0, age), Color(0.22, 0.2, 0.24, (1.0 - age) * 0.55 * (0.4 + u)))
		# mid buildings
		_skyline(top + h * 0.82, h * 0.48, Color("12151f").lerp(Color("545b66"), day), 0.07, 23.0, 0.45 * (1.0 - day * 0.9), Color(1.25, 1.0, 0.7))
		# helicopter with searchlight
		var hp := fposmod(t * 0.045, 1.4) - 0.2
		var hx := lerpf(w * 0.7, -w * 0.7, hp) + v.parallax(0.05)
		var hy := top + h * 0.24 + sin(t * 0.7) * 6.0
		var beam_a := 0.35 + sin(t * 0.6) * 0.35
		var beam := PackedVector2Array([Vector2(hx, hy + 6), Vector2(hx - 30 + beam_a * 160.0 - 80.0, top + h), Vector2(hx + 90 + beam_a * 160.0 - 80.0, top + h)])
		draw_colored_polygon(beam, Color(0.9, 0.95, 1.0, 0.08 + 0.06 * u))
		Vec.ellipse(self, Vector2(hx, hy), 26, 10, Color("0a0c12"))
		Vec.rect(self, Rect2(hx + 18, hy - 3, 34, 5), Color("0a0c12"))
		Vec.line(self, Vector2(hx - 40, hy - 14), Vector2(hx + 40, hy - 14), Color(0.05, 0.06, 0.08, 0.7), 2.0)
		if fposmod(t, 1.0) < 0.15:
			Vec.glow(self, Vector2(hx + 52, hy - 2), 16, Color(3.0, 0.4, 0.3, 0.9))
		# street far below
		var sy := top + h * 0.86
		Vec.rect(self, Rect2(-w * 0.5, sy, w, h * 0.14), Color("1a1a22").lerp(Color("5b5a5c"), day))
		Vec.rect(self, Rect2(-w * 0.5, sy + h * 0.06, w, 3), Color(0.9, 0.75, 0.3, 0.5))
		# streetlights
		for k in 5:
			var lx := -w * 0.5 + fposmod(k * 140.0 + v.parallax(0.12), w + 140.0) - 70.0
			Vec.glow(self, Vector2(lx, sy + 8), 40, Color(1.4, 1.0, 0.6, 0.4), 0.5)
		# vehicles with emergency lights
		var n_cars := 1 + int(u * 3.0)
		for k in n_cars:
			var speed := 70.0 + k * 35.0
			var dir := -1.0 if k % 2 == 0 else 1.0
			var cx := fposmod(t * speed * dir + k * 230.0 + v.parallax(0.12), w + 160.0) - w * 0.5 - 80.0
			var cy := sy + h * 0.03 + (k % 2) * h * 0.05
			var body := Color("d9d9d9") if k % 3 != 2 else Color("4a5a3a")
			Vec.rrect(self, Rect2(cx - 22, cy - 9, 44, 12), 3, body)
			var on := fposmod(t * 4.0 + k, 1.0) < 0.5
			var lc := Color(3.0, 0.3, 0.3) if on else Color(0.4, 0.6, 3.0)
			Vec.glow(self, Vector2(cx, cy - 10), 26, Color(lc, 0.8), 0.7)
			Vec.circle(self, Vector2(cx, cy - 10), 3, lc)
		# running people (tiny silhouettes)
		var n_people := int(u * 9.0)
		for k in n_people:
			var ps := 40.0 + Vec.hash01(k) * 50.0
			var pdir := -1.0 if Vec.hash01(k + 3.0) > 0.5 else 1.0
			var px := fposmod(t * ps * pdir + k * 97.0 + v.parallax(0.12), w + 40.0) - w * 0.5 - 20.0
			var py := sy + h * 0.1 + Vec.hash01(k + 7.0) * h * 0.03
			var leg := sin(t * 14.0 + k) * 3.0
			Vec.circle(self, Vector2(px, py - 12), 2.6, Color("0b0b10"))
			Vec.line(self, Vector2(px, py - 10), Vector2(px, py - 4), Color("0b0b10"), 2.5)
			Vec.line(self, Vector2(px, py - 4), Vector2(px + leg, py), Color("0b0b10"), 2.0)
			Vec.line(self, Vector2(px, py - 4), Vector2(px - leg, py), Color("0b0b10"), 2.0)

	func _skyline(base: float, maxh: float, col: Color, depth: float, seed_off: float, lit: float, win: Color) -> void:
		var v := owner_view
		var w := v.size.x
		var x := -w * 0.5 - 120.0 + fposmod(v.parallax(depth), 60.0)
		var i := 0
		while x < w * 0.5 + 60.0:
			var bw := 40.0 + Vec.hash01(i + seed_off) * 70.0
			var bh := maxh * (0.35 + 0.65 * Vec.hash01(i * 1.7 + seed_off))
			Vec.rect(self, Rect2(x, base - bh, bw, bh + 200.0), col)
			if Vec.hash01(i + seed_off * 2.0) > 0.7:
				Vec.rect(self, Rect2(x + bw * 0.45, base - bh - 18.0, 3, 18), col)
				if fposmod(t + i, 1.6) < 0.2:
					Vec.circle(self, Vector2(x + bw * 0.45 + 1.5, base - bh - 20.0), 2.5, Color(2.5, 0.4, 0.3))
			# windows
			var rows := int(bh / 18.0)
			for r in rows:
				for cidx in int(bw / 14.0):
					var key := i * 131.0 + r * 17.0 + cidx * 3.0 + seed_off
					var hv := Vec.hash01(key)
					if hv < lit:
						var flick := 1.0
						if Vec.hash01(key + 1.0) > 0.92:
							flick = 0.4 + 0.6 * absf(sin(t * 3.0 + key))
						var wc := win if Vec.hash01(key + 2.0) > 0.25 else Color(0.6, 0.8, 1.1)
						Vec.rect(self, Rect2(x + 5 + cidx * 14.0, base - bh + 8 + r * 18.0, 6, 8), Color(wc * flick, 0.85))
			x += bw + 4.0
			i += 1


class _Front extends Node2D:
	var owner_view: WindowView

	func _draw() -> void:
		var v := owner_view
		var w := v.size.x
		var h := v.size.y
		var fc := v.frame_color
		# glass reflection streaks
		draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.3, -h), Vector2(-w * 0.18, -h), Vector2(-w * 0.42, 0), Vector2(-w * 0.5, 0), Vector2(-w * 0.5, -h * 0.3)]), Color(1, 1, 1, 0.04))
		# frame + mullions
		var t := 18.0
		Vec.rect(self, Rect2(-w * 0.5 - t, -h - t, w + t * 2, t), fc)
		Vec.rect(self, Rect2(-w * 0.5 - t, -h, t, h), fc)
		Vec.rect(self, Rect2(w * 0.5, -h, t, h), fc)
		Vec.rect(self, Rect2(-6, -h, 12, h), fc)
		Vec.rect(self, Rect2(-w * 0.5, -h * 0.42, w, 10), fc)
		# sill
		Vec.rrect(self, Rect2(-w * 0.5 - 34, 0, w + 68, 22), 4, Vec.shade(fc, 0.08))
		Vec.rect(self, Rect2(-w * 0.5 - 34, 18, w + 68, 6), Vec.shade(fc, 0.3))
		# curtain rod + curtains (gathered at the sides)
		Vec.line(self, Vector2(-w * 0.5 - 90, -h - 46), Vector2(w * 0.5 + 90, -h - 46), Color("3a3d44"), 6.0)
		for sgn in [-1.0, 1.0]:
			var x0: float = sgn * (w * 0.5 + 20.0)
			var pts := PackedVector2Array()
			pts.append(Vector2(x0 + sgn * 70.0, -h - 46))
			pts.append(Vector2(x0 - sgn * 40.0, -h - 46))
			pts.append(Vector2(x0 - sgn * 10.0, -h * 0.45))
			pts.append(Vector2(x0 - sgn * 30.0, 40))
			pts.append(Vector2(x0 + sgn * 70.0, 40))
			Vec.fill(self, pts, v.curtain_color)
			for k in 3:
				var fx: float = x0 + sgn * (k * 22.0 - 10.0)
				Vec.line(self, Vector2(fx, -h - 40), Vector2(fx - sgn * 6.0, 36), Vec.shade(v.curtain_color, 0.25), 3.0)
			# tie-back
			Vec.rrect(self, Rect2(x0 - 34 - (0.0 if sgn > 0 else -0.0), -h * 0.47, 70, 12), 6, Color("c9a250"))
