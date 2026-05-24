extends Node

const BASE_SCENE := preload("res://scenes/base/BaseHub.tscn")
const CITY_SCENE := preload("res://scenes/city/CityExplore.tscn")
const NIGHT_SCENE := preload("res://scenes/defense/NightDefense.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const POPUP_SCENE := preload("res://scenes/ui/EventPopup.tscn")
const RESEARCH_SCENE := preload("res://scenes/ui/ResearchPanel.tscn")
const BASE_PANEL_SCENE := preload("res://scenes/ui/BasePanel.tscn")
const MainMenu := preload("res://scripts/ui/MainMenu.gd")
const PauseMenu := preload("res://scripts/ui/PauseMenu.gd")
const EndScreen := preload("res://scripts/ui/EndScreen.gd")
const BuildMenu := preload("res://scripts/ui/BuildMenu.gd")
const CraftingPanel := preload("res://scripts/ui/CraftingPanel.gd")
const SkillsPanel := preload("res://scripts/ui/SkillsPanel.gd")
const DefenseOverlayUI := preload("res://scripts/ui/DefenseOverlayUI.gd")

var world_root: Node2D
var ui_layer: CanvasLayer
var current_world: Node
var hud: Control
var popup: Control
var research_panel: Control
var base_panel: Control
var main_menu: Control
var pause_menu: Control
var end_screen: Control
var build_menu: Control
var crafting_panel: Control
var skills_panel: Control
var defense_overlay: Control
var gameplay_started := false


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

	main_menu = MainMenu.new()
	pause_menu = PauseMenu.new()
	end_screen = EndScreen.new()
	build_menu = BuildMenu.new()
	crafting_panel = CraftingPanel.new()
	skills_panel = SkillsPanel.new()
	defense_overlay = DefenseOverlayUI.new()
	ui_layer.add_child(main_menu)
	ui_layer.add_child(build_menu)
	ui_layer.add_child(defense_overlay)
	ui_layer.add_child(crafting_panel)
	ui_layer.add_child(skills_panel)
	ui_layer.add_child(pause_menu)
	ui_layer.add_child(end_screen)

	SceneRouter.scene_change_requested.connect(_load_world)
	EventBus.research_panel_requested.connect(research_panel.open)
	EventBus.base_panel_requested.connect(base_panel.open)
	EventBus.game_over_requested.connect(_show_failure)
	EventBus.demo_completed_requested.connect(_show_demo_completed)
	EventBus.save_requested.connect(_save_current_game)
	main_menu.new_game_requested.connect(_start_new_game)
	main_menu.continue_requested.connect(_continue_game)
	main_menu.quit_requested.connect(_quit_game)
	pause_menu.resume_requested.connect(pause_menu.close)
	pause_menu.save_requested.connect(_save_current_game)
	pause_menu.main_menu_requested.connect(_return_to_menu)
	pause_menu.quit_requested.connect(_quit_game)
	end_screen.new_game_requested.connect(_start_new_game)
	end_screen.main_menu_requested.connect(_return_to_menu)
	end_screen.quit_requested.connect(_quit_game)

	_show_game_ui(false)
	_show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_started:
		return
	if event.is_action_pressed("open_research") and not pause_menu.visible and not popup.visible:
		research_panel.toggle()
	elif event.is_action_pressed("open_base") and not pause_menu.visible and not popup.visible:
		EventBus.build_panel_requested.emit()
	elif event.is_action_pressed("close_ui"):
		if pause_menu.visible:
			pause_menu.close()
		elif popup.visible:
			popup.hide_popup()
		elif crafting_panel.visible:
			crafting_panel.close()
		elif skills_panel.visible:
			skills_panel.close()
		elif build_menu.visible:
			build_menu.close()
		elif research_panel.visible:
			research_panel.close()
		elif base_panel.visible:
			base_panel.close()
		else:
			pause_menu.open()


func _load_world(scene_key: String) -> void:
	if current_world != null:
		current_world.queue_free()
		current_world = null

	var packed: PackedScene = BASE_SCENE
	if scene_key == "city":
		packed = CITY_SCENE
		GameState.enter_city()
		AudioManager.stop_ambience()
	elif scene_key == "night":
		packed = NIGHT_SCENE
		AudioManager.play_ambience("res://assets/audio/ambience/night_wind.wav")
	else:
		packed = BASE_SCENE
		GameState.enter_base()
		AudioManager.stop_ambience()

	current_world = packed.instantiate()
	world_root.add_child(current_world)
	EventBus.set_prompt("")
	_save_current_game()


func _show_opening_event() -> void:
	GameState.mark_tutorial_flag("opened_tutorial")
	var event_data: Dictionary = DataRegistry.get_event("opening")
	var body := str(event_data.get("body", "地堡系统上线。"))
	body += "\n\n目标：完成第一阶段解药研究，或撑过第 3 个夜晚。先去城市和坠机点搜刮样本与物资，回基地维护发电机、农田、畜舍、炮塔和防线。"
	EventBus.announce_event(event_data.get("title", "Bunkertopia"), body)


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("attack", [KEY_SPACE])
	_add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	_add_key_action("open_research", [KEY_R])
	_add_key_action("open_base", [KEY_B])
	_add_key_action("close_ui", [KEY_ESCAPE])


func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _add_mouse_action(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _start_new_game() -> void:
	get_tree().paused = false
	SaveManager.delete_save()
	GameState.reset_new_game()
	SceneRouter.current_scene_key = "base"
	main_menu.visible = false
	end_screen.hide_result()
	_show_game_ui(true)
	gameplay_started = true
	_load_world("base")
	call_deferred("_show_opening_event")


func _continue_game() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		main_menu.refresh_continue_state()
		EventBus.announce_notice("没有可读取的存档。")
		return
	var scene_key := str(data.get("scene_key", "base"))
	if scene_key == "night":
		scene_key = "base"
	get_tree().paused = false
	main_menu.visible = false
	end_screen.hide_result()
	_show_game_ui(true)
	gameplay_started = true
	SceneRouter.current_scene_key = scene_key
	_load_world(scene_key)


func _show_game_ui(enabled: bool) -> void:
	hud.visible = enabled
	research_panel.visible = false
	base_panel.visible = false
	popup.visible = false
	if build_menu != null:
		build_menu.visible = false
	if crafting_panel != null:
		crafting_panel.visible = false
	if skills_panel != null:
		skills_panel.visible = false


func _show_main_menu() -> void:
	gameplay_started = false
	get_tree().paused = false
	_clear_world()
	_show_game_ui(false)
	main_menu.visible = true
	main_menu.refresh_continue_state()
	pause_menu.visible = false
	end_screen.visible = false
	AudioManager.stop_ambience()


func _return_to_menu() -> void:
	pause_menu.close()
	_show_main_menu()


func _clear_world() -> void:
	if current_world != null:
		current_world.queue_free()
		current_world = null
	EventBus.set_prompt("")


func _save_current_game() -> void:
	if gameplay_started:
		SaveManager.save_game(SceneRouter.current_scene_key)
		EventBus.announce_notice("存档已更新。")


func _show_failure(title: String, body: String) -> void:
	SaveManager.delete_save()
	end_screen.show_result(title, body, false)
	AudioManager.play_sfx("fail")


func _show_demo_completed(title: String, body: String) -> void:
	SaveManager.delete_save()
	end_screen.show_result(title, body, true)
	AudioManager.play_sfx("research")


func _quit_game() -> void:
	get_tree().quit()
