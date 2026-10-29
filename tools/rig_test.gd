extends Node2D
## Dev tool: cast lineup with gameplay poses -> screenshot.
var t := 0.0
var done := false
var rigs := []

func _ready() -> void:
	var bg := ColorRect.new(); bg.color = Color(0.36, 0.33, 0.36); bg.size = Vector2(1920, 1080); add_child(bg)
	var specs := [
		["alex", 120, 470, "determined", {"aiming": true, "prop_front": "gun", "aim_angle": 0.15}],
		["mara", 330, 470, "neutral", {}],
		["soldier", 540, 470, "determined", {"prop_front": "rifle", "pose_front": "hold_radio"}],
		["nadia", 760, 470, "worried", {"carry": "baby", "baby_crying": true}],
		["mr_das", 980, 470, "hurt", {"limp": 1.0, "velocity_x": 150.0}],
		["mrs_chowdhury", 1190, 470, "worried", {}],
		["rafi", 1400, 470, "smile", {"pose_front": "point"}],
		["zombie_a", 1610, 470, "zombie", {"zombie": true, "velocity_x": 85.0}],
		["zombie_b", 1800, 470, "zombie", {"zombie": true}],
		["zombie_c", 300, 1030, "zombie", {"down": 1.0}],
		["june", 600, 1030, "neutral", {"sit": 1.0}],
		["alex", 900, 1030, "scared", {"reload_t": 0.3, "prop_front": "gun"}],
	]
	for s in specs:
		var r := CharacterRig.new()
		r.design = load("res://characters/designs/%s.tres" % s[0])
		r.position = Vector2(s[1], s[2])
		r.scale = Vector2(0.92, 0.92)
		r.expression = s[3]
		for k in s[4]:
			r.set(k, s[4][k])
		add_child(r)

func _process(dt: float) -> void:
	t += dt
	if t > 1.2 and not done:
		done = true
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/cast.png")
		get_tree().quit()
