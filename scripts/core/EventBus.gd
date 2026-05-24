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


func announce_event(title: String, body: String, options: Array = []) -> void:
	event_requested.emit(title, body, options)


func announce_notice(text: String) -> void:
	notice_requested.emit(text)


func set_prompt(text: String) -> void:
	interact_prompt_changed.emit(text)
