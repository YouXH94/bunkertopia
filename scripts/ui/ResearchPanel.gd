extends Control

var progress_bar: ProgressBar
var project_list: VBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.resources_changed.connect(func(_resources): _refresh())
	EventBus.body_changed.connect(func(_body): _refresh())
	EventBus.research_changed.connect(func(_progress, _unlocked): _refresh())


func open() -> void:
	visible = true
	AudioManager.play_ui()
	_refresh()


func close() -> void:
	visible = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.24)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(190, 110)
	panel.custom_minimum_size = Vector2(900, 500)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.060, 0.050, 0.96)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "实验室：解药研究"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.78, 0.95, 0.72))
	box.add_child(title)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.custom_minimum_size = Vector2(840, 26)
	box.add_child(progress_bar)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 350)
	box.add_child(scroll)

	project_list = VBoxContainer.new()
	project_list.add_theme_constant_override("separation", 8)
	scroll.add_child(project_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(110, 36)
	close_button.pressed.connect(close)
	footer.add_child(close_button)


func _refresh() -> void:
	if progress_bar == null:
		return
	progress_bar.value = GameState.research_progress
	progress_bar.tooltip_text = "解药研究进度 %.0f%%" % GameState.research_progress

	for child in project_list.get_children():
		child.queue_free()

	for project in DataRegistry.get_research_projects():
		project_list.add_child(_make_project_row(project))


func _make_project_row(project: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.075, 0.06, 0.92)))

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	row.add_child(content)

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(620, 70)
	content.add_child(text_box)

	var title := Label.new()
	title.text = str(project.get("name", "研究项目"))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.60))
	text_box.add_child(title)

	var desc := Label.new()
	desc.text = str(project.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.80, 0.80, 0.72))
	text_box.add_child(desc)

	var req := Label.new()
	req.text = "要求：" + _format_cost(project.get("cost", {}), project.get("body_cost", {}))
	req.add_theme_font_size_override("font_size", 13)
	req.add_theme_color_override("font_color", Color(0.68, 0.84, 0.86))
	text_box.add_child(req)

	var button := Button.new()
	var project_id := str(project.get("id", ""))
	var unlocked: bool = GameState.unlocked_research.has(project_id)
	var missing_prereq := _missing_prereq(project)
	button.text = "已完成" if unlocked else "推进 +%d%%" % int(project.get("progress", 0))
	button.custom_minimum_size = Vector2(145, 54)
	button.disabled = unlocked or missing_prereq or not GameState.can_afford(project.get("cost", {})) or not GameState.body_can_pay(project.get("body_cost", {}))
	if missing_prereq:
		button.text = "缺少前置"
	button.pressed.connect(_try_project.bind(project_id))
	content.add_child(button)
	return row


func _missing_prereq(project: Dictionary) -> bool:
	for required_id in project.get("requires", []):
		if not GameState.unlocked_research.has(required_id):
			return true
	return false


func _try_project(project_id: String) -> void:
	var project := DataRegistry.get_research_project(project_id)
	if project.is_empty():
		return
	var cost: Dictionary = project.get("cost", {})
	var body_cost: Dictionary = project.get("body_cost", {})
	if not GameState.can_afford(cost) or not GameState.body_can_pay(body_cost):
		EventBus.announce_notice("研究条件不足。")
		AudioManager.play_sfx("fail")
		return
	if not GameState.spend(cost, "research"):
		return

	var body_delta := {}
	for key in body_cost.keys():
		body_delta[key] = -int(body_cost[key])
	GameState.apply_body_delta(body_delta)
	GameState.add_research_progress(float(project.get("progress", 0)), project_id)
	EventBus.announce_event("研究推进：" + str(project.get("name", "")), str(project.get("description", "")) + "\n\n解药研究进度提升。")
	AudioManager.play_sfx("research")
	_refresh()


func _format_cost(cost: Dictionary, body_cost: Dictionary) -> String:
	var names := {
		"food": "食物",
		"water": "水",
		"power": "电力",
		"ammo": "弹药",
		"fuel": "燃料",
		"samples": "样本",
		"parts": "零件",
		"calories": "卡路里",
		"protein": "蛋白质",
		"vitamins": "维生素",
		"fat": "脂肪",
		"sleep": "睡眠",
		"sanity": "理智",
		"infection": "感染风险"
	}
	var parts := []
	for key in cost.keys():
		parts.append(str(names.get(key, key)) + " " + str(cost[key]))
	for key in body_cost.keys():
		parts.append(str(names.get(key, key)) + " " + str(body_cost[key]))
	return ", ".join(parts)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.36, 0.42, 0.30, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
