class_name InventoryService
extends RefCounted

var definitions: Dictionary
func _init(catalog: Dictionary = {}) -> void:
	definitions = catalog

func setup(state: Dictionary) -> void:
	state.containers = {"bag": container(3, 2, 10.0), "warehouse": container(12, 8, -1.0), "ground": container(0, 0, -1.0)}
	state.player.equipment = {"weapon_1": "", "weapon_2": "", "weapon_3": "", "armor": "", "backpack": "", "extra_1": "", "extra_2": "", "extra_3": "", "extra_4": ""}
	state.player.quick = ["", "", "", "", "", ""]
	state.base.energy_store = {"energy": 0.0, "capacity": 1000.0}

static func container(width: int, height: int, maximum_weight: float) -> Dictionary:
	return {"width": width, "height": height, "maximum_weight": maximum_weight}

func items_in(state: Dictionary, location: String) -> Array:
	return state.items.values().filter(func(i: Dictionary) -> bool: return i.container_id == location)

func weight(state: Dictionary, location: String) -> float:
	var total := 0.0
	for item: Dictionary in items_in(state, location):
		total += float(definitions[item.definition_id].get("weight", 0)) * item.quantity
	return total

func dimensions(item: Dictionary) -> Vector2i:
	var size: Array = definitions[item.definition_id].get("size", [1, 1])
	return Vector2i(size[1], size[0]) if item.rotated else Vector2i(size[0], size[1])

func fits(state: Dictionary, item: Dictionary, location: String, cell: Vector2i) -> bool:
	if not state.containers.has(location): return false
	var c: Dictionary = state.containers[location]
	if c.width == 0 and c.height == 0: return true
	var rect := Rect2i(cell, dimensions(item))
	if not Rect2i(0, 0, c.width, c.height).encloses(rect): return false
	for other: Dictionary in items_in(state, location):
		if other.id != item.id and rect.intersects(Rect2i(Vector2i(other.cell[0], other.cell[1]), dimensions(other))): return false
	return true

func place(state: Dictionary, item: Dictionary, location: String) -> bool:
	var c: Dictionary = state.containers[location]
	if c.maximum_weight >= 0 and weight(state, location) + (0.0 if item.container_id == location else definitions[item.definition_id].get("weight", 0.0) * item.quantity) > c.maximum_weight: return false
	for rotated in [false, true]:
		item.rotated = rotated
		for y in range(maxi(1, c.height)):
			for x in range(maxi(1, c.width)):
				if fits(state, item, location, Vector2i(x, y)):
					item.container_id = location
					item.cell = [x, y]
					return true
	return false

func spawn(state: Dictionary, definition_id: String, location: String, quantity: int = 1) -> Dictionary:
	if not definitions.has(definition_id) or not state.containers.has(location) or quantity < 1: return {}
	var d: Dictionary = definitions[definition_id]
	if d.get("unique", false) and quantity != 1: return {}
	if d.get("unique", false) and state.unique_items.has(definition_id): return {}
	var trial := state.duplicate(true)
	var item := WorldState.create_item(trial, definition_id, "pending")
	item.quantity = quantity
	item.capacity = float(d.get("capacity", 0))
	item.durability = float(d.get("durability", 0))
	item.is_battery = d.get("category") == "battery"
	if not move(trial, item.id, location).ok: return {}
	if d.get("unique", false): trial.unique_items[definition_id] = item.id
	commit(state, trial)
	return state.items.get(item.id, {"id": item.id, "merged": true})

static func commit(state: Dictionary, trial: Dictionary) -> void:
	state.clear()
	state.merge(trial, true)

