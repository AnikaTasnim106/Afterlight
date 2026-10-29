@tool
class_name HeliInterior
extends Node2D
## Inside the helicopter cabin (cutscene set). Origin = cabin floor centre.

@export var width := 1700.0
@export var alarm := false

var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var w := width
	var shake := Vector2(sin(_t * 31.0), cos(_t * 23.0)) * 1.5
	draw_set_transform(shake)
	Vec.rect(self, Rect2(-w * 0.5 - 200, -900, w + 400, 1200), Color("0c0d0b"))
	Vec.vgrad(self, Rect2(-w * 0.5, -760, w, 760), Color("2c3124"), Color("3a4030"))
	# ribs
	var x := -w * 0.5 + 60
	while x < w * 0.5:
		Vec.rect(self, Rect2(x, -760, 18, 760), Color("252a1e"))
		x += 220.0
	# windows with moving city
	for wx in [-w * 0.28, w * 0.18]:
		var r := Rect2(wx - 110, -600, 220, 150)
		Vec.rrect(self, r.grow(10), 20, Color("1a1d16"))
		Vec.vgrad(self, r, Color("8a98a8"), Color("cfb79a"))
		for i in 8:
			var bx := r.position.x + fposmod(i * 50.0 - _t * 120.0, r.size.x + 50.0) - 25.0
			var bh := 30.0 + Vec.hash01(i + wx) * 70.0
			Vec.rect(self, Rect2(maxf(bx, r.position.x), r.end.y - bh, minf(36.0, r.end.x - maxf(bx, r.position.x)), bh), Color("5c6370"))
		Vec.circle(self, Vector2(r.position.x + fposmod(-_t * 40.0, r.size.x), r.position.y + 60), 26, Color(0.3, 0.29, 0.31, 0.6))
	# cargo net + bench
	for i in 7:
		Vec.line(self, Vector2(-w * 0.5 + 80 + i * 30, -700), Vector2(-w * 0.5 + 80 + i * 30, -380), Color(0.6, 0.6, 0.5, 0.25), 2.0)
	Vec.rect(self, Rect2(-w * 0.5, -132, w, 30), Color("4e5640"))
	Vec.rect(self, Rect2(-w * 0.5, -102, w, 102), Color("1e2219"))
	Vec.rect(self, Rect2(-w * 0.5, 0, w, 40), Color("2a2e22"))
	# red cabin light (alarm flashes)
	var on := (fposmod(_t, 0.8) < 0.4) if alarm else true
	Vec.rect(self, Rect2(-40, -770, 80, 20), Color(2.4, 0.4, 0.3) if on else Color(0.4, 0.1, 0.1))
	Vec.glow(self, Vector2(0, -700), 900, Color(1.2, 0.25, 0.2, 0.35 if on else 0.1), 0.8)
	draw_set_transform(Vector2.ZERO)
