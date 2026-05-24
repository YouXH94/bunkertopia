extends Node

signal resources_changed(resources)
signal body_changed(body_status)
signal research_changed(progress, unlocked)
signal phase_changed(phase_name, day)
signal event_requested(title, body, options)
signal interact_prompt_changed(text)
signal report_requested(report)
signal notice_requested(text)
signal base_damage_changed(wall_integrity, base_integrity)
signal research_panel_requested
signal base_panel_requested
signal game_over_requested(title, body)
signal demo_completed_requested(title, body)
signal save_requested
signal build_mode_changed(enabled)
signal build_selection_changed(building_id)
signal build_tool_changed(tool)
signal build_overlay_changed(overlay)
signal build_panel_requested
signal crafting_panel_requested
signal skills_panel_requested
signal power_changed(report)
signal build_feedback(text, is_error)


func announce_event(title: String, body: String, options: Array = []) -> void:
	event_requested.emit(title, body, options)


func announce_notice(text: String) -> void:
	notice_requested.emit(text)


func set_prompt(text: String) -> void:
	interact_prompt_changed.emit(text)


func request_game_over(title: String, body: String) -> void:
	game_over_requested.emit(title, body)


func request_demo_complete(title: String, body: String) -> void:
	demo_completed_requested.emit(title, body)
