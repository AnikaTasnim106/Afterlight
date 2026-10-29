extends LevelBase
## Level 1 · Scene 2 — "Checking the building".
## Three different corridor floors (4, 3, 2) joined by a real stairwell
## (W/S on the stairs). Talk to three neighbours — their stories don't agree.
## Then Mr. Daniels limps in injured; while Alex helps him home, the soldiers
## evacuate the upper floors. Alex runs back up: everyone is gone (→ Scene 3).

const F2 := 0.0
const F3 := -900.0
const F4 := -1800.0

var chowdhury: Actor
var rafi: Actor
var nadia: Actor
var das: Actor
var talked := {}
var stage := "talk"
var _rafi_t := 0.0


func _ready() -> void:
	super._ready()
	chowdhury = _spawn("mrs_chowdhury", Vector2(570, F4), 1)
	rafi = _spawn("rafi", Vector2(1250, F3), -1)
	nadia = _spawn("nadia", Vector2(1960, F2), -1)
	nadia.rig.carry = "baby"
	das = _spawn("mr_das", Vector2(3550, F2 - 450), -1)
	das.visible = false
	das.rig.limp = 1.0
	das.rig.expression = "hurt"
	register("chowdhury", chowdhury)
	register("rafi", rafi)
	register("nadia", nadia)
	register("das", das)
	for pair in [["chowdhury", chowdhury], ["rafi", rafi], ["nadia", nadia], ["das", das]]:
		var it: Interactable = get_node("Interactables/" + pair[0])
		it.follow_path = (pair[1] as Node).get_path()
	enable("das", false)
	enable("door_2b", false)
	enable("door_4c", false)
	enable("shawl", false)
	alex.global_position = Vector2(1520, F4 - 2)
	alex.rig.facing = -1
	ui.set_hud("DAY 1", "8:09 PM", "TOWER 9  ·  FLOOR 4", _talk_obj())
	await chapter_intro("", "")
	cam.cut(alex.global_position + cam.follow_offset, 1.0)
	cam.follow(alex, 1.0, 0.4)
	await dialog.run(BuildingLines.intro())
	ui.hide_caption()
	ui.toast("W / S  ·  take the stairs")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _spawn(design: String, pos: Vector2, face: int) -> Actor:
	var a := Cast.make(design)
	a.position = pos
	$Actors.add_child(a)
	a.rig.facing = face
	return a


func _talk_obj() -> String:
	return "Talk to the neighbours  (%d/3)" % talked.size()


func _physics_process(dt: float) -> void:
	# Ryan paces with his phone
	if stage == "talk" and rafi.visible and not Inputs.input_locked:
		_rafi_t -= dt
		if _rafi_t <= 0.0:
			_rafi_t = randf_range(2.5, 4.0)
			rafi.walk_to(randf_range(1050.0, 1500.0))
	# floor label in the HUD
	var fl := "STAIRWELL"
	if alex.stair == null:
		if absf(alex.global_position.y - F4) < 60.0: fl = "FLOOR 4"
		elif absf(alex.global_position.y - F3) < 60.0: fl = "FLOOR 3"
		elif absf(alex.global_position.y - F2) < 60.0: fl = "FLOOR 2"
	ui._hud_place.text = "TOWER 9  ·  " + fl


func interact(id: String) -> void:
	match id:
		"chowdhury":
			if not talked.has("c"):
				rafi.stop_nav()
				await conversation("chowdhury", BuildingLines.mrs_chowdhury())
				_talked("c")
			else:
				await think([{think = "She's already closed her door halfway.", face = "neutral"}])
		"rafi":
			if not talked.has("r"):
				rafi.walk_to(rafi.global_position.x)
				await conversation("rafi", BuildingLines.rafi())
				_talked("r")
			else:
				await think([{think = "He's dialling his cousin again.", face = "sad"}])
		"nadia":
			if not talked.has("n"):
				await conversation("nadia", BuildingLines.nadia())
				_talked("n")
			else:
				await think([{think = "She's rocking the baby, humming.", face = "sad"}])
		"door_3b":
			await think(BuildingLines.door_3b())
		"notice":
			await think([{think = "'WATER SUPPLY 6–8 PM.' Feels like a notice from another world.", face = "tired"}])
		"elevator":
			await think([{think = "Out of order. Since March. Of course.", face = "tired"}])
		"das":
			if stage == "das_waiting":
				das.stop_nav()
				await conversation("das", BuildingLines.das_arrives())
				stage = "escort"
				das.follow_target = alex
				das.follow_dist = 130.0
				enable("das", false)
				enable("door_2b")
				set_objective("Help Mr. Daniels to his door (2B)")
		"door_2b":
			if stage == "escort":
				if das.global_position.distance_to(alex.global_position) > 320.0:
					await think([{think = "Wait for Mr. Daniels. He can barely walk.", face = "worried"}])
				else:
					await _das_home()
		"shawl":
			await think(BuildingLines.chowdhury_gone())
		"door_4c":
			if stage == "return":
				await finish("s3", "SCENE 3", "THE EMPTY APARTMENT")


func _talked(k: String) -> void:
	talked[k] = true
	set_objective(_talk_obj())
	if talked.size() == 3:
		_das_event()


func _das_event() -> void:
	await wait(1.0)
	ui.toast("[from the stairwell]  Help! Somebody!")
	das.visible = true
	das.nav_target = Vector2(2300, F2)
	das.nav_stop = 20.0
	stage = "das_waiting"
	enable("das")
	set_objective("Someone's calling for help — Floor 2 stairwell")


func _das_home() -> void:
	Inputs.input_locked = true
	das.stop_nav()
	das.walk_to($Interactables/door_2b.global_position.x)
	alex.walk_to($Interactables/door_2b.global_position.x + 170.0, false, -1)
	await das.arrived
	await wait(0.3)
	das.visible = false
	cam.shake(8.0)
	ui.letterbox(true, 0.4)
	await wait(0.4)
	das.visible = true
	await dialog.run(BuildingLines.upstairs_shout())
	ui.hide_caption()
	das.visible = false
	ui.letterbox(false, 0.4)
	cam.follow(alex, 1.0, 0.6)
	# meanwhile the soldiers cleared floors 3 and 4
	for a in [chowdhury, rafi]:
		a.visible = false
	for n in ["Door3A", "Door3C", "Door4B", "Door4D"]:
		var d: VectorProp = get_node("Props/" + n)
		d.label = d.label + "_open"
		d.queue_redraw()
	$Props/Shawl.visible = true
	enable("shawl")
	enable("chowdhury", false)
	enable("rafi", false)
	enable("door_2b", false)
	enable("door_4c")
	stage = "return"
	ui.set_hud("DAY 1", "8:27 PM", "TOWER 9", "Get back to June — Floor 4, apartment 4C")
	Inputs.input_locked = false


# --- test bot -----------------------------------------------------------------------

func _bot() -> void:
	await bot_use("chowdhury")
	await bot_go(Vector2(1250, F3))
	await bot_walk(rafi.global_position.x + 160.0)
	await bot_use("rafi")
	await bot_use("door_3b")
	await bot_go(Vector2(1800, F2))
	await bot_use("nadia")
	while absf(das.global_position.x - 2300.0) > 40.0 or das.stair != null:
		await wait(0.2)
	await bot_walk(das.global_position.x - 150.0)
	await bot_use("das")
	await bot_walk($Interactables/door_2b.global_position.x + 60.0)
	await wait(3.0)
	await bot_use("door_2b")
	await bot_go(Vector2(1500, F4), true)
	await bot_use("door_4c")
