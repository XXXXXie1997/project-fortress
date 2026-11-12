extends SceneTree
func _init() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var trade: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))
	defs.merge(crops.item_definitions)
	defs.merge(trade.item_definitions)
	var inv := InventoryService.new(defs)
	var s := WorldState.fresh()
	inv.setup(s)
	var b := BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
	b.setup(s)
	var deps := {"inventory":inv,"building":b,"production":ProductionService.new(b,{}),"farming":FarmingService.new(b,crops.crops),"quests":QuestService.new(inv),"trade":TradeService.new(inv,trade),"exploration":ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps)}
	var cycle = load("res://scripts/base/day_cycle.gd").new(deps)
	for n in range(20): inv.spawn(s,"scrap","warehouse")
	for id in s.base.buildings:
		if s.base.buildings[id].type == "trade":
			assert(b.upgrade(s,id))
			assert(b.upgrade(s,id))
			print("QA trade actual level ",s.base.buildings[id].level)
	assert(cycle.to_dusk(s))
	assert(cycle.begin_night(s,"manual").ok)
	assert(cycle.finish_night(s,{"enemy_power":0},true).ok)
	var found = false
	for item in inv.items_in(s,"shop"):
		print("QA SHOP ",item.definition_id)
		if item.definition_id == "trade_blade": found = true
	print("QA trade level integration ","PASS" if found else "FAIL")
	quit(0 if found else 1)