func move(state: Dictionary, id: String, location: String) -> Dictionary:
	if not state.items.has(id) or not state.containers.has(location): return {"ok": false}
	var trial := state.duplicate(true)
	var item: Dictionary = trial.items[id]
	var old: String = item.container_id
	if old == location: return {"ok": true}
	var d: Dictionary = definitions[item.definition_id]
	# Stateful items are never stacked. Merge only plain resources/consumables.
	var stackable: bool = d.get("category", "") in ["material", "consumable"]
	var limit: int = int(d.get("warehouse_stack" if location == "warehouse" else "backpack_stack", 1))
	if not stackable:
		limit = 1
		if item.quantity>1 and (d.get("unique",false) or not item.plugins.is_empty() or float(item.energy)!=0.0):return {"ok":false,"reason":"ambiguous_stateful_batch"}
	var c: Dictionary = trial.containers[location]
	if c.maximum_weight >= 0 and weight(trial, location) + d.get("weight", 0.0) * item.quantity > c.maximum_weight: return {"ok": false}
	if stackable and not d.get("suppress_stack_merge",false):
		for target: Dictionary in items_in(trial, location):
			if target.definition_id == item.definition_id and target.quality == item.quality:
				var moved := mini(item.quantity, limit - int(target.quantity))
				target.quantity += moved
				item.quantity -= moved
				if item.quantity == 0: break
	while item.quantity > limit:
		var split := WorldState.create_item(trial, item.definition_id, "pending")
		split.quantity = limit
		split.quality = item.quality
		if not stackable:
			split.capacity=float(d.get("capacity",0))
			split.is_battery=d.get("category", "")=="battery"
			# Existing wear is preserved; only spawn supplies new-item durability.
			split.durability=item.durability
		item.quantity -= limit
		if not place(trial, split, location): return {"ok": false}
	if item.quantity > 0 and not place(trial, item, location): return {"ok": false}
	if d.get("category") == "battery":
		if location == "warehouse":
			if item.energy > trial.base.energy_store.capacity - trial.base.energy_store.energy: return {"ok": false, "reason": "energy_capacity"}
			EnergyService.transfer(item, trial.base.energy_store, item.energy)
		elif old == "warehouse" and location == "bag": EnergyService.transfer(trial.base.energy_store, item, item.capacity)
	for slot: String in trial.player.equipment:
		if trial.player.equipment[slot] == id: trial.player.equipment[slot] = ""
	if item.quantity == 0: trial.items.erase(id)
	commit(state, trial)
	return {"ok": true}

# Safe on migration trials only; reject invalid energy rather than truncate it.
func repair_battery_metadata(state: Dictionary) -> bool:
	for item:Dictionary in state.get("items",{}).values():
		var definition:Dictionary=definitions.get(item.get("definition_id",""),{})
		if definition.get("category","")!="battery":continue
		var capacity:=float(definition.get("capacity",0))
		var energy:=float(item.get("energy",0))
		if not is_finite(energy) or energy<0 or not is_finite(capacity) or capacity<0 or energy>capacity:return false
	for item:Dictionary in state.get("items",{}).values():
		var definition:Dictionary=definitions.get(item.get("definition_id",""),{})
		if definition.get("category","")=="battery":
			item.capacity=float(definition.get("capacity",0));item.is_battery=true
	return true

func destroy(state: Dictionary, id: String) -> bool:
	if not state.items.has(id): return false
	var item: Dictionary = state.items[id]
	if not item.plugins.is_empty(): return false
	if state.unique_items.get(item.definition_id) == id: state.unique_items.erase(item.definition_id)
	for slot: String in state.player.equipment:
		if state.player.equipment[slot] == id: state.player.equipment[slot] = ""
	state.items.erase(id)
	return true

func count(state: Dictionary, definition_id: String, location: String = "bag") -> int:
	var total := 0
	for item: Dictionary in items_in(state, location):
		if item.definition_id == definition_id: total += int(item.quantity)
	return total

func consume(state: Dictionary, definition_id: String, amount: int, location: String = "bag") -> bool:
	if amount < 1 or count(state, definition_id, location) < amount: return false
	for item: Dictionary in items_in(state, location):
		if item.definition_id != definition_id: continue
		var taken := mini(amount, item.quantity)
		item.quantity -= taken
		amount -= taken
		if item.quantity == 0: destroy(state, item.id)
		if amount == 0: break
	return true

