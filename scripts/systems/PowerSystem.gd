extends Node


func get_power_report() -> Dictionary:
	var generation: int = int(round(GameState.city_grid_power / 10.0))
	var consumption: int = 0
	var storage: int = 0
	var fuel_use: int = 0
	var offline: Array = []
	for building in GameState.placed_buildings:
		if int(building.get("health", 0)) <= 0:
			continue
		var data: Dictionary = DataRegistry.get_defense_building(str(building.get("id", "")))
		generation += int(data.get("power_generation", 0))
		consumption += int(data.get("power_need", 0))
		storage += int(data.get("power_storage", 0))
		fuel_use += int(data.get("fuel_use", 0)) if int(data.get("power_generation", 0)) > 0 else 0
	var available: int = generation + storage
	var overload: int = max(0, consumption - available)
	if overload > 0:
		for building in GameState.placed_buildings:
			var offline_data: Dictionary = DataRegistry.get_defense_building(str(building.get("id", "")))
			if int(offline_data.get("power_need", 0)) > 0:
				offline.append(offline_data.get("name", building.get("id", "")))
	return {
		"generation": generation,
		"consumption": consumption,
		"storage": storage,
		"overload": overload,
		"fuel_use": fuel_use,
		"city_grid_power": GameState.city_grid_power,
		"offline": offline
	}


func is_power_available(power_need: int) -> bool:
	var report: Dictionary = get_power_report()
	return int(report.get("generation", 0)) + int(report.get("storage", 0)) >= int(report.get("consumption", 0)) + power_need


func building_is_powered(building_id: String) -> bool:
	var data: Dictionary = DataRegistry.get_defense_building(building_id)
	var need: int = int(data.get("power_need", 0))
	if need <= 0:
		return true
	return int(get_power_report().get("overload", 0)) <= 0
