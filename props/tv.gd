@tool
class_name TV
extends Node2D
## Wall TV on a low media cabinet. The screen shows a live SubViewport
## (props/news_broadcast.gd). Origin = floor contact point of the cabinet.

@export var screen_size := Vector2(400, 225)
@export var cabinet_size := Vector2(480, 120)
## Raise to change the headlines (0 calm, 1 violent, 2 military)
@export var news_stage := 0:
	set(v):
		news_stage = v
		if _news:
			_news.stage = v
## The screen is emissive: compensates for the room's dark CanvasModulate.
@export var screen_boost := 1.55
@export var powered := true

var _vp: SubViewport
var _news: Node2D
var _screen: Sprite2D


func _ready() -> void:
	for c in get_children():
		if c.has_meta("_generated"):
			c.queue_free()
	_vp = SubViewport.new()
	_vp.set_meta("_generated", true)
	_vp.size = Vector2i(640, 360)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(_vp)
	_news = preload("res://props/news_broadcast.gd").new()
	_vp.add_child(_news)
	_news.stage = news_stage
	_screen = Sprite2D.new()
	_screen.set_meta("_generated", true)
	_screen.texture = _vp.get_texture()
	_screen.centered = true
	_screen.position = _screen_center()
	_screen.scale = screen_size / Vector2(640, 360)
	_screen.modulate = Color(screen_boost, screen_boost, screen_boost)
	add_child(_screen)


func _screen_center() -> Vector2:
	return Vector2(0, -cabinet_size.y - 70 - screen_size.y * 0.5)


func _process(_dt: float) -> void:
	if _screen:
		_screen.visible = powered
		_screen.modulate = Color(screen_boost, screen_boost, screen_boost)
	queue_redraw()


func _draw() -> void:
	var cw := cabinet_size.x
	var ch := cabinet_size.y
	Vec.ellipse(self, Vector2(0, -2), cw * 0.52, 10, Color(0, 0, 0, 0.3))
	# cabinet
	Vec.rrect(self, Rect2(-cw * 0.5, -ch, cw, ch - 10), 4, Color("5a3d2b"))
	Vec.rrect(self, Rect2(-cw * 0.5, -ch, cw, 14), 4, Color("6e4a33"))
	for i in 2:
		Vec.stroke(self, Vec.rrect_pts(Rect2(-cw * 0.46 + i * cw * 0.48, -ch + 24, cw * 0.44, ch - 44), 3), Color("3f2a1e"), 3.0)
	for x in [-cw * 0.42, cw * 0.42]:
		Vec.rect(self, Rect2(x - 6, -12, 12, 12), Color("2a1d15"))
	# router with blinking LED, game console, plant
	Vec.rrect(self, Rect2(-cw * 0.4, -ch - 20, 70, 20), 4, Color("e6e3dc"))
	var t := Time.get_ticks_msec() / 1000.0
	for i in 3:
		var on := fposmod(t * (1.3 + i * 0.7), 1.0) < 0.5
		Vec.circle(self, Vector2(-cw * 0.4 + 14 + i * 14, -ch - 10), 3, Color(0.3, 2.0, 0.6) if on else Color(0.1, 0.3, 0.12))
	Vec.rrect(self, Rect2(cw * 0.12, -ch - 16, 110, 16), 3, Color("24262b"))
	# TV bezel
	var c := _screen_center()
	var r := Rect2(c - screen_size * 0.5, screen_size)
	if powered:
		Vec.glow(self, c, screen_size.x * 0.85, Color(0.35, 0.6, 1.2, 0.35), 0.75)
	Vec.rrect(self, r.grow(12), 6, Color("101115"))
	Vec.rect(self, r, Color("05060a"))
	Vec.rect(self, Rect2(c.x - 30, r.end.y + 12, 60, 8), Color("101115"))
	# wall mount arm
	Vec.rect(self, Rect2(c.x - 12, r.end.y + 20, 24, 50), Color("2a2c31"))
