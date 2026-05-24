extends Control

var list: VBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	EventBus.skills_panel_requested.connect(open)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(920, 132)
	panel.custom_minimum_size = Vector2(340, 430)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.046, 0.050, 0.044, 0.97)))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "技能"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	box.add_child(title)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	box.add_child(list)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close)
	box.add_child(close_button)


func _refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	for skill_id in ["engineering", "agriculture", "husbandry", "biology"]:
		var row := VBoxContainer.new()
		var label := Label.new()
		label.text = "%s  Lv.%d  XP %d/%d\n加成：成功率 +%d%%，时间 %.0f%%，产量 +%d" % [
			_name(skill_id),
			SkillSystem.get_level(skill_id),
			SkillSystem.get_xp(skill_id),
			SkillSystem.get_level(skill_id) * 40,
			int(SkillSystem.success_bonus(skill_id) * 100),
			SkillSystem.time_multiplier(skill_id) * 100,
			SkillSystem.yield_bonus(skill_id)
		]
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.72))
		row.add_child(label)
		var button := Button.new()
		button.text = "阅读书本学习"
		button.disabled = int(GameState.inventory.get("books", 0)) <= 0
		button.pressed.connect(_learn.bind(skill_id))
		row.add_child(button)
		list.add_child(row)


func _learn(skill_id: String) -> void:
	if SkillSystem.learn_from_book(skill_id):
		EventBus.announce_notice("读完一本脏兮兮的手册：" + _name(skill_id) + " 经验提升。")
		AudioManager.play_sfx("research")
	else:
		EventBus.announce_notice("没有可读的书本。")
		AudioManager.play_sfx("fail")
	_refresh()


func _name(skill_id: String) -> String:
	var names := {
		"engineering": "工程学",
		"agriculture": "农学",
		"husbandry": "畜牧学",
		"biology": "生物学"
	}
	return str(names.get(skill_id, skill_id))


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
