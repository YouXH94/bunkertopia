extends RefCounted

const PathGridSystem := preload("res://scripts/systems/PathGridSystem.gd")


static func get_spawn_cells() -> Array[Vector2i]:
	return PathGridSystem.spawn_cells_for_pressure(GameState.base_footprint, GameState.base_noise, GameState.base_smell, GameState.base_light)


static func threat_summary() -> String:
	var directions := get_spawn_cells().size()
	return "威胁方向 %d，噪音 %d，气味 %d，光源 %d，防守面积 %d" % [
		directions,
		GameState.base_noise,
		GameState.base_smell,
		GameState.base_light,
		GameState.base_footprint
	]


static func weak_path_hint(report: Dictionary) -> String:
	if int(report.get("power_report", {}).get("overload", 0)) > 0:
		return "电力过载导致部分防御离线，优先补发电机、电池或输电杆。"
	if int(report.get("farm_loss", 0)) > 0:
		return "农田暴露在尸潮路径上，建议用栅栏或陷阱把路线拨开。"
	if int(report.get("animal_loss", 0)) > 0:
		return "畜舍气味吸引了尸群，外侧需要废铁墙和火焰陷阱。"
	if int(report.get("ammo_waste", 0)) > 8:
		return "爬行群消耗了大量弹药，尖刺陷阱能更便宜地处理小体型目标。"
	if int(report.get("wall_damage", 0)) > 30:
		return "主路线承压过高，尝试增加折线路径和电铁丝减速。"
	return "防线表现稳定，可以考虑扩展实验或生产设施，但会增加夜间压力。"
