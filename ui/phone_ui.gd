class_name PhoneUI
extends Control
## Alex's phone, shown on screen: chat with June, emergency alerts, silent mode.

const W := 500.0
const H := 860.0

var font_body: Font = preload("res://assets/fonts/Nunito.ttf")
var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_mono: Font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")

var _body: Panel
var _header: Label
var _status: Label
var _list: VBoxContainer
var _alert: PanelContainer
var _alert_title: Label
var _alert_body: Label
var _silent: Label
var _open := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(1920 + 40, 110)
	size = Vector2(W, H)
	_body = Panel.new()
	_body.size = Vector2(W, H)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101217")
	sb.set_corner_radius_all(48)
	sb.border_color = Color("2b2e36")
	sb.set_border_width_all(10)
	_body.add_theme_stylebox_override("panel", sb)
	add_child(_body)
	var screen := ColorRect.new()
	screen.color = Color("1a1d24")
	screen.position = Vector2(22, 60)
	screen.size = Vector2(W - 44, H - 100)
	add_child(screen)
	_status = _lbl(font_mono, 20, Color(1, 1, 1, 0.75), Vector2(44, 22))
	_status.text = "8:31        ▂▄▆  NO SERVICE"
	_header = _lbl(font_title, 34, Color("39c2b4"), Vector2(44, 76))
	_header.text = "June"
	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.12)
	rule.position = Vector2(22, 124)
	rule.size = Vector2(W - 44, 2)
	add_child(rule)
	_list = VBoxContainer.new()
	_list.position = Vector2(36, 140)
	_list.size = Vector2(W - 72, H - 200)
	_list.add_theme_constant_override("separation", 14)
	add_child(_list)
	_alert = PanelContainer.new()
	var asb := StyleBoxFlat.new()
	asb.bg_color = Color("8f1f1a")
	asb.set_corner_radius_all(18)
	asb.content_margin_left = 20
	asb.content_margin_right = 20
	asb.content_margin_top = 16
	asb.content_margin_bottom = 16
	_alert.add_theme_stylebox_override("panel", asb)
	_alert.position = Vector2(36, 200)
	_alert.custom_minimum_size = Vector2(W - 72, 0)
	_alert.size = Vector2(W - 72, 0)
	var av := VBoxContainer.new()
	_alert.add_child(av)
	_alert_title = Label.new()
	_alert_title.add_theme_font_override("font", font_title)
	_alert_title.add_theme_font_size_override("font_size", 34)
	av.add_child(_alert_title)
	_alert_body = Label.new()
	_alert_body.add_theme_font_override("font", font_body)
	_alert_body.add_theme_font_size_override("font_size", 24)
	_alert_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_alert_body.custom_minimum_size = Vector2(W - 112, 0)
	av.add_child(_alert_body)
	_alert.visible = false
	add_child(_alert)
	_silent = _lbl(font_title, 44, Color("f3eee6"), Vector2(0, 380))
	_silent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_silent.size = Vector2(W, 60)
	_silent.visible = false


func _lbl(font: Font, sz: int, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	add_child(l)
	return l


func open() -> void:
	_open = true
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", 1300.0, 0.45)
	await tw.finished


func close() -> void:
	_open = false
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:x", 1960.0, 0.35)
	await tw.finished


func set_time(t: String, service := false) -> void:
	_status.text = "%s        ▂▄▆  %s" % [t, "4G" if service else "NO SERVICE"]


func clear() -> void:
	for c in _list.get_children():
		c.queue_free()
	_alert.visible = false
	_silent.visible = false
	_list.visible = true


## Add a chat bubble. status: "", "sending", "failed"
func add_message(from_me: bool, text: String, time := "", status := "") -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if from_me else BoxContainer.ALIGNMENT_BEGIN
	var bubble := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("8a5a1c") if from_me else Color("2a3a40")
	bs.set_corner_radius_all(20)
	bs.content_margin_left = 18
	bs.content_margin_right = 18
	bs.content_margin_top = 10
	bs.content_margin_bottom = 10
	bubble.add_theme_stylebox_override("panel", bs)
	var v := VBoxContainer.new()
	bubble.add_child(v)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	l.add_theme_font_override("font", font_body)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color("f3eee6"))
	v.add_child(l)
	var meta := Label.new()
	meta.add_theme_font_override("font", font_mono)
	meta.add_theme_font_size_override("font_size", 16)
	meta.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	meta.text = time
	if status == "failed":
		meta.text = "⚠  Not delivered — no network"
		meta.add_theme_color_override("font_color", Color("ff7a66"))
	v.add_child(meta)
	row.add_child(bubble)
	_list.add_child(row)
	bubble.modulate.a = 0.0
	create_tween().tween_property(bubble, "modulate:a", 1.0, 0.25)
	return row


func show_alert(title: String, body: String) -> void:
	_list.visible = false
	_alert_title.text = title
	_alert_body.text = body
	_alert.visible = true
	_alert.modulate.a = 0.0
	create_tween().tween_property(_alert, "modulate:a", 1.0, 0.2)


func show_silent() -> void:
	_list.visible = false
	_alert.visible = false
	_silent.text = "🔕  SILENT MODE\nON"
	_silent.text = "SILENT  MODE\nON"
	_silent.visible = true


func buzz() -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(self, "rotation", 0.02 if i % 2 == 0 else -0.02, 0.05)
	tw.tween_property(self, "rotation", 0.0, 0.05)
