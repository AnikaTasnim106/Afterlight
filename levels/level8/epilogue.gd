extends LevelBase
## Level 8 — Afterlight (epilogue). Six weeks later.
##   l8a  Main Street, recovery day. Walk with June, say hello to everyone who
##        made it (Nina, Mr. Daniels and Mara/Theo are needed; the rest are optional),
##        then go home.
##   l8b  Home. June pins the six rules on the fridge. Tea. The end.

const HOME_DOOR := 5300.0
const IN_X := 8000.0
const FRIDGE_X := 9480.0
const SOFA_X := 8640.0
const NEEDED := ["nina", "das", "mara"]

@onready var fridge: VectorProp = $Props/Fridge
@onready var window_view: Node2D = $Props/Window

var june: Actor
var people := {}
var met: Array = []
var stage := ""
var _pace_dir := 1
var _pace_x := 2200.0
var _photo_done := false
var _flash: ColorRect


func _ready() -> void:
	super._ready()
	var gun: GunController = alex.get_node("Gun")
	gun.set_active(false)
	june = Cast.make("june")
	$Actors.add_child(june)
	register("june", june)
	var cast := [
		["hale", "hale", 820.0, 1], ["chowdhury", "mrs_chowdhury", 1480.0, -1], ["rafi", "rafi", 1620.0, -1],
		["das", "mr_das", 2200.0, 1], ["nina", "nadia", 2880.0, -1], ["nick", "nick", 3020.0, -1],
		["leo", "leo", 3640.0, -1], ["ward", "ward", 4180.0, -1], ["chen", "chen", 4320.0, -1],
		["mara", "mara", 4760.0, -1], ["theo", "theo", 4900.0, -1], ["sam", "sam", 5040.0, -1],
	]
	for c in cast:
		var a := Cast.make(c[1])
		a.position = Vector2(c[2], 0)
		$Actors.add_child(a)
		a.rig.facing = c[3]
		register(c[0], a)
		people[c[0]] = a
	people.nina.rig.carry = "baby"
	people.chowdhury.rig.prop_front = "mug"
	people.theo.rig.sit = 1.0
	people.sam.rig.sit = 1.0
	alex.died.connect(func(): pass)
	enable("home", true)
	enable("fridge", false)
	enable("sofa", false)
	if Game.phase == "l8b":
		_home(true)
	else:
		Game.phase = "l8a"
		_street()


