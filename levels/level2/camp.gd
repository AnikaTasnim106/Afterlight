extends LevelBase
## Level 2 — Relief Zone Bravo (stadium camp).
##   l2a  Day → dusk: register, learn June (and Theo) left on Convoy 7 to Harbor
##        Point, meet Dr. Ward, Sam, settle Nina & Mr. Daniels, talk with Mara at the fence.
##   l2b  Night: the east fence fails. Escort Dr. Ward (and her samples) west to
##        the motor pool while Mara covers you. Sgt. Hale gives you a truck.

const MOTOR_X := 420.0
const EAST_X := 7050.0

@onready var bg: StadiumBG = $Backdrop
@onready var fence: VectorProp = $Props/FenceEast
@onready var truck: VectorProp = $Props/Truck

var mara: Companion
var nina: Actor
var das: Actor
var hale: Actor
var price: Actor
var ward: Actor
var sam: Actor
var extras: Array[Actor] = []
var stage := ""
var seen := {}
var gun: GunController
var budget := 16
var _spawn_t := 2.0


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 16
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	mara.position = Vector2(1000, 0)
	$Actors.add_child(mara)
	mara.max_hp = 5
	mara.hp = 5
	mara.add_to_group("living")
	nina = _spawn("nadia", Vector2(2760, 0), -1)
	nina.rig.carry = "baby"
	das = _spawn("mr_das", Vector2(4560, 0), 1)
	hale = _spawn("hale", Vector2(1350, 0), -1)
	hale.rig.prop_front = "rifle"
	hale.rig.pose_front = "hold_radio"
	price = _spawn("price", Vector2(2060, 0), -1)
	ward = _spawn("ward", Vector2(4380, 0), 1)
	sam = _spawn("sam", Vector2(3260, 0), -1)
	for d in [["refugee_a", 5200, 1], ["refugee_b", 5330, -1], ["refugee_a", 3600, 1], ["refugee_b", 2250, 1]]:
		var e := _spawn(d[0], Vector2(d[1], 0), d[2])
		extras.append(e)
	for pair in [["mara", mara], ["nina", nina], ["das", das], ["hale", hale], ["price", price], ["ward", ward], ["sam", sam], ["survivor", extras[0]]]:
		register(pair[0], pair[1])
		var it := get_node_or_null("Interactables/" + pair[0]) as Interactable
		if it:
			it.follow_path = (pair[1] as Node).get_path()
	for id in ["hale", "price", "ward", "sam", "nina", "survivor", "fence", "mara", "truck"]:
		enable(id, false)
	if Game.phase == "l2b":
		_night()
	else:
		Game.phase = "l2a"
		_day()


func _spawn(design: String, pos: Vector2, face: int) -> Actor:
	var a := Cast.make(design)
	a.position = pos
	$Actors.add_child(a)
	a.rig.facing = face
	return a


# =====================================================================================
# Day
# =====================================================================================

