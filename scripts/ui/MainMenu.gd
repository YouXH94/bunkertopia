extends Control

signal new_game_requested
signal continue_requested
signal quit_requested

var continue_button: Button
var settings_panel: Control
var fullscreen_toggle: CheckButton
var master_slider: HSlider
var sfx_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	refresh_continue_state()


func refresh_continue_state() -> void:
	if continue_button != null:
		continue_button.disabled = not SaveManager.has_save()


func _build_ui() -> void:
	var bg_texture = load("res://assets/steam_store/menu_background.png") if ResourceLoader.exists("res://assets/steam_store/menu_background.png") else null
	if bg_texture != null:
		var bg := TextureRect.new()
		bg.texture = bg_texture
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color(0.035, 0.04, 0.035)
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fallback)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.36)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var content := VBoxContainer.new()
	content.position = Vector2(82, 96)
	content.custom_minimum_size = Vector2(520, 540)
	content.add_theme_constant_override("separation", 14)
	add_child(content)

	var title := Label.new()
	title.text = "BUNKERTOPIA"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.86, 0.92, 0.76))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Steam Demo Candidate"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.95, 0.72, 0.46))
	content.add_child(subtitle)

	var body := Label.new()
	body.text = "三天。一个地堡。一条还没变成笑话的解药路线。"
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", Color(0.82, 0.80, 0.70))
	content.add_child(body)

	content.add_child(_spacer(24))

	var new_button := _make_button("新游戏")
	new_button.pressed.connect(_on_new_game)
	content.add_child(new_button)

	continue_button = _make_button("继续游戏")
	continue_button.pressed.connect(_on_continue)
	content.add_child(continue_button)

	var settings_button := _make_button("设置")
	settings_button.pressed.connect(_toggle_settings)
	content.add_child(settings_button)

	var quit_button := _make_button("退出")
	quit_button.pressed.connect(_on_quit)
	content.add_child(quit_button)

	settings_panel = _make_settings_panel()
	settings_panel.position = Vector2(690, 138)
	settings_panel.visible = false
	add_child(settings_panel)


func _make_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 360)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.050, 0.043, 0.96)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.90, 0.86, 0.62))
	box.add_child(title)

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "全屏"
	fullscreen_toggle.add_theme_font_size_override("font_size", 16)
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	box.add_child(fullscreen_toggle)

	var resolution := OptionButton.new()
	resolution.add_item("1280 x 720")
	resolution.add_item("1600 x 900")
	resolution.add_item("1920 x 1080")
	resolution.item_selected.connect(_set_resolution)
	box.add_child(resolution)

	box.add_child(_make_slider_row("主音量", "Master"))
	box.add_child(_make_slider_row("音效", "SFX"))

	var controls := Label.new()
	controls.text = "控制：WASD/方向键移动，E 交互，Space 攻击，R 研究，B 基地，Esc 暂停。"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(0.78, 0.78, 0.70))
	box.add_child(controls)
	return panel


func _make_slider_row(label_text: String, bus_name: String) -> Control:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.72))
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 0.82
	slider.value_changed.connect(_set_bus_volume.bind(bus_name))
	row.add_child(slider)
	if bus_name == "Master":
		master_slider = slider
	else:
		sfx_slider = slider
	return row


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 46)
	button.add_theme_font_size_override("font_size", 18)
	return button


func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, height)
	return spacer


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.37, 0.36, 0.27, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _on_new_game() -> void:
	AudioManager.play_ui()
	new_game_requested.emit()


func _on_continue() -> void:
	AudioManager.play_ui()
	continue_requested.emit()


func _toggle_settings() -> void:
	AudioManager.play_ui()
	settings_panel.visible = not settings_panel.visible


func _on_quit() -> void:
	AudioManager.play_ui()
	quit_requested.emit()


func _set_fullscreen(enabled: bool) -> void:
	AudioManager.play_ui()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)


func _set_resolution(index: int) -> void:
	AudioManager.play_ui()
	var sizes := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	DisplayServer.window_set_size(sizes[index])


func _set_bus_volume(value: float, bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(max(value, 0.01)))
