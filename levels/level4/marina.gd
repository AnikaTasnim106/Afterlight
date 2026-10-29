extends LevelBase
## Level 4 — The Marina (l4a). Meet Gus, fetch two fuel cans from the fuel
## dock at the far end of the pier (one at a time — you can't shoot while
## carrying), load his boat, a quiet moment with Mara, cast off.

const BOAT_X := 1150.0
const LOCKER_X := 5650.0

var gun: GunController
var mara: Companion
var ward: Actor
var gus: Actor
var stage := ""
var loaded := 0
var carrying := false
var _spawn_t := 6.0
var _hinted := false


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 16
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	mara.position = Vector2(300, 0)
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 700.0
	mara.max_hp = 6
	mara.hp = 6
	mara.add_to_group("living")
	ward = Cast.make("ward")
	ward.position = Vector2(180, 0)
	$Actors.add_child(ward)
	ward.rig.prop_front = "case"
	gus = Cast.make("gus")
	gus.position = Vector2(880, 0)
	$Actors.add_child(gus)
	gus.rig.facing = -1
	for p in [["mara", mara], ["ward", ward], ["gus", gus]]:
		register(p[0], p[1])
	$Interactables/gus.follow_path = gus.get_path()
	mara.died.connect(func(): fail("Mara didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	for x in [2300.0, 3300.0, 4300.0, 5100.0]:
		_zombie(Vector2(x, 0))
	for id in ["gus", "locker", "load"]:
		enable(id, false)
	enable("gus")
	alex.global_position = Vector2(420, -2)
	ui.set_hud("DAY 3", "7:48 PM", "OLD MARINA", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 4", "THE RIVER", 1.4)
	cam.follow_offset = Vector2(200, -420)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	ui.fade(false, 1.0)
	ui.show_hud(true)
	cam.follow(alex, 0.85, 0.4)
	dialog.partner_id = "mara"
	await dialog.run(RiverLines.arrive())
	dialog.end()
	mara.follow_target = alex
	mara.follow_dist = 170.0
	ward.walk_to(760.0)
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["MARA", mara]]
	stage = "meet"
	set_objective("Talk to the man on the houseboat")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _zombie(pos: Vector2) -> Zombie:
	var z := Cast.make(["zombie_a", "zombie_b", "zombie_c"][randi() % 3], "zombie") as Zombie
	z.position = pos
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	z.rig.facing = 1 if randf() < 0.5 else -1
	return z


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	mara.nav_run = mara.global_position.distance_to(alex.global_position) > 450.0
	if carrying:
		alex.speed_scale = 0.8
	else:
		alex.speed_scale = 1.0
	# a few more climb out of the water while you're fetching fuel
	if stage == "fuel":
		_spawn_t -= dt
		if _spawn_t <= 0.0 and get_tree().get_nodes_in_group("zombies").size() < 3:
			_spawn_t = randf_range(9.0, 12.0)
			var x := clampf(alex.global_position.x + (900.0 if randf() < 0.5 else -900.0), 1800.0, 5900.0)
			_zombie(Vector2(x, 0))


func interact(id: String) -> void:
	match id:
		"gus":
			if stage == "meet":
				await conversation("gus", RiverLines.gus_meet())
				stage = "fuel"
				enable("locker")
				enable("load")
				_fuel_objective()
			elif stage == "ready":
				await conversation("gus", RiverLines.cast_off())
				await finish("l4b", "THE CROSSING", "")
			else:
				await conversation("gus", [{say = "gus", t = "End of the pier. The red locker.", face = "neutral", shot = "two"}])
		"locker":
			if stage == "fuel" and not carrying and loaded < 2:
				carrying = true
				gun.set_active(false)
				alex.rig.prop_front = "can"
				alex.rig.pose_front = "hold_radio"
				ui.toast("Fuel can (%d/2)" % (loaded + 1))
				if not _hinted:
					_hinted = true
					await think(RiverLines.carry_hint())
				_fuel_objective()
		"load":
			if carrying:
				carrying = false
				loaded += 1
				alex.rig.prop_front = "none"
				alex.rig.pose_front = "none"
				gun.set_active(true)
				ui.toast("Fuel loaded (%d/2)" % loaded)
				if loaded >= 2:
					await _both_loaded()
				else:
					_fuel_objective()
			elif stage == "fuel":
				await think([{think = "Need the fuel first. End of the pier.", face = "neutral"}])


func _fuel_objective() -> void:
	if carrying:
		set_objective("Carry the fuel back to Gus's boat (%d/2)" % (loaded + 1))
	else:
		set_objective("Fetch fuel from the locker at the end of the pier (%d/2)" % loaded)


func _both_loaded() -> void:
	stage = "promise"
	Inputs.input_locked = true
	await conversation("gus", RiverLines.both_loaded(), true)
	gus.walk_to(BOAT_X + 120.0)
	Inputs.input_locked = true
	ui.set_hud("DAY 3", "8:20 PM", "OLD MARINA", "")
	await conversation("mara", RiverLines.mara_promise())
	stage = "ready"
	set_objective("Tell Gus you're ready")
	Inputs.input_locked = false


# --- test bot ----------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	var t := 0.0
	while not _ended and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var threat: Zombie = null
		var best := 700.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var d := (z as Node2D).global_position.distance_to(alex.global_position)
			if d < best:
				best = d
				threat = z
		if threat and not carrying:
			alex.walk_to(alex.global_position.x)
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if threat and carrying and best < 220.0:
			alex.walk_to(alex.global_position.x - 120.0 * signf(threat.global_position.x - alex.global_position.x))
			continue
		match stage:
			"meet":
				await bot_walk(gus.global_position.x + 160.0)
				await do_interact("gus")
			"fuel":
				if carrying:
					if absf(alex.global_position.x - BOAT_X) > 40.0:
						alex.walk_to(BOAT_X)
					else:
						await do_interact("load")
				else:
					if absf(alex.global_position.x - LOCKER_X) > 40.0:
						alex.walk_to(LOCKER_X)
					else:
						await do_interact("locker")
			"ready":
				await bot_walk(gus.global_position.x - 150.0)
				await do_interact("gus")
	print("BOT marina t=", t, " stage=", stage, " loaded=", loaded, " hp=", alex.hp)