func _street() -> void:
	alex.global_position = Vector2(260, -2)
	june.global_position = Vector2(100, 0)
	ui.set_hud("SIX WEEKS LATER", "11:20 AM", "MAIN STREET", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 8", "AFTERLIGHT", 1.6)
	cam.follow_offset = Vector2(200, -420)
	cam.cut(Vector2(700, -520), 0.8)
	ui.fade(false, 1.4)
	ui.show_hud(true)
	await wait(0.8)
	dialog.partner_id = "june"
	await dialog.run(EpilogueLines.opening())
	dialog.end()
	cam.follow(alex, 0.8, 0.6)
	june.follow_target = alex
	june.follow_dist = 170.0
	stage = "street"
	_update_objective()
	ui.over.set_hint("Walk up to people and press E · then head home (east end)")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _update_objective() -> void:
	var need := 0
	for n in NEEDED:
		if n not in met:
			need += 1
	if need > 0:
		set_objective("Say hello — Nina, Mr. Daniels, Mara & Theo (%d left) · others too, if you like" % need)
	else:
		set_objective("Go home — east end of the street")


func _physics_process(_dt: float) -> void:
	if _ended or stage != "street":
		return
	# Mr. Daniels is showing off his new legs: up and down, no limp
	var das: Actor = people.das
	if not das.is_walking() and not Inputs.input_locked:
		_pace_dir = -_pace_dir
		das.walk_to(_pace_x + 160.0 * _pace_dir)
	$Interactables/das.position.x = das.global_position.x


func interact(id: String) -> void:
	if stage == "street" and id in ["hale", "carter", "das", "nina_n", "leo", "ward_c", "mara_t"]:
		var partner: String = {"carter": "chowdhury", "nina_n": "nina", "mara_t": "mara", "ward_c": "ward"}.get(id, id)
		var lines: Array = []
		match partner:
			"hale": lines = EpilogueLines.hale()
			"chowdhury": lines = EpilogueLines.carter()
			"das": lines = EpilogueLines.daniels()
			"nina": lines = EpilogueLines.nina()
			"leo": lines = EpilogueLines.leo()
			"ward": lines = EpilogueLines.ward()
			"mara": lines = EpilogueLines.mara()
		if partner == "das":
			people.das.stop_nav()
		await conversation(partner, lines)
		ui.hide_caption()
		if partner == "das" and Game.flag("race_on"):
			await _race()
		if partner not in met:
			met.append(partner)
		enable(id, false)
		_update_objective()
		Inputs.input_locked = false
		return
	match id:
		"home":
			if stage != "street":
				return
			for n in NEEDED:
				if n not in met:
					await think(EpilogueLines.not_yet())
					return
			for m in met:
				Game.set_flag("met_" + m, true)
			if not _photo_done:
				await _group_photo()
			Game.phase = "l8b"
			Game.save_checkpoint("l8b")
			await _home(false)
		"fridge":
			if stage == "home":
				await _fridge()
		"sofa":
			if stage == "sofa":
				await _ending()


const RACE_END := 3500.0

func _race() -> void:
	Game.set_flag("race_on", false)
	stage = "race"
	Inputs.input_locked = true
	var das: Actor = people.das
	june.follow_target = null
	june.stop_nav()
	await ui.fade(true, 0.4).finished
	alex.global_position = Vector2(2200, -2)
	das.global_position = Vector2(2060, 0)
	alex.rig.facing = 1
	das.rig.facing = 1
	june.global_position = Vector2(1900, 0)
	cam.cut(Vector2(2600, -480), 0.7)
	ui.fade(false, 0.4)
	set_objective("RACE to the pharmacy sign — hold Shift!")
	for n in ["3", "2", "1"]:
		ui.big(n)
		await wait(0.7)
	ui.big("GO!")
	Audio.sfx("ui_choice", Vector2.INF, -2.0, 0.0)
	cam.follow(alex, 0.75, 0.4)
	das.speed_scale = 0.97
	das.walk_to(RACE_END + 40.0, true)
	Inputs.input_locked = false
	if autoplay:
		alex.walk_to(RACE_END + 40.0, true)
	var won := false
	while true:
		await get_tree().physics_frame
		if not is_inside_tree():
			return
		if alex.global_position.x >= RACE_END:
			won = true
			break
		if das.global_position.x >= RACE_END:
			break
	Inputs.input_locked = true
	das.speed_scale = 1.0
	cam.shake(2.0)
	ui.big("YOU WIN!" if won else "DANIELS WINS!")
	Game.set_flag("race_won", won)
	await wait(1.4)
	_pace_x = RACE_END - 200.0
	dialog.partner_id = "das"
	await dialog.run(EpilogueLines.race_result(won))
	dialog.end()
	cam.follow(alex, 0.8, 0.6)
	june.follow_target = alex
	stage = "street"
	_update_objective()
	Inputs.input_locked = false


func _group_photo() -> void:
	_photo_done = true
	Inputs.input_locked = true
	dialog.partner_id = "sam"
	await dialog.run(EpilogueLines.photo_call())
	ui.hide_caption()
	await ui.fade(true, 0.6).finished
	june.follow_target = null
	var row: Array = [people.hale, people.chowdhury, people.rafi, people.das, people.nina, people.nick,
		alex, june, people.mara, people.theo, people.sam, people.leo, people.ward, people.chen]
	var x0 := 3000.0 - (row.size() - 1) * 120.0 * 0.5
	for i in row.size():
		var a: Actor = row[i]
		a.stop_nav()
		a.rig.sit = 0.0
		a.global_position = Vector2(x0 + i * 120.0, -2 if a == alex else 0.0)
		a.rig.facing = 1 if i < row.size() / 2 else -1
		a.rig.expression = "happy"
		a.rig.pose_front = "wave" if i % 3 == 0 else "none"
	cam.cut(Vector2(3000, -470), 0.62)
	ui.letterbox(true, 0.01)
	ui.fade(false, 0.6)
	await wait(0.8)
	for n in ["3", "2", "1"]:
		ui.big(n)
		await wait(0.6)
	# the flash
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 1)
	_flash.size = Vector2(1920, 1080)
	layer.add_child(_flash)
	cam.shake(1.0)
	Audio.sfx("shutter", Vector2.INF, 0.0, 0.0)
	$CanvasModulate.color = Color(1.0, 0.9, 0.78)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 1.2)
	await tw.finished
	layer.queue_free()
	await dialog.run(EpilogueLines.photo_after())
	ui.hide_caption()
	await wait(0.6)
	$CanvasModulate.color = Color(0.96, 0.93, 0.9)
	for a in row:
		(a as Actor).rig.pose_front = "none"


