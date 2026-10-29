@tool
class_name Helicopter
extends Node2D
## Military transport helicopter (side view). Rotors spin; lights blink.
## Origin = ground contact under the skids. Facing -1 = nose to the left.

@export var facing := -1:
	set(v):
		facing = v
		queue_redraw()
@export var door_open := true
@export var body_color := Color("4a5236")
@export var searchlight := false
@export var rotor_speed := 1.0

var _t := 0.0


func _process(dt: float) -> void:
	if not Engine.is_editor_hint():
		Audio.loop("heli%d" % get_instance_id(), "heli", is_visible_in_tree() and rotor_speed > 0.1, self, 2.0)
	_t += dt * rotor_speed
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-facing, 1))
	var c := body_color
	var dark := Vec.shade(c, 0.3)
	# skids
	Vec.line(self, Vector2(-260, -6), Vector2(220, -6), Color("23251c"), 8.0)
	for x in [-180.0, 140.0]:
		Vec.line(self, Vector2(x, -6), Vector2(x + 20, -70), Color("23251c"), 7.0)
	# tail boom + fin + tail rotor
	Vec.fill(self, PackedVector2Array([Vector2(-200, -230), Vector2(-680, -250), Vector2(-700, -220), Vector2(-200, -160)]), dark)
	Vec.fill(self, PackedVector2Array([Vector2(-640, -250), Vector2(-700, -360), Vector2(-720, -350), Vector2(-700, -220)]), dark)
	var tr := Vector2(-705, -300)
	for i in 2:
		var a := _t * 30.0 + i * PI * 0.5
		Vec.line(self, tr - Vector2.from_angle(a) * 70.0, tr + Vector2.from_angle(a) * 70.0, Color(0.1, 0.1, 0.1, 0.55), 6.0)
	# fuselage
	var body := PackedVector2Array([Vector2(-230, -80), Vector2(200, -80), Vector2(320, -120), Vector2(360, -190), Vector2(330, -270), Vector2(220, -330), Vector2(-160, -330), Vector2(-240, -260)])
	Vec.fill(self, body, c)
	Vec.fill(self, PackedVector2Array([Vector2(-230, -80), Vector2(200, -80), Vector2(320, -120), Vector2(300, -140), Vector2(-220, -120)]), dark)
	# cockpit glass
	Vec.fill(self, PackedVector2Array([Vector2(220, -320), Vector2(320, -265), Vector2(345, -190), Vector2(240, -190)]), Color(0.45, 0.62, 0.75))
	Vec.line(self, Vector2(260, -300), Vector2(280, -190), dark, 4.0)
	# side door
	if door_open:
		Vec.rect(self, Rect2(-120, -300, 250, 210), Color("121410"))
		Vec.glow(self, Vector2(0, -200), 140, Color(1.4, 0.35, 0.3, 0.3))
		Vec.rect(self, Rect2(-150, -305, 30, 220), Vec.shade(c, 0.15))
	else:
		Vec.rect(self, Rect2(-120, -300, 250, 210), Vec.shade(c, 0.08))
		Vec.stroke(self, Vec.rrect_pts(Rect2(-120, -300, 250, 210), 6), dark, 3.0)
	# markings
	Vec.rect(self, Rect2(-210, -240, 60, 30), Color("d9d2c5"))
	draw_string(preload("res://assets/fonts/BarlowCondensed-Bold.ttf"), Vector2(-206, -216), "K-2", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("23251c"))
	# rotor mast + blurred blades
	Vec.rect(self, Rect2(-30, -370, 60, 44), dark)
	var blade := absf(sin(_t * 14.0))
	Vec.ellipse(self, Vector2(0, -378), 560, 10, Color(0.1, 0.1, 0.1, 0.25))
	Vec.line(self, Vector2(-560 * blade, -378), Vector2(560 * blade, -378), Color(0.12, 0.12, 0.12, 0.7), 8.0)
	# lights
	if fposmod(_t, 1.0) < 0.2:
		Vec.glow(self, Vector2(-700, -230), 40, Color(3.0, 0.4, 0.3, 0.9))
		Vec.glow(self, Vector2(0, -80), 30, Color(3.0, 0.4, 0.3, 0.8))
	if searchlight:
		draw_colored_polygon(PackedVector2Array([Vector2(300, -100), Vector2(-200, 900), Vector2(500, 900)]), Color(1, 1, 0.9, 0.08))
	draw_set_transform(Vector2.ZERO)
