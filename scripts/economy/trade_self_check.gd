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
	var p := ProductionService.new(b,{})
	var w := WorkstationService.new(p,wc)
	inv.spawn(s,"scrap","warehouse",100)
	var gun: String = inv.spawn(s,"rifle_basic","warehouse").id
	var scope: String = inv.spawn(s,"scope_basic","warehouse").id
	assert(w.modify(s,"building_4",gun,"install",scope))
	s.items[gun].energy = 25
	s.base.technology = {"storage":true}
	assert(w.modify(s,"building_4",gun,"upgrade","rifle_advanced"))
	assert(s.items[gun].energy == 25 and s.items[gun].plugins.scope == scope)
	var trade := TradeService.new(inv,tc)
	assert(trade.refresh(s,3))
	assert(not trade.refresh(s,3))
	var value := trade.price(s,gun,true)
	assert(trade.transact(s,[gun],[],"warehouse").ok)
	assert(trade.transact(s,[],[gun],"warehouse").ok)
	assert(s.items[gun].energy == 25 and s.items[gun].plugins.scope == scope)
	assert(w.modify(s,"building_4",gun,"uninstall","scope"))
	assert(w.modify(s,"building_4",gun,"dismantle"))
	assert(w.craft(s,"building_4","rifle_basic",1))
	assert(p.settle(s,"x"))
	assert(value > 0)
	var battery: String = inv.spawn(s,"battery_basic","warehouse").id
	s.base.energy_store.energy = 500
	var sold := trade.transact(s,[battery],[],"warehouse")
	assert(sold.ok and sold.actual_net == 10)
	assert(s.base.energy_store.energy == 510 and s.items[battery].energy == 0)
	var pack: String = inv.spawn(s,"backpack_small","warehouse").id
	assert(inv.equip(s,pack,"backpack").ok)
	var large: String = inv.spawn(s,"rifle_basic","bag").id
	assert(inv.relocate(s,large,Vector2i(3,2),false))
	var before := WorldState.encode(s)
	var refused := trade.transact(s,[pack],[],"warehouse")
	assert(not refused.ok and refused.confirmation_required)
	assert(WorldState.encode(s) == before)
	assert(trade.transact(s,[pack],[],"warehouse",true).ok)
	assert(s.containers.bag.width == 3 and s.containers.bag.height == 2 and s.containers.bag.maximum_weight == 10)
	assert(s.items[large].container_id == "warehouse")
	assert(trade.transact(s,[],[pack],"warehouse").ok)
	assert(inv.equip(s,pack,"backpack").ok)
	assert(inv.move(s,large,"bag").ok)
	assert(inv.relocate(s,large,Vector2i(3,2),false))
	before = WorldState.encode(s)
	assert(not w.modify(s,"building_4",pack,"dismantle"))
	assert(WorldState.encode(s) == before)
	assert(w.modify(s,"building_4",pack,"dismantle","",true))
	assert(s.containers.bag.width == 3 and s.containers.bag.maximum_weight == 10)
	print("TRADE_SELF_CHECK_OK")
	quit()

