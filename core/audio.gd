extends Node
## Audio autoload: music (crossfaded), ambience, one-shot + looping SFX.
## Every sound in assets/audio was synthesized for this game (see README).
## Noise events (Sound.emit) automatically play their matching effect, so the
## gameplay "rings" you see are also what you hear.

const CHAPTER_AUDIO := {
	"menu": ["menu", ""],
	"s1": ["menu", "indoor"], "s2": ["tension", "indoor"], "s3": ["sad", "indoor"],
	"s4": ["tension", "indoor"], "s5": ["sad", "indoor"], "s6": ["combat", "indoor"],
	"s7": ["combat", "wind"],
	"l2a": ["sad", "camp"], "l2b": ["combat", "camp"],
	"l3a": ["tension", "city"], "l3b": ["tension", "tunnel"],
	"l4a": ["tension", "river"], "l4b": ["combat", "river"],
	"l5a": ["sad", "hospital"], "l5b": ["tension", "hospital"],
	"l6a": ["combat", "hospital"], "l6b": ["combat", "hospital"],
	"l7a": ["combat", "wind"], "l7b": ["hope", "wind"],
	"l8a": ["hope", "day"], "l8b": ["hope", "indoor"],
}
const NOISE_SFX := {
	"gunshot": ["gunshot", 0.0], "alarm": ["alarm", -8.0], "bang": ["bang", 0.0],
	"clank": ["clank", -2.0], "ring": ["ring", -6.0], "phone": ["ring", -14.0],
	"growl": ["snarl", 0.0], "hum": ["", 0.0],
}
const MUSIC_DB := -9.0
const AMB_DB := -13.0

var _cache := {}
var _music: Array[AudioStreamPlayer] = []
var _cur_music := 0
var _music_name := "~"
var _amb: AudioStreamPlayer
var _amb_name := "~"
var _ui: Array[AudioStreamPlayer] = []
var _ui_i := 0
var _loops := {}
var _phase := ""
var _sfx_lock := 0


## Player-facing volume settings (0..1) + mute, saved to user://settings.cfg.
var volumes := {"Master": 1.0, "Music": 0.8, "Effects": 1.0}
var muted := false
const SETTINGS := "user://settings.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["Music", "Effects"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	_load_settings()
	if not InputMap.has_action("mute"):
		InputMap.add_action("mute")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_M
		InputMap.action_add_event("mute", ev)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		p.bus = "Music"
		add_child(p)
		_music.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = AMB_DB
	_amb.bus = "Effects"
	add_child(_amb)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_ui.append(p)
	Sound.heard.connect(_on_noise)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute") and not event.is_echo():
		set_muted(not muted)
		get_viewport().set_input_as_handled()


func set_volume(bus: String, v: float) -> void:
	volumes[bus] = clampf(v, 0.0, 1.0)
	_apply()
	_save_settings()


func set_muted(on: bool) -> void:
	muted = on
	_apply()
	_save_settings()
	var s := get_tree().current_scene
	if s is LevelBase:
		(s as LevelBase).ui.toast("Sound off  (M)" if on else "Sound on")


func _apply() -> void:
	for b in volumes:
		var i := AudioServer.get_bus_index(b)
		if i >= 0:
			var v: float = volumes[b]
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_mute(0, muted or volumes.Master <= 0.001)


func _load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS) == OK:
		for b in volumes:
			volumes[b] = float(c.get_value("audio", b, volumes[b]))
		muted = bool(c.get_value("audio", "muted", false))
	_apply()


func _save_settings() -> void:
	var c := ConfigFile.new()
	for b in volumes:
		c.set_value("audio", b, volumes[b])
	c.set_value("audio", "muted", muted)
	c.save(SETTINGS)


func _exit_tree() -> void:
	for p in _music:
		p.stream = null
	_amb.stream = null
	for u in _ui:
		u.stream = null
	_cache.clear()


