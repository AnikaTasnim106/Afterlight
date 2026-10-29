extends LevelBase
## Level 5 — Harbor Point Medical Campus (3 floors + stairwell).
##   l5a  Day: badges in the lobby, records office (June: Ward 4, sealed),
##        duty roster (Theo: Ward 4 night shift), the lab (Dr. Chen, the compound).
##   l5b  Night: sneak from floor 3 to the basement service door on floor 1.
##        Guards with flashlights patrol — they don't shoot, but if they see you
##        (or Mara) you're marched back to the last checkpoint. Crouch (C)
##        behind carts and beds to stay out of their light.

const F1 := 0.0
const F2 := -900.0
const F3 := -1800.0
const SERVICE_X := 230.0

var mara: Companion
var ward: Actor
var holly: Actor
var chen: Actor
var stage := ""
var seen := {}
var guards: Array = []
var covers: Array = []
var checkpoint := Vector2.ZERO
var _caught := false


func _ready() -> void:
	super._ready()
	alex.can_crouch = true
	alex.get_node("Gun").set_active(false)
	mara = Cast.make("mara", "companion") as Companion
	$Actors.add_child(mara)
	ward = Cast.make("ward")
	$Actors.add_child(ward)
	holly = Cast.make("holly")
	holly.position = Vector2(950, F1)
	$Actors.add_child(holly)
	holly.rig.facing = -1
	chen = Cast.make("chen")
	chen.position = Vector2(1650, F3)
	$Actors.add_child(chen)
	chen.rig.facing = -1
	for p in [["mara", mara], ["ward", ward], ["holly", holly], ["chen", chen]]:
		register(p[0], p[1])
	for n in $Props.get_children():
		if n is VectorProp and n.kind in ["cart", "hospital_bed", "shop_counter"]:
			covers.append(n)
	for id in ["holly", "records", "roster", "chen", "service"]:
		enable(id, false)
	$Interactables/holly.follow_path = holly.get_path()
	$Interactables/chen.follow_path = chen.get_path()
	if Game.phase == "l5b":
		_night()
	else:
		Game.phase = "l5a"
		_day()


func _physics_process(dt: float) -> void:
	if _ended:
		return
	var fl := "STAIRWELL"
	if alex.stair == null:
		for pair in [[F1, "GROUND FLOOR"], [F2, "FLOOR 2"], [F3, "FLOOR 3"]]:
			if absf(alex.global_position.y - pair[0]) < 60.0:
				fl = pair[1]
	ui._hud_place.text = "HARBOR POINT  ·  " + fl
	mara.crouching = alex.crouching
	mara.nav_run = mara.global_position.distance_to(alex.global_position) > 450.0
	if stage == "night":
		_cover_update()
		_guards_update(dt)


# =====================================================================================
# Day
# =====================================================================================

