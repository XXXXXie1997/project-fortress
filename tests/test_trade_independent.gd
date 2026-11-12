extends SceneTree
func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	var wc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment_recipes.json"))
	var tc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))
	defs.merge(wc.item_definitions)
	defs.merge(tc.item_definitions)
	var inv := InventoryService.new(defs)
	var s := WorldState.fresh()
	inv.setup(s)
	var b := BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
	b.setup(s)
	var w := WorkstationService.new(ProductionService.new(b,{}),wc)
	var t := TradeService.new(inv,tc)
	t.refresh(s,3)
	var bag: String = inv.spawn(s,"backpack_small","warehouse").id
	assert(inv.equip(s,bag,"backpack").ok)
	print("SELL_BAG before=",s.containers.bag," result=",t.transact(s,[bag],[],"warehouse")," after=",s.containers.bag," slot=",s.player.equipment.backpack)
	var bag2: String = inv.spawn(s,"backpack_small","warehouse").id
	assert(inv.equip(s,bag2,"backpack").ok)
	print("DISMANTLE_BAG result=",w.modify(s,"building_4",bag2,"dismantle")," after=",s.containers.bag," slot=",s.player.equipment.backpack)
	var battery: String = inv.spawn(s,"battery_basic","warehouse").id
	s.base.energy_store.energy = 500.0
	print("BATTERY before=",s.items[battery].energy," store=",s.base.energy_store.energy," price=",t.price(s,battery,true))
	print("BATTERY_SELL result=",t.transact(s,[battery],[],"warehouse")," battery=",s.items[battery].energy," store=",s.base.energy_store.energy)
	print("BATTERY_BUYBACK result=",t.transact(s,[],[battery],"warehouse")," battery=",s.items[battery].energy," store=",s.base.energy_store.energy)
	quit()
