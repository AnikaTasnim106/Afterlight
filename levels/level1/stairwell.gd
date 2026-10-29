extends LevelBase
## Level 1 · Scene 6 — "Stairwell evacuation" (combat).
## Climb from floor 4 to the roof door on floor 7 with Nina (and her crying
## baby) and the injured Mr. Daniels. Zombies climb up from the lower floors.
##   * Every gunshot is loud (big Sound ring) and pulls more of them in.
##   * The baby's crying draws them too — stand next to Nina and HOLD E to calm her.
##   * Running is noisy. Your phone was silenced in Scene 4 (or not...).

const FY := {2: 0.0, 3: -900.0, 4: -1800.0, 5: -2700.0, 6: -3600.0, 7: -4500.0}
const DOOR_X := 2390.0

var gun: GunController
var nadia: Actor
var das: Actor
var stage := "start"
var baby := 0.0
var _cry_t := 0.0
var _calm_lock := 0.0
var _calming := 0.0
var alarm := 0.0
var budget := 12
var _spawn_t := 3.0
var _ran_flag := false
var _phone_done := false
var _floor6_spawned := false
var _survivors_joined := false


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 8 + (8 if Game.flag("ammo_box") else 0)
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	gun.empty_clicked.connect(func(): ui.toast("Empty — press R to reload"))
	nadia = _spawn("nadia", Vector2(2480, FY[5]), 1)
	nadia.rig.carry = "baby"
	nadia.max_hp = 3
	nadia.hp = 3
	das = _spawn("mr_das", Vector2(2640, FY[5]), -1)
	das.rig.limp = 1.0
	das.rig.expression = "hurt"
	das.rig.sit = 1.0
	das.max_hp = 3
	das.hp = 3
	das.speed_scale = 1.0
	register("nadia", nadia)
	register("das", das)
	nadia.died.connect(func(): fail("Nina didn't make it."))
	das.died.connect(func(): fail("Mr. Daniels didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	alex.max_hp = 5
	alex.hp = 5
	$Interactables/nadia.follow_path = nadia.get_path()
	enable("nadia", false)
	# a lone wanderer on the half-landing above floor 4
	var z := _spawn_zombie("zombie_a", Vector2(3460, FY[4] - 450))
	z.rig.facing = -1
	Sound.heard.connect(_on_sound)
	ui.over.survivors = []
	ui.over.max_hp = alex.max_hp
	alex.global_position = Vector2(2470, FY[4] - 2)
	alex.rig.facing = 1
	ui.set_hud("DAY 2", "8:04 AM", "STAIRWELL  ·  FLOOR 4", "Get to the roof (Floor 7)")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(0, -340)
	cam.cut(alex.global_position + cam.follow_offset, 0.82)
	cam.follow(alex, 0.82, 0.3)
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.set_hint("Mouse aim · LMB shoot · R reload · H bandage · W/S stairs · Shift run (noisy)")
	await dialog.run(StairLines.start())
	ui.hide_caption()
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _spawn(design: String, pos: Vector2, face: int) -> Actor:
	var a := Cast.make(design)
	a.position = pos
	$Actors.add_child(a)
	a.rig.facing = face
	return a


func _spawn_zombie(design: String, pos: Vector2) -> Zombie:
	var z := Cast.make(design, "zombie") as Zombie
	z.position = pos
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	return z


func _on_sound(pos: Vector2, _radius: float, kind: String) -> void:
	match kind:
		"gunshot":
			alarm += 2.0
			if _survivors_joined and pos.distance_to(nadia.global_position) < 900.0:
				baby = minf(1.0, baby + 0.35)
		"baby":
			alarm += 0.8
		"footsteps":
			alarm += 0.25
			if not _ran_flag:
				_ran_flag = true
				ui.rule_flash(2)
		"phone":
			alarm += 3.0


func _physics_process(dt: float) -> void:
	if _ended:
		return
	# HUD
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	ui.over.baby_level = baby if _survivors_joined else 0.0
	var fl := "STAIRS"
	for k in FY:
		if alex.stair == null and absf(alex.global_position.y - FY[k]) < 60.0:
			fl = "FLOOR %d" % k
	ui._hud_place.text = "STAIRWELL  ·  " + fl
	# first zombie warning
	if stage == "start" and alex.global_position.y < FY[4] - 150.0:
		stage = "climb"
		_thought_async(StairLines.first_zombie())
	# meeting the survivors on floor 5
	if stage == "climb" and alex.stair == null and absf(alex.global_position.y - FY[5]) < 40.0:
		stage = "meet"
		_meet()
	# phone buzz on floor 6
	if _survivors_joined and not _phone_done and alex.global_position.y < FY[6] + 200.0:
		_phone_done = true
		_phone_buzz()
	if _survivors_joined and not _floor6_spawned and alex.global_position.y < FY[5] - 300.0:
		_floor6_spawned = true
		_spawn_zombie("zombie_c", Vector2(DOOR_X + 30.0, FY[6]))
	# baby
	if _survivors_joined:
		_calm_lock = maxf(0.0, _calm_lock - dt)
		for z in get_tree().get_nodes_in_group("zombies"):
			if (z as Node2D).global_position.distance_to(nadia.global_position) < 500.0:
				baby = minf(1.0, baby + 0.25 * dt)
		baby = maxf(0.0, baby - 0.025 * dt)
		if _calm_lock > 0.0:
			baby = 0.0
		nadia.rig.baby_crying = baby > 0.3
		nadia.rig.expression = "scared" if baby > 0.3 else "worried"
		if baby > 0.3:
			_cry_t -= dt
			if _cry_t <= 0.0:
				_cry_t = 2.4
				Sound.emit(nadia.global_position, 1300.0, "baby")
	# spawning from the lower floors
	alarm = maxf(0.0, alarm - 0.12 * dt)
	if _survivors_joined and budget > 0:
		_spawn_t -= dt
		var alive := get_tree().get_nodes_in_group("zombies").size()
		if _spawn_t <= 0.0 and alive < 5:
			_spawn_t = maxf(2.8, 8.0 - alarm * 0.6)
			if alarm > 0.5:
				budget -= 1
				var floor_n := 2 if randf() < 0.5 else 3
				var design: String = ["zombie_a", "zombie_b", "zombie_c"][randi() % 3]
				var z := _spawn_zombie(design, Vector2(DOOR_X + 20.0, FY[floor_n]))
				z.state = "investigate"
				z.nav_target = Vector2(2500, FY[5])
				z.nav_run = true


func _thought_async(lines: Array) -> void:
	# non-blocking thought (combat keeps going)
	await dialog.run(lines)
	ui.hide_caption()


func _meet() -> void:
	Inputs.input_locked = true
	alex.velocity = Vector2.ZERO
	gun.set_active(false)
	await conversation("das", StairLines.meet_survivors(), false, 170.0)
	dialog.end()
	gun.set_active(true)
	var tw := create_tween()
	tw.tween_property(das.rig, "sit", 0.0, 0.6)
	await tw.finished
	nadia.add_to_group("living")
	das.add_to_group("living")
	nadia.follow_target = alex
	nadia.follow_dist = 190.0
	das.follow_target = alex
	das.follow_dist = 330.0
	nadia.nav_run = false
	das.nav_run = false
	_survivors_joined = true
	baby = 1.0
	alarm += 3.0
	_spawn_t = 1.5
	ui.over.survivors = [["NINA", nadia], ["MR. DANIELS", das]]
	enable("nadia")
	set_objective("Protect Nina & Mr. Daniels — get to the roof (Floor 7)")
	ui.over.set_hint("HOLD E next to Nina to calm the baby · LMB shoot · R reload · H bandage")
	_thought_async(StairLines.they_heard())


func _phone_buzz() -> void:
	if Game.flag("phone_silent"):
		ui.toast("Your phone buzzed — silently. Rule 2 kept you hidden.")
		_thought_async(StairLines.phone_silent())
	else:
		Sound.emit(alex.global_position, 1500.0, "phone")
		ui.rule_flash(2)
		_thought_async(StairLines.phone_loud())


func interact(id: String) -> void:
	match id:
		"nadia":
			await _calm_baby()
		"roof":
			var ok := nadia.global_position.distance_to(alex.global_position) < 520.0 and das.global_position.distance_to(alex.global_position) < 620.0
			if not _survivors_joined or not ok:
				await think(StairLines.roof_wait())
			else:
				gun.set_active(false)
				ui.over.combat_visible = false
				Game.set_flag("das_hp", das.hp)
				Game.set_flag("nadia_hp", nadia.hp)
				await finish("s7", "SCENE 7", "ROOFTOP EXTRACTION")


func _calm_baby() -> void:
	if baby <= 0.3:
		await think([{think = "She's quiet for now.", face = "relieved"}])
		return
	gun.set_active(false)
	alex.rig.expression = "worried"
	alex.rig.pose_front = "open_hand"
	nadia.stop_nav()
	_calming = 0.0
	ui.toast("Humming...")
	while _calming < 2.0:
		await get_tree().physics_frame
		var holding := Input.is_action_pressed("interact") or autoplay
		if not holding or not alex.alive or alex.global_position.distance_to(nadia.global_position) > 260.0:
			break
		_calming += get_physics_process_delta_time()
	alex.rig.pose_front = "none"
	if _calming >= 2.0:
		baby = 0.0
		_calm_lock = 10.0
		ui.toast("The baby is calm.")
	nadia.follow_target = alex
	gun.set_active(true)


# --- test bot ------------------------------------------------------------------------

func _bot() -> void:
	var path := [Vector2(2480, FY[5]), Vector2(2500, FY[6]), Vector2(2470, FY[7])]
	var i := 0
	var t := 0.0
	alex.player_controlled = false
	while not _ended and t < 240.0:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		if Inputs.input_locked or _busy:
			continue
		# threats first
		var threat: Zombie = null
		var best := 1100.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			var d := zz.global_position.distance_to(alex.global_position)
			if d < best and absf(zz.global_position.y - alex.global_position.y) < 520.0:
				best = d
				threat = zz
		if threat:
			alex.nav_target = Vector2.INF
			var zones: Array = threat.rig.hit_zones()
			gun.bot_aim = zones[0] if randf() < 0.5 else (zones[2] + zones[3]) * 0.5
			if gun.in_mag == 0:
				gun.reload()
			elif best < 950.0:
				gun.fire()
			continue
		gun.bot_aim = alex.global_position + Vector2(300 * alex.rig.facing, -330)
		if gun.in_mag < 4 and gun.reserve > 0 and not gun.reloading:
			gun.reload()
		if alex.hp <= 2 and int(Game.flag("bandages", 0)) > 0:
			gun.use_bandage()
		if _survivors_joined and baby > 0.5 and alex.global_position.distance_to(nadia.global_position) < 250.0:
			await do_interact("nadia")
			continue
		# keep the group together
		if _survivors_joined and (das.global_position.distance_to(alex.global_position) > 650.0):
			alex.nav_target = Vector2.INF
			continue
		if i < path.size():
			var goal: Vector2 = path[i]
			alex.nav_target = goal
			alex.nav_stop = 20.0
			if alex.stair == null and absf(alex.global_position.y - goal.y) < 30.0 and absf(alex.global_position.x - goal.x) < 40.0:
				i += 1
				alex.nav_target = Vector2.INF
		else:
			alex.nav_target = Vector2.INF
			await wait(1.0)
			await do_interact("roof")
	print("BOT stairwell ended=", _ended, " t=", t, " pos=", alex.global_position, " hp=", alex.hp, " nadia=", nadia.hp, " das=", das.hp, " budget=", budget)
