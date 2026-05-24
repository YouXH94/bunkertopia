extends Control

var list: VBoxContainer
var detail: Label
var power_label: Label
var current_category := "defense"
var selected_id := "barricade"


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.build_panel_requested.connect(toggle)
	EventBus.build_feedback.connect(_on_feedback)
	EventBus.power_changed.connect(_on_power_changed)


func toggle() -> void:
	visible = not visible
	EventBus.build_mode_changed.emit(visible)
	_refresh()


func close() -> void:
	visible = false
	EventBus.build_mode_changed.emit(false)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 145)
	panel.custom_minimum_size = Vector2(355, 520)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.050, 0.043, 0.94)))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "建造模式"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	box.add_child(title)

	var cat := HBoxContainer.new()
	cat.add_theme_constant_override("separation", 4)
	box.add_child(cat)
	for item in [["defense", "防御"], ["power", "电力"], ["production", "生产"], ["agriculture", "农业"], ["husbandry", "畜牧"], ["research", "科研"]]:
		var button := Button.new()
		button.text = item[1]
		button.pressed.connect(_set_category.bind(item[0]))
		cat.add_child(button)

	var tools := HBoxContainer.new()
	box.add_child(tools)
	for item in [["place", "放置"], ["repair", "维修"], ["demolish", "拆除"]]:
		var button := Button.new()
		button.text = item[1]
		button.pressed.connect(_set_tool.bind(str(item[0])))
		tools.add_child(button)

	var overlays := HBoxContainer.new()
	box.add_child(overlays)
	for item in [["none", "普通"], ["power", "电网"], ["threat", "威胁"]]:
		var button := Button.new()
		button.text = item[1]
		button.pressed.connect(_set_overlay.bind(str(item[0])))
		overlays.add_child(button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 210)
	box.add_child(scroll)
	list = VBoxContainer.new()
	scroll.add_child(list)

	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(310, 110)
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(0.82, 0.82, 0.72))
	box.add_child(detail)

	power_label = Label.new()
	power_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	power_label.add_theme_font_size_override("font_size", 13)
	power_label.add_theme_color_override("font_color", Color(0.70, 0.84, 0.88))
	box.add_child(power_label)

	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	var craft := Button.new()
	craft.text = "制作"
	craft.pressed.connect(func(): EventBus.crafting_panel_requested.emit())
	bottom.add_child(craft)
	var skills := Button.new()
	skills.text = "技能"
	skills.pressed.connect(func(): EventBus.skills_panel_requested.emit())
	bottom.add_child(skills)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close)
	bottom.add_child(close_button)
	_refresh()


func _set_category(category: String) -> void:
	current_category = category
	_refresh()


func _set_tool(tool: String) -> void:
	EventBus.build_tool_changed.emit(tool)
	AudioManager.play_ui()


func _set_overlay(overlay: String) -> void:
	EventBus.build_overlay_changed.emit(overlay)
	AudioManager.play_ui()


func _refresh() -> void:
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	for building in DataRegistry.get_defense_buildings():
		if str(building.get("category", "")) != current_category:
			continue
		var button := Button.new()
		button.text = str(building.get("name", building.get("id", "")))
		button.disabled = not GameState.can_afford_items(building.get("cost", {}))
		button.pressed.connect(_select_building.bind(str(building.get("id", ""))))
		list.add_child(button)
	_update_detail()
	_on_power_changed(PowerSystem.get_power_report())


func _select_building(building_id: String) -> void:
	selected_id = building_id
	EventBus.build_selection_changed.emit(building_id)
	_update_detail()
	AudioManager.play_ui()


func _update_detail() -> void:
	var data := DataRegistry.get_defense_building(selected_id)
	if data.is_empty():
		return
	detail.text = "%s\n%s\n成本：%s\n耐久：%d  占格：%s  耗电：%d  维修：%s" % [
		data.get("name", selected_id),
		data.get("description", ""),
		_format_cost(data.get("cost", {})),
		data.get("max_health", 0),
		str(data.get("size", [1, 1])),
		data.get("power_need", 0),
		_format_cost(data.get("repair_cost", {}))
	]


func _on_power_changed(report: Dictionary) -> void:
	if power_label == null:
		return
	power_label.text = "电力：发电 %d / 耗电 %d / 电池 %d / 过载 %d\n城市电网剩余：%d%%" % [
		report.get("generation", 0),
		report.get("consumption", 0),
		report.get("storage", 0),
		report.get("overload", 0),
		report.get("city_grid_power", 0)
	]


func _on_feedback(text: String, is_error: bool) -> void:
	if visible:
		EventBus.announce_notice(text)
		_refresh()


func _format_cost(cost: Dictionary) -> String:
	if cost.is_empty():
		return "无"
	var names := DataRegistry.get_items()
	var parts := []
	for key in cost.keys():
		var name := str(names.get(key, key))
		if GameState.resources.has(key):
			name = key
		parts.append(name + " " + str(cost[key]))
	return ", ".join(parts)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.37, 0.36, 0.27, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
