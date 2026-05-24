extends Control

var recipe_list: VBoxContainer
var item_label: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.crafting_panel_requested.connect(open)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(405, 132)
	panel.custom_minimum_size = Vector2(500, 460)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.050, 0.050, 0.042, 0.97)))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "制作与加工"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	box.add_child(title)
	item_label = Label.new()
	item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_label.add_theme_font_size_override("font_size", 13)
	item_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.80))
	box.add_child(item_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(455, 290)
	box.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.add_theme_constant_override("separation", 6)
	scroll.add_child(recipe_list)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close)
	box.add_child(close_button)


func _refresh() -> void:
	item_label.text = "库存：" + _format_values(GameState.inventory)
	for child in recipe_list.get_children():
		child.queue_free()
	for recipe in DataRegistry.get_recipes():
		var row := Button.new()
		var skill := str(recipe.get("skill", "engineering"))
		var chance := int((float(recipe.get("success", 0.8)) + SkillSystem.success_bonus(skill)) * 100)
		row.text = "%s  成功率 %d%%  设施 %s" % [recipe.get("name", ""), chance, recipe.get("facility", "")]
		row.disabled = not CraftingSystem.can_craft(str(recipe.get("id", "")))
		row.tooltip_text = "输入：" + _format_values(recipe.get("inputs", {})) + "\n输出：" + _format_values(recipe.get("outputs", {}))
		row.pressed.connect(_craft.bind(str(recipe.get("id", ""))))
		recipe_list.add_child(row)


func _craft(recipe_id: String) -> void:
	var result := CraftingSystem.craft(recipe_id)
	EventBus.announce_notice(str(result.get("message", "")))
	AudioManager.play_sfx("research" if bool(result.get("success", false)) else "fail")
	_refresh()


func _format_values(values: Dictionary) -> String:
	if values.is_empty():
		return "无"
	var names := DataRegistry.get_items()
	var parts := []
	for key in values.keys():
		parts.append(str(names.get(key, key)) + " " + str(values[key]))
	return ", ".join(parts)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.40, 0.38, 0.28, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
