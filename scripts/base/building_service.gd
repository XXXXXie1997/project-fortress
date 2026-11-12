class_name BuildingService
extends RefCounted

var inventory: InventoryService
var config: Dictionary
func _init(inv: InventoryService, catalog: Dictionary) -> void:
	inventory = inv
	config = catalog

func preparation(state: Dictionary) -> bool:
	return state.phase in ["morning", "dusk"] and not state.base.get("combat", false)

func active(state: Dictionary, id: String) -> bool:
	return state.base.get("buildings", {}).has(id) and state.base.buildings[id].durability > 0

func pay(state: Dictionary, costs: Dictionary, energy: float = 0, rewards: Dictionary = {}) -> bool:
	if not is_finite(energy) or state.base.energy_store.energy - energy < 0 or state.base.energy_store.energy - energy > state.base.energy_store.capacity: return false
	var trial := state.duplicate(true)
	if not inventory.exchange(trial, costs, rewards).ok: return false
	trial.base.energy_store.energy -= energy
	InventoryService.commit(state, trial)
	return true

func setup(state: Dictionary) -> bool:
	if state.base.has("buildings"): return false
	state.base.buildings = {}
	state.base.building_next_id = 1
	state.base.bounds = config.bounds.duplicate()
	state.base.resident_capacity = config.resident_capacity
	state.base.residents = []
	state.base.generation_ids = []
	state.base.expansion_level = 0
	for entry: Dictionary in config.initial: _add(state, entry.type, entry.cell, entry.type != "generator")
	state.base.energy_store.energy = minf(config.initial_energy, state.base.energy_store.capacity)
	return true

func _add(state: Dictionary, type: String, cell: Array, preset: bool) -> String:
	var id := "building_%d" % int(state.base.building_next_id)
	state.base.building_next_id += 1
	var d: Dictionary = config.types[type]
	state.base.buildings[id] = {"id": id, "type": type, "cell": cell.duplicate(), "level": 1, "durability": d.hp, "maximum": d.hp, "preset": preset, "paid": d.cost.duplicate(true)}
	return id

func valid_position(state: Dictionary, type: String, cell: Array, camera: Rect2i, except_id: String = "") -> bool:
	var size: Array = config.types[type].size
	var rect := Rect2i(cell[0], cell[1], size[0], size[1])
	var bounds: Array = state.base.bounds
	if not Rect2i(bounds[0], bounds[1], bounds[2], bounds[3]).encloses(rect) or not camera.encloses(rect): return false
	var footprint := Rect2(Vector2(rect.position) * 48, Vector2(rect.size) * 48)
	if footprint.intersects(preload("res://scripts/base/base_geometry.gd").entrance_reservation(bounds)): return false
	for zone: Array in config.forbidden:
		if rect.intersects(Rect2i(zone[0], zone[1], zone[2], zone[3])): return false
	for id: String in state.base.buildings:
		if id == except_id: continue
		var b: Dictionary = state.base.buildings[id]
		var other: Array = config.types[b.type].size
		if rect.intersects(Rect2i(b.cell[0], b.cell[1], other[0], other[1])): return false
	return true

func build(state: Dictionary, type: String, cell: Array, camera: Rect2i) -> String:
	if not preparation(state) or not config.types.has(type): return ""
	if config.types[type].get("unique", false):
		for b: Dictionary in state.base.buildings.values():
			if b.type == type: return ""
	if not valid_position(state, type, cell, camera) or not pay(state, config.types[type].cost): return ""
	return _add(state, type, cell, false)

func move(state: Dictionary, id: String, cell: Array, camera: Rect2i) -> bool:
	if not preparation(state) or not state.base.buildings.has(id): return false
	if not valid_position(state, state.base.buildings[id].type, cell, camera, id): return false
	state.base.buildings[id].cell = cell.duplicate()
	return true

func repair(state: Dictionary, id: String) -> bool:
	if not preparation(state) or not state.base.buildings.has(id): return false
	var b: Dictionary = state.base.buildings[id]
	if b.durability >= b.maximum: return false
	var costs := {}
	for key: String in b.paid: costs[key] = maxi(1, ceili(float(b.paid[key]) * (1.0 - float(b.durability) / b.maximum)))
	if not pay(state, costs): return false
	state.base.buildings[id].durability = b.maximum
	return true

func demolish(state: Dictionary, id: String) -> bool:
	if not preparation(state) or not state.base.buildings.has(id): return false
	var b: Dictionary = state.base.buildings[id]
	if b.preset or b.has("order") or not b.get("batches", []).is_empty(): return false
	var refund := {}
	for key: String in b.paid: refund[key] = floori(float(b.paid[key]) * b.durability / b.maximum)
	if not pay(state, {}, 0, refund): return false
	state.base.buildings.erase(id)
	return true

func settle(state: Dictionary, settlement_id: String) -> bool:
	if settlement_id.is_empty() or settlement_id in state.base.generation_ids: return false
	for b: Dictionary in state.base.buildings.values():
		if b.type == "generator" and b.durability > 0: state.base.energy_store.energy = minf(state.base.energy_store.capacity, state.base.energy_store.energy + config.generation * b.level)
	state.base.generation_ids.append(settlement_id)
	return true

func upgrade(state: Dictionary, id: String) -> bool:
	if not preparation(state) or not active(state, id): return false
	var b: Dictionary = state.base.buildings[id]
	var d: Dictionary = config.types[b.type]
	if b.level >= d.max_level: return false
	var trial := state.duplicate(true)
	if not pay(trial, d.cost): return false
	var target: Dictionary = trial.base.buildings[id]
	target.level += 1
	target.maximum += d.hp
	target.durability = target.maximum
	for key: String in d.cost: target.paid[key] = int(target.paid.get(key, 0)) + int(d.cost[key])
	if b.type == "warehouse":
		if not inventory.upgrade_station(trial, target.level, trial.containers.warehouse.width + 2, trial.containers.warehouse.height + 2, trial.base.energy_store.capacity + config.storage_increment): return false
	InventoryService.commit(state, trial)
	return true

func expand(state: Dictionary) -> bool:
	if not preparation(state) or state.base.expansion_level >= config.expansions.size(): return false
	var expansion: Dictionary = config.expansions[state.base.expansion_level]
	if not pay(state, expansion.cost): return false
	state.base.bounds = expansion.bounds.duplicate()
	state.base.resident_capacity += expansion.residents
	state.base.expansion_level += 1
	return true
