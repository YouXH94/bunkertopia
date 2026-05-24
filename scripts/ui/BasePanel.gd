extends Control

var status_label: Label
var option_list: VBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.resources_changed.connect(func(_resources): _refresh())
	EventBus.base_damage_changed.connect(func(_wall, _base): _refresh())


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
	shade.color = Color(0.0, 0.0, 0.0, 0.22)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(270, 125)
	panel.custom_minimum_size = Vector2(740, 470)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.060, 0.050, 0.038, 0.96)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "基地管理：资源与防线"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	box.add_child(title)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.74))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	option_list = VBoxContainer.new()
	option_list.add_theme_constant_override("separation", 8)
	box.add_child(option_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(110, 36)
	close_button.pressed.connect(close)
	footer.add_child(close_button)


func _refresh() -> void:
	if status_label == null:
		return
	status_label.text = "围墙完整度 %d%%，地堡结构 %d%%。发电机、电网、炮塔和农田维持着今天的生存窗口。" % [
		GameState.wall_integrity,
		GameState.base_integrity
	]

	for child in option_list.get_children():
		child.queue_free()

	for option in DataRegistry.get_build_options():
		option_list.add_child(_make_option_row(option))


func _make_option_row(option: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.075, 0.055, 0.92)))

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	row.add_child(content)

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(500, 64)
	content.add_child(text_box)

	var title := Label.new()
	title.text = str(option.get("name", "建造项"))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.84, 0.62))
	text_box.add_child(title)

	var desc := Label.new()
	desc.text = str(option.get("description", "")) + "\n消耗：" + _format_cost(option.get("cost", {}))
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.70))
	text_box.add_child(desc)

	var button := Button.new()
	var option_id := str(option.get("id", ""))
	button.text = "执行"
	button.custom_minimum_size = Vector2(105, 48)
	button.disabled = not GameState.can_afford(option.get("cost", {}))
	button.pressed.connect(_try_build.bind(option_id))
	content.add_child(button)
	return row


func _try_build(option_id: String) -> void:
	var selected := {}
	for option in DataRegistry.get_build_options():
		if option.get("id", "") == option_id:
			selected = option
			break
	if selected.is_empty():
		return
	if not GameState.spend(selected.get("cost", {}), "base_build"):
		EventBus.announce_notice("资源不足，无法执行。")
		AudioManager.play_sfx("fail")
		return

	var effect: Dictionary = selected.get("effect", {})
	if effect.has("wall_repair"):
		GameState.repair_wall(int(effect["wall_repair"]))
	if effect.has("power"):
		GameState.add_power(int(effect["power"]))
	if effect.has("turret_ready"):
		GameState.turret_ready = true
		GameState.mark_tutorial_flag("loaded_turret")
	EventBus.announce_notice("基地维护完成：" + str(selected.get("name", "")))
	AudioManager.play_sfx("pickup")
	_refresh()


func _format_cost(cost: Dictionary) -> String:
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
	for key in cost.keys():
		parts.append(str(names.get(key, key)) + " " + str(cost[key]))
	return ", ".join(parts)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.46, 0.38, 0.26, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
