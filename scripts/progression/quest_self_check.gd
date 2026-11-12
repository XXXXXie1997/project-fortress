extends SceneTree
func _init() -> void:
	var state := WorldState.fresh()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	var inventory := InventoryService.new(catalog)
	inventory.setup(state)
	state.base.energy_store.energy = 100
	inventory.spawn(state, "scrap", "warehouse", 20)
	var tech := TechnologyService.new(inventory)
	assert(not tech.unlock(state, "agriculture", true).ok)
	assert(tech.unlock(state, "storage", true).ok)
	assert(inventory.count(state, "scrap", "warehouse") == 18)
	assert(state.base.energy_store.energy == 80)
	var quests := QuestService.new(inventory)
	quests.record(state, "reach", "map_1_relay", "before")
	assert(quests.accept(state, "main_1", true).ok)
	assert(not quests.deliver(state, "main_1", true).ok)
	quests.record(state, "reach", "map_1_relay", "visit")
	var before := JSON.stringify(state)
	state.base.energy_store.capacity = 80
	var full := JSON.stringify(state)
	assert(not quests.deliver(state, "main_1", true).ok)
	assert(JSON.stringify(state) == full)
	state.base.energy_store.capacity = 1000
	assert(quests.deliver(state, "main_1", true).ok)
	assert(state.player.growth.xp == 100)
	assert(state.quests.pending_stages[0].effective_day == 2)
	assert(not quests.deliver(state, "main_1", true).ok)
	assert(quests.accept(state, "main_2", true).ok)
	quests.record(state, "reach", "map_2_transmitter", "visit2")
	assert(quests.deliver(state, "main_2", true).ok)
	assert(state.quests.ending == "contact_restored")
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	quests.refresh(state, rng)
	for id in state.quests.offers.keys(): assert(quests.accept(state, id, true).ok)
	assert(state.quests.active.size() == 5)
	state.day = 3
	quests.expire(state)
	assert(state.quests.active.is_empty())
	quests.new_survivor(state)
	assert(state.base.technology.has("storage"))
	print("DEV-312 SELF CHECK PASS")
	quit()
