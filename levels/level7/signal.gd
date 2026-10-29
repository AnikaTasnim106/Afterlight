extends LevelBase
## Level 7 — The Signal.
##   l7a  Harbor Point roof, before dawn. Bar both roof doors (rule 1), then June
##        powers up the antenna. The hum is rule two broken on purpose: everything
##        left in the hospital comes for it. Hold the doors, keep June alive and
##        reset the drifting relays (HOLD E) until the protocol is out.
##   l7b  Dawn. Sgt. Hale lands. Carry Dr. Chen's three cold cases from the west
##        stair landing to the helicopter (no gun while carrying). Goodbyes.

const WEST_DOOR := 435.0
const EAST_DOOR := 3735.0
const RELAY_W := 1000.0
const RELAY_E := 3200.0
const CONSOLE_X := 1840.0
const HELI_X := 2750.0
const BROADCAST_SECS := 66.0

@onready var sky: SkyBG = $Sky
@onready var antenna: VectorProp = $Props/Antenna
@onready var heli: Helicopter = $Props/Heli
@onready var modulate_node: CanvasModulate = $CanvasModulate

var gun: GunController
var mara: Companion
var june: Actor
var theo: Actor
var hale: Actor
var soldier: Actor
var stage := ""
var progress := 0.0
var drifting := ""
var _drifts_done := 0
var _spawn_t := 3.0
var _budget := 0
var _door := {"w": "closed", "e": "closed"}
var _bang := {"w": 0.0, "e": 0.0}
var _side_flip := false
var _hum_t := 0.0
var _halfway_said := false
var carrying := false
var loaded := 0
var _soldier_cool := 0.0
var _spawned := 0
var _brute_done := false
const RELAY_FREQ := {"w": 143.8, "e": 148.15}


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 32
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 1000.0
	mara.add_to_group("living")
	june = Cast.make("june")
	$Actors.add_child(june)
	theo = Cast.make("theo")
	$Actors.add_child(theo)
	theo.invulnerable = true
	hale = Cast.make("hale")
	$Actors.add_child(hale)
	hale.visible = false
	soldier = Cast.make("soldier")
	$Actors.add_child(soldier)
	soldier.visible = false
	for p in [["mara", mara], ["june", june], ["theo", theo], ["hale", hale], ["soldier", soldier]]:
		register(p[0], p[1])
	alex.died.connect(func(): fail("Alex didn't make it."))
	for id in ["bar_w", "bar_e", "console", "relay_w", "relay_e", "case", "heli"]:
		enable(id, false)
	heli.visible = false
	if Game.phase == "l7b":
		_dawn(true)
	else:
		Game.phase = "l7a"
		_roof()


func _zombie(x: float, design := "") -> Zombie:
	var z := Cast.make(design if design != "" else ["zombie_a", "zombie_b", "zombie_c"][randi() % 3], "zombie") as Zombie
	z.position = Vector2(x, 0)
	z.max_hp = 4 if stage == "broadcast" else 3
	$Actors.add_child(z)
	z.hp = z.max_hp
	_spawned += 1
	z.state = "investigate"
	z.nav_target = Vector2(CONSOLE_X, 0)
	z.rig.facing = 1 if x < CONSOLE_X else -1
	return z


func _set_night(n: float) -> void:
	sky.night = n
	modulate_node.color = Color(0.92, 0.9, 0.92).lerp(Color(0.42, 0.46, 0.62), n)


# =====================================================================================

func _roof() -> void:
	_set_night(0.9)
	alex.global_position = Vector2(1300, -2)
	mara.global_position = Vector2(1500, 0)
	june.global_position = Vector2(1720, 0)
	theo.global_position = Vector2(1600, 0)
	june.rig.facing = 1
	theo.rig.facing = 1
	june.rig.prop_front = "radio"
	theo.rig.expression = "tired"
	ui.set_hud("DAY 6", "4:50 AM", "HARBOR POINT · ROOF", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 7", "THE SIGNAL", 1.4)
	cam.follow_offset = Vector2(150, -420)
	cam.cut(Vector2(1700, -520), 0.75)
	ui.fade(false, 1.2)
	ui.show_hud(true)
	await wait(0.6)
	theo.rig.sit = 1.0
	dialog.partner_id = "june"
	await dialog.run(SignalLines.roof())
	dialog.end()
	cam.follow(alex, 0.75, 0.6)
	_place_mara()
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["JUNE", june], ["MARA", mara]]
	ui.over.set_hint("Bar both roof doors · then talk to June to start the broadcast")
	stage = "prep"
	Audio.music("tension")
	enable("bar_w")
	enable("bar_e")
	enable("console")
	set_objective("Rule 1 — bar both roof doors (west + east)")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _place_mara() -> void:
	mara.follow_target = null
	mara.nav_target = Vector2(780.0 if Game.flag("mara_west", false) else 1560.0, 0)
	mara.nav_stop = 30.0


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	if stage == "broadcast":
		_broadcast_tick(dt)
	if stage == "cases":
		_cases_tick(dt)


