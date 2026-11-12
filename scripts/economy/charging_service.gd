class_name ChargingService
extends RefCounted

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