func _home(direct: bool) -> void:
	stage = "home"
	Inputs.input_locked = true
	if direct:
		ui.set_black(true)
	else:
		june.stop_nav()
		june.follow_target = null
		alex.walk_to(HOME_DOOR)
		await alex.arrived
		await ui.fade(true, 1.0).finished
	alex.global_position = Vector2(IN_X + 200.0, -2)
	june.global_position = Vector2(IN_X + 60.0, 0)
	alex.rig.facing = 1
	june.rig.facing = 1
	ui.set_hud("SIX WEEKS LATER", "5:40 PM", "HOME · APARTMENT 4C", "")
	ui.over.set_hint("")
	cam.follow_offset = Vector2(150, -420)
	cam.cut(Vector2(IN_X + 600.0, -480), 0.85)
	ui.fade(false, 1.2)
	ui.show_hud(true)
	alex.walk_to(IN_X + 520.0)
	june.walk_to(IN_X + 360.0)
	await alex.arrived
	dialog.partner_id = "june"
	await dialog.run(EpilogueLines.home_arrive())
	dialog.end()
	cam.follow(alex, 0.85, 0.6)
	enable("fridge")
	set_objective("The fridge")
	Inputs.input_locked = false
	if autoplay and direct:
		_bot()


func _fridge() -> void:
	Inputs.input_locked = true
	enable("fridge", false)
	june.walk_to(FRIDGE_X - 140.0, false, 1)
	alex.walk_to(FRIDGE_X - 320.0, false, 1)
	await june.arrived
	june.rig.pose_front = "reach"
	await wait(0.8)
	fridge.label = "rules"
	fridge.queue_redraw()
	june.rig.pose_front = "none"
	ui.rule_flash(6)
	await wait(0.6)
	dialog.partner_id = "june"
	await dialog.run(EpilogueLines.fridge())
	dialog.end()
	cam.follow(alex, 0.85, 0.6)
	stage = "sofa"
	enable("sofa")
	set_objective("Tea. Sit down.")
	Inputs.input_locked = false


func _ending() -> void:
	Inputs.input_locked = true
	enable("sofa", false)
	ui.set_objective("")
	alex.rig.prop_front = "mug"
	june.rig.prop_front = "mug"
	alex.walk_to(SOFA_X - 60.0, false, 1)
	june.walk_to(SOFA_X + 80.0, false, -1)
	await alex.arrived
	ui.letterbox(true, 0.8)
	var tw := create_tween()
	tw.tween_property(alex.rig, "sit", 1.0, 0.6)
	tw.parallel().tween_property(june.rig, "sit", 1.0, 0.6)
	await wait(0.8)
	dialog.partner_id = "june"
	await dialog.run(EpilogueLines.last())
	ui.hide_caption()
	# camera drifts to the window: the city, lit up again
	cam.shot(Vector2(window_view.global_position.x, -560.0), 0.7, 4.0)
	await wait(3.0)
	Game.set_flag("game_complete", true)
	ui.show_hud(false)
	await ui.fade(true, 2.0).finished
	await ui.title_card("AFTERLIGHT", "THE END", 2.4)
	for card in [
		["A GAME BY ANIKA", "built with Claude  ·  made in Godot"],
		["ALEX · JUNE · MARA · THEO", "and everyone who waited for the people coming for them"],
		["THE SIX RULES", "Lock the door · Stay quiet · Keep your distance · Conserve · Be ready · Wait for help"],
	]:
		await ui.title_card(card[0], card[1], 1.8)
	await finish("", "", "")
	if not autoplay:
		get_tree().change_scene_to_file("res://levels/menu.tscn")


# --- test bot ------------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	var order := ["hale", "carter", "das", "nina_n", "leo", "ward_c", "mara_t"]
	var t := 0.0
	while not _ended and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var use := ""
		match stage:
			"street":
				for id in order:
					if (get_node("Interactables/" + id) as Interactable).enabled:
						use = id
						break
				if use == "":
					use = "home"
			"home":
				use = "fridge"
			"sofa":
				use = "sofa"
		if use == "":
			continue
		var target := (get_node("Interactables/" + use) as Node2D).global_position.x
		if absf(alex.global_position.x - target) < 50.0:
			alex.nav_target = Vector2.INF
			await do_interact(use)
		else:
			alex.nav_target = Vector2(target, 0)
			alex.nav_stop = 20.0
	print("BOT epilogue t=", t, " stage=", stage, " met=", met)
