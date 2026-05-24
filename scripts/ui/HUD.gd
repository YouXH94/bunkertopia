extends Control

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

var phase_label: Label
var resource_labels := {}
var body_label: Label
var power_status_label: Label
var wall_bar: ProgressBar
var base_bar: ProgressBar
var research_bar: ProgressBar
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
	EventBus.research_changed.connect(_on_research_changed)
	EventBus.power_changed.connect(_on_power_changed)
	GameState.emit_full_refresh()


func _build_ui() -> void:
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(14, 10)
	top_panel.custom_minimum_size = Vector2(900, 118)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.035, 0.030, 0.88)))
	add_child(top_panel)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 7)
	top_panel.add_child(top_box)

	phase_label = _make_label(18, Color(0.82, 0.92, 0.66))
	top_box.add_child(phase_label)

	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	top_box.add_child(resource_row)

	for data in [
		["food", "食物"],
		["water", "水"],
		["power", "电力"],
		["ammo", "弹药"],
		["fuel", "燃料"],
		["samples", "样本"],
		["parts", "零件"]
	]:
		resource_row.add_child(_make_resource_chip(data[0], data[1]))

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	top_box.add_child(bottom_row)

	research_bar = _make_bar(Color(0.48, 0.76, 0.67))
	research_bar.custom_minimum_size = Vector2(185, 18)
	bottom_row.add_child(_make_bar_group("解药", research_bar))

	wall_bar = _make_bar(Color(0.78, 0.45, 0.34))
	wall_bar.custom_minimum_size = Vector2(185, 18)
	bottom_row.add_child(_make_bar_group("围墙", wall_bar))

	base_bar = _make_bar(Color(0.80, 0.65, 0.40))
	base_bar.custom_minimum_size = Vector2(185, 18)
	bottom_row.add_child(_make_bar_group("地堡", base_bar))

	body_label = _make_label(13, Color(0.74, 0.84, 0.84))
	bottom_row.add_child(body_label)

	power_status_label = _make_label(13, Color(0.70, 0.84, 0.88))
	bottom_row.add_child(power_status_label)

	var prompt_panel := PanelContainer.new()
	prompt_panel.position = Vector2(410, 657)
	prompt_panel.custom_minimum_size = Vector2(460, 44)
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.040, 0.035, 0.025, 0.90)))
	add_child(prompt_panel)

	prompt_label = _make_label(17, Color(0.95, 0.86, 0.62))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	var notice_panel := PanelContainer.new()
	notice_panel.position = Vector2(890, 18)
	notice_panel.custom_minimum_size = Vector2(370, 74)
	notice_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.060, 0.045, 0.88)))
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


func _make_resource_chip(key: String, display_name: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(102, 30)
	chip.add_theme_stylebox_override("panel", _chip_style(Color(0.070, 0.073, 0.060, 0.92)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.texture = TextureLoader.load_texture(ArtRegistry.icon_path(key, "res://assets/art/ui/icon_%s.png" % key))
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := _make_label(13, Color(0.88, 0.86, 0.74))
	label.text = display_name + " 0"
	resource_labels[key] = label
	row.add_child(label)
	return chip


func _make_bar_group(title: String, bar: ProgressBar) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var label := _make_label(12, Color(0.82, 0.80, 0.70))
	label.text = title
	box.add_child(label)
	box.add_child(bar)
	return box


func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = true
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.050, 0.046, 0.040, 0.95)
	background.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	fill_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_style)
	return bar


func _on_resources_changed(resources: Dictionary) -> void:
	for key in resource_labels.keys():
		var label: Label = resource_labels[key]
		var value := int(resources.get(key, 0))
		label.text = _resource_name(key) + " " + str(value)
		label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.38) if value <= _warn_threshold(key) else Color(0.88, 0.86, 0.74))


func _on_body_changed(body: Dictionary) -> void:
	body_label.text = "身体  卡路里 %d  睡眠 %d  理智 %d  感染 %d" % [
		body.get("calories", 0),
		body.get("sleep", 0),
		body.get("sanity", 0),
		body.get("infection", 0)
	]
	body_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.38) if int(body.get("infection", 0)) >= 70 else Color(0.74, 0.84, 0.84))


func _on_phase_changed(phase_name: String, day: int) -> void:
	phase_label.text = "Day %d  |  %s  |  目标：解药阶段一或撑过第 3 夜" % [day, phase_name]


func _on_base_damage_changed(wall_integrity: int, base_integrity: int) -> void:
	wall_bar.value = wall_integrity
	base_bar.value = base_integrity


func _on_research_changed(progress: float, _unlocked: Array) -> void:
	research_bar.value = progress


func _on_power_changed(report: Dictionary) -> void:
	if power_status_label == null:
		return
	power_status_label.text = "电网 %d%%  发电 %d  耗电 %d  电池 %d  过载 %d" % [
		report.get("city_grid_power", 0),
		report.get("generation", 0),
		report.get("consumption", 0),
		report.get("storage", 0),
		report.get("overload", 0)
	]
	power_status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.38) if int(report.get("overload", 0)) > 0 else Color(0.70, 0.84, 0.88))


func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text


func _on_notice(text: String) -> void:
	var panel: Control = notice_label.get_meta("panel")
	notice_label.text = text
	panel.visible = true
	notice_timer.start(3.0)


func _resource_name(key: String) -> String:
	var names := {
		"food": "食物",
		"water": "水",
		"power": "电力",
		"ammo": "弹药",
		"fuel": "燃料",
		"samples": "样本",
		"parts": "零件"
	}
	return str(names.get(key, key))


func _warn_threshold(key: String) -> int:
	if key == "fuel" or key == "samples":
		return 1
	if key == "ammo":
		return 6
	return 5


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


func _chip_style(color: Color) -> StyleBoxFlat:
	var style := _panel_style(color)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