func _broadcast_tick(dt: float) -> void:
	Audio.loop("antenna", "hum", true, antenna, -4.0)
	if drifting == "":
		progress = minf(1.0, progress + dt / BROADCAST_SECS)
	antenna.power = 0.3 + progress * 0.7 if drifting == "" else 0.15
	_set_night(lerpf(0.9, 0.4, progress))
	set_objective(("Relay drifting — E at the %s relay, tune it with A/D" % ("west" if drifting == "w" else "east")) if drifting != "" else "Defend June — broadcast %d%%" % int(progress * 100.0))
	# the hum: rule two, broken on purpose
	_hum_t -= dt
	if _hum_t <= 0.0:
		_hum_t = 2.6
		Sound.emit(antenna.global_position + Vector2(0, -500), 900.0, "hum")
	# barred doors take a beating before they give
	for s in ["w", "e"]:
		if _door[s] == "banging":
			var before: float = _bang[s]
			_bang[s] = before - dt
			if int(before) != int(_bang[s]):
				cam.shake(1.5)
				Sound.emit(Vector2(WEST_DOOR if s == "w" else EAST_DOOR, -250), 500.0, "bang")
			if _bang[s] <= 0.0:
				_door[s] = "open"
				var hut: VectorProp = $Props/HutW if s == "w" else $Props/HutE
				hut.label = "open"
				hut.queue_redraw()
				cam.shake(4.0)
				Audio.sfx("crash", Vector2(WEST_DOOR if s == "w" else EAST_DOOR, -250))
				enable("bar_" + s)
				bark(SignalLines.door_broke("West" if s == "w" else "East"))
	# waves
	_spawn_t -= dt
	var alive := get_tree().get_nodes_in_group("zombies").size()
	if _spawn_t <= 0.0 and _budget > 0 and alive < 5:
		_spawn_t = randf_range(2.6, 3.8) if drifting == "" else 1.8
		_side_flip = not _side_flip
		var order := ["w", "e"] if _side_flip else ["e", "w"]
		for s in order:
			if _door[s] == "barred":
				_door[s] = "banging"
				_bang[s] = 9.0
				bark(SignalLines.banging("west" if s == "w" else "east"))
				break
			if _door[s] == "open" or _door[s] == "closed":
				if _door[s] == "closed":
					_door[s] = "open"
					var hut2: VectorProp = $Props/HutW if s == "w" else $Props/HutE
					hut2.label = "open"
					hut2.queue_redraw()
				_zombie(WEST_DOOR if s == "w" else EAST_DOOR)
				_budget -= 1
				break
	# relays drift twice
	if drifting == "" and ((_drifts_done == 0 and progress >= 0.3) or (_drifts_done == 1 and progress >= 0.68)):
		drifting = "w" if _drifts_done == 0 else "e"
		var r: VectorProp = $Props/RelayW if drifting == "w" else $Props/RelayE
		r.label = ""
		r.queue_redraw()
		enable("relay_" + drifting)
		bark(SignalLines.drift("west" if drifting == "w" else "east"))
	if not _brute_done and progress >= 0.45:
		_brute_done = true
		_spawn_brute()
	if not _halfway_said and progress >= 0.5:
		_halfway_said = true
		bark(SignalLines.halfway())
	if progress >= 1.0 and drifting == "":
		stage = "done"
		_broadcast_done()


func _spawn_brute() -> void:
	var s := "e"
	if _door.e != "open" and _door.w == "open":
		s = "w"
	if _door[s] != "open":
		_door[s] = "open"
		var hut: VectorProp = $Props/HutE if s == "e" else $Props/HutW
		hut.label = "open"
		hut.queue_redraw()
		enable("bar_" + s)
		cam.shake(8.0)
		Audio.sfx("crash", Vector2(EAST_DOOR if s == "e" else WEST_DOOR, -250))
	var z := _zombie(EAST_DOOR if s == "e" else WEST_DOOR, "zombie_c")
	z.scale = Vector2(1.28, 1.28)
	z.max_hp = 12
	z.hp = 12
	z.speed_scale = 0.72
	z.damage = 2
	z.sight = 900.0
	z.rig.flinch = 1.0
	bark([{say = "mara", t = "That one's *huge!* It tore the door off — *focus fire!*", face = "scared", shot = "keep", hold = 0.4}])


