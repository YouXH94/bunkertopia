extends Control

signal resume_requested
signal save_requested
signal main_menu_requested
signal quit_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func open() -> void:
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.52)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(430, 112)
	panel.custom_minimum_size = Vector2(420, 500)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.044, 0.036, 0.98)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "暂停"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	box.add_child(title)

	var controls := Label.new()
	controls.text = "WASD/方向键 移动\nE 交互 / 搜刮\nSpace 近战/应急射击\nR 研究界面\nB 基地管理\nEsc 返回"
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color(0.80, 0.80, 0.72))
	box.add_child(controls)

	box.add_child(_make_button("继续", _on_resume))
	box.add_child(_make_button("保存", _on_save))
	box.add_child(_make_button("返回主菜单", _on_main_menu))
	box.add_child(_make_button("退出游戏", _on_quit))


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 42)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	return button


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.40, 0.39, 0.30, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


func _on_resume() -> void:
	AudioManager.play_ui()
	resume_requested.emit()


func _on_save() -> void:
	AudioManager.play_ui()
	save_requested.emit()


func _on_main_menu() -> void:
	AudioManager.play_ui()
	main_menu_requested.emit()


func _on_quit() -> void:
	AudioManager.play_ui()
	quit_requested.emit()
