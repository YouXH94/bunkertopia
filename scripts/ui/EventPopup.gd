extends Control

var panel: PanelContainer
var title_label: Label
var body_label: Label
var option_box: HBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.event_requested.connect(show_event)
	EventBus.report_requested.connect(show_report)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	panel = PanelContainer.new()
	panel.position = Vector2(340, 185)
	panel.custom_minimum_size = Vector2(600, 330)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.055, 0.04, 0.96)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	box.add_child(title_label)

	body_label = Label.new()
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.75))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(540, 170)
	box.add_child(body_label)

	option_box = HBoxContainer.new()
	option_box.add_theme_constant_override("separation", 10)
	box.add_child(option_box)


func show_event(title: String, body: String, options: Array = []) -> void:
	title_label.text = title
	body_label.text = body
	_set_options(options)
	visible = true


func show_report(report: Dictionary) -> void:
	var consumed := _format_dict(report.get("consumed", {}))
	var losses: Array = report.get("losses", [])
	var loss_text := "无"
	if not losses.is_empty():
		loss_text = ", ".join(losses)
	var body := "击杀数：%d\n基地损伤：%d\n围墙损伤：%d\n消耗资源：%s\n损失：%s\n围墙完整度：%d%%   地堡结构：%d%%" % [
		report.get("kills", 0),
		report.get("base_damage", 0),
		report.get("wall_damage", 0),
		consumed,
		loss_text,
		report.get("wall_integrity", 0),
		report.get("base_integrity", 0)
	]
	if int(report.get("sample_reward", 0)) > 0:
		body += "\n回收感染样本 +" + str(report.get("sample_reward", 0))
	show_event("黎明战报", body, [{"text": "返回基地", "action": "go_base"}])


func hide_popup() -> void:
	visible = false


func _set_options(options: Array) -> void:
	for child in option_box.get_children():
		child.queue_free()

	if options.is_empty():
		options = [{"text": "继续"}]

	for option in options:
		var button := Button.new()
		var text := "继续"
		if typeof(option) == TYPE_DICTIONARY:
			text = str(option.get("text", "继续"))
		else:
			text = str(option)
		button.text = text
		button.custom_minimum_size = Vector2(120, 38)
		button.pressed.connect(_on_option_pressed.bind(option))
		option_box.add_child(button)


func _on_option_pressed(option) -> void:
	hide_popup()
	if typeof(option) != TYPE_DICTIONARY:
		return
	if option.has("resource_delta"):
		GameState.apply_resource_delta(option["resource_delta"], "event")
	if option.has("body_delta"):
		GameState.apply_body_delta(option["body_delta"])
	var action := str(option.get("action", ""))
	if action == "go_base":
		SceneRouter.go_base()
	elif action == "go_city":
		SceneRouter.go_city()
	elif action == "go_night":
		SceneRouter.go_night()


func _format_dict(values: Dictionary) -> String:
	if values.is_empty():
		return "无"
	var names := {
		"food": "食物",
		"water": "水",
		"power": "电力",
		"ammo": "弹药",
		"fuel": "燃料",
		"samples": "样本",
		"parts": "零件"
	}
	var parts := []
	for key in values.keys():
		parts.append(str(names.get(key, key)) + " -" + str(values[key]))
	return ", ".join(parts)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.50, 0.42, 0.29, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style
