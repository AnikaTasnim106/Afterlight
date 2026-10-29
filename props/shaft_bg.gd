@tool
class_name ShaftBG
extends Node2D
## Background of the stairwell shaft: concrete walls, floor slabs, big painted
## floor numbers and a wall lamp per floor. Origin = top-left of the shaft.

@export var width := 1300.0
@export var floors := PackedInt32Array([2, 3, 4])
@export var floor_y := PackedFloat32Array([0.0, -900.0, -1800.0])
@export var wall := Color("6f6c6a")
@export var paint := Color("c9a23c")
@export var lamps_on := true

var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var f := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
	var top := 999999.0
	var bottom := -999999.0
	for y in floor_y:
		top = minf(top, y)
		bottom = maxf(bottom, y)
	Vec.vgrad(self, Rect2(0, top - 900, width, bottom - top + 1100), Vec.shade(wall, 0.25), wall)
	for i in floors.size():
		var y := floor_y[i]
		# floor slab of the landing side
		Vec.rect(self, Rect2(0, y, 460, 70), Vec.shade(wall, 0.35))
		Vec.rect(self, Rect2(0, y, 460, 8), Vec.shade(wall, -0.15))
		# painted floor number
		draw_string(f, Vector2(80, y - 470), str(floors[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 230, Color(paint, 0.85))
		Vec.rect(self, Rect2(80, y - 450, 150, 12), Color(paint, 0.7))
		draw_string(f, Vector2(84, y - 410), "FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(paint, 0.7))
		# wall lamp (some flicker)
		var on := lamps_on and not (i % 2 == 1 and fposmod(_t * 0.8 + i, 3.0) < 0.2)
		Vec.rect(self, Rect2(560, y - 700, 90, 26), Color("2a2c31"))
		Vec.rect(self, Rect2(566, y - 676, 78, 14), Color(2.2, 2.0, 1.6) if on else Color(0.3, 0.3, 0.28))
		if on:
			Vec.glow(self, Vector2(605, y - 640), 260, Color(1.0, 0.95, 0.75, 0.18), 0.7)
		# pipes
		Vec.rect(self, Rect2(width - 90, y - 900, 18, 900), Vec.shade(wall, 0.15))
		Vec.rect(self, Rect2(width - 60, y - 900, 10, 900), Color("8a3b30"))
	# vertical shadow at the corridor edge
	Vec.hgrad(self, Rect2(0, top - 900, 60, bottom - top + 1100), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0))
