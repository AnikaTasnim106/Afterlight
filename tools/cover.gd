extends Node2D
## Key-art / cover renderer (dev tool). Builds a poster shot from game assets,
## saves $COVER_OUT (png) after a moment and quits.
## xvfb-run godot --rendering-driver opengl3 --resolution 1260x1000 res://tools/cover.tscn

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_semi: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")


func _ready() -> void:
	get_tree().root.content_scale_size = Vector2i(1260, 1000)
	var mod := CanvasModulate.new()
	mod.color = Color(0.42, 0.43, 0.6)
	add_child(mod)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 1.1
	e.glow_strength = 1.15
	e.glow_bloom = 0.08
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.glow_hdr_threshold = 1.0
	env.environment = e
	add_child(env)

	var sky := SkyBG.new()
	sky.width = 2400.0
	sky.height = 1700.0
	sky.horizon = -40.0
	sky.night = 0.97
	sky.position = Vector2(-1200, 0)
	add_child(sky)

	var ant := VectorProp.new()
	ant.kind = "antenna"
	ant.size = Vector2(0, 1250)
	ant.position = Vector2(470, 0)
	ant.power = 1.0
	add_child(ant)

	var rail := VectorProp.new()
	rail.kind = "roof_rail"
	rail.size = Vector2(2600, 0)
	rail.position = Vector2(-1300, -20)
	add_child(rail)

	var fl := WalkFloor.new()
	fl.width = 2600.0
	fl.style = 2
	fl.color = Color("4e4a48")
	fl.position = Vector2(-1300, 0)
	add_child(fl)

	# the infected coming out of the dark, left
	for p in [[-640.0, "zombie_b", 0.55], [-470.0, "zombie_a", 0.8], [-800.0, "zombie_c", 0.42]]:
		var z := Cast.make(p[1], "zombie")
		z.position = Vector2(p[0], 0)
		add_child(z)
		z.set_physics_process(false)
		z.rig.facing = 1
		z.rig.pose_front = "reach"
		z.rig.pose_back = "reach"
		z.modulate = Color(p[2] * 0.6, p[2] * 0.65, p[2] * 0.85)

	# June with the radio, behind Alex
	var june := Cast.make("june")
	june.position = Vector2(250, 0)
	add_child(june)
	june.set_physics_process(false)
	june.rig.facing = -1
	june.rig.expression = "determined"
	june.rig.prop_front = "radio"
	june.rig.pose_front = "radio_ear"

	# Alex, aiming into the dark
	var alex := Cast.make("alex")
	alex.position = Vector2(30, 0)
	add_child(alex)
	alex.set_physics_process(false)
	alex.rig.facing = -1
	alex.rig.expression = "determined"
	alex.rig.prop_front = "gun"
	alex.rig.aiming = true
	alex.rig.aim_angle = PI + 0.12

	# light: warm dawn rim from the right, cold fill on the infected
	for l in [[Vector2(760, -380), 1300.0, Color(1.0, 0.6, 0.35), 1.5], [Vector2(-560, -300), 600.0, Color(0.85, 0.85, 0.75), 0.45], [Vector2(160, -420), 600.0, Color(1.0, 0.85, 0.7), 0.8]]:
		var pl := SoftLight.new()
		pl.position = l[0]
		pl.radius = l[1]
		pl.color = l[2]
		pl.base_energy = l[3]
		add_child(pl)

	# dawn glow on the horizon behind the antenna
	var glow := Glow.new()
	glow.z_index = -1
	add_child(glow)
	move_child(glow, 4)
	# the torch: Alex's flashlight beam cuts into the dark
	var beam := Beam.new()
	add_child(beam)

	var cam := Camera2D.new()
	cam.position = Vector2(-70, -470)
	cam.zoom = Vector2(0.93, 0.93)
	add_child(cam)
	cam.make_current()

	# title block
	var ui := CanvasLayer.new()
	add_child(ui)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.02, 0.02, 0.05, 0.92), Color(0.02, 0.02, 0.05, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.size = Vector2(1260, 420)
	ui.add_child(shade)
	var bot := TextureRect.new()
	var g2 := Gradient.new()
	g2.colors = PackedColorArray([Color(0.02, 0.02, 0.05, 0.0), Color(0.02, 0.02, 0.05, 0.85)])
	var gt2 := GradientTexture2D.new()
	gt2.gradient = g2
	gt2.fill_to = Vector2(0, 1)
	bot.texture = gt2
	bot.stretch_mode = TextureRect.STRETCH_SCALE
	bot.position = Vector2(0, 820)
	bot.size = Vector2(1260, 180)
	ui.add_child(bot)
	_text(ui, "AFTERLIGHT", font_title, 236, Color("f6f1e8"), 40, 14)
	_text(ui, "THE BEGINNING OF APOCALYPSE", font_semi, 50, Color("ec9f3c"), 286, 8)
	_text(ui, "SIX RULES  ·  ONE SISTER  ·  ONE SIGNAL", font_semi, 36, Color(1, 1, 1, 0.8), 920, 6)

	await get_tree().create_timer(0.8).timeout
	beam.origin = alex.rig.muzzle_global_position()
	beam.queue_redraw()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("COVER_OUT")
	if out == "":
		out = "user://cover.png"
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


func _text(parent: Node, t: String, f: Font, sz: int, col: Color, y: float, spacing: int) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_y", 5)
	l.add_theme_constant_override("shadow_outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1260, sz * 1.2)
	l.position = Vector2(0, y)
	parent.add_child(l)


class Beam extends Node2D:
	var origin := Vector2.ZERO
	func _draw() -> void:
		for k in 5:
			var spread := 60.0 + k * 40.0
			var a := 0.12 - k * 0.02
			var tip := origin + Vector2(-1000, 130)
			var pts := PackedVector2Array([origin + Vector2(0, -6), tip + Vector2(0, -spread), tip + Vector2(0, spread), origin + Vector2(0, 6)])
			draw_colored_polygon(pts, Color(1.25, 1.15, 0.95, a))
		draw_circle(origin, 10, Color(2.6, 2.4, 1.9, 1.0))


class Glow extends Node2D:
	func _draw() -> void:
		Vec.glow(self, Vector2(620, -40), 760, Color(1.5, 0.6, 0.3, 0.32), 0.4)
		Vec.glow(self, Vector2(560, -60), 420, Color(2.0, 1.1, 0.5, 0.5), 0.4)
