extends RefCounted


static func build_wave() -> Array:
	var zombies := DataRegistry.get_zombies()
	var entries := []
	var budget := 12 + GameState.day * 5 + int(GameState.base_noise / 2) + int(GameState.base_smell / 2) + int(GameState.base_light / 3)
	for zombie in zombies:
		var weight := int(zombie.get("spawn_weight", 10))
		var tech_bias := 0
		if GameState.day >= 2 and str(zombie.get("id", "")) in ["crusher", "fire_weak_infected", "armored"]:
			tech_bias = 8
		if GameState.base_footprint >= 12 and str(zombie.get("id", "")) in ["crawler", "runner"]:
			tech_bias += 5
		for _i in range(max(1, weight + tech_bias)):
			entries.append(zombie)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wave := []
	for _i in range(budget):
		wave.append(entries[rng.randi_range(0, entries.size() - 1)])
	return wave
