class_name WorkstationService
extends RefCounted
var production: ProductionService
var config: Dictionary
func _init(service: ProductionService, catalog: Dictionary) -> void:
	production = service
	config = catalog
	production.recipes.merge(config.recipes)
func allowed(s: Dictionary, station: String) -> bool:
	return production.buildings.preparation(s) and production.buildings.active(s,station) and s.base.buildings[station].type == "workstation"
func owned(s: Dictionary, id: String) -> bool:
	if not s.items.has(id): return false
	var item: Dictionary = s.items[id]
	if item.container_id in ["bag","warehouse","equipment"]: return true
	if item.container_id != "plugin": return false
	var parents: Array = []
	for parent: Dictionary in s.items.values():
		for slot in parent.plugins:
			if parent.plugins[slot] == id: parents.append(parent)
	if parents.size() != 1: return false
	var parent: Dictionary = parents[0]
	if parent.container_id not in ["bag","warehouse","equipment"]: return false
	if parent.container_id == "equipment" and parent.id not in s.player.equipment.values(): return false
	var definitions: Dictionary = production.buildings.inventory.definitions
	if definitions[parent.definition_id].category != "ranged": return false
	return parent.plugins.get(definitions[item.definition_id].get("slot", ""), "") == id
func craft(s: Dictionary, station: String, recipe: String, quantity: int) -> bool:
	if not allowed(s,station) or not config.recipes.has(recipe): return false
	for tech in config.recipes[recipe].get("requires",[]):
		if not s.base.get("technology",{}).has(tech): return false
	return production.order(s,station,recipe,quantity)
func modify(s: Dictionary, station: String, id: String, action: String, target: String = "", confirmed: bool = false) -> bool:
	if not allowed(s,station) or not owned(s,id): return false
	if s.items[id].container_id == "plugin" and action != "upgrade": return false
	var inv := production.buildings.inventory
	var trial := s.duplicate(true)
	var item: Dictionary = trial.items[id]
	var d: Dictionary = inv.definitions[item.definition_id]
	if action == "install":
		if not owned(trial,target) or target == id: return false
		var plugin: Dictionary = inv.definitions[trial.items[target].definition_id]
		var slot: String = plugin.get("slot","")
		if d.category != "ranged" or slot.is_empty() or item.plugins.has(slot): return false
		for parent: Dictionary in trial.items.values():
			if target in parent.plugins.values(): return false
		trial.items[target].container_id = "plugin"
		for key: String in trial.player.equipment:
			if trial.player.equipment[key] == target: trial.player.equipment[key] = ""
		item.plugins[slot] = target
	elif action == "uninstall":
		if not item.plugins.has(target): return false
		var plugin_id: String = item.plugins[target]
		item.plugins.erase(target)
		if not inv.move(trial,plugin_id,"warehouse").ok: return false
	elif action == "upgrade":
		if d.category == "extra" or not config.tiers.has(target) or not config.tiers.has(item.definition_id): return false
		var old: Dictionary = config.tiers[item.definition_id]
		var next: Dictionary = config.tiers[target]
		if next.family != old.family or int(next.level) != int(old.level)+1: return false
		if d.category == "plugin" and inv.definitions[target].get("slot", "") != d.get("slot", ""): return false
		for tech in next.get("requires",[]):
			if not trial.base.get("technology",{}).has(tech): return false
		var costs := {}
		for key: String in next.materials:
			var difference := int(next.materials[key])-int(old.materials.get(key,0))
			if difference > 0: costs[key] = difference
		if not production.buildings.pay(trial,costs,float(next.energy)-float(old.energy)): return false
		if item.container_id == "plugin" and not trial.containers.has("plugin"):
			trial.containers.plugin = InventoryService.container(0,0,-1)
		if not inv.upgrade(trial,id,target).ok: return false
	elif action == "repair":
		var maximum: float = d.get("durability",0)
		if maximum <= 0 or item.durability >= maximum: return false
		var cost := maxi(1,ceili(config.repair_scrap * (1.0-item.durability/maximum)))
		if not production.buildings.pay(trial,{"scrap":cost}): return false
		trial.items[id].durability = maximum
	elif action == "dismantle":
		if not item.plugins.is_empty(): return false
		var removed_backpack: bool = trial.player.equipment.backpack == id
		if not inv.destroy(trial,id): return false
		if removed_backpack and not inv.resize_bag(trial,3,2,10.0,confirmed,true).ok: return false
		if not inv.exchange(trial,{},{"scrap":int(config.dismantle_scrap)}).ok: return false
	else: return false
	inv.commit(s,trial)
	return true