func _day() -> void:
	$CanvasModulate.color = Color(0.9, 0.9, 0.92)
	alex.global_position = Vector2(420, F1 - 2)
	mara.global_position = Vector2(260, F1)
	ward.global_position = Vector2(560, F1)
	ward.rig.prop_front = "case"
	ui.set_hud("DAY 4", "9:05 AM", "HARBOR POINT", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 5", "HARBOR POINT", 1.4)
	cam.follow_offset = Vector2(100, -400)
	cam.cut(alex.global_position + cam.follow_offset, 0.9)
	ui.fade(false, 1.0)
	ui.show_hud(true)
	cam.follow(alex, 0.9, 0.4)
	await conversation("holly", HospitalLines.lobby())
	# Ward heads up to the lab on her own
	ward.nav_target = Vector2(1450, F3)
	ward.nav_stop = 20.0
	mara.follow_target = alex
	mara.follow_dist = 160.0
	stage = "day"
	for id in ["records", "roster", "holly"]:
		enable(id)
	set_objective("Records office (floor 2) — find June")
	ui.toast("W / S  ·  stairs (east end)")
	Inputs.input_locked = false
	if autoplay:
		await bot_go(Vector2(1300, F2))
		await bot_use("records")
		await bot_use("roster")
		await bot_go(Vector2(1900, F3))
		await bot_use("chen")


func interact(id: String) -> void:
	match id:
		"holly":
			await conversation("holly", [{say = "holly", t = "Records on two, lab on three. And *please* — nowhere east.", face = "worried", shot = "two"}])
		"records":
			if not seen.has("records"):
				await think(HospitalLines.records())
				seen["records"] = true
				Game.set_flag("june_sealed", true)
				_day_progress()
		"roster":
			if not seen.has("roster"):
				Inputs.input_locked = true
				if mara.global_position.distance_to(alex.global_position) > 400.0:
					mara.global_position = alex.global_position + Vector2(-160, 0)
				dialog.partner_id = "mara"
				await dialog.run(HospitalLines.roster())
				dialog.end()
				seen["roster"] = true
				Game.set_flag("theo_ward4", true)
				_day_progress()
		"chen":
			if stage == "lab":
				await conversation("chen", HospitalLines.lab())
				Game.set_flag("compound_ready_dawn", true)
				await finish("l5b", "NIGHT", "11:48 PM")
			else:
				await conversation("chen", [{say = "chen", t = "Elena tells me you got her here alive. Thank you.", face = "smile", shot = "two"}])
		"service":
			if stage == "night":
				stage = "done"
				Inputs.input_locked = true
				dialog.partner_id = "mara"
				await dialog.run(HospitalLines.hatch())
				ui.hide_caption()
				Game.set_flag("level5_complete", true)
				await finish("l6a", "END OF LEVEL 5", "HARBOR POINT")


func _day_progress() -> void:
	if seen.has("records") and seen.has("roster"):
		stage = "lab"
		enable("chen")
		set_objective("Find Dr. Ward in the lab (floor 3)")
	elif seen.has("records"):
		set_objective("Check the duty roster board (floor 2)")
	else:
		set_objective("Check the records terminal (floor 2)")


# =====================================================================================
# Night
# =====================================================================================

func _night() -> void:
	$CanvasModulate.color = Color(0.32, 0.34, 0.45)
	for l in $Lights.get_children():
		l.base_energy *= 0.6
	holly.visible = false
	ward.visible = false
	chen.visible = false
	alex.global_position = Vector2(2500, F3 - 2)
	mara.global_position = Vector2(2380, F3)
	mara.follow_target = alex
	mara.follow_dist = 45.0
	_add_guard(Vector2(1200, F3), 300.0, 1900.0)
	_add_guard(Vector2(3250, F2), 3250.0, 3250.0, -1)
	_add_guard(Vector2(2400, F1), 900.0, 2700.0)
	_add_guard(Vector2(1300, F2), 400.0, 2300.0)
	checkpoint = alex.global_position
	ui.set_hud("DAY 4", "11:48 PM", "HARBOR POINT", "")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(0, -400)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow(alex, 0.85, 0.3)
	dialog.partner_id = "mara"
	await dialog.run(HospitalLines.night_start())
	dialog.end()
	stage = "night"
	enable("service")
	ui.over.set_hint("C crouch · hide behind carts and beds · stay out of the flashlights · W/S stairs")
	set_objective("Reach the service door — ground floor, far west")
	Inputs.input_locked = false
	if autoplay:
		_bot_night()


func _add_guard(pos: Vector2, a: float, b: float, face := 1) -> void:
	var g := Cast.make("soldier" if guards.size() % 2 == 0 else "soldier_b")
	g.position = pos
	$Actors.add_child(g)
	g.rig.facing = face
	g.rig.prop_front = "rifle"
	g.rig.pose_front = "hold_radio"
	var light := SoftLight.new()
	light.radius = 560.0
	light.base_energy = 1.0
	light.color = Color(1.0, 0.95, 0.75)
	light.position = Vector2(260 * face, -300)
	g.add_child(light)
	var cone := _Cone.new()
	g.add_child(cone)
	guards.append({"g": g, "a": a, "b": b, "home": pos, "dir": float(face), "wait": 0.0, "light": light, "cone": cone, "face0": face})


func _cover_update() -> void:
	for a in [alex, mara]:
		a.in_cover = false
		if a.crouching:
			for c in covers:
				if absf(a.global_position.x - c.global_position.x) < maxf(90.0, c.size.x * 0.5) and absf(a.global_position.y - c.global_position.y) < 60.0:
					a.in_cover = true


func _guards_update(dt: float) -> void:
	if _caught or Inputs.input_locked:
		return
	for gd in guards:
		var g: Actor = gd.g
		if gd.a != gd.b:
			if gd.wait > 0.0:
				gd.wait -= dt
				if gd.wait <= 0.0:
					gd.dir = -gd.dir
			else:
				var target_x: float = gd.b if gd.dir > 0.0 else gd.a
				if absf(g.global_position.x - target_x) < 12.0:
					gd.wait = 2.2
					g.walk_to(g.global_position.x)
				else:
					g.walk_to(target_x)
		var f := g.rig.facing
		gd.light.position.x = 260.0 * f
		gd.cone.facing = f
		# like most stealth games, only Alex can be spotted — Mara follows his lead
		for who in [alex]:
			var dx: float = who.global_position.x - g.global_position.x
			var same_floor := absf(who.global_position.y - g.global_position.y) < 60.0 and who.stair == null
			var in_front := int(signf(dx)) == f
			var reach := 520.0 if not who.crouching else 330.0
			if same_floor and in_front and absf(dx) < reach and not who.in_cover:
				if autoplay:
					print("  seen: ", who.name, " at ", who.global_position.x, " guard ", g.global_position.x, " crouch=", who.crouching, " stair=", who.stair)
				_get_caught(g)
				return


func _get_caught(g: Actor) -> void:
	_caught = true
	Inputs.input_locked = true
	g.walk_to(g.global_position.x)
	register("guard", g)
	dialog.partner_id = "guard"
	ui.rule_flash(3)
	await dialog.run(HospitalLines.caught())
	ui.hide_caption()
	await ui.fade(true, 0.5).finished
	for gd in guards:
		gd.g.global_position = gd.home
		gd.g.rig.facing = gd.face0
		gd.dir = float(gd.face0)
		gd.wait = 0.0
	alex.global_position = checkpoint
	mara.global_position = checkpoint + Vector2(-120, 0)
	for a in [alex, mara]:
		a.stair = null
		a.set_collision_mask_value(1, true)
		a.velocity = Vector2.ZERO
		a.last_floor_pos = a.global_position
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow(alex, 0.85, 0.2)
	await ui.fade(false, 0.5).finished
	_caught = false
	Inputs.input_locked = false
	if autoplay:
		print("CAUGHT -> checkpoint ", checkpoint)


func _process(dt: float) -> void:
	super._process(dt)
	if stage == "night" and not _caught and alex.stair == null:
		# new checkpoint when Alex reaches a new floor's landing
		for y in [F2, F1]:
			if absf(alex.global_position.y - y) < 30.0 and checkpoint.y < y - 100.0 and alex.global_position.x > 3200.0:
				checkpoint = Vector2(3330, y - 2)
				ui.toast("Checkpoint")


class _Cone extends Node2D:
	var facing := 1
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var f := float(facing)
		draw_colored_polygon(PackedVector2Array([Vector2(30 * f, -330), Vector2(520 * f, -470), Vector2(520 * f, -40), Vector2(30 * f, -250)]), Color(1.0, 0.95, 0.6, 0.07))


# --- test bot ----------------------------------------------------------------------------

func _bot_night() -> void:
	alex.player_controlled = false
	var route := [Vector2(3330, F2), Vector2(3330, F1), Vector2(SERVICE_X, F1)]
	var i := 0
	var t := 0.0
	while not _ended and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy or _caught:
			continue
		alex.crouching = true
		var goal: Vector2 = route[mini(i, route.size() - 1)]
		if alex.stair == null and absf(alex.global_position.y - goal.y) < 30.0 and absf(alex.global_position.x - goal.x) < 40.0:
			if i >= route.size() - 1:
				alex.nav_target = Vector2.INF
				await do_interact("service")
				continue
			i += 1
			continue
		# danger: a guard on my floor facing me within 900 → hold in cover / wait
		var danger := false
		for gd in guards:
			var g: Actor = gd.g
			var dx := alex.global_position.x - g.global_position.x
			if absf(alex.global_position.y - g.global_position.y) < 60.0 and int(signf(dx)) == g.rig.facing and absf(dx) < 850.0:
				danger = true
		var next_x := goal.x
		if alex.stair == null and absf(alex.global_position.y - goal.y) < 30.0:
			# move from cover to cover
			if danger:
				if alex.in_cover:
					alex.nav_target = Vector2.INF
					alex.walk_to(alex.global_position.x)
					continue
				var best := INF
				for c in covers:
					if absf(c.global_position.y - alex.global_position.y) < 60.0 and absf(c.global_position.x - alex.global_position.x) < best:
						best = absf(c.global_position.x - alex.global_position.x)
						next_x = c.global_position.x
		alex.nav_target = Vector2(next_x, goal.y)
		alex.nav_stop = 10.0
	print("BOT hospital night t=", t, " stage=", stage, " pos=", alex.global_position)
