extends "res://scripts/base/InteractablePoint.gd"

var container_data := {}
var searched := false
var rng := RandomNumberGenerator.new()


func setup(data: Dictionary) -> void:
	container_data = data
	prompt = "E 搜刮：" + str(data.get("name", "容器"))


func _ready() -> void:
	rng.randomize()
	super()


func interact(actor: Node) -> void:
	if searched:
		EventBus.announce_notice("这里已经被搜空了。")
		return

	searched = true
	if marker != null:
		marker.modulate = Color(0.45, 0.45, 0.45, 1.0)

	var loot := _roll_loot(container_data.get("loot", {}))
	GameState.apply_resource_delta(loot, "city_scavenge")
	var risk := int(container_data.get("risk", 0))
	GameState.apply_body_delta({"infection": risk, "calories": -2, "sleep": -1})

	var loot_text := _format_loot(loot)
	var body := str(container_data.get("event", "你翻出了还能用的物资。"))
	body += "\n\n获得：" + loot_text + "\n感染风险 +" + str(risk)
	EventBus.announce_event(str(container_data.get("name", "搜刮点")), body)


func _roll_loot(loot_ranges: Dictionary) -> Dictionary:
	var loot := {}
	for key in loot_ranges.keys():
		var range = loot_ranges[key]
		var amount := 0
		if typeof(range) == TYPE_ARRAY and range.size() >= 2:
			amount = rng.randi_range(int(range[0]), int(range[1]))
		else:
			amount = int(range)
		if amount != 0:
			loot[key] = amount
	return loot


func _format_loot(loot: Dictionary) -> String:
	var names := {
		"food": "食物",
		"water": "水",
		"power": "电力",
		"ammo": "弹药",
		"fuel": "燃料",
		"samples": "样本",
		"parts": "零件"
	}
	var parts := []
	for key in loot.keys():
		parts.append(str(names.get(key, key)) + " +" + str(loot[key]))
	if parts.is_empty():
		return "没有可用物资"
	return ", ".join(parts)
