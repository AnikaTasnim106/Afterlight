class_name DialogueRunner
extends Node
## Plays a conversation written as plain data (see levels/level1/scene1_lines.gd).
## Each line sets the speaker's expression / pose / prop and the camera shot,
## so acting is part of the script — not something the player toggles.
##
## Item formats (Dictionaries):
##   {say="june", t="Text with *highlight*", face="curious", pose="hold_radio",
##    prop="radio", look=Vector2(..), shot="two"|"close"|"wide"|"keep",
##    react={alex="smile"}, react_pose={alex="shrug"}}
##   {think="Alex's inner thought"}
##   {choice=[{t="Option", set={flag=value}, add={june_bond=1}, toast="June will remember that.",
##             need="flag", then=[...items]}, ...]}
##   {if_flag="flag", then=[...], else=[...]}
##   {do=Callable}           # may be a coroutine; awaited
##   {wait=0.5}
##   {face="june", value="worried"}   # set expression without a line

var actors := {}          # id -> Actor
var ui: CinemaUI
var cam: CameraDirector
var player_id := "alex"
var partner_id := ""

const NAMES := {"alex": "ALEX", "june": "JUNE", "radio": "RADIO", "news": "NEWS", "chowdhury": "MRS. CARTER",
	"rafi": "RYAN", "nadia": "NINA", "das": "MR. DANIELS", "voices": "VOICES", "mara": "MARA", "soldier": "SOLDIER", "pilot": "PILOT (RADIO)",
	"hale": "SGT. HALE", "price": "OFFICER PRICE", "ward": "DR. WARD", "sam": "SAM", "survivor": "SURVIVOR", "nina": "NINA",
	"gus": "GUS", "leo": "LEO", "ruth": "RUTH", "kai": "KAI", "chen": "DR. CHEN", "holly": "NURSE HOLLY", "theo": "THEO", "guard": "GUARD", "nick": "NICK"}


func begin(partner: String = "") -> void:
	Inputs.input_locked = true
	ui.hide_prompt()
	ui.letterbox(true, 0.5)
	partner_id = partner
	if partner != "" and actors.has(partner):
		face_each_other(player_id, partner)


func end() -> void:
	partner_id = ""
	for a in actors.values():
		a.rig.talking = false
	ui.hide_caption()
	ui.letterbox(false, 0.5)
	cam.follow(actors[player_id], cam.follow_zoom, 0.9)
	Inputs.input_locked = false


func face_each_other(a_id: String, b_id: String) -> void:
	var a: Actor = actors[a_id]
	var b: Actor = actors[b_id]
	a.rig.facing = 1 if b.global_position.x > a.global_position.x else -1
	b.rig.facing = -a.rig.facing


func run(items: Array) -> void:
	for item in items:
		await _run_item(item)


func _run_item(it: Dictionary) -> void:
	# real conversations always wait for the player (a bark may have left
	# auto_advance on)
	ui.auto_advance = ui.auto_default
	if it.has("say"):
		await _say(it)
	elif it.has("think"):
		_apply_acting(it, player_id)
		await ui.think(it.think)
	elif it.has("choice"):
		await _choice(it.choice)
	elif it.has("if_flag"):
		if Game.flag(it.if_flag):
			await run(it.get("then", []))
		else:
			await run(it.get("else", it.get("otherwise", [])))
	elif it.has("do"):
		await (it.do as Callable).call()
	elif it.has("wait"):
		await get_tree().create_timer(float(it.wait)).timeout
	elif it.has("face"):
		actors[it.face].rig.expression = it.value
	if it.has("set"):
		for k in it.set:
			Game.set_flag(k, it.set[k])


func _apply_acting(it: Dictionary, who: String) -> void:
	if not actors.has(who):
		return
	var rig: CharacterRig = actors[who].rig
	if it.has("face"):
		rig.expression = it.face
	if it.has("pose"):
		rig.pose_front = it.pose
	if it.has("prop"):
		rig.prop_front = it.prop
	if it.has("look"):
		rig.look = it.look


func _say(it: Dictionary) -> void:
	var who: String = it.say
	_apply_acting(it, who)
	for other in it.get("react", {}):
		actors[other].rig.expression = it.react[other]
	for other in it.get("react_pose", {}):
		actors[other].rig.pose_front = it.react_pose[other]
	_shot(it.get("shot", "keep"), who)
	var speaking: Actor = actors.get(who)
	if speaking:
		speaking.rig.talking = true
	await ui.say(NAMES.get(who, who.to_upper()), it.t, float(it.get("hold", 1.1)))
	if speaking:
		speaking.rig.talking = false


func _choice(options: Array) -> void:
	var visible := []
	var labels := []
	for o in options:
		if o.has("need") and not Game.flag(o.need):
			continue
		visible.append(o)
		labels.append(o.t)
	_shot("two", player_id)
	var idx := await ui.choose(labels)
	var o: Dictionary = visible[idx]
	for k in o.get("set", {}):
		Game.set_flag(k, o.set[k])
	for k in o.get("add", {}):
		Game.add(k, o.add[k])
	if o.has("toast"):
		ui.toast(o.toast)
	await run(o.get("then", []))


func _head(who: String) -> Vector2:
	var a: Actor = actors[who]
	return a.rig.head_global_position()


func _shot(kind: String, speaker: String) -> void:
	if kind == "keep" or cam == null:
		return
	var p: Actor = actors[player_id]
	var partner := partner_id
	if partner == "" or not actors.has(partner):
		var best_d := 900.0
		partner = player_id
		for k in actors:
			if k == player_id or not actors[k].visible:
				continue
			var dd: float = (actors[k] as Node2D).global_position.distance_to(p.global_position)
			if dd < best_d:
				best_d = dd
				partner = k
	match kind:
		"two":
			var mid := (_head(player_id) + _head(partner)) * 0.5
			cam.shot(mid + Vector2(0, 70), 1.5, 0.9, 0.012)
		"close":
			if not actors.has(speaker):
				speaker = player_id
			var listener := partner if speaker == player_id else player_id
			var h := _head(speaker)
			var toward := signf(_head(listener).x - h.x)
			cam.shot(h + Vector2(toward * 120.0, 90), 2.0, 0.8, 0.015)
		"wide":
			var mid2 := (_head(player_id) + _head(partner)) * 0.5
			cam.shot(mid2 + Vector2(0, 40), 1.1, 1.0, 0.0)
