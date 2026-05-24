extends Node

enum Phase { BASE_DAY, CITY_EXPLORE, NIGHT_DEFENSE, DAWN_REPORT }

const INITIAL_RESOURCES := {
	"food": 42,
	"water": 34,
	"power": 36,
	"ammo": 28,
	"fuel": 8,
	"samples": 0,
	"parts": 30
}

const INITIAL_BODY_STATUS := {
	"calories": 78,
	"protein": 58,
	"vitamins": 56,
	"fat": 48,
	"sleep": 74,
	"sanity": 70,
	"infection": 4
}

const INITIAL_INVENTORY := {
	"scrap": 18,
	"wood": 16,
	"cloth": 6,
	"wire": 6,
	"electronics": 4,
	"chemicals": 3,
	"seeds": 4,
	"raw_food": 4,
	"medicine": 2,
	"books": 1,
	"iron_ingot": 0,
	"screws": 2,
	"circuit_board": 0,
	"battery_cell": 0,
	"fertilizer": 0,
	"animal_feed": 0
}

const INITIAL_SKILLS := {
	"engineering": {"level": 1, "xp": 0},
	"agriculture": {"level": 1, "xp": 0},
	"husbandry": {"level": 1, "xp": 0},
	"biology": {"level": 1, "xp": 0}
}

var day := 1
var phase := Phase.BASE_DAY
var phase_name := "白天：基地建设"
var resources := INITIAL_RESOURCES.duplicate(true)
var body_status := INITIAL_BODY_STATUS.duplicate(true)
var research_progress := 0.0
var unlocked_research := []
var wall_integrity := 100
var base_integrity := 100
var turret_ready := true
var night_stats := {}
var inventory := INITIAL_INVENTORY.duplicate(true)
var skills := INITIAL_SKILLS.duplicate(true)
var placed_buildings := []
var next_building_uid := 1
var city_grid_power := 60
var base_footprint := 0
var base_noise := 0
var base_smell := 0
var base_light := 0
var demo_completed := false
var failed := false
var tutorial_flags := {
	"opened_tutorial": false,
	"scavenged": false,
	"maintained_generator": false,
	"used_farm": false,
	"used_animal_pen": false,
	"loaded_turret": false,
	"survived_first_night": false
}


func _ready() -> void:
	call_deferred("emit_full_refresh")


func emit_full_refresh() -> void:
	EventBus.resources_changed.emit(resources.duplicate(true))
	EventBus.body_changed.emit(body_status.duplicate(true))
	EventBus.research_changed.emit(research_progress, unlocked_research.duplicate())
	EventBus.phase_changed.emit(phase_name, day)
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)
	_recalculate_base_pressure()
	if has_node("/root/PowerSystem"):
		EventBus.power_changed.emit(PowerSystem.get_power_report())


func reset_new_game() -> void:
	day = 1
	phase = Phase.BASE_DAY
	phase_name = "白天：基地建设"
	resources = INITIAL_RESOURCES.duplicate(true)
	body_status = INITIAL_BODY_STATUS.duplicate(true)
	research_progress = 0.0
	unlocked_research = []
	wall_integrity = 100
	base_integrity = 100
	turret_ready = false
	night_stats = {}
	inventory = INITIAL_INVENTORY.duplicate(true)
	skills = INITIAL_SKILLS.duplicate(true)
	next_building_uid = 1
	placed_buildings = _initial_buildings()
	city_grid_power = 60
	base_footprint = 0
	base_noise = 0
	base_smell = 0
	base_light = 0
	demo_completed = false
	failed = false
	tutorial_flags = {
		"opened_tutorial": false,
		"scavenged": false,
		"maintained_generator": false,
		"used_farm": false,
		"used_animal_pen": false,
		"loaded_turret": false,
		"survived_first_night": false
	}
	emit_full_refresh()


func enter_base() -> void:
	phase = Phase.BASE_DAY
	phase_name = "白天：基地建设"
	EventBus.phase_changed.emit(phase_name, day)


func enter_city() -> void:
	phase = Phase.CITY_EXPLORE
	phase_name = "白天：城市搜刮"
	EventBus.phase_changed.emit(phase_name, day)