func interact(id: String) -> void:
	match id:
		"bar_w", "bar_e":
			var s := id.substr(4)
			if stage == "broadcast" and _door[s] == "open":
				await _rebar(s)
				return
			if _door[s] == "closed":
				Inputs.input_locked = true
				alex.rig.pose_front = "reach"
				await wait(0.6)
				alex.rig.pose_front = "none"
				_door[s] = "barred"
				var hut: VectorProp = $Props/HutW if s == "w" else $Props/HutE
				hut.label = "barred"
				hut.queue_redraw()
				enable(id, false)
				ui.rule_flash(1)
				await think(SignalLines.bar_door())
				if _door.w == "barred" and _door.e == "barred":
					set_objective("Tell June you're ready")
				Inputs.input_locked = false
		"console":
			if stage != "prep":
				return
			if _door.w == "closed" or _door.e == "closed":
				await think(SignalLines.not_ready())
				return
			Inputs.input_locked = true
			dialog.partner_id = "june"
			await dialog.run(SignalLines.ready_q() + SignalLines.start())
			dialog.end()
			cam.follow(alex, 0.75, 0.6)
			enable("console", false)
			june.rig.pose_front = "reach"
			june.rig.sit = 1.0
			june.add_to_group("living")
			june.max_hp = 6
			june.hp = 6
			june.died.connect(func(): fail("June didn't make it."))
			ui.rule_flash(2)
			cam.shake(3.0)
			stage = "broadcast"
			Audio.music("combat", 1.0)
			_budget = 17
			_spawn_t = 4.0
			ui.over.set_hint("Defend June · E at a drifting relay · E at a broken door to re-bar · H bandage")
			Inputs.input_locked = false
		"relay_w", "relay_e":
			if drifting == id.substr(6):
				await _tune_relay(id)
		"case":
			if stage == "cases" and not carrying and loaded < 3:
				carrying = true
				gun.set_active(false)
				alex.rig.prop_front = "case"
				alex.rig.pose_front = "hold_radio"
				alex.speed_scale = 0.85
				enable("case", false)
				enable("heli")
				set_objective("Carry the case to the helicopter (%d/3)" % loaded)
		"heli":
			if stage == "cases" and carrying:
				carrying = false
				loaded += 1
				alex.rig.prop_front = "none"
				alex.rig.pose_front = "none"
				alex.speed_scale = 1.0
				gun.set_active(true)
				enable("heli", false)
				bark(SignalLines.case_loaded(loaded))
				if loaded >= 3:
					await _farewell()
				else:
					enable("case")
					set_objective("Fetch the next cold case — west stair landing (%d/3)" % loaded)


## Re-barring a broken door mid-fight: HOLD E (you can't shoot while you do it).
func _rebar(s: String) -> void:
	var door_x := WEST_DOOR if s == "w" else EAST_DOOR
	gun.set_active(false)
	alex.rig.pose_front = "reach"
	var held_t := 0.0
	while held_t < 2.2:
		await get_tree().physics_frame
		if not is_inside_tree() or _ended:
			return
		var held := Input.is_action_pressed("interact") or autoplay
		if not held or not alex.alive:
			break
		held_t += get_physics_process_delta_time()
		ui.show_prompt("Barring the door… %d%%" % int(held_t / 2.2 * 100.0), Vector2(door_x, -620))
	alex.rig.pose_front = "none"
	gun.set_active(true)
	ui.hide_prompt()
	if held_t >= 2.2:
		_door[s] = "barred"
		var hut: VectorProp = $Props/HutW if s == "w" else $Props/HutE
		hut.label = "barred"
		hut.queue_redraw()
		enable("bar_" + s, false)
		ui.rule_flash(1)
		ui.toast("Door barred again")


