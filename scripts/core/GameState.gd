extends Node

enum Phase { BASE_DAY, CITY_EXPLORE, NIGHT_DEFENSE, DAWN_REPORT }

var day := 12
var phase := Phase.BASE_DAY
var phase_name := "白天：基地建设"

var resources := {
	"food": 118,
	"water": 86,
	"power": 84,
	"ammo": 58,
	"fuel": 24,
	"samples": 6,
	"parts": 72
}

var body_status := {
	"calories": 72,
	"protein": 54,
	"vitamins": 61,
	"fat": 46,
	"sleep": 68,
	"sanity": 74,
	"infection": 12
}

var research_progress := 12.0
var unlocked_research := []
var wall_integrity := 100
var base_integrity := 100
var turret_ready := true
var night_stats := {}


func _ready() -> void:
	call_deferred("emit_full_refresh")


func emit_full_refresh() -> void:
	EventBus.resources_changed.emit(resources.duplicate(true))
	EventBus.body_changed.emit(body_status.duplicate(true))
	EventBus.research_changed.emit(research_progress, unlocked_research.duplicate())
	EventBus.phase_changed.emit(phase_name, day)
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)


func enter_base() -> void:
	phase = Phase.BASE_DAY
	phase_name = "白天：基地建设"
	EventBus.phase_changed.emit(phase_name, day)


func enter_city() -> void:
	phase = Phase.CITY_EXPLORE
	phase_name = "白天：城市搜刮"
	EventBus.phase_changed.emit(phase_name, day)


func start_night() -> void:
	phase = Phase.NIGHT_DEFENSE
	phase_name = "夜晚：基地防守"
	night_stats = {
		"kills": 0,
		"base_damage": 0,
		"wall_damage": 0,
		"consumed": {},
		"losses": []
	}
	apply_resource_delta({"power": -6, "fuel": -1}, "night_start")
	EventBus.phase_changed.emit(phase_name, day)


func finish_night() -> Dictionary:
	phase = Phase.DAWN_REPORT
	phase_name = "黎明：战报"
	var sample_reward := int(night_stats.get("kills", 0) / 4)
	if sample_reward > 0:
		apply_resource_delta({"samples": sample_reward}, "night_samples")
		night_stats["sample_reward"] = sample_reward
	apply_body_delta({"sleep": -10, "sanity": -6, "calories": -8})
	var report := night_stats.duplicate(true)
	report["day"] = day
	report["wall_integrity"] = wall_integrity
	report["base_integrity"] = base_integrity
	report["research_progress"] = research_progress
	day += 1
	EventBus.phase_changed.emit(phase_name, day)
	return report


func can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		if int(resources.get(key, 0)) < int(cost[key]):
			return false
	return true


func body_can_pay(cost: Dictionary) -> bool:
	for key in cost.keys():
		if int(body_status.get(key, 0)) < int(cost[key]):
			return false
	return true


func apply_resource_delta(delta: Dictionary, reason: String = "") -> void:
	for key in delta.keys():
		var old_value := int(resources.get(key, 0))
		var change := int(delta[key])
		resources[key] = max(0, old_value + change)
		if phase == Phase.NIGHT_DEFENSE and change < 0:
			var consumed: Dictionary = night_stats.get("consumed", {})
			consumed[key] = int(consumed.get(key, 0)) + abs(change)
			night_stats["consumed"] = consumed
	EventBus.resources_changed.emit(resources.duplicate(true))


func apply_body_delta(delta: Dictionary) -> void:
	for key in delta.keys():
		var old_value := int(body_status.get(key, 0))
		var change := int(delta[key])
		body_status[key] = clamp(old_value + change, 0, 100)
	EventBus.body_changed.emit(body_status.duplicate(true))


func spend(cost: Dictionary, reason: String = "") -> bool:
	if not can_afford(cost):
		return false
	var delta := {}
	for key in cost.keys():
		delta[key] = -int(cost[key])
	apply_resource_delta(delta, reason)
	return true


func unlock_research(project_id: String) -> void:
	if not unlocked_research.has(project_id):
		unlocked_research.append(project_id)
		EventBus.research_changed.emit(research_progress, unlocked_research.duplicate())


func add_research_progress(amount: float, project_id: String = "") -> void:
	research_progress = clamp(research_progress + amount, 0.0, 100.0)
	if project_id != "":
		unlock_research(project_id)
	EventBus.research_changed.emit(research_progress, unlocked_research.duplicate())
	if research_progress >= 100.0:
		EventBus.announce_event("解药原型完成", "地堡实验室终于合成了第一支可注射原型。预览版到这里结束，但 Bunkertopia 的故事才刚开始。")
	else:
		var event_data := DataRegistry.get_event("research")
		EventBus.announce_notice(event_data.get("body", "研究进度提升。"))


func repair_wall(amount: int) -> void:
	wall_integrity = clamp(wall_integrity + amount, 0, 100)
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)


func add_power(amount: int) -> void:
	apply_resource_delta({"power": amount}, "generator")


func record_kill() -> void:
	night_stats["kills"] = int(night_stats.get("kills", 0)) + 1


func record_wall_damage(amount: int) -> void:
	wall_integrity = clamp(wall_integrity - amount, 0, 100)
	night_stats["wall_damage"] = int(night_stats.get("wall_damage", 0)) + amount
	if wall_integrity < 45:
		EventBus.announce_notice("外墙完整度跌破警戒线。")
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)


func record_base_damage(amount: int) -> void:
	base_integrity = clamp(base_integrity - amount, 0, 100)
	night_stats["base_damage"] = int(night_stats.get("base_damage", 0)) + amount
	if base_integrity < 60:
		EventBus.announce_notice("地堡门承受了直接冲击。")
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)


func add_loss(text: String) -> void:
	var losses: Array = night_stats.get("losses", [])
	losses.append(text)
	night_stats["losses"] = losses
