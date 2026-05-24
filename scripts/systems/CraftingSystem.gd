extends Node

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func can_craft(recipe_id: String) -> bool:
	var recipe := DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if not GameState.has_facility(str(recipe.get("facility", ""))):
		return false
	if int(recipe.get("power", 0)) > 0 and not PowerSystem.is_power_available(int(recipe.get("power", 0))):
		return false
	if int(recipe.get("fuel", 0)) > 0 and int(GameState.resources.get("fuel", 0)) < int(recipe.get("fuel", 0)):
		return false
	return GameState.can_afford_items(recipe.get("inputs", {}))


func craft(recipe_id: String) -> Dictionary:
	var recipe := DataRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "message": "未知配方。"}
	if not GameState.has_facility(str(recipe.get("facility", ""))):
		return {"ok": false, "message": "缺少设施：" + str(recipe.get("facility", ""))}
	if not can_craft(recipe_id):
		return {"ok": false, "message": "材料、电力或燃料不足。"}

	var cost: Dictionary = recipe.get("inputs", {})
	GameState.spend_mixed(cost, "craft")
	if int(recipe.get("fuel", 0)) > 0:
		GameState.apply_resource_delta({"fuel": -int(recipe.get("fuel", 0))}, "craft_fuel")
	if int(recipe.get("power", 0)) > 0:
		GameState.apply_resource_delta({"power": -int(recipe.get("power", 0))}, "craft_power")

	var skill_id: String = str(recipe.get("skill", "engineering"))
	var success_chance: float = clamp(float(recipe.get("success", 0.8)) + SkillSystem.success_bonus(skill_id), 0.05, 0.98)
	var success: bool = rng.randf() <= success_chance
	if success:
		var outputs: Dictionary = recipe.get("outputs", {})
		var boosted := {}
		for key in outputs.keys():
			boosted[key] = int(outputs[key]) + SkillSystem.yield_bonus(skill_id)
		GameState.apply_item_delta(boosted)
		GameState.add_skill_xp(skill_id, int(recipe.get("xp", 8)))
		return {"ok": true, "message": "制作完成：" + str(recipe.get("name", recipe_id)), "success": true}

	var refund := {}
	for key in cost.keys():
		if rng.randf() < 0.35:
			refund[key] = 1
	GameState.apply_item_delta(refund)
	GameState.add_skill_xp(skill_id, int(int(recipe.get("xp", 8)) / 2))
	return {"ok": true, "message": "制作失败，回收了一部分材料。", "success": false}
