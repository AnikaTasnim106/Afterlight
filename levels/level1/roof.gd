extends LevelBase
## Level 1 · Scene 7 — "Rooftop extraction".
## Hold the roof until the helicopter lands (they keep coming up the stairs),
## get Nina and Mr. Daniels aboard, board last. Inside: Mara, the soldier,
## and a radio call that ends Level 1 on a cliffhanger.

const DOOR_X := 560.0
const HELI_X := 2750.0
const ETA := 32.0

@onready var heli: Helicopter = $Props/Heli
@onready var hut: VectorProp = $Props/Hut
@onready var interior: HeliInterior = $Props/Interior

var gun: GunController
var nadia: Actor
var das: Actor
var soldier: Actor
var stage := "intro"
var eta := ETA
var spawned := 0
var barred := false
var _spawn_t := 6.0
var _soldier_cool := 1.0
var boarded := {}


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 8 + (8 if Game.flag("ammo_box") else 0)
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	nadia = _spawn("nadia", Vector2(DOOR_X - 40.0, 0), 1)
	nadia.rig.carry = "baby"
	das = _spawn("mr_das", Vector2(DOOR_X - 140.0, 0), 1)
	das.rig.limp = 1.0
	das.rig.expression = "hurt"
	for a in [nadia, das]:
		a.max_hp = 3
		a.add_to_group("living")
	nadia.hp = int(Game.flag("nadia_hp", 3))
	das.hp = int(Game.flag("das_hp", 3))
	register("nadia", nadia)
	register("das", das)
	nadia.died.connect(func(): fail("Nina didn't make it."))
	das.died.connect(func(): fail("Mr. Daniels didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	heli.visible = false
	interior.visible = false
	enable("bar", false)
	enable("heli", false)
	hut.label = "open"
	alex.global_position = Vector2(DOOR_X + 60.0, -2)
	alex.rig.facing = 1
	ui.set_hud("DAY 2", "8:29 AM", "TOWER 9  ·  ROOF", "")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(220, -420)
	cam.cut(alex.global_position + cam.follow_offset, 0.8)
	cam.follow(alex, 0.8, 0.3)
	await conversation("nadia", StairLines.roof_arrive(), true, 160.0)
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["NINA", nadia], ["MR. DANIELS", das]]
	ui.over.set_hint("Hold the roof · E at the door to bar it · LMB shoot · R reload")
	nadia.follow_target = alex
	nadia.follow_dist = 200.0
	das.follow_target = alex
	das.follow_dist = 320.0
	stage = "hold"
	enable("bar")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _spawn(design: String, pos: Vector2, face: int) -> Actor:
	var a := Cast.make(design)
	a.position = pos
	$Actors.add_child(a)
	a.rig.facing = face
	return a


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	match stage:
		"hold":
			eta -= dt
			set_objective("Hold the roof  ·  helicopter in 0:%02d" % maxi(0, int(ceil(eta))))
			_spawn_t -= dt
			if _spawn_t <= 0.0 and spawned < 6:
				_spawn_t = 5.0 + (5.0 if barred and spawned < 2 else 0.0)
				spawned += 1
				if barred and spawned == 1:
					cam.shake(4.0)
					ui.toast("[thud]  Something is hitting the roof door")
					hut.label = "open"
					hut.queue_redraw()
				var z := Cast.make(["zombie_a", "zombie_b", "zombie_c"][spawned % 3], "zombie") as Zombie
				z.position = Vector2(DOOR_X - 30.0, 0)
				z.max_hp = 3
				$Actors.add_child(z)
				z.hp = 3
				z.state = "investigate"
				z.nav_target = alex.global_position
			if eta <= 0.0:
				stage = "landing"
				_land()
		"board":
			for a in [nadia, das]:
				if not boarded.has(a.name) and a.alive and absf(a.global_position.x - HELI_X) < 200.0 and a.visible:
					boarded[a.name] = true
					a.stop_nav()
					a.remove_from_group("living")
					_board_npc(a)
			_soldier_cover(dt)
		"landing":
			_soldier_cover(dt)


func _board_npc(a: Actor) -> void:
	a.walk_to(HELI_X)
	await a.arrived
	a.visible = false
	a.set_physics_process(false)
	ui.toast("%s is aboard" % ("Nina" if a == nadia else "Mr. Daniels"))


func _land() -> void:
	heli.visible = true
	heli.position = Vector2(HELI_X + 1800.0, -1100.0)
	ui.toast("Helicopter inbound!")
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(heli, "position", Vector2(HELI_X, 0), 5.5)
	await tw.finished
	cam.shake(6.0)
	soldier = _spawn("soldier", Vector2(HELI_X, 0), -1)
	soldier.rig.prop_front = "rifle"
	soldier.rig.pose_front = "point"
	register("soldier", soldier)
	soldier.walk_to(HELI_X - 260.0)
	await dialog.run(StairLines.heli_arrives())
	ui.hide_caption()
	soldier.rig.pose_front = "hold_radio"
	# the soldier waves them in: survivors make for the helicopter on their own
	for a in [nadia, das]:
		a.follow_target = null
		a.nav_target = Vector2(HELI_X, 0)
		a.nav_stop = 30.0
		a.nav_run = a == nadia
	stage = "board"
	enable("heli")
	set_objective("Cover Nina and Mr. Daniels while they reach the helicopter — then board")


func _soldier_cover(dt: float) -> void:
	if soldier == null or not soldier.alive:
		return
	_soldier_cool -= dt
	if _soldier_cool > 0.0:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		var zz := z as Zombie
		if absf(zz.global_position.x - soldier.global_position.x) < 1300.0:
			_soldier_cool = 1.1
			soldier.rig.facing = int(signf(zz.global_position.x - soldier.global_position.x))
			soldier.rig.recoil = 1.0
			zz.hurt(2, soldier.global_position.x)
			Sound.emit(soldier.global_position + Vector2(0, -300), 1400.0, "gunshot")
			cam.shake(2.0)
			return


func interact(id: String) -> void:
	match id:
		"bar":
			if not barred:
				Inputs.input_locked = true
				alex.walk_to(DOOR_X + 40.0, false, -1)
				await alex.arrived
				alex.rig.pose_front = "reach"
				await wait(0.5)
				hut.label = ""
				hut.queue_redraw()
				barred = true
				alex.rig.pose_front = "none"
				ui.rule_flash(1)
				await think([{think = "Pipe through the handle. That'll hold for a bit.", face = "determined"}])
				enable("bar", false)
		"heli":
			if boarded.size() < 2:
				await think([{think = "Nina and Mr. Daniels first.", face = "determined"}])
			else:
				await _inside()


func _inside() -> void:
	stage = "inside"
	_ended = true
	Inputs.input_locked = true
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	alex.walk_to(HELI_X)
	await alex.arrived
	await ui.fade(true, 0.8).finished
	# cabin set
	for z in get_tree().get_nodes_in_group("zombies"):
		z.queue_free()
	interior.visible = true
	var base := interior.global_position
	var mara := _spawn("mara", base + Vector2(220, 0), -1)
	var soldier2 := _spawn("soldier_b", base + Vector2(560, 0), -1)
	register("mara", mara)
	register("soldier", soldier2)
	var seat := {alex: -260.0, nadia: -520.0, das: -720.0}
	for a in seat:
		(a as Actor).visible = true
		(a as Actor).global_position = base + Vector2(seat[a], 0)
	for a in [alex, nadia, das, mara, soldier2]:
		a.set_physics_process(false)
		a.velocity = Vector2.ZERO
		a.rig.velocity_x = 0.0
		a.rig.sit = 1.0
	alex.rig.facing = 1
	nadia.rig.facing = 1
	das.rig.facing = 1
	alex.rig.expression = "tired"
	mara.rig.expression = "neutral"
	soldier2.rig.prop_front = "rifle"
	soldier2.rig.pose_front = "hold_radio"
	ui.letterbox(true, 0.01)
	ui.set_hud("DAY 2", "8:34 AM", "KESTREL-2  ·  AIRBORNE", "")
	cam.cut(base + Vector2(-20, -330), 1.25, 0.01)
	await ui.fade(false, 1.0).finished
	dialog.partner_id = "mara"
	await dialog.run(StairLines.heli_inside())
	dialog.partner_id = "soldier"
	await dialog.run(StairLines.ask_soldier())
	ui.hide_caption()
	await wait(0.6)
	interior.alarm = true
	cam.shake(5.0)
	dialog.partner_id = "mara"
	mara.rig.expression = "worried"
	alex.rig.expression = "worried"
	await dialog.run(StairLines.cliffhanger())
	ui.hide_caption()
	alex.rig.expression = "determined"
	cam.shot(alex.rig.head_global_position() + Vector2(120, 80), 2.1, 1.6, 0.03)
	await wait(2.0)
	await ui.fade(true, 1.4).finished
	ui.letterbox(false, 0.01)
	await ui.title_card("END OF LEVEL 1", "THE FIRST EVACUATION", 2.0)
	Game.set_flag("level1_complete", true)
	if autoplay:
		print("CHAPTER_DONE s7 -> l2a flags=", Game.flags)
		if OS.get_environment("CHAIN") == "1":
			Game.goto("l2a")
		else:
			get_tree().quit()
		return
	Game.goto("l2a")


# --- test bot -------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	await do_interact("bar")
	await bot_walk(1300.0)
	var t := 0.0
	while not _ended and t < 160.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var threat: Zombie = null
		var best := 1200.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var d := (z as Node2D).global_position.distance_to(alex.global_position)
			if d < best:
				best = d
				threat = z
		if threat:
			var zones: Array = threat.rig.hit_zones()
			gun.bot_aim = zones[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if stage == "board":
			if boarded.size() < 2:
				alex.walk_to(HELI_X - 80.0)
			else:
				await do_interact("heli")
	print("BOT roof t=", t, " stage=", stage)