## Relay reset = the radio tuner: A/D to find the carrier and hold it.
## You can't shoot while tuning; E (or getting hit) steps you away.
func _tune_relay(id: String) -> void:
	var side := id.substr(6)
	var r: VectorProp = $Props/RelayW if side == "w" else $Props/RelayE
	gun.set_active(false)
	alex.player_controlled = false
	alex.velocity.x = 0.0
	alex.rig.pose_front = "reach"
	var target: float = RELAY_FREQ[side]
	ui.over.bot_tune = autoplay
	ui.over.start_tuning(target)
	ui.over.freq = target + (3.2 if randf() < 0.5 else -3.2)
	ui.over.set_hint("A / D  tune the relay to %.2f MHz · hold it steady · E step away" % target)
	var hp0 := alex.hp
	await get_tree().physics_frame
	var ok := false
	while true:
		await get_tree().physics_frame
		if not is_inside_tree() or _ended:
			return
		if not ui.over.tuning:
			ok = true
			break
		var abort := Input.is_action_just_pressed("interact") or alex.hp < hp0 or not alex.alive
		if autoplay:
			for z in get_tree().get_nodes_in_group("zombies"):
				if (z as Node2D).global_position.distance_to(alex.global_position) < 380.0:
					abort = true
		if abort:
			break
	ui.over.tuning = false
	ui.over.bot_tune = false
	ui.over.set_hint("Defend June · E at a drifting relay · E at a broken door to re-bar · H bandage")
	alex.player_controlled = not autoplay
	alex.rig.pose_front = "none"
	gun.set_active(true)
	if ok:
		r.label = "ok"
		r.queue_redraw()
		enable(id, false)
		drifting = ""
		_drifts_done += 1
		bark(SignalLines.relay_ok())


func _broadcast_done() -> void:
	Inputs.input_locked = true
	ui.hide_caption()
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).die()
	antenna.power = 1.0
	Audio.loop("antenna", "hum", false)
	Audio.music("hope", 3.0)
	await wait(1.2)
	ui.letterbox(true, 0.5)
	alex.stop_nav()
	alex.walk_to(CONSOLE_X - 200.0, false, 1)
	mara.nav_target = Vector2.INF
	mara.walk_to(CONSOLE_X - 380.0, false, 1)
	await alex.arrived
	june.rig.pose_front = "none"
	var tw := create_tween()
	tw.tween_method(_set_night, 0.4, 0.12, 6.0)
	dialog.partner_id = "june"
	await dialog.run(SignalLines.broadcast_done())
	ui.hide_caption()
	Game.set_flag("protocol_broadcast", true)
	Game.phase = "l7b"
	Game.save_checkpoint("l7b")
	await _dawn(false)


# =====================================================================================

func _dawn(direct: bool) -> void:
	# the fight is over: only the case + helicopter prompts from here on
	for id in ["bar_w", "bar_e", "relay_w", "relay_e", "console"]:
		enable(id, false)
	if direct:
		_set_night(0.12)
		antenna.power = 1.0
		alex.global_position = Vector2(CONSOLE_X - 200.0, -2)
		mara.global_position = Vector2(CONSOLE_X - 380.0, 0)
		june.global_position = Vector2(1720, 0)
		theo.global_position = Vector2(1600, 0)
		theo.rig.sit = 1.0
		june.rig.facing = 1
		for s in ["HutW", "HutE"]:
			($Props.get_node(s) as VectorProp).label = "open"
		($Props/RelayW as VectorProp).label = "ok"
		($Props/RelayE as VectorProp).label = "ok"
		ui.set_hud("DAY 6", "6:12 AM", "HARBOR POINT · ROOF", "")
		await chapter_intro("", "")
		cam.cut(alex.global_position + Vector2(300, -420), 0.75)
	june.rig.sit = 0.0
	ui.set_hud("DAY 6", "6:12 AM", "HARBOR POINT · ROOF", "")
	# the helicopter comes in out of the sunrise
	heli.visible = true
	heli.position = Vector2(HELI_X + 2000.0, -1200.0)
	cam.shot(Vector2(HELI_X - 200.0, -560.0), 0.6, 2.0)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(heli, "position", Vector2(HELI_X, 0), 5.0)
	await tw.finished
	cam.shake(6.0)
	hale.visible = true
	hale.global_position = Vector2(HELI_X, 0)
	soldier.visible = true
	soldier.global_position = Vector2(HELI_X + 60.0, 0)
	soldier.rig.prop_front = "rifle"
	hale.walk_to(HELI_X - 380.0, false, -1)
	soldier.walk_to(HELI_X + 420.0, false, 1)
	alex.walk_to(HELI_X - 600.0, false, 1)
	await hale.arrived
	dialog.partner_id = "hale"
	await dialog.run(SignalLines.hale_arrives())
	dialog.end()
	cam.follow(alex, 0.75, 0.6)
	soldier.rig.pose_front = "hold_radio"
	mara.follow_target = null
	mara.nav_target = Vector2(1300, 0)
	ui.over.combat_visible = true
	ui.over.survivors = [["JUNE", june], ["MARA", mara]]
	ui.over.set_hint("No gun while carrying · the crew covers the pad")
	gun.set_active(true)
	stage = "cases"
	_budget = 5
	_spawn_t = 5.0
	enable("case")
	set_objective("Fetch a cold case — west stair landing (0/3)")
	Inputs.input_locked = false
	if autoplay and direct:
		_bot()


