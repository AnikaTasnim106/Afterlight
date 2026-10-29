extends LevelBase
## Level 3 — Dead City (l3a). Stealth through downtown.
##  * C = sneak (slow, silent, hard to see). Crouch behind cars/the bus = cover.
##  * E behind an unaware wanderer = silent takedown.
##  * Running near an alarm car, or gunshots near it, sets it off (huge noise).
##  * Pharmacy: desperate survivors (Leo, Ruth, Kai) — share or not; get ice
##    packs for Dr. Ward's samples. Then a horde passes — hide behind the bus.

const INTERIOR_X := 10150.0
const PHARMACY_X := 4200.0
const SUBWAY_X := 8700.0

@onready var bg: StreetBG = $Backdrop

var gun: GunController
var mara: Companion
var ward: Actor
var leo: Actor
var ruth: Actor
var kai: Actor
var stage := "street"
var covers := []
var alarms := []
var _alarm_t := {}
var _takedown: Zombie
var _loud_t := 0.0
var _horde: Array = []
var _hint_shown := false
var _horde_started := false
var _hiding := false


func _ready() -> void:
	super._ready()
	alex.can_crouch = true
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 16
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	mara.position = Vector2(380, 0)
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 280.0
	ward = _spawn("ward", Vector2(260, 0), 1)
	ward.rig.prop_front = "case"
	for a in [mara, ward]:
		a.add_to_group("living")
		a.max_hp = 4
		a.hp = 4
	register("mara", mara)
	register("ward", ward)
	leo = _spawn("leo", Vector2(INTERIOR_X + 620, 0), -1)
	leo.rig.prop_front = "bat"
	leo.rig.pose_front = "hold_radio"
	ruth = _spawn("ruth", Vector2(INTERIOR_X + 420, 0), -1)
	kai = _spawn("kai", Vector2(INTERIOR_X + 880, 0), -1)
	register("leo", leo)
	register("ruth", ruth)
	register("kai", kai)
	for n in get_tree().get_nodes_in_group("cover_prop"):
		covers.append(n)
	for n in $Props.get_children():
		if n is VectorProp and n.kind in ["car", "bus"]:
			covers.append(n)
			if n.label.contains("alarm"):
				alarms.append(n)
	mara.died.connect(func(): fail("Mara didn't make it."))
	ward.died.connect(func(): fail("Dr. Ward didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	# wanderers
	_zombie("zombie_a", Vector2(1700, 0), 1)
	_zombie("zombie_b", Vector2(2650, 0), -1)
	_zombie("zombie_c", Vector2(3500, 0), 1)
	_zombie("zombie_a", Vector2(7000, 0), 1)
	_zombie("zombie_b", Vector2(8050, 0), -1)
	enable("pharmacy")
	enable("cooler", false)
	enable("kai", false)
	enable("hide", false)
	enable("exit", false)
	enable("subway", false)
	enable("takedown", false)
	alex.global_position = Vector2(520, -2)
	ui.set_hud("DAY 3", "5:12 PM", "DOWNTOWN  ·  MAIN ST", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 3", "DEAD CITY", 1.4)
	cam.follow_offset = Vector2(150, -420)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	ui.fade(false, 1.0)
	ui.show_hud(true)
	cam.follow(alex, 0.85, 0.5)
	await wait(0.6)
	dialog.partner_id = "mara"
	await dialog.run(CityLines.truck_dies())
	dialog.end()
	mara.follow_target = alex
	mara.follow_dist = 170.0
	ward.follow_target = alex
	ward.follow_dist = 290.0
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["MARA", mara], ["DR. WARD", ward]]
	ui.over.set_hint("C sneak · crouch behind cars to hide · E behind a wanderer: silent takedown · shots & alarms draw crowds")
	set_objective("Find ice packs for the samples — the pharmacy on Main St")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _spawn(design: String, pos: Vector2, face: int) -> Actor:
	var a := Cast.make(design)
	a.position = pos
	$Actors.add_child(a)
	a.rig.facing = face
	return a


func _zombie(design: String, pos: Vector2, face: int) -> Zombie:
	var z := Cast.make(design, "zombie") as Zombie
	z.position = pos
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	z.rig.facing = face
	return z


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	# companions copy Alex's sneaking
	for a in [mara, ward]:
		a.crouching = alex.crouching
		a.nav_run = absf(a.global_position.x - alex.global_position.x) > 450.0
	# cover
	for a in [alex, mara, ward]:
		a.in_cover = false
		if a.crouching:
			for c in covers:
				var half: float = c.size.x * 0.5
				if absf(a.global_position.x - c.global_position.x) < half + 40.0:
					a.in_cover = true
	if _hiding:
		for a in [alex, mara, ward]:
			a.crouching = true
			a.in_cover = true
	# Mara and Dr. Ward huddle in with Alex
	if alex.in_cover:
		for a in [mara, ward]:
			if a.crouching and absf(a.global_position.x - alex.global_position.x) < 420.0:
				a.in_cover = true
	# Mara holds fire unless it's already loud (or one is on top of her)
	_loud_t = maxf(0.0, _loud_t - dt)
	mara.range_px = 950.0 if _loud_t > 0.0 else 280.0
	# car alarms
	for car in alarms:
		var on: bool = _alarm_t.get(car, 0.0) > 0.0
		if not on and alex.running and absf(alex.global_position.x - car.global_position.x) < 220.0:
			_trigger_alarm(car)
		if on:
			_alarm_t[car] -= dt
			car.alarm_on = _alarm_t[car] > 0.0
			if fposmod(_alarm_t[car], 1.0) < dt:
				Sound.emit(car.global_position + Vector2(0, 100), 2200.0, "alarm")
	# silent takedown candidate
	_takedown = null
	if not Inputs.input_locked and alex.stair == null:
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			if absf(zz.global_position.x - alex.global_position.x) < 140.0 and absf(zz.global_position.y - alex.global_position.y) < 40.0 and zz.unaware_of(alex):
				_takedown = zz
				break
	var td: Interactable = $Interactables/takedown
	td.enabled = _takedown != null
	if _takedown:
		td.global_position = _takedown.global_position
		if not _hint_shown:
			_hint_shown = true
			_thought_async(CityLines.first_wanderer())
	# the horde
	if stage == "north" and alex.global_position.x > 5200.0 and not _horde_started:
		_horde_started = true
		_start_horde()
	for z in _horde.duplicate():
		if not is_instance_valid(z):
			_horde.erase(z)
		elif z.alive and z.state != "chase" and z.global_position.x < 3200.0:
			z.queue_free()
			_horde.erase(z)


func _thought_async(lines: Array) -> void:
	await dialog.run(lines)
	ui.hide_caption()


func _trigger_alarm(car: Node) -> void:
	_alarm_t[car] = 8.0
	car.alarm_on = true
	_loud_t = 15.0
	ui.rule_flash(2)
	_thought_async(CityLines.alarm())
	for k in 2:
		_zombie(["zombie_a", "zombie_b", "zombie_c"][k], Vector2(car.global_position.x + (1300.0 if k % 2 == 0 else -1300.0) + k * 60.0, 0), 1)


func _on_gunshot_near_alarms(pos: Vector2) -> void:
	for car in alarms:
		if pos.distance_to(car.global_position) < 500.0 and _alarm_t.get(car, 0.0) <= 0.0:
			_trigger_alarm(car)


func _enter_tree() -> void:
	Sound.heard.connect(_on_sound)


func _exit_tree() -> void:
	if Sound.heard.is_connected(_on_sound):
		Sound.heard.disconnect(_on_sound)


func _on_sound(pos: Vector2, _r: float, kind: String) -> void:
	if kind == "gunshot":
		_loud_t = 15.0
		_on_gunshot_near_alarms(pos)


func _start_horde() -> void:
	Audio.music("combat", 1.0)
	ui.toast("[a hundred footsteps]")
	_thought_async(CityLines.horde_warning())
	for k in 6:
		var z := _zombie(["zombie_a", "zombie_b", "zombie_c"][k % 3], Vector2(7700.0 + k * 110.0, 0), -1)
		z.state = "investigate"
		z.nav_target = Vector2(1000, 0)
		z.nav_run = false
		z.nav_stop = 10.0
		z.sight = 500.0
		_horde.append(z)
	enable("hide")
	set_objective("HIDE — get behind the bus and press E")


func interact(id: String) -> void:
	match id:
		"takedown":
			if _takedown and _takedown.alive:
				var z := _takedown
				Inputs.input_locked = true
				alex.rig.facing = int(signf(z.global_position.x - alex.global_position.x))
				alex.rig.pose_front = "reach"
				await wait(0.25)
				z.die(signf(z.global_position.x - alex.global_position.x))
				Audio.sfx("takedown", z.global_position + Vector2(0, -250))
				cam.shake(1.5)
				await wait(0.35)
				alex.rig.pose_front = "none"
				Inputs.input_locked = false
		"hide":
			if not _hiding and _horde_started:
				await _hide_bus()
		"pharmacy":
			if stage == "street":
				await _enter_pharmacy()
		"cooler":
			if stage == "inside":
				await _cooler()
		"kai":
			if stage == "inside" or stage == "loot":
				enable("kai", false)
				await conversation("kai", CityLines.kai_talk(), true, 170.0)
				ui.hide_caption()
		"shelf":
			if not Game.flag("pharmacy_bandages"):
				Game.set_flag("pharmacy_bandages", true)
				Game.add("bandages", 2)
				await think([{think = "Two rolls of gauze behind the cough syrup. Everyone else missed them.", face = "relieved"}])
				ui.toast("+2 bandages")
			else:
				await think([{think = "Nothing useful left.", face = "neutral"}])
		"exit":
			if stage == "loot":
				await _exit_pharmacy()
		"subway":
			if stage == "north":
				gun.set_active(false)
				await think(CityLines.subway_entry())
				await finish("l3b", "LINE 2", "UNDERGROUND")


## Rule 2 + cover: the whole group ducks down behind the bus while the horde passes.
func _hide_bus() -> void:
	_hiding = true
	Inputs.input_locked = true
	enable("hide", false)
	gun.set_active(false)
	var bus: VectorProp = $Props/Bus
	var bx := bus.global_position.x
	bus.z_index = 5
	for z in get_tree().get_nodes_in_group("zombies"):
		var zz := z as Zombie
		zz.z_index = 6
		if zz.state == "chase" or zz.state == "attack":
			zz.state = "investigate"
			zz.rig.pose_front = "none"
			zz.rig.pose_back = "none"
	var was_player := alex.player_controlled
	alex.player_controlled = false
	for p in [[alex, bx - 120.0], [mara, bx - 300.0], [ward, bx + 60.0]]:
		var a: Actor = p[0]
		a.stop_nav()
		a.follow_target = null
		a.walk_to(p[1], true)
	await alex.arrived
	alex.rig.facing = 1
	cam.shot(Vector2(bx, -430), 0.75, 1.0)
	ui.toast("Hidden. Don't move.")
	var t := 0.0
	while t < 30.0:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		t += get_physics_process_delta_time()
		var left := 0
		for z in _horde:
			if is_instance_valid(z) and z.alive and z.global_position.x > bx - 750.0:
				left += 1
		if left == 0 and t > 3.0:
			break
	bus.z_index = 0
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Node2D).z_index = 0
	_hiding = false
	alex.player_controlled = was_player
	mara.follow_target = alex
	ward.follow_target = alex
	gun.set_active(true)
	cam.follow(alex, 0.85, 0.8)
	set_objective("Reach the subway entrance (Line 2)")
	Audio.music("tension", 2.0)
	await think([{think = "They're gone. Keep moving — quietly.", face = "relieved"}])


func _teleport_group(x: float) -> void:
	alex.global_position = Vector2(x, -2)
	mara.global_position = Vector2(x - 150.0, -2)
	ward.global_position = Vector2(x - 280.0, -2)
	for a in [alex, mara, ward]:
		a.velocity = Vector2.ZERO
		a.last_floor_pos = a.global_position
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow(alex, 0.85, 0.2)


func _enter_pharmacy() -> void:
	Inputs.input_locked = true
	await ui.fade(true, 0.5).finished
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).nav_target = Vector2.INF
	_teleport_group(INTERIOR_X + 80.0)
	alex.rig.facing = 1
	ui.set_hud("DAY 3", "5:40 PM", "MAIN ST PHARMACY", "")
	await ui.fade(false, 0.5).finished
	gun.set_active(false)
	await conversation("leo", CityLines.pharmacy_standoff(), true, 220.0)
	if int(Game.flag("bandages", 0)) < 0:
		Game.set_flag("bandages", 0)
	if Game.flag("shared_supplies"):
		gun.reserve += 8
		ui.toast("Kai: +8 rounds")
	stage = "inside"
	enable("pharmacy", false)
	enable("cooler")
	enable("kai")
	set_objective("Get the ice packs from the cooler")
	Inputs.input_locked = false


