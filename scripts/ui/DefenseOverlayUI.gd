extends Control

var mode_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	mode_label = Label.new()
	mode_label.position = Vector2(390, 142)
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_label.add_theme_color_override("font_color", Color(0.76, 0.88, 0.82))
	add_child(mode_label)
	EventBus.build_overlay_changed.connect(_on_overlay_changed)
	EventBus.build_mode_changed.connect(func(enabled): visible = enabled)


func _on_overlay_changed(overlay: String) -> void:
	if overlay == "power":
		mode_label.text = "电网覆盖：蓝色为供电/储电节点，红色为断电设施。"
	elif overlay == "threat":
		mode_label.text = "威胁覆盖：红点为预计尸潮方向，红线为可能冲击路线。"
	else:
		mode_label.text = "建造覆盖：绿色可放置，红色不可放置或会封死路径。"