func _day() -> void:
	bg.night = 0.0
	$CanvasModulate.color = Color(0.92, 0.9, 0.88)
	for l in $Lights.get_children():
		l.base_energy = 0.0
	alex.global_position = Vector2(1150, -2)
	alex.rig.facing = 1
	mara.follow_target = alex
	mara.follow_dist = 170.0
	das.global_position = Vector2(950, 0)
	nina.global_position = Vector2(880, 0)
	ui.set_hud("DAY 2", "9:10 AM", "RELIEF ZONE BRAVO", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 2", "RELIEF ZONE BRAVO", 1.4)
	cam.follow_offset = Vector2(0, -420)
	cam.cut(Vector2(3600, -600), 0.42, 0.006)
	ui.fade(false, 1.2)
	await wait(2.4)
	ui.show_hud(true)
	cam.follow(alex, 0.9, 1.4)
	await wait(1.0)
	await conversation("hale", CampLines.hale_welcome())
	# Nina and Mr. Daniels are taken to their places
	nina.walk_to(2760.0, false, -1)
	das.walk_to(4560.0, false, 1)
	stage = "register"
	enable("price")
	set_objective("Register at the white tent")
	Inputs.input_locked = false
	if autoplay:
		await bot_walk(price.global_position.x - 160.0)
		await bot_use("price")
		await bot_walk(4300.0)
		await bot_use("ward")
		await bot_walk(sam.global_position.x - 150.0)
		await bot_use("sam")
		await bot_walk(nina.global_position.x - 150.0)
		await bot_use("nina")
		await bot_walk(6000.0)
		await bot_use("fence")


func _check_day_progress() -> void:
	if stage == "explore" and seen.has("ward") and seen.has("sam"):
		stage = "dusk"
		ui.set_hud("DAY 2", "6:40 PM", "RELIEF ZONE BRAVO", "Mara went to the east fence")
		var tw := create_tween()
		tw.tween_property(bg, "night", 0.55, 3.0)
		tw.parallel().tween_property($CanvasModulate, "color", Color(0.68, 0.6, 0.62), 3.0)
		mara.stop_nav()
		mara.walk_to(6050.0, false, 1)
		enable("fence")
		set_objective("Find Mara at the east fence")


func interact(id: String) -> void:
	match id:
		"hale":
			await conversation("hale", CampLines.hale_again())
		"price":
			if stage == "register":
				await conversation("price", CampLines.price_records())
				Game.set_flag("june_harbor_point", true)
				stage = "explore"
				for e in ["ward", "sam", "nina", "survivor", "hale"]:
					enable(e)
				set_objective("Look around the camp — the medical tent, and ask about Theo")
			else:
				await think([{think = "Convoy 7. Harbor Point. I won't forget it.", face = "determined"}])
		"ward":
			if not seen.has("ward"):
				await conversation("ward", CampLines.ward_daniels())
				seen["ward"] = true
				_check_day_progress()
			else:
				await think([{think = "She's labelling vials. Dozens of them.", face = "curious"}])
		"sam":
			if not seen.has("sam"):
				await conversation("sam", CampLines.sam())
				seen["sam"] = true
				Game.set_flag("theo_convoy7", true)
				_check_day_progress()
			else:
				await conversation("sam", [{say = "sam", t = "Tell Theo I'm keeping his pick safe!", face = "happy", shot = "two"}])
		"nina":
			await conversation("nina", CampLines.nina())
		"survivor":
			await conversation("survivor", CampLines.refugee())
		"truck":
			if stage == "escape":
				await _interact_truck()
		"fence":
			if stage == "dusk":
				await conversation("mara", CampLines.mara_fence())
				Game.save_checkpoint("l2a_end")
				await finish("l2b", "NIGHT", "02:13 AM")


# =====================================================================================
# Night — the breach
# =====================================================================================

func _night() -> void:
	bg.night = 1.0
	bg.fire = 0.6
	$CanvasModulate.color = Color(0.34, 0.35, 0.47)
	for n in [nina, das, price, sam, hale]:
		n.visible = false
	nina.set_physics_process(false)
	for e in extras:
		e.global_position.x = randf_range(1500.0, 5000.0)
	fence.label = "broken"
	fence.queue_redraw()
	alex.global_position = Vector2(3700, -2)
	alex.rig.facing = 1
	mara.global_position = Vector2(3560, 0)
	ward.global_position = Vector2(3850, 0)
	ward.rig.prop_front = "case"
	ui.set_hud("DAY 3", "2:13 AM", "RELIEF ZONE BRAVO", "")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(-150, -400)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow(alex, 0.85, 0.3)
	hale.visible = true
	hale.global_position = Vector2(3420, 0)
	hale.rig.facing = 1
	cam.shake(6.0)
	ui.toast("[sirens]  The east fence is down")
	await wait(0.6)
	dialog.partner_id = "hale"
	await dialog.run(CampLines.breach())
	dialog.end()
	hale.walk_to(MOTOR_X + 200.0, true)
	mara.armed = true
	mara.follow_target = alex
	mara.follow_dist = 160.0
	ward.add_to_group("living")
	ward.max_hp = 3
	ward.hp = 3
	ward.follow_target = alex
	ward.follow_dist = 240.0
	ward.speed_scale = 0.95
	ward.died.connect(func(): fail("Dr. Ward didn't make it."))
	mara.died.connect(func(): fail("Mara didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	for e in extras:
		e.walk_to(MOTOR_X + randf_range(100.0, 500.0), true)
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["DR. WARD", ward], ["MARA", mara]]
	ui.over.max_hp = alex.max_hp
	ui.over.set_hint("Escort Dr. Ward west · LMB shoot · R reload · H bandage · Shift run")
	set_objective("Get Dr. Ward to the motor pool — WEST")
	stage = "escape"
	enable("truck")
	# first wave: behind you, and two already in the tent rows ahead
	for k in 3:
		_spawn_zombie(Vector2(EAST_X - k * 120.0, 0))
	_spawn_zombie(Vector2(2500, 0))
	_spawn_zombie(Vector2(1750, 0))
	Inputs.input_locked = false
	if autoplay:
		_bot_night()


func _spawn_zombie(pos: Vector2) -> void:
	var z := Cast.make(["zombie_a", "zombie_b", "zombie_c"][randi() % 3], "zombie") as Zombie
	z.position = pos
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	z.state = "investigate"
	z.nav_target = Vector2(ward.global_position.x, 0)
	z.nav_run = true


func _physics_process(dt: float) -> void:
	if stage != "escape" or _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	# the escort keeps up when Alex runs
	# Dr. Ward can't run with the sample case — this is an escort, not a race
	ward.nav_run = false
	mara.nav_run = absf(mara.global_position.x - alex.global_position.x) > 400.0
	_spawn_t -= dt
	if _spawn_t <= 0.0 and budget > 0 and get_tree().get_nodes_in_group("zombies").size() < 5:
		_spawn_t = randf_range(3.0, 4.5)
		budget -= 1
		# from the east, or out of the tent rows behind you
		# from the east behind you, or climbing down from the stands ahead of you
		var x := EAST_X
		if randf() < 0.5:
			x = alex.global_position.x - randf_range(900.0, 1300.0)
			if x < MOTOR_X + 400.0:
				x = EAST_X
		_spawn_zombie(Vector2(x, 0))


func _escape_ready() -> bool:
	return absf(ward.global_position.x - MOTOR_X) < 500.0 and absf(alex.global_position.x - MOTOR_X) < 400.0


func _interact_truck() -> void:
	if not _escape_ready():
		await think([{think = "Not without Dr. Ward.", face = "determined"}])
		return
	stage = "leaving"
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	Inputs.input_locked = true
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).nav_target = Vector2(EAST_X, 0)
	hale.global_position = Vector2(MOTOR_X + 260.0, 0)
	hale.visible = true
	hale.rig.facing = -1
	dialog.partner_id = "hale"
	ui.letterbox(true, 0.4)
	await dialog.run(CampLines.truck())
	ui.hide_caption()
	for a in [alex, mara, ward]:
		a.visible = false
	truck.seed_value = 2
	truck.queue_redraw()
	cam.shot(truck.global_position + Vector2(-200, -320), 0.9, 1.0)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(truck, "position:x", truck.position.x - 1600.0, 3.0)
	await wait(1.6)
	dialog.partner_id = "mara"
	await dialog.run(CampLines.radio_end())
	ui.hide_caption()
	Game.set_flag("level2_complete", true)
	await finish("l3a", "END OF LEVEL 2", "RELIEF ZONE BRAVO")


# --- test bot ------------------------------------------------------------------------

func _bot_night() -> void:
	alex.player_controlled = false
	var t := 0.0
	while not _ended and t < 240.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var threat: Zombie = null
		var best := 800.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zp := (z as Node2D).global_position
			var d := minf(zp.distance_to(ward.global_position), zp.distance_to(alex.global_position))
			if d < best:
				best = d
				threat = z
		if threat:
			alex.walk_to(alex.global_position.x)
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if alex.hp <= 2:
			gun.use_bandage()
		if absf(alex.global_position.x - MOTOR_X) > 60.0:
			if absf(ward.global_position.x - alex.global_position.x) < 450.0:
				alex.walk_to(maxf(MOTOR_X, alex.global_position.x - 300.0), true)
		elif _escape_ready():
			await do_interact("truck")
	print("BOT camp night t=", t, " stage=", stage, " ward=", ward.hp, " mara=", mara.hp, " alex=", alex.hp)