func _cooler() -> void:
	Inputs.input_locked = true
	$Props/Cooler.label = "empty"
	$Props/Cooler.queue_redraw()
	dialog.partner_id = "ward"
	await dialog.run(CityLines.cooler())
	ui.hide_caption()
	dialog.partner_id = "leo" if Game.flag("shared_supplies") else "kai"
	await dialog.run(CityLines.leo_route(Game.flag("shared_supplies")))
	ui.hide_caption()
	dialog.partner_id = "mara"
	await dialog.run(CityLines.mara_backroom())
	dialog.end()
	Game.set_flag("ice_packs", true)
	stage = "loot"
	enable("cooler", false)
	enable("exit")
	set_objective("Head out — subway Line 2, east end of Main St")
	Inputs.input_locked = false


func _exit_pharmacy() -> void:
	Inputs.input_locked = true
	await ui.fade(true, 0.5).finished
	var tw := create_tween()
	tw.tween_property(bg, "dusk", 0.7, 0.1)
	$CanvasModulate.color = Color(0.55, 0.52, 0.6)
	_teleport_group(PHARMACY_X + 120.0)
	ui.set_hud("DAY 3", "6:55 PM", "DOWNTOWN  ·  MAIN ST", "Reach the subway entrance (Line 2)")
	await ui.fade(false, 0.5).finished
	gun.set_active(true)
	stage = "north"
	enable("exit", false)
	enable("subway")
	Inputs.input_locked = false