func start_night() -> void:
	if failed or demo_completed:
		return
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
	_decay_city_power()
	var report := night_stats.duplicate(true)
	report["day"] = day
	report["wall_integrity"] = wall_integrity
	report["base_integrity"] = base_integrity
	report["research_progress"] = research_progress
	report["base_noise"] = base_noise
	report["base_smell"] = base_smell
	report["base_light"] = base_light
	report["power_report"] = PowerSystem.get_power_report() if has_node("/root/PowerSystem") else {}
	report["demo_completed"] = day >= 3
	tutorial_flags["survived_first_night"] = true
	day += 1
	EventBus.phase_changed.emit(phase_name, day)
	if bool(report["demo_completed"]):
		demo_completed = true
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
	if failed:
		return
	for key in delta.keys():
		var old_value := int(resources.get(key, 0))
		var change := int(delta[key])
		resources[key] = max(0, old_value + change)
		if phase == Phase.NIGHT_DEFENSE and change < 0:
			var consumed: Dictionary = night_stats.get("consumed", {})
			consumed[key] = int(consumed.get(key, 0)) + abs(change)
			night_stats["consumed"] = consumed
	EventBus.resources_changed.emit(resources.duplicate(true))
	_check_resource_pressure(reason)
	if has_node("/root/PowerSystem"):
		EventBus.power_changed.emit(PowerSystem.get_power_report())


func apply_body_delta(delta: Dictionary) -> void:
	if failed:
		return
	for key in delta.keys():
		var old_value := int(body_status.get(key, 0))
		var change := int(delta[key])
		body_status[key] = clamp(old_value + change, 0, 100)
	EventBus.body_changed.emit(body_status.duplicate(true))
	_check_body_pressure()


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
	if project_id == "field_vaccine_hint":
		_complete_demo("第一阶段解药研究完成", "疫苗线索已经足够稳定。地堡记录下第一支原型的配方，Steam Demo 到这里完成。")


func add_research_progress(amount: float, project_id: String = "") -> void:
	if failed or demo_completed:
		return
	research_progress = clamp(research_progress + amount, 0.0, 100.0)
	if project_id != "":
		unlock_research(project_id)
	EventBus.research_changed.emit(research_progress, unlocked_research.duplicate())
	if research_progress >= 100.0:
		_complete_demo("解药原型完成", "地堡实验室终于合成了第一支可注射原型。Steam Demo 到这里完成。")
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
	if failed:
		return
	wall_integrity = clamp(wall_integrity - amount, 0, 100)
	night_stats["wall_damage"] = int(night_stats.get("wall_damage", 0)) + amount
	if wall_integrity < 45:
		EventBus.announce_notice("外墙完整度跌破警戒线。")
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)


func record_base_damage(amount: int) -> void:
	if failed:
		return
	base_integrity = clamp(base_integrity - amount, 0, 100)
	night_stats["base_damage"] = int(night_stats.get("base_damage", 0)) + amount
	if base_integrity < 60:
		EventBus.announce_notice("地堡门承受了直接冲击。")
	EventBus.base_damage_changed.emit(wall_integrity, base_integrity)
	if base_integrity <= 0:
		_fail_demo("基地核心被毁", "地堡门被尸潮撕开，发电机停转，实验室冷库也失去了供电。")


func add_loss(text: String) -> void:
	var losses: Array = night_stats.get("losses", [])
	losses.append(text)
	night_stats["losses"] = losses


func apply_item_delta(delta: Dictionary) -> void:
	for key in delta.keys():
		var old_value := int(inventory.get(key, 0))
		inventory[key] = max(0, old_value + int(delta[key]))


func can_afford_items(cost: Dictionary) -> bool:
	for key in cost.keys():
		if _is_resource_key(key):
			if int(resources.get(key, 0)) < int(cost[key]):
				return false
		elif int(inventory.get(key, 0)) < int(cost[key]):
			return false
	return true


