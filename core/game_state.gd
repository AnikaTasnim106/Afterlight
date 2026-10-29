extends Node
## Global story state (autoload "Game"): flags set by choices, the current
## chapter, and checkpoint save/load in user://save.json.

signal flag_changed(key: String, value: Variant)

## Level 1 chapters, in story order.
const CHAPTERS := {
	"s1": {"scene": "res://levels/level1/apartment.tscn", "title": "1 · A Normal Evening"},
	"s2": {"scene": "res://levels/level1/building.tscn", "title": "2 · Checking the Building"},
	"s3": {"scene": "res://levels/level1/apartment.tscn", "title": "3 · June Is Gone"},
	"s4": {"scene": "res://levels/level1/apartment.tscn", "title": "4 · The Emergency Rules"},
	"s5": {"scene": "res://levels/level1/apartment.tscn", "title": "5 · The Next Morning"},
	"s6": {"scene": "res://levels/level1/stairwell.tscn", "title": "6 · Stairwell Evacuation"},
	"s7": {"scene": "res://levels/level1/roof.tscn", "title": "7 · Rooftop Extraction"},
	"l2a": {"scene": "res://levels/level2/camp.tscn", "title": "L2 · Relief Zone Bravo"},
	"l2b": {"scene": "res://levels/level2/camp.tscn", "title": "L2 · The Breach"},
	"l3a": {"scene": "res://levels/level3/city.tscn", "title": "L3 · Dead City"},
	"l3b": {"scene": "res://levels/level3/subway.tscn", "title": "L3 · Underground"},
	"l4a": {"scene": "res://levels/level4/marina.tscn", "title": "L4 · The Marina"},
	"l4b": {"scene": "res://levels/level4/crossing.tscn", "title": "L4 · The Crossing"},
	"l5a": {"scene": "res://levels/level5/hospital.tscn", "title": "L5 · Harbor Point"},
	"l5b": {"scene": "res://levels/level5/hospital.tscn", "title": "L5 · Lights Out"},
	"l6a": {"scene": "res://levels/level6/wing.tscn", "title": "L6 · The Quarantine Wing"},
	"l6b": {"scene": "res://levels/level6/wing.tscn", "title": "L6 · The First Dose"},
	"l7a": {"scene": "res://levels/level7/signal.tscn", "title": "L7 · The Signal"},
	"l7b": {"scene": "res://levels/level7/signal.tscn", "title": "L7 · Dawn"},
	"l8a": {"scene": "res://levels/level8/epilogue.tscn", "title": "L8 · Afterlight"},
	"l8b": {"scene": "res://levels/level8/epilogue.tscn", "title": "L8 · Home"},
}
const ORDER := ["s1", "s2", "s3", "s4", "s5", "s6", "s7", "l2a", "l2b", "l3a", "l3b", "l4a", "l4b", "l5a", "l5b", "l6a", "l6b", "l7a", "l7b", "l8a", "l8b"]

## Flags each chapter can assume if you jump there from Chapter Select.
const CHAPTER_DEFAULTS := {
	"s2": {"recorded_frequency": true, "june_bond": 1},
	"s6": {"rules_known": true, "recorded_frequency": true, "june_bond": 1, "locked_door": true, "phone_silent": true,
		"packed": true, "bandages": 2, "ammo_box": true, "conserved_food": true},
}

var flags := {}
var phase := "s1"


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flag_changed.emit(key, value)


func flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func add(key: String, amount: int) -> void:
	set_flag(key, int(flags.get(key, 0)) + amount)


## Go to a chapter, saving a checkpoint at its start.
func goto(chapter: String) -> void:
	phase = chapter
	save_checkpoint(chapter)
	get_tree().change_scene_to_file(CHAPTERS[chapter].scene)


func next_chapter() -> void:
	var i := ORDER.find(phase)
	if i >= 0 and i + 1 < ORDER.size():
		goto(ORDER[i + 1])


## Retry the current chapter with the flags it started with.
func retry() -> void:
	var cp := load_checkpoint()
	if cp == "":
		cp = phase
	phase = cp
	get_tree().change_scene_to_file(CHAPTERS[cp].scene)


## Chapter select: start a chapter with sensible defaults for earlier choices.
func start_chapter(chapter: String) -> void:
	reset()
	var keys := ORDER.slice(0, ORDER.find(chapter) + 1)
	for k in keys:
		for f in CHAPTER_DEFAULTS.get(k, {}):
			flags[f] = CHAPTER_DEFAULTS[k][f]
	if ORDER.find(chapter) >= ORDER.find("s5"):
		for f in CHAPTER_DEFAULTS["s6"]:
			flags[f] = CHAPTER_DEFAULTS["s6"][f]
	goto(chapter)


func save_checkpoint(id: String) -> void:
	var data := {"checkpoint": id, "flags": flags}
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


func has_save() -> bool:
	return FileAccess.file_exists("user://save.json")


func load_checkpoint() -> String:
	if not has_save():
		return ""
	var f := FileAccess.open("user://save.json", FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		flags = data.get("flags", {})
		# JSON turns ints into floats; keep counters as ints
		for k in flags:
			if flags[k] is float and flags[k] == floor(flags[k]):
				flags[k] = int(flags[k])
		phase = str(data.get("checkpoint", "s1"))
		return phase
	return ""


func continue_game() -> void:
	var cp := load_checkpoint()
	if cp == "":
		cp = "s1"
	get_tree().change_scene_to_file(CHAPTERS[cp].scene)


func reset() -> void:
	flags.clear()
	phase = "s1"
