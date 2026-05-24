extends Control

var phase_label: Label
var resource_label: Label
var body_label: Label
var defense_label: Label
var prompt_label: Label
var notice_label: Label
var notice_timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.body_changed.connect(_on_body_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.notice_requested.connect(_on_notice)
	EventBus.base_damage_changed.connect(_on_base_damage_changed)
	GameState.emit_full_refresh()


func _build_ui() -> void:
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(14, 10)
	top_panel.custom_minimum_size = Vector2(830, 95)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.04, 0.035, 0.86)))
	add_child(top_panel)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top_panel.add_child(top_box)

	phase_label = _make_label(18, Color(0.79, 0.92, 0.66))
	resource_label = _make_label(15, Color(0.92, 0.89, 0.78))
	body_label = _make_label(14, Color(0.72, 0.84, 0.88))
	defense_label = _make_label(14, Color(0.95, 0.70, 0.55))
	top_box.add_child(phase_label)
	top_box.add_child(resource_label)
	top_box.add_child(body_label)
	top_box.add_child(defense_label)

	var prompt_panel := PanelContainer.new()
	prompt_panel.position = Vector2(420, 660)
	prompt_panel.custom_minimum_size = Vector2(440, 42)
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.035, 0.025, 0.88)))
	add_child(prompt_panel)

	prompt_label = _make_label(17, Color(0.95, 0.86, 0.62))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	var notice_panel := PanelContainer.new()
	notice_panel.position = Vector2(880, 18)
	notice_panel.custom_minimum_size = Vector2(380, 70)
	notice_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.06, 0.04, 0.84)))
	add_child(notice_panel)

	notice_label = _make_label(14, Color(1.0, 0.82, 0.58))
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_panel.add_child(notice_label)
	notice_panel.visible = false
	notice_label.set_meta("panel", notice_panel)

	notice_timer = Timer.new()
	notice_timer.one_shot = true
	notice_timer.timeout.connect(func(): notice_panel.visible = false)
	add_child(notice_timer)


func _on_resources_changed(resources: Dictionary) -> void:
	resource_label.text = "食物 %d   水 %d   电力 %d   弹药 %d   燃料 %d   样本 %d   零件 %d   研究 %.0f%%" % [
		resources.get("food", 0),
		resources.get("water", 0),
		resources.get("power", 0),
		resources.get("ammo", 0),
		resources.get("fuel", 0),
		resources.get("samples", 0),
		resources.get("parts", 0),
		GameState.research_progress
	]


func _on_body_changed(body: Dictionary) -> void:
	body_label.text = "卡路里 %d   蛋白质 %d   维生素 %d   脂肪 %d   睡眠 %d   理智 %d   感染风险 %d" % [
		body.get("calories", 0),
		body.get("protein", 0),
		body.get("vitamins", 0),
		body.get("fat", 0),
		body.get("sleep", 0),
		body.get("sanity", 0),
		body.get("infection", 0)
	]


func _on_phase_changed(phase_name: String, day: int) -> void:
	phase_label.text = "Day %d  |  %s" % [day, phase_name]


func _on_base_damage_changed(wall_integrity: int, base_integrity: int) -> void:
	defense_label.text = "围墙完整度 %d%%   地堡结构 %d%%" % [wall_integrity, base_integrity]


func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text


func _on_notice(text: String) -> void:
	var panel: Control = notice_label.get_meta("panel")
	notice_label.text = text
	panel.visible = true
	notice_timer.start(3.0)


func _make_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.38, 0.36, 0.29, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