func _cases_tick(dt: float) -> void:
	_spawn_t -= dt
	if _spawn_t <= 0.0 and _budget > 0 and get_tree().get_nodes_in_group("zombies").size() < 2:
		_spawn_t = randf_range(6.0, 8.0)
		_budget -= 1
		var z := _zombie(EAST_DOOR if randf() < 0.6 else WEST_DOOR)
		z.nav_target = alex.global_position
	# Hale's crew covers the pad
	_soldier_cool -= dt
	if _soldier_cool <= 0.0:
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			if absf(zz.global_position.x - soldier.global_position.x) < 1100.0:
				_soldier_cool = 1.2
				soldier.rig.facing = int(signf(zz.global_position.x - soldier.global_position.x))
				soldier.rig.recoil = 1.0
				zz.hurt(2, soldier.global_position.x)
				Sound.emit(soldier.global_position + Vector2(0, -300), 1400.0, "gunshot")
				break


func _farewell() -> void:
	stage = "farewell"
	Inputs.input_locked = true
	await wait(0.8)
	ui.hide_caption()
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).die()
	ui.letterbox(true, 0.5)
	for a in [june, mara, theo]:
		a.stop_nav()
		a.follow_target = null
	theo.rig.sit = 0.0
	theo.rig.limp = 0.5
	alex.walk_to(HELI_X - 600.0, false, 1)
	june.walk_to(HELI_X - 760.0, false, 1)
	mara.walk_to(HELI_X - 900.0, false, 1)
	theo.walk_to(HELI_X - 1040.0, false, 1)
	await alex.arrived
	await wait(1.0)
	dialog.partner_id = "hale"
	await dialog.run(SignalLines.farewell())
	ui.hide_caption()
	hale.walk_to(HELI_X)
	soldier.walk_to(HELI_X)
	await hale.arrived
	hale.visible = false
	soldier.visible = false
	cam.shot(Vector2(HELI_X - 300.0, -700.0), 0.6, 2.5)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(heli, "position", Vector2(HELI_X - 2600.0, -1500.0), 5.0)
	await wait(2.5)
	Game.set_flag("level7_complete", true)
	await finish("l8a", "END OF LEVEL 7", "THE SIGNAL")


# --- test bot ------------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	var t := 0.0
	while not _ended and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var threat: Zombie = null
		var best := 850.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zp := (z as Node2D).global_position
			var d := minf(zp.distance_to(alex.global_position), zp.distance_to(june.global_position) - 150.0)
			if d < best:
				best = d
				threat = z
		if threat and not carrying:
			alex.nav_target = Vector2.INF
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if threat and carrying and threat.global_position.distance_to(alex.global_position) < 260.0:
			alex.nav_target = Vector2.INF
			continue
		if alex.hp <= 2:
			gun.use_bandage()
		var goal := NAN
		var use := ""
		match stage:
			"prep":
				if _door.w == "closed":
					goal = WEST_DOOR; use = "bar_w"
				elif _door.e == "closed":
					goal = EAST_DOOR; use = "bar_e"
				else:
					goal = CONSOLE_X - 120.0; use = "console"
			"broadcast":
				if drifting != "":
					goal = RELAY_W if drifting == "w" else RELAY_E
					use = "relay_" + drifting
				else:
					goal = CONSOLE_X + 260.0
			"cases":
				if carrying:
					goal = HELI_X; use = "heli"
				else:
					goal = WEST_DOOR; use = "case"
		if is_nan(goal):
			continue
		if absf(alex.global_position.x - goal) < 40.0:
			alex.nav_target = Vector2.INF
			if use != "":
				await do_interact(use)
		else:
			alex.nav_target = Vector2(goal, 0)
			alex.nav_stop = 20.0
	print("BOT signal t=", t, " stage=", stage, " hp=", alex.hp, " june=", june.hp, " progress=", progress, " loaded=", loaded, " spawned=", _spawned)
