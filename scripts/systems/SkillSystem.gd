extends Node


func get_level(skill_id: String) -> int:
	return int(GameState.skills.get(skill_id, {}).get("level", 1))


func get_xp(skill_id: String) -> int:
	return int(GameState.skills.get(skill_id, {}).get("xp", 0))


func success_bonus(skill_id: String) -> float:
	return float(get_level(skill_id) - 1) * 0.06


func time_multiplier(skill_id: String) -> float:
	return max(0.55, 1.0 - float(get_level(skill_id) - 1) * 0.07)


func yield_bonus(skill_id: String) -> int:
	return int((get_level(skill_id) - 1) / 2)


func learn_from_book(skill_id: String) -> bool:
	if int(GameState.inventory.get("books", 0)) <= 0:
		return false
	GameState.apply_item_delta({"books": -1})
	GameState.add_skill_xp(skill_id, 28)
	return true
