@tool
class_name RoomShell
extends Node2D
## Back wall + ceiling + floor band for one room segment (side-section view).
## Origin = left end of the wall base. Floor band extends downward (+Y).

@export var width := 1200.0:
	set(v):
		width = v
		queue_redraw()
@export var wall_height := 800.0:
	set(v):
		wall_height = v
		queue_redraw()
@export var floor_depth := 260.0
@export var wall_color := Color("8b7466"):
	set(v):
		wall_color = v
		queue_redraw()
@export var wall_pattern_color := Color("7f6a5d")
@export_enum("stripes", "plain", "tiles", "panel") var wall_pattern := 0
@export var floor_color := Color("7b4f35")
@export_enum("planks", "tiles", "concrete") var floor_type := 0
@export var baseboard_color := Color("d9cbb8")
@export var ceiling_color := Color("2b2427")
@export var left_cap := true
@export var right_cap := true


func _draw() -> void:
	var w := width
	var h := wall_height
	# wall
	Vec.vgrad(self, Rect2(0, -h, w, h), Vec.shade(wall_color, 0.12), wall_color)
	match wall_pattern:
		0:
			var x := 0.0
			while x < w:
				draw_rect(Rect2(x, -h, 18, h), Color(wall_pattern_color, 0.55))
				x += 64.0
		2:
			for row in int(h / 48.0) + 1:
				var y := -h + row * 48.0
				draw_line(Vector2(0, y), Vector2(w, y), Vec.shade(wall_color, 0.12), 2.0)
				var off := 24.0 if row % 2 == 1 else 0.0
				var x2 := off
				while x2 < w:
					draw_line(Vector2(x2, y), Vector2(x2, y + 48.0), Vec.shade(wall_color, 0.12), 2.0)
					x2 += 48.0
		3:
			# lower wainscot panels
			draw_rect(Rect2(0, -h * 0.38, w, h * 0.38), Vec.shade(wall_color, 0.1))
			draw_rect(Rect2(0, -h * 0.38, w, 10), Vec.shade(baseboard_color, 0.1))
			var px := 30.0
			while px + 150.0 < w:
				Vec.stroke(self, Vec.rrect_pts(Rect2(px, -h * 0.34, 150, h * 0.28), 4), Vec.shade(wall_color, 0.2), 3.0)
				px += 185.0
	# ceiling + crown moulding
	draw_rect(Rect2(0, -h - 120, w, 120), ceiling_color)
	draw_rect(Rect2(0, -h - 4, w, 16), Vec.shade(baseboard_color, 0.15))
	# floor band
	var fd := floor_depth
	match floor_type:
		0:
			Vec.vgrad(self, Rect2(0, 0, w, fd), Vec.shade(floor_color, 0.22), floor_color)
			var rows := 7
			for i in rows:
				var y := fd * pow(float(i) / rows, 1.25)
				draw_line(Vector2(0, y), Vector2(w, y), Vec.shade(floor_color, 0.3), 2.0)
				var step := 260.0
				var off2 := fmod(i * 97.0, step)
				var x3 := off2
				var nexty := fd * pow(float(i + 1) / rows, 1.25)
				while x3 < w:
					draw_line(Vector2(x3, y), Vector2(x3, nexty), Vec.shade(floor_color, 0.26), 2.0)
					x3 += step
		1:
			Vec.vgrad(self, Rect2(0, 0, w, fd), Vec.shade(floor_color, 0.15), floor_color)
			for i in 6:
				var y2 := fd * pow(float(i) / 6.0, 1.2)
				draw_line(Vector2(0, y2), Vector2(w, y2), Vec.shade(floor_color, 0.2), 2.0)
			var tx := 0.0
			while tx < w:
				draw_line(Vector2(tx, 0), Vector2(tx + (tx - w * 0.5) * 0.12, fd), Vec.shade(floor_color, 0.2), 2.0)
				tx += 90.0
		2:
			Vec.vgrad(self, Rect2(0, 0, w, fd), Vec.shade(floor_color, 0.2), floor_color)
			for i in 40:
				var p := Vector2(Vec.hash01(i) * w, Vec.hash01(i + 9.0) * fd)
				Vec.circle(self, p, 3.0 + Vec.hash01(i + 3.0) * 5.0, Vec.shade(floor_color, 0.12))
	# baseboard + contact shadow
	draw_rect(Rect2(0, -22, w, 24), baseboard_color)
	draw_rect(Rect2(0, -24, w, 4), Vec.shade(baseboard_color, 0.25))
	Vec.vgrad(self, Rect2(0, 2, w, 26), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0))
	# room-end walls (cut-away edges)
	if left_cap:
		draw_rect(Rect2(-40, -h - 120, 40, h + 120 + fd), Color("16131a"))
	if right_cap:
		draw_rect(Rect2(w, -h - 120, 40, h + 120 + fd), Color("16131a"))
