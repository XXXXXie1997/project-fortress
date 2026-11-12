class_name FarmingService
extends RefCounted
var buildings: BuildingService
var crops: Dictionary
func _init(service: BuildingService, catalog: Dictionary) -> void:
	buildings = service
	crops = catalog

func plant(state: Dictionary, id: String, crop: String) -> bool:
	if not buildings.preparation(state) or not buildings.active(state, id) or not crops.has(crop): return false
	var b: Dictionary = state.base.buildings[id]
	if b.type != "farm" or b.get("batches", []).size() >= buildings.config.types.farm.plots: return false
	if not buildings.pay(state, crops[crop].cost): return false
	if not state.base.buildings[id].has("batches"): state.base.buildings[id].batches = []
	state.base.buildings[id].batches.append({"crop": crop, "age": 0, "harvest": {}})
	return true

func settle(state: Dictionary, settlement_id: String, self_sufficient: bool = false) -> bool:
	if not state.base.has("farming_ids"): state.base.farming_ids = []
	if settlement_id.is_empty() or settlement_id in state.base.farming_ids: return false
	for id: String in state.base.buildings.keys():
		if not buildings.active(state, id): continue
		var batches: Array = state.base.buildings[id].get("batches", []).duplicate(true)
		
		for batch: Dictionary in batches:
			var crop: Dictionary = crops[batch.crop]
			batch.age = mini(int(crop.stages), int(batch.age) + 1)
			if batch.age < crop.stages:
				continue
			if batch.harvest.is_empty():
				batch.harvest = crop.output.duplicate(true)
				var rng := RandomNumberGenerator.new()
				rng.state = int(state.rng_state)
				var returned: bool = rng.randf() < crop.seed_chance
				state.rng_state = str(rng.state)
				if self_sufficient or returned:
					for seed_id: String in crop.cost:
						batch.harvest[seed_id] = int(batch.harvest.get(seed_id, 0)) + int(crop.cost[seed_id])
			
		state.base.buildings[id].batches = batches
	collect_ready(state)
	state.base.farming_ids.append(settlement_id)
	return true


# Safe to call after any inventory capacity change. No growth, RNG or energy tick.
func collect_ready(state: Dictionary) -> int:
	var collected := 0
	for id: String in state.base.buildings.keys():
		if not buildings.active(state, id): continue
		var remaining: Array = []
		for batch: Dictionary in state.base.buildings[id].get("batches", []).duplicate(true):
			if batch.harvest.is_empty() or not buildings.pay(state, {}, 0, batch.harvest):
				remaining.append(batch)
			else:
				collected += 1
		state.base.buildings[id].batches = remaining
	return collected
