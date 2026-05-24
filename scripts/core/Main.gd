extends Node

const BASE_SCENE := preload("res://scenes/base/BaseHub.tscn")
const CITY_SCENE := preload("res://scenes/city/CityExplore.tscn")
const NIGHT_SCENE := preload("res://scenes/defense/NightDefense.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const POPUP_SCENE := preload("res://scenes/ui/EventPopup.tscn")
const RESEARCH_SCENE := preload("res://scenes/ui/ResearchPanel.tscn")
const BASE_PANEL_SCENE := preload("res://scenes/ui/BasePanel.tscn")

var world_root: Node2D
var ui_layer: CanvasLayer
var current_world: Node
var hud: Control
var popup: Control
var research_panel: Control
var base_panel: Control


func _ready() -> void:
	_setup_input()

	world_root = Node2D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	hud = HUD_SCENE.instantiate()
	popup = POPUP_SCENE.instantiate()
	research_panel = RESEARCH_SCENE.instantiate()
	base_panel = BASE_PANEL_SCENE.instantiate()
	ui_layer.add_child(hud)
	ui_layer.add_child(research_panel)
	ui_layer.add_child(base_panel)
	ui_layer.add_child(popup)

	SceneRouter.scene_change_requested.connect(_load_world)
	EventBus.research_panel_requested.connect(research_panel.open)
	EventBus.base_panel_requested.connect(base_panel.open)
	_load_world("base")
	call_deferred("_show_opening_event")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_research"):
		research_panel.toggle()
	elif event.is_action_pressed("open_base"):
		base_panel.toggle()
	elif event.is_action_pressed("trigger_night"):
		SceneRouter.go_night()
	elif event.is_action_pressed("close_ui"):
		if popup.visible:
			popup.hide_popup()
		elif research_panel.visible:
			research_panel.close()
		elif base_panel.visible:
			base_panel.close()


func _load_world(scene_key: String) -> void:
	if current_world != null:
		current_world.queue_free()
		current_world = null

	var packed: PackedScene = BASE_SCENE
	if scene_key == "city":
		packed = CITY_SCENE
		GameState.enter_city()
	elif scene_key == "night":
		packed = NIGHT_SCENE
	else:
		packed = BASE_SCENE
		GameState.enter_base()

	current_world = packed.instantiate()
	world_root.add_child(current_world)
	EventBus.set_prompt("")


func _show_opening_event() -> void:
	var event_data := DataRegistry.get_event("opening")
	EventBus.announce_event(event_data.get("title", "Bunkertopia"), event_data.get("body", "地堡系统上线。"))


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("open_research", [KEY_R])
	_add_key_action("open_base", [KEY_B])
	_add_key_action("trigger_night", [KEY_N])
	_add_key_action("close_ui", [KEY_ESCAPE])


func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)
