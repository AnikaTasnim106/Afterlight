@tool
class_name SoftLight
extends PointLight2D
## PointLight2D with a generated soft falloff texture and optional flicker.
## Lights CanvasItems (characters, props) under a dark CanvasModulate.

@export var radius := 400.0:
	set(v):
		radius = v
		_apply()
@export var base_energy := 1.0:
	set(v):
		base_energy = v
		energy = v
## 0 = steady. TV ~0.35, failing bulb ~0.6
@export_range(0.0, 1.0) var flicker := 0.0
@export var flicker_speed := 9.0
## Optional pulse (sirens): seconds per cycle; 0 = off
@export var pulse_period := 0.0
@export var pulse_colors: PackedColorArray = PackedColorArray()

var _t := 0.0
var _noise := 0.0
var _noise_target := 0.0
var _noise_timer := 0.0


func _ready() -> void:
	_apply()


func _apply() -> void:
	texture = Vec.glow_texture()
	texture_scale = radius / 128.0
	energy = base_energy


func _process(dt: float) -> void:
	_t += dt
	var e := base_energy
	if flicker > 0.0:
		_noise_timer -= dt
		if _noise_timer <= 0.0:
			_noise_timer = 1.0 / flicker_speed * randf_range(0.5, 1.5)
			_noise_target = randf_range(-1.0, 1.0)
		_noise = lerpf(_noise, _noise_target, clampf(dt * flicker_speed * 1.5, 0.0, 1.0))
		e *= 1.0 + _noise * flicker * 0.5
	if pulse_period > 0.0 and pulse_colors.size() > 0:
		var ph := fposmod(_t / pulse_period, 1.0)
		var idx := int(ph * pulse_colors.size()) % pulse_colors.size()
		color = pulse_colors[idx]
		var local := fposmod(ph * pulse_colors.size(), 1.0)
		e *= pow(sin(local * PI), 2.0)
	energy = e
