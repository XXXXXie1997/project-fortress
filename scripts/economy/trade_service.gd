class_name TradeService
extends RefCounted
var inventory: InventoryService
var config: Dictionary
func _init(inv: InventoryService, catalog: Dictionary) -> void:
	inventory = inv
	config = catalog
func price(s: Dictionary, id: String, selling: bool = false) -> int:
	var item: Dictionary = s.items[id]
	var d: Dictionary = inventory.definitions[item.definition_id]
	var condition := 1.0
	if float(d.get("durability",0)) > 0: condition = 0.25 + 0.75 * item.durability / float(d.durability)
	var value: float = d.get("price",20) * maxf(1,item.quality) * condition * int(item.quantity)
	for child: String in item.plugins.values(): value += price(s,child)
	return maxi(1,floori(value * (float(config.sell_ratio) if selling else 1.0)))
func refresh(s: Dictionary, level: int) -> bool:
	if int(s.trade.get("day",-1)) == int(s.day): return false
	var trial := s.duplicate(true)
	for item: Dictionary in inventory.items_in(trial,"shop")+inventory.items_in(trial,"buyback"):
		for child: String in item.plugins.values(): inventory.destroy(trial,child)
		item.plugins.clear()
		inventory.destroy(trial,item.id)
	trial.containers.shop = InventoryService.container(0,0,-1)
	trial.containers.buyback = InventoryService.container(0,0,-1)
	trial.trade = {"day":trial.day,"buyback_prices":{}}
	var rng := RandomNumberGenerator.new()
	rng.state = int(trial.rng_state)
	for entry: Dictionary in config.stock:
		if level < int(entry.level): continue
		var count: int = rng.randi_range(int(entry.minimum),int(entry.maximum))
		for n in range(count):
			var spawned := inventory.spawn(trial,entry.item,"shop")
			if not spawned.is_empty() and entry.has("plugin") and rng.randf() < float(entry.get("plugin_chance",0.5)):
				trial.containers.plugin = InventoryService.container(0,0,-1)
				var plugin := inventory.spawn(trial,entry.plugin,"plugin")
				if not plugin.is_empty(): trial.items[spawned.id].plugins[inventory.definitions[entry.plugin].slot] = plugin.id
	trial.rng_state = str(rng.state)
	inventory.commit(s,trial)
	return true
func transact(s: Dictionary, sell: Array, buy: Array, preferred: String, confirmed: bool = false, at_base: bool = true) -> Dictionary:
	if not at_base or not preferred in ["bag","warehouse"] or s.phase == "night" or s.base.get("combat",false): return {"ok":false}
	var station_active := false
	for building: Dictionary in s.base.get("buildings",{}).values():
		if building.type == "trade" and building.durability > 0: station_active = true
	if not station_active: return {"ok":false}
	var seen := {}
	var income := 0
	var expense := 0
	for id in sell:
		if seen.has(id) or not s.items.has(id) or not s.items[id].container_id in ["bag","warehouse","equipment"]: return {"ok":false}
		seen[id] = true
		income += price(s,id,true)
	for id in buy:
		if seen.has(id) or not s.items.has(id) or not s.items[id].container_id in ["shop","buyback"]: return {"ok":false}
		seen[id] = true
		expense += int(s.trade.buyback_prices[id]) if s.items[id].container_id == "buyback" else price(s,id)
	var balance: float = s.base.energy_store.energy + income - expense
	if balance < 0: return {"ok":false}
	var lost := maxf(0,balance-s.base.energy_store.capacity)
	if lost > 0 and not confirmed: return {"ok":false,"confirmation_required":true,"lost_energy":lost,"actual_net":income-expense-lost}
	var trial := s.duplicate(true)
	var destinations := {}
	var overflow: Array = []
	var removes_backpack: bool = trial.player.equipment.backpack in sell
	# Net settlement precedes physical moves; battery moves use the same real pool.
	trial.base.energy_store.energy = minf(balance,trial.base.energy_store.capacity)
	for id: String in sell:
		var original_price := price(trial,id,true)
		if not inventory.move(trial,id,"buyback").ok: return {"ok":false}
		trial.trade.buyback_prices[id] = original_price
	if removes_backpack:
		var resized := inventory.resize_bag(trial,3,2,10.0,confirmed,true)
		if not resized.ok: return resized
		overflow = resized.overflow
	for id: String in buy:
		var result := inventory.deliver(trial,id,preferred)
		if not result.ok: return {"ok":false}
		destinations[id] = result
		trial.trade.buyback_prices.erase(id)
	var storage_delta: float = trial.base.energy_store.energy - s.base.energy_store.energy
	inventory.commit(s,trial)
	return {"ok":true,"lost_energy":lost,"actual_net":income-expense-lost,"destinations":destinations,"overflow":overflow,"storage_delta":storage_delta}




