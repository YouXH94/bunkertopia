extends Control

signal new_game_requested
signal main_menu_requested
signal quit_requested

var title_label: Label
var body_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func show_result(title: String, body: String, success: bool) -> void:
	title_label.text = title
	body_label.text = body
	title_label.add_theme_color_override("font_color", Color(0.82, 0.94, 0.66) if success else Color(0.95, 0.45, 0.34))
	visible = true
	get_tree().paused = true


func hide_result() -> void:
	visible = false
	get_tree().paused = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.012, 0.016, 0.014, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.position = Vector2(290, 138)
	panel.custom_minimum_size = Vector2(700, 445)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.050, 0.040, 0.98)))
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 31)
	box.add_child(title_label)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(620, 210)
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.72))
	box.add_child(body_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	buttons.add_child(_make_button("新游戏", _on_new_game))
	buttons.add_child(_make_button("主菜单", _on_main_menu))
	buttons.add_child(_make_button("退出", _on_quit))


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 42)
	button.pressed.connect(callback)
	return button


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.42, 0.38, 0.27, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style


func _on_new_game() -> void:
	AudioManager.play_ui()
	new_game_requested.emit()


func _on_main_menu() -> void:
	AudioManager.play_ui()
	main_menu_requested.emit()


func _on_quit() -> void:
	AudioManager.play_ui()
	quit_requested.emit()