func equip(state: Dictionary, id: String, slot: String, confirm_overflow: bool = false, at_base: bool = true) -> Dictionary:
	if not state.items.has(id) or not state.player.equipment.has(slot): return {"ok": false}
	var category: String = definitions[state.items[id].definition_id].category
	var allowed: bool = (slot.begins_with("weapon_") and category in ["ranged", "melee"]) or (slot.begins_with("extra_") and category == "extra") or slot == category
	if not allowed: return {"ok": false}
	var trial := state.duplicate(true)
	var previous: String = trial.player.equipment[slot]
	for other_slot: String in trial.player.equipment:
		if trial.player.equipment[other_slot] == id: trial.player.equipment[other_slot] = ""
	trial.items[id].container_id = "equipment"
	trial.player.equipment[slot] = id
	if not previous.is_empty() and previous != id:
		if not place(trial, trial.items[previous], "bag"):
			if slot != "backpack": return {"ok": false, "reason": "unequip_capacity"}
			trial.items[previous].container_id = "overflow"
	var overflow: Array = []
	if slot == "backpack":
		var d: Dictionary = definitions[trial.items[id].definition_id]
		var resized := resize_bag(trial, int(d.get("bag_width", 6)), int(d.get("bag_height", 4)), float(d.get("bag_weight", 30)), true, at_base)
		overflow = resized.overflow
		if not previous.is_empty() and previous != id and trial.items[previous].container_id == "overflow":
			overflow.append(previous)
			if not at_base or not move(trial, previous, "warehouse").ok: move(trial, previous, "ground")
	if not overflow.is_empty() and not confirm_overflow: return {"ok": false, "confirmation_required": true, "overflow": overflow}
	commit(state, trial)
	return {"ok": true, "overflow": overflow}

func resize_bag(state: Dictionary, width: int, height: int, maximum_weight: float, confirmed: bool, at_base: bool) -> Dictionary:
	if width < 1 or height < 1 or maximum_weight < 0: return {"ok": false, "overflow": []}
	var trial := state.duplicate(true)
	trial.containers.bag = container(width, height, maximum_weight)
	var overflow: Array = []
	for item: Dictionary in items_in(trial, "bag"):
		if not fits(trial, item, "bag", Vector2i(item.cell[0], item.cell[1])) or weight(trial, "bag") > maximum_weight:
			item.container_id = "overflow"
			overflow.append(item.id)
	if not confirmed and not overflow.is_empty(): return {"ok": false, "confirmation_required": true, "overflow": overflow}
	for id: String in overflow:
		if at_base and move(trial, id, "warehouse").ok: continue
		move(trial, id, "ground")
	commit(state, trial)
	return {"ok": true, "overflow": overflow}

func quick_count(state: Dictionary, slot: int) -> int:
	if slot < 0 or slot >= 6: return 0
	return count(state, state.player.quick[slot])

func select_items(state: Dictionary, tab: String) -> Array:
	return items_in(state, {"equipment": "equipment", "bag": "bag", "warehouse": "warehouse"}.get(tab, "invalid"))

# Atomic dry-run for deliveries; unlike trade this never silently drops rewards.
func exchange(state: Dictionary, costs: Dictionary, rewards: Dictionary, commit_result: bool = true) -> Dictionary:
	var trial := state.duplicate(true)
	for definition_id: String in costs:
		if not consume(trial, definition_id, int(costs[definition_id]), "warehouse"): return {"ok": false, "reason": "cost"}
	for definition_id: String in rewards:
		var remaining: int = int(rewards[definition_id])
		if remaining < 0 or not definitions.has(definition_id): return {"ok": false}
		while remaining > 0:
			var amount := mini(remaining, int(definitions[definition_id].get("warehouse_stack", 1)))
			if spawn(trial, definition_id, "warehouse", amount).is_empty(): return {"ok": false, "reason": "reward_capacity"}
			remaining -= amount
	if commit_result: commit(state, trial)
	return {"ok": true}