func spend_mixed(cost: Dictionary, reason: String = "") -> bool:
	if not can_afford_items(cost):
		return false
	var resource_delta := {}
	var item_delta := {}
	for key in cost.keys():
		if _is_resource_key(key):
			resource_delta[key] = -int(cost[key])
		else:
			item_delta[key] = -int(cost[key])
	if not resource_delta.is_empty():
		apply_resource_delta(resource_delta, reason)
	if not item_delta.is_empty():
		apply_item_delta(item_delta)
	return true


func has_facility(facility_id: String) -> bool:
	for building in placed_buildings:
		if str(building.get("id", "")) == facility_id and int(building.get("health", 0)) > 0:
			return true
	return false


func add_building(building_id: String, grid: Vector2i, rotation: int = 0) -> Dictionary:
	var data := DataRegistry.get_defense_building(building_id)
	if data.is_empty():
		return {}
	if not spend_mixed(data.get("cost", {}), "build"):
		return {}
	var entry := {
		"uid": next_building_uid,
		"id": building_id,
		"grid": [grid.x, grid.y],
		"rotation": rotation,
		"health": int(data.get("max_health", 1))
	}
	next_building_uid += 1
	placed_buildings.append(entry)
	_recalculate_base_pressure()
	if has_node("/root/PowerSystem"):
		EventBus.power_changed.emit(PowerSystem.get_power_report())
	return entry


func remove_building(uid: int) -> bool:
	for i in range(placed_buildings.size()):
		var building: Dictionary = placed_buildings[i]
		if int(building.get("uid", -1)) == uid:
			if bool(building.get("locked", false)):
				return false
			placed_buildings.remove_at(i)
			_recalculate_base_pressure()
			return true
	return false


func update_building_health(uid: int, health: int) -> void:
	for building in placed_buildings:
		if int(building.get("uid", -1)) == uid:
			building["health"] = max(0, health)
			_recalculate_base_pressure()
			return


func repair_building(uid: int) -> bool:
	for building in placed_buildings:
		if int(building.get("uid", -1)) == uid:
			var data := DataRegistry.get_defense_building(str(building.get("id", "")))
			if data.is_empty():
				return false
			if not spend_mixed(data.get("repair_cost", {}), "repair"):
				return false
			building["health"] = int(data.get("max_health", building.get("health", 1)))
			_recalculate_base_pressure()
			return true
	return false


func add_skill_xp(skill_id: String, amount: int) -> void:
	if not skills.has(skill_id):
		return
	var skill: Dictionary = skills[skill_id]
	skill["xp"] = int(skill.get("xp", 0)) + amount
	var needed := int(skill.get("level", 1)) * 40
	while int(skill.get("xp", 0)) >= needed:
		skill["xp"] = int(skill.get("xp", 0)) - needed
		skill["level"] = int(skill.get("level", 1)) + 1
		needed = int(skill.get("level", 1)) * 40
	skills[skill_id] = skill


func _is_resource_key(key: String) -> bool:
	return resources.has(key)


func _initial_buildings() -> Array:
	var initial := []
	for item in [
		["bunker_core", Vector2i(12, 7), true],
		["lab_station", Vector2i(15, 6), true],
		["farm_plot", Vector2i(5, 4), true],
		["animal_pen", Vector2i(7, 4), true],
		["generator", Vector2i(10, 10), true],
		["workbench", Vector2i(14, 9), true]
	]:
		var data := DataRegistry.get_defense_building(str(item[0]))
		initial.append({
			"uid": next_building_uid,
			"id": item[0],
			"grid": [item[1].x, item[1].y],
			"rotation": 0,
			"health": int(data.get("max_health", 100)),
			"locked": item[2]
		})
		next_building_uid += 1
	return initial


func _decay_city_power() -> void:
	city_grid_power = max(0, city_grid_power - 18)
	EventBus.announce_notice("城市电网继续衰减，剩余供电约 " + str(city_grid_power) + "%。")


func _recalculate_base_pressure() -> void:
	base_footprint = 0
	base_noise = 0
	base_smell = 0
	base_light = 0
	for building in placed_buildings:
		if int(building.get("health", 0)) <= 0:
			continue
		var data := DataRegistry.get_defense_building(str(building.get("id", "")))
		var size: Array = data.get("size", [1, 1])
		base_footprint += int(size[0]) * int(size[1])
		base_noise += int(data.get("noise", 0))
		base_smell += int(data.get("smell", 0))
		base_light += int(data.get("light", 0))


