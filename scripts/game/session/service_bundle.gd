extends RefCounted
# Construction is deliberately separate from new-world initialization.
const Catalog = preload("res://scripts/content/catalog.gd")

static func create() -> Dictionary:
	var inventory := InventoryService.new(Catalog.items())
	var building := BuildingService.new(inventory, Catalog.read("data/buildings.json"))
	var production := ProductionService.new(building, Catalog.recipes())
	var exploration := ExplorationService.new(inventory, projected_maps())
	var quests := QuestService.new(inventory)
	var services := {"inventory": inventory, "building": building, "production": production,
		"farming": FarmingService.new(building, Catalog.read("data/crops.json").crops),
		"workstation": WorkstationService.new(production, Catalog.equipment()),
		"trade": TradeService.new(inventory, Catalog.read("data/trade.json")),
		"exploration": exploration, "quests": quests, "technology": TechnologyService.new(inventory),
		"effects": ProgressionEffectBridge.new(), "growth": PlayerGrowth.new()}
	services.cycle = DayCycle.new(services.duplicate())
	services.restart = RunRestart.new(inventory, building, exploration, quests)
	services.recruitment = preload("res://scripts/game/session/recruitment.gd").new()
	return services

static func projected_maps() -> Dictionary:
	var maps := Catalog.maps()
	var projection := GridProjection.new()
	for map: Dictionary in maps.values():
		for key in ["enemies", "night_enemies", "containers", "objectives", "events"]:
			for entry: Dictionary in map.get(key, []): entry.position = projection.project_array(entry.position)
		for point: Dictionary in map.points.values(): point.position = projection.project_array(point.position)
	return maps

static func fresh(services: Dictionary, seed_value: int) -> Dictionary:
	var state := WorldState.fresh()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	state.rng_state = str(rng.state)
	services.inventory.setup(state)
	if not services.building.setup(state): return {"ok": false, "reason": "base_setup"}
	var session_config: Dictionary = Catalog.read("scripts/game/session/session_config.json")
	state.base.shield = {"energy": session_config.shield_initial_energy, "capacity": session_config.shield_capacity}
	state.player = services.restart.player_fresh()
	state.run_number = 1
	services.restart.reset_cycle(state)
	services.exploration.setup(state)
	var loadout: Dictionary = Catalog.starting_loadout()
	# Equip the capacity provider first; all placements use real inventory transactions.
	var slots: Array = ["backpack"]
	for slot: String in loadout.equipment:
		if slot != "backpack": slots.append(slot)
	for slot: String in slots:
		var item: Dictionary = services.inventory.spawn(state, loadout.equipment[slot], "ground")
		if item.is_empty() or not services.inventory.equip(state, item.id, slot).ok:
			return {"ok": false, "reason": "starting_equipment", "slot": slot}
	for entry: Dictionary in loadout.supplies:
		for index in int(entry.quantity):
			var item: Dictionary = services.inventory.spawn(state, entry.definition_id, "bag")
			if item.is_empty(): return {"ok": false, "reason": "starting_capacity"}
			if float(entry.energy_each) > 0:
				if not state.items.has(item.id): return {"ok": false, "reason": "energy_item_merged"}
				state.items[item.id].energy = minf(float(entry.energy_each), float(state.items[item.id].capacity))
	state.player.quick = loadout.quick.duplicate()
	services.restart.refresh_quests(state)
	services.trade.refresh(state, 1)
	services.cycle.setup(state)
	services.recruitment.refresh(state)
	state.session = {"location": "base", "coordinate_version": "diamond_world_v1", "revision": 0}
	state.content_version = 1
	return {"ok": true, "state": state}