func deliver(state: Dictionary, id: String, preferred: String) -> Dictionary:
	var alternate := "bag" if preferred == "warehouse" else "warehouse"
	for location: String in [preferred, alternate, "ground"]:
		if move(state, id, location).ok: return {"ok": true, "destination": location, "fallback": location != preferred}
	return {"ok": false}

func unequip(state: Dictionary, slot: String, confirmed: bool = false, at_base: bool = true) -> Dictionary:
	if not state.player.equipment.has(slot) or state.player.equipment[slot] == "": return {"ok": false}
	var trial := state.duplicate(true)
	var id: String = trial.player.equipment[slot]
	if not move(trial, id, "bag").ok:
		if slot != "backpack": return {"ok": false, "reason": "capacity"}
		trial.items[id].container_id = "overflow"
		trial.player.equipment[slot] = ""
	if slot == "backpack":
		var result := resize_bag(trial, 3, 2, 10.0, confirmed, at_base)
		if not result.ok: return result
		if trial.items[id].container_id == "overflow":
			if not confirmed: return {"ok": false, "confirmation_required": true, "overflow": [id]}
			if not at_base or not move(trial, id, "warehouse").ok: move(trial, id, "ground")
	commit(state, trial)
	return {"ok": true}

func upgrade(state: Dictionary, id: String, target_definition: String, confirmed: bool = false, at_base: bool = true) -> Dictionary:
	if not state.items.has(id) or not definitions.has(target_definition): return {"ok": false}
	var d: Dictionary = definitions[target_definition]
	if d.category == "extra" or definitions[state.items[id].definition_id].category != d.category: return {"ok": false}
	var trial := state.duplicate(true)
	var item: Dictionary = trial.items[id]
	if item.energy > float(d.get("capacity", 0)): return {"ok": false, "reason": "energy_capacity"}
	item.definition_id = target_definition
	item.capacity = float(d.get("capacity", 0))
	item.durability = float(d.get("durability", 0))
	item.quality = int(d.get("quality", item.quality + 1))
	if trial.player.equipment.backpack == id:
		var result := resize_bag(trial, int(d.get("bag_width", 3)), int(d.get("bag_height", 2)), float(d.get("bag_weight", 10)), confirmed, at_base)
		if not result.ok: return result
	elif item.container_id != "equipment" and not place(trial, item, item.container_id): return {"ok": false, "reason": "capacity"}
	commit(state, trial)
	return {"ok": true}

func relocate(state: Dictionary, id: String, cell: Vector2i, rotated: bool) -> bool:
	if not state.items.has(id) or state.items[id].container_id == "equipment": return false
	var trial := state.duplicate(true)
	var item: Dictionary = trial.items[id]
	item.rotated = rotated
	if not fits(trial, item, item.container_id, cell): return false
	item.cell = [cell.x, cell.y]
	commit(state, trial)
	return true

func sort_container(state: Dictionary, location: String) -> bool:
	if not state.containers.has(location): return false
	var trial := state.duplicate(true)
	var entries := items_in(trial, location)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return dimensions(a).x * dimensions(a).y > dimensions(b).x * dimensions(b).y)
	for item: Dictionary in entries: item.container_id = "sorting"
	for item: Dictionary in entries:
		if not place(trial, item, location): return false
	commit(state, trial)
	return true

func upgrade_station(state: Dictionary, level: int, width: int, height: int, capacity: float) -> bool:
	if level <= int(state.base.get("station_level", 1)) or width < state.containers.warehouse.width or height < state.containers.warehouse.height or capacity < state.base.energy_store.capacity or not is_finite(capacity): return false
	state.base.station_level = level
	state.containers.warehouse.width = width
	state.containers.warehouse.height = height
	state.base.energy_store.capacity = capacity
	return true