func _stream(path: String, loop := false) -> AudioStream:
	var key := path + ("#L" if loop else "")
	if _cache.has(key):
		return _cache[key]
	var full := "res://assets/audio/%s.ogg" % path
	if not ResourceLoader.exists(full):
		return null
	var s: AudioStreamOggVorbis = (load(full) as AudioStreamOggVorbis)
	if s == null:
		return null
	if loop:
		s = s.duplicate()
		s.loop = true
	_cache[key] = s
	return s


func _process(_dt: float) -> void:
	_sync()
	if _sfx_lock > 0:
		_sfx_lock -= 1
	# loops tied to nodes that went away
	for k in _loops.keys():
		if not is_instance_valid(_loops[k]):
			_loops.erase(k)


## Follow the chapter: each chapter has a music bed + ambience.
func _sync() -> void:
	var scene := get_tree().current_scene
	var ph: String = Game.phase if scene is LevelBase else "menu"
	if ph != _phase:
		_phase = ph
		var a: Array = CHAPTER_AUDIO.get(ph, ["", ""])
		_music_to(a[0], 2.0)
		ambient(a[1])


## Crossfade to a music track ("" = silence). Levels call this for story beats.
func music(name: String, secs := 2.0) -> void:
	_sync()
	_music_to(name, secs)


func _music_to(name: String, secs: float) -> void:
	if name == _music_name:
		return
	_music_name = name
	var old := _music[_cur_music]
	_cur_music = 1 - _cur_music
	var nu := _music[_cur_music]
	var tw := create_tween().set_parallel()
	tw.tween_property(old, "volume_db", -80.0, secs)
	if name != "":
		nu.stream = _stream("music/" + name, true)
		nu.volume_db = -40.0
		nu.play()
		tw.tween_property(nu, "volume_db", MUSIC_DB, secs)
	tw.chain().tween_callback(func(): if old.volume_db <= -79.0: old.stop())


func ambient(name: String) -> void:
	if name == _amb_name:
		return
	_amb_name = name
	if name == "":
		_amb.stop()
		return
	_amb.stream = _stream("amb/" + name, true)
	_amb.volume_db = AMB_DB
	_amb.play()


## One-shot effect. With a world position it is placed in the scene (panned/attenuated).
func sfx(name: String, pos := Vector2.INF, db := 0.0, pitch_var := 0.07) -> void:
	var s := _stream("sfx/" + name)
	if s == null:
		return
	var pitch := 1.0 + randf_range(-pitch_var, pitch_var)
	var scene := get_tree().current_scene
	if pos != Vector2.INF and scene:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Effects"
		p.stream = s
		p.volume_db = db
		p.pitch_scale = pitch
		p.max_distance = 2800.0
		p.attenuation = 1.2
		p.global_position = pos
		scene.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
		return
	var u := _ui[_ui_i]
	_ui_i = (_ui_i + 1) % _ui.size()
	u.stream = s
	u.volume_db = db
	u.pitch_scale = pitch
	u.play()


## A looping effect attached to a node (helicopter rotor, antenna hum, static).
func loop(key: String, name: String, on: bool, host: Node = null, db := 0.0) -> void:
	var have: bool = _loops.has(key) and is_instance_valid(_loops[key])
	if on and not have:
		var parent: Node = host if host else self
		var p: Node
		if host is Node2D:
			var p2 := AudioStreamPlayer2D.new()
			p2.max_distance = 3200.0
			p2.attenuation = 1.0
			p = p2
		else:
			p = AudioStreamPlayer.new()
		p.set("bus", "Effects")
		p.set("stream", _stream("sfx/" + name, true))
		p.set("volume_db", db)
		parent.add_child(p)
		p.call("play")
		_loops[key] = p
	elif not on and have:
		(_loops[key] as Node).queue_free()
		_loops.erase(key)


func _on_noise(pos: Vector2, _radius: float, kind: String) -> void:
	if kind == "footsteps":
		return
	var m: Array = NOISE_SFX.get(kind, ["", 0.0])
	if m[0] != "":
		sfx(m[0], pos, m[1])