func mark_tutorial_flag(flag: String) -> void:
	tutorial_flags[flag] = true


func to_save_dict() -> Dictionary:
	return {
		"version": 1,
		"day": day,
		"phase": int(phase),
		"phase_name": phase_name,
		"resources": resources.duplicate(true),
		"body_status": body_status.duplicate(true),
		"research_progress": research_progress,
		"unlocked_research": unlocked_research.duplicate(),
		"wall_integrity": wall_integrity,
		"base_integrity": base_integrity,
		"turret_ready": turret_ready,
		"inventory": inventory.duplicate(true),
		"skills": skills.duplicate(true),
		"placed_buildings": placed_buildings.duplicate(true),
		"next_building_uid": next_building_uid,
		"city_grid_power": city_grid_power,
		"demo_completed": demo_completed,
		"failed": failed,
		"tutorial_flags": tutorial_flags.duplicate(true)
	}


func load_from_save_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	phase = int(data.get("phase", Phase.BASE_DAY))
	phase_name = str(data.get("phase_name", "白天：基地建设"))
	resources = _merge_defaults(INITIAL_RESOURCES, data.get("resources", {}))
	body_status = _merge_defaults(INITIAL_BODY_STATUS, data.get("body_status", {}))
	research_progress = float(data.get("research_progress", 0.0))
	unlocked_research = data.get("unlocked_research", [])
	wall_integrity = int(data.get("wall_integrity", 100))
	base_integrity = int(data.get("base_integrity", 100))
	turret_ready = bool(data.get("turret_ready", false))
	inventory = _merge_defaults(INITIAL_INVENTORY, data.get("inventory", {}))
	skills = _merge_defaults(INITIAL_SKILLS, data.get("skills", {}))
	placed_buildings = data.get("placed_buildings", [])
	if placed_buildings.is_empty():
		next_building_uid = 1
		placed_buildings = _initial_buildings()
	else:
		next_building_uid = int(data.get("next_building_uid", placed_buildings.size() + 1))
	city_grid_power = int(data.get("city_grid_power", 60))
	demo_completed = bool(data.get("demo_completed", false))
	failed = bool(data.get("failed", false))
	tutorial_flags = _merge_defaults(tutorial_flags, data.get("tutorial_flags", {}))
	night_stats = {}
	emit_full_refresh()


func _merge_defaults(defaults: Dictionary, incoming) -> Dictionary:
	var merged := defaults.duplicate(true)
	if typeof(incoming) == TYPE_DICTIONARY:
		for key in incoming.keys():
			merged[key] = incoming[key]
	return merged


func _check_resource_pressure(reason: String) -> void:
	if reason == "load":
		return
	if int(resources.get("food", 0)) <= 5:
		EventBus.announce_notice("食物库存接近见底。")
	if int(resources.get("water", 0)) <= 5:
		EventBus.announce_notice("净水库存接近见底。")
	if int(resources.get("power", 0)) <= 5:
		EventBus.announce_notice("电力不足，炮塔和实验室都会受影响。")
	if int(resources.get("food", 0)) <= 0 and int(resources.get("water", 0)) <= 0:
		_fail_demo("关键资源耗尽", "地堡同时失去食物和净水，幸存者无法继续维持实验。")


func _check_body_pressure() -> void:
	if int(body_status.get("infection", 0)) >= 100:
		_fail_demo("感染失控", "感染曲线突破安全阈值，实验室把你锁在了隔离舱外。")
	elif int(body_status.get("calories", 0)) <= 0:
		_fail_demo("体力崩溃", "持续搜刮和夜战耗尽了最后一点体力。")
	elif int(body_status.get("sanity", 0)) <= 0:
		_fail_demo("理智崩溃", "无线电里的噪声终于比墙外的撞击更大声。")


func _fail_demo(title: String, body: String) -> void:
	if failed or demo_completed:
		return
	failed = true
	EventBus.request_game_over(title, body)


func _complete_demo(title: String, body: String) -> void:
	if failed or demo_completed:
		return
	demo_completed = true
	EventBus.request_demo_complete(title, body)
