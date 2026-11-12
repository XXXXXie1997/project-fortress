class_name ProductionService
extends RefCounted
var buildings: BuildingService
var recipes: Dictionary
func _init(service: BuildingService, catalog: Dictionary) -> void:
	buildings = service
	recipes = catalog

func order(state: Dictionary, id: String, recipe: String, quantity: int) -> bool:
	if quantity < 1 or not recipes.has(recipe) or not buildings.preparation(state) or not buildings.active(state, id): return false
	var r: Dictionary = recipes[recipe]
	var b: Dictionary = state.base.buildings[id]
	if b.has("order") or b.type != r.facility: return false
	var costs := {}
	for key: String in r.cost: costs[key] = int(r.cost[key]) * quantity
	if not buildings.pay(state, costs, r.energy * quantity): return false
	state.base.buildings[id].order = {"recipe": recipe, "remaining": quantity, "produced": 0}
	return true

func cancel(state: Dictionary, id: String) -> bool:
	if not buildings.preparation(state) or not state.base.buildings.has(id) or not state.base.buildings[id].has("order"): return false
	var o: Dictionary = state.base.buildings[id].order
	var r: Dictionary = recipes[o.recipe]
	var refund := {}
	for key: String in r.cost: refund[key] = int(r.cost[key]) * int(o.remaining)
	if not buildings.pay(state, {}, -r.energy * o.remaining, refund): return false
	state.base.buildings[id].erase("order")
	return true

func settle(state: Dictionary, settlement_id: String) -> bool:
	if not state.base.has("production_ids"): state.base.production_ids = []
	if settlement_id.is_empty() or settlement_id in state.base.production_ids: return false
	for id: String in state.base.buildings.keys():
		if not buildings.active(state, id) or not state.base.buildings[id].has("order"): continue
		var recipe: Dictionary = recipes[state.base.buildings[id].order.recipe]
		for unit in range(int(recipe.capacity)):
			if not state.base.buildings[id].has("order"): break
			if not buildings.pay(state, {}, 0, recipe.output): break
			var o: Dictionary = state.base.buildings[id].order
			o.remaining -= 1
			o.produced += 1
			if o.remaining == 0: state.base.buildings[id].erase("order")
	state.base.production_ids.append(settlement_id)
	return true
