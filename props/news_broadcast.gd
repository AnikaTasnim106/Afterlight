extends Node2D
## The TV channel's broadcast, rendered into the TV's SubViewport (640x360).
## `stage` escalates the story: 0 = mild, 1 = violent incidents, 2 = military.

const W := 640.0
const H := 360.0

const HEADLINES := [
	["DEVELOPING", "HOSPITALS REPORT SURGE IN UNKNOWN FEVER CASES",
		"Health officials say there is no cause for alarm  •  Riverside Bridge closed for maintenance  •  Residents asked to avoid crowded areas  •  Pharmacies report shortage of fever medicine  •  "],
	["BREAKING", "VIOLENT INCIDENTS REPORTED ACROSS EASTSIDE",
		"Police ask witnesses not to approach disoriented individuals  •  Several streets closed near Central Hospital  •  Mobile networks overloaded  •  "],
	["EMERGENCY", "ARMY DEPLOYED — STAY INDOORS UNTIL FURTHER NOTICE",
		"Evacuation points being set up  •  Keep your phone charged  •  Follow official instructions only  •  Do not spread unverified reports  •  "],
	["EMERGENCY ALERT", "CITY EMERGENCY NOTICE — FOLLOW THE SIX RULES",
		"1 Stay indoors, lock doors  •  2 Avoid unnecessary noise  •  3 Do not approach aggressive or disoriented individuals  •  4 Conserve food and water  •  5 Keep supplies ready  •  6 Wait for official evacuation instructions  •  "],
]

@export var stage := 0:
	set(v):
		stage = clampi(v, 0, HEADLINES.size() - 1)
		_apply_stage()

var _t := 0.0
var _anchor: CharacterRig
var _tag: Label
var _headline: Label
var _ticker: Label
var _clock: Label
var _font_title := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var _font_body := preload("res://assets/fonts/Nunito.ttf")


var _bg: Node2D


func _ready() -> void:
	_bg = Node2D.new()
	_bg.z_index = -2
	_bg.draw.connect(_draw_bg)
	add_child(_bg)
	_anchor = CharacterRig.new()
	_anchor.z_index = -1
	_anchor.design = preload("res://characters/designs/news_anchor.tres")
	_anchor.position = Vector2(170, 468)
	_anchor.scale = Vector2(0.88, 0.88)
	_anchor.talking = true
	_anchor.pose_front = "open_hand"
	add_child(_anchor)
	_tag = _make_label(_font_title, 26, Color.WHITE, Vector2(18, 240))
	_headline = _make_label(_font_title, 30, Color("161a22"), Vector2(18, 272))
	_ticker = _make_label(_font_body, 19, Color.WHITE, Vector2(W, 330))
	_clock = _make_label(_font_title, 20, Color.WHITE, Vector2(560, 14))
	var logo := _make_label(_font_title, 24, Color.WHITE, Vector2(22, 12))
	logo.text = "CITY 7  NEWS"
	var live := _make_label(_font_title, 18, Color.WHITE, Vector2(345, 51))
	live.text = "LIVE"
	_apply_stage()


func _make_label(font: Font, sz: int, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	l.z_index = 5
	add_child(l)
	return l


func _apply_stage() -> void:
	if _tag == null:
		return
	var hl: Array = HEADLINES[stage]
	_tag.text = hl[0]
	_headline.text = hl[1]
	_ticker.text = hl[2] + hl[2]
	_anchor.expression = ["neutral", "worried", "determined", "determined"][stage]
	_anchor.visible = stage < 3
	queue_redraw()


func _process(dt: float) -> void:
	_t += dt
	_ticker.position.x -= dt * 70.0
	if _ticker.position.x < -_ticker.size.x * 0.5:
		_ticker.position.x += _ticker.size.x * 0.5
	_clock.text = "LIVE  7:%02d" % (42 + int(_t / 60.0))
	queue_redraw()
	_bg.queue_redraw()


func _draw_bg() -> void:
	var red := Color("c8402f")
	var ci := _bg
	# studio
	Vec.vgrad(ci, Rect2(0, 0, W, H), Color("0d2340"), Color("1c4a73"))
	for i in 7:
		var x := 40.0 + i * 95.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 30, 0), Vector2(x - 40, H), Vector2(x - 70, H)]), Color(1, 1, 1, 0.035))
	for i in 60:
		var p := Vector2(330 + Vec.hash01(i) * 290, 40 + Vec.hash01(i + 5.0) * 150)
		Vec.circle(ci, p, 1.6, Color(0.5, 0.8, 1.0, 0.25))
	# live footage inset
	var inset := Rect2(330, 44, 290, 170)
	Vec.rect(ci, inset.grow(4), Color("0a0d14"))
	Vec.vgrad(ci, inset, Color("1b1d2c"), Color(0.55, 0.28, 0.2) if stage > 0 else Color("3a3550"))
	var x2 := inset.position.x
	var k := 0
	while x2 < inset.end.x:
		var bw := 22.0 + Vec.hash01(k) * 30.0
		var bh := 40.0 + Vec.hash01(k + 2.0) * 90.0
		Vec.rect(ci, Rect2(x2, inset.end.y - bh, minf(bw, inset.end.x - x2), bh), Color("0e1018"))
		x2 += bw + 2.0
		k += 1
	if stage >= 1:
		for j in 6:
			var age := fposmod(_t * 0.15 + j / 6.0, 1.0)
			Vec.circle(ci, Vector2(inset.position.x + 120 + age * 40, inset.end.y - 60 - age * 110), 10 + age * 26, Color(0.25, 0.22, 0.25, (1.0 - age) * 0.7))
		var on := fposmod(_t * 3.0, 1.0) < 0.5
		Vec.circle(ci, Vector2(inset.position.x + 60, inset.end.y - 10), 5, Color(2.5, 0.3, 0.3) if on else Color(0.3, 0.5, 2.5))
	if stage >= 2:
		Vec.rrect(ci, Rect2(inset.position.x + 160, inset.end.y - 22, 70, 18), 3, Color("4a5a3a"))
	Vec.rrect(ci, Rect2(inset.position.x + 8, inset.position.y + 8, 46, 20), 3, red)


func _draw() -> void:
	var red := Color("c8402f")
	var amber := Color("e3a03c")
	var tag_col: Color = [amber, red, red, red][stage]
	if stage == 3:
		Vec.rect(self, Rect2(0, 0, W, 238), Color("7a1410"))
		for i in 8:
			Vec.rect(self, Rect2(0, 20 + i * 26, W, 10), Color(0, 0, 0, 0.15))
		Vec.rect(self, Rect2(150, 60, 340, 120), Color("f1ece2"))
		draw_string(_font_title, Vector2(176, 112), "EMERGENCY", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color("b8261d"))
		draw_string(_font_title, Vector2(212, 160), "ALERT", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color("b8261d"))
	# desk
	Vec.rect(self, Rect2(0, 222, 320, 20), Color("0a1626"))
	# lower third
	Vec.rect(self, Rect2(0, 238, W, 34), tag_col)
	Vec.rect(self, Rect2(0, 272, W, 44), Color("f2efe8"))
	# ticker
	Vec.rect(self, Rect2(0, 324, W, 36), Color("0b0f17"))
	Vec.rect(self, Rect2(0, 324, W, 3), tag_col)
	# channel bug
	Vec.rrect(self, Rect2(12, 10, 150, 32), 4, Color(0, 0, 0, 0.35))
	Vec.circle(self, Vector2(548, 27), 5, Color(2.5, 0.35, 0.3) if fposmod(_t, 1.0) < 0.6 else Color(0.5, 0.1, 0.1))