# --- test bot ---------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	alex.crouching = true
	var goals := [PHARMACY_X, -1.0, SUBWAY_X]
	var t := 0.0
	var gi := 0
	while not _ended and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		alex.crouching = stage != "inside" and stage != "loot"
		if OS.get_environment("BOT_TRACE") == "1" and fmod(t, 1.0) < get_physics_process_delta_time():
			var ch := 0
			for z in get_tree().get_nodes_in_group("zombies"):
				if (z as Zombie).state == "chase":
					ch += 1
			print("  t=%.0f x=%.0f hp=%d cover=%s crouch=%s chase=%d horde=%d mag=%d res=%d" % [t, alex.global_position.x, alex.hp, alex.in_cover, alex.crouching, ch, _horde.size(), gun.in_mag, gun.reserve])
		if _takedown:
			await do_interact("takedown")
			continue
		var threat: Zombie = null
		var best := 600.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			var d := zz.global_position.distance_to(alex.global_position)
			if d < best and (zz.state == "chase" or zz.state == "attack"):
				best = d
				threat = zz
		if threat:
			alex.walk_to(alex.global_position.x)
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		# wait for the horde to pass behind the bus
		var pending := false
		for z in _horde:
			if is_instance_valid(z) and z.alive and z.global_position.x > alex.global_position.x - 120.0 and z.state == "investigate":
				pending = true
		if stage == "north" and pending and ($Interactables/hide as Interactable).enabled:
			await bot_use("hide")
			continue
		if stage == "north" and pending:
			var bus_x: float = $Props/Bus.global_position.x
			if absf(alex.global_position.x - bus_x) > 60.0 and alex.global_position.x < bus_x + 400.0:
				alex.walk_to(bus_x)
			continue
		match stage:
			"street":
				if absf(alex.global_position.x - PHARMACY_X) > 40.0:
					alex.walk_to(PHARMACY_X)
				else:
					await do_interact("pharmacy")
			"inside":
				if ($Interactables/kai as Interactable).enabled:
					await bot_use("kai")
				else:
					await bot_use("cooler")
			"loot":
				await bot_use("exit")
			"north":
				var ahead := false
				for z in get_tree().get_nodes_in_group("zombies"):
					var zz := z as Zombie
					if zz.global_position.x > alex.global_position.x and zz.global_position.x - alex.global_position.x < 160.0 and not zz.unaware_of(alex):
						ahead = true
				if absf(alex.global_position.x - SUBWAY_X) > 40.0:
					alex.walk_to(SUBWAY_X)
				else:
					await do_interact("subway")
	print("BOT city t=", t, " stage=", stage, " hp=", alex.hp, " mara=", mara.hp, " ward=", ward.hp)
