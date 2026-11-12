class_name ChargingService
extends RefCounted

static func carried_item(state: Dictionary, id: String) -> bool:
	if not state.items.has(id): return false
	var item: Dictionary = state.items[id]
	return item.container_id == "bag" or (item.container_id == "equipment" and id in state.player.equipment.values())

# Resolve only a unique installed tactical parent. Ordinary inventory permissions
# deliberately do not expose the plugin container as a movable source.
static func installed_charge_parent(state: Dictionary, id: String, definitions: Dictionary = {}) -> String:
	if not state.items.has(id) or state.items[id].container_id != "plugin": return ""
	if definitions.is_empty(): definitions = preload("res://scripts/content/catalog.gd").items()
	var definition: Dictionary = definitions.get(state.items[id].definition_id,{})
	if definition.get("tactical_type","") not in ["light","laser"]: return ""
	var references := 0
	var owner := ""
	for parent: Dictionary in state.items.values():
		for slot: String in parent.get("plugins",{}):
			if parent.plugins[slot] != id: continue
			references += 1
			if slot == "tactical" and carried_item(state,parent.id) and definitions.get(parent.definition_id,{}).get("category","") == "ranged": owner=parent.id
	return owner if references == 1 else ""

static func manual_target_allowed(state: Dictionary, id: String, parent_id := "", definitions: Dictionary = {}) -> bool:
	if not state.items.has(id): return false
	var item: Dictionary = state.items[id]
	if item.get("capacity",0) <= 0: return false
	if item.container_id == "plugin":
		return not parent_id.is_empty() and installed_charge_parent(state,id,definitions) == parent_id
	return parent_id.is_empty() and carried_item(state,id) and not item.get("is_battery",false)

static func manual_battery_allowed(state: Dictionary, id: String) -> bool:
	return state.items.has(id) and state.items[id].container_id == "bag" and state.items[id].get("is_battery",false)

static func charge_manual(state: Dictionary, target_id: String, requested: float, battery_id: String, parent_id := "", definitions: Dictionary = {}) -> float:
	if not manual_target_allowed(state,target_id,parent_id,definitions) or not manual_battery_allowed(state,battery_id): return 0.0
	# An exhausted but still carried chosen battery keeps the existing fallback:
	# remaining carried batteries are consumed least-energy-first.
	return charge_weapon(state,target_id,requested,battery_id)

static func wireless(state: Dictionary, delta: float, rate: float, in_range: bool, station_active: bool, paused: bool) -> float:
	if paused or not in_range or not station_active or delta <= 0 or rate <= 0 or not is_finite(delta) or not is_finite(rate): return 0.0
	var transferred := 0.0
	for id: String in wireless_targets(state):
		transferred += EnergyService.transfer(state.base.energy_store, state.items[id], rate * delta)
	return transferred

# IDs, not persistent dictionary references: inventory transactions replace nested state.
# Installed plugins live in container "plugin" and are owned by one parent's
# plugins[slot] reference. Only plugins of actually worn weapon slots are eligible.
static func wireless_targets(state: Dictionary) -> Array:
	var targets: Dictionary = {}
	for item: Dictionary in state.items.values():
		if item.container_id == "bag" and item.get("is_battery", false):
			targets[item.id] = true
	for slot: String in state.player.equipment:
		var id: String = state.player.equipment[slot]
		if not state.items.has(id) or state.items[id].container_id != "equipment": continue
		targets[id] = true
		if not slot.begins_with("weapon_"): continue
		for plugin_id: String in state.items[id].plugins.values():
			if not state.items.has(plugin_id) or state.items[plugin_id].container_id != "plugin": continue
			var owners: Dictionary = {}
			for parent: Dictionary in state.items.values():
				if plugin_id in parent.plugins.values(): owners[parent.id] = true
			if owners.size() == 1 and owners.has(id): targets[plugin_id] = true
	return targets.keys()

static func charge_weapon(state: Dictionary, weapon_id: String, requested: float, selected_battery: String = "") -> float:
	if not state.items.has(weapon_id) or requested <= 0 or not is_finite(requested): return 0.0
	var batteries: Array = state.items.values().filter(func(item: Dictionary) -> bool: return item.container_id == "bag" and item.get("is_battery", false) and item.energy > 0)
	batteries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.energy < b.energy)
	if not selected_battery.is_empty():
		for index in range(batteries.size()):
			if batteries[index].id == selected_battery:
				var selected: Dictionary = batteries.pop_at(index)
				batteries.push_front(selected)
				break
	var transferred := 0.0
	for battery: Dictionary in batteries:
		transferred += EnergyService.transfer(battery, state.items[weapon_id], requested - transferred)
	return transferred

static func drain_passives(state: Dictionary, delta: float, rate: float, paused: bool) -> float:
	if paused or delta <= 0 or rate <= 0 or not is_finite(delta) or not is_finite(rate): return 0.0
	var total := 0.0
	for slot: String in state.player.equipment:
		if not slot.begins_with("extra_"): continue
		var id: String = state.player.equipment[slot]
		if not state.items.has(id): continue
		var amount := minf(state.items[id].energy, delta * rate)
		state.items[id].energy -= amount
		total += amount
	return total
