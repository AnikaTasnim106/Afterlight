@tool
class_name RiverBG
extends Node2D
## River backdrop: sunset sky, far shore with Harbor Point's antenna, a broken
## bridge, and animated water. `scroll` moves the shore (boat travelling).

@export var width := 7000.0
@export var water_y := 120.0
@export_range(0.0, 1.0) var dusk := 0.5
@export var scroll_speed := 0.0
@export var show_bridge := true

var _t := 0.0
var _scroll := 0.0


func _process(dt: float) -> void:
	_t += dt
	_scroll += scroll_speed * dt
	queue_redraw()


func _draw() -> void:
	var d := dusk
	Vec.vgrad(self, Rect2(-600, -2200, width + 1200, 1500), Color("6d84a8").lerp(Color("2a2a48"), d), Color("e7b38a").lerp(Color("d46a4a"), d))
	Vec.vgrad(self, Rect2(-600, -700, width + 1200, 700 + water_y), Color("e7b38a").lerp(Color("d46a4a"), d), Color("f0c890").lerp(Color("e89a5a"), d))
	Vec.glow(self, Vector2(width * 0.55, -420), 500, Color(1.6, 1.1, 0.6, 0.45))
	Vec.circle(self, Vector2(width * 0.55, -420), 70, Color(2.2, 1.6, 1.0))
	# far shore (Harbor Point)
	var x := -600.0 - fposmod(_scroll * 0.3, 260.0)
	var i := 0
	while x < width + 600:
		var bw := 120.0 + Vec.hash01(i + 3.0) * 160.0
		var bh := 120.0 + Vec.hash01(i * 2.7) * 260.0
		Vec.rect(self, Rect2(x, water_y - 120 - bh, bw, bh + 40), Color("6a5a68").lerp(Color("3a2c3a"), d))
		x += bw + 14.0
		i += 1
	var ax := width * 0.72 - fposmod(_scroll * 0.3, width)
	Vec.line(self, Vector2(ax, water_y - 300), Vector2(ax, water_y - 900), Color("3a2c3a"), 8.0)
	for k in 4:
		Vec.line(self, Vector2(ax - 60 + k * 10, water_y - 700 + k * 60), Vector2(ax + 60 - k * 10, water_y - 700 + k * 60), Color("3a2c3a"), 4.0)
	if fposmod(_t, 1.2) < 0.2:
		Vec.glow(self, Vector2(ax, water_y - 905), 24, Color(3.0, 0.4, 0.3))
	# broken bridge
	if show_bridge:
		var bx := width * 0.25 - fposmod(_scroll * 0.5, width + 2000.0) + 1000.0
		Vec.rect(self, Rect2(bx - 1400, water_y - 330, 1100, 40), Color("4a3d48"))
		Vec.rect(self, Rect2(bx - 200, water_y - 330, 1200, 40), Color("4a3d48"))
		for k in 5:
			Vec.rect(self, Rect2(bx - 1300 + k * 560, water_y - 290, 40, 300), Color("4a3d48"))
		Vec.fill(self, PackedVector2Array([Vector2(bx - 300, water_y - 330), Vector2(bx - 230, water_y - 330), Vector2(bx - 260, water_y - 230)]), Color("4a3d48"))
	# water
	Vec.vgrad(self, Rect2(-600, water_y, width + 1200, 900), Color("3a5a78").lerp(Color("2a3450"), d), Color("16243a"))
	for r in 10:
		var y := water_y + 20 + r * r * 8.0
		var off := fposmod(_t * (20.0 + r * 6.0) + _scroll * (0.6 + r * 0.1), 180.0)
		var sx := -600.0 - off
		while sx < width + 600:
			Vec.line(self, Vector2(sx, y), Vector2(sx + 70 + r * 6, y), Color(1.0, 0.8, 0.6, 0.18 - r * 0.012), 2.0 + r * 0.3)
			sx += 180.0
	# sun reflection
	for k in 8:
		Vec.line(self, Vector2(width * 0.55 - 60 + sin(_t + k) * 20.0, water_y + 20 + k * 22), Vector2(width * 0.55 + 60 + sin(_t + k) * 20.0, water_y + 20 + k * 22), Color(1.6, 1.0, 0.6, 0.35), 4.0)
