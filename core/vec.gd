class_name Vec
## Vector drawing helpers. Godot's GL Compatibility renderer has no 2D MSAA,
## so every filled shape gets a thin antialiased outline in the same colour.
## Call these only from inside a CanvasItem's _draw().

const AA_WIDTH := 1.25


static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, aa := true) -> void:
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, col)
	if aa:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, col, AA_WIDTH, true)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r, col, true, -1.0, true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, col, w, true)


static func stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() >= 2:
		ci.draw_polyline(pts, col, w, true)


## Round-capped line with optional taper (radius at a, radius at b).
static func capsule_pts(a: Vector2, b: Vector2, ra: float, rb: float, seg := 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d := b - a
	if d.length() < 0.001:
		d = Vector2(0, 0.001)
	var ang := d.angle()
	for i in seg + 1:
		var t := -PI / 2 + PI * float(i) / seg
		pts.append(b + Vector2.from_angle(ang + t) * rb)
	for i in seg + 1:
		var t := PI / 2 + PI * float(i) / seg
		pts.append(a + Vector2.from_angle(ang + t) * ra)
	return pts


static func capsule(ci: CanvasItem, a: Vector2, b: Vector2, ra: float, rb: float, col: Color) -> void:
	fill(ci, capsule_pts(a, b, ra, rb), col)


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot := 0.0, seg := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var t := TAU * float(i) / seg
		pts.append(c + Vector2(cos(t) * rx, sin(t) * ry).rotated(rot))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	fill(ci, ellipse_pts(c, rx, ry, rot), col)


static func rrect_pts(r: Rect2, rad: float, seg := 4) -> PackedVector2Array:
	rad = min(rad, r.size.x * 0.5, r.size.y * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[r.position + Vector2(r.size.x - rad, rad), -PI / 2],
		[r.position + r.size - Vector2(rad, rad), 0.0],
		[r.position + Vector2(rad, r.size.y - rad), PI / 2],
		[r.position + Vector2(rad, rad), PI],
	]
	for c in corners:
		for i in seg + 1:
			var t: float = c[1] + (PI / 2) * float(i) / seg
			pts.append(c[0] + Vector2.from_angle(t) * rad)
	return pts


static func rrect(ci: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	if rad <= 0.5:
		ci.draw_rect(r, col)
	else:
		fill(ci, rrect_pts(r, rad), col)


static func rect(ci: CanvasItem, r: Rect2, col: Color) -> void:
	ci.draw_rect(r, col)


## Vertical gradient rectangle (top colour -> bottom colour).
static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


## Horizontal gradient rectangle (left -> right).
static func hgrad(ci: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	var pts := PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)])
	ci.draw_polygon(pts, PackedColorArray([left, right, right, left]))


static var _glow_tex: GradientTexture2D


## Shared white radial falloff texture (also used by SoftLight).
static func glow_texture() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 256
		_glow_tex.height = 256
	return _glow_tex


## Soft radial blob: centre colour fading to transparent. Cheap fake glow.
## Use HDR colours (>1) to trigger bloom.
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, squash := 1.0) -> void:
	ci.draw_texture_rect(glow_texture(), Rect2(c - Vector2(r, r * squash), Vector2(r * 2, r * 2 * squash)), false, col)


## Quadratic bezier sampled as points.
static func qbez(a: Vector2, ctrl: Vector2, b: Vector2, seg := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg + 1:
		var t := float(i) / seg
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


static func xform(pts: PackedVector2Array, origin: Vector2, rot: float, scale: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = origin + (pts[i] * scale).rotated(rot)
	return out


static func shade(c: Color, amount: float) -> Color:
	return c.darkened(amount) if amount >= 0.0 else c.lightened(-amount)


## Deterministic hash noise in [0,1).
static func hash01(n: float) -> float:
	var s := sin(n * 127.1 + 311.7) * 43758.5453
	return s - floor(s)
