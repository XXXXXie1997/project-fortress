extends SceneTree
var inv: InventoryService
var w: WorkstationService
var t: TradeService
var s: Dictionary
var checks := 0
func ck(v: bool, label: String) -> void:
	checks += 1
	if not v:
		push_error(label)
		quit(1)
		assert(v,label)
func reset() -> void:
	s = WorldState.fresh()
	inv.setup(s)
	var b := BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
	b.setup(s)
	w = WorkstationService.new(ProductionService.new(b,{}),JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment_recipes.json")))
	t.refresh(s,3)
func spawn(d: String, c: String="warehouse", q: int=1) -> String:
	return inv.spawn(s,d,c,q).id
func snap() -> String: return JSON.stringify(s)
func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	defs.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/equipment_recipes.json")).item_definitions)
	var tc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))
	defs.merge(tc.item_definitions)
	inv = InventoryService.new(defs)
	t = TradeService.new(inv,tc)
	reset()
	var bag := spawn("backpack_small")
	ck(inv.equip(s,bag,"backpack").ok,"equip")
	var cargo := spawn("knife_basic","bag")
	ck(inv.relocate(s,cargo,Vector2i(5,2),false),"cargo placement")
	var before := snap()
	ck(not t.transact(s,[bag],[],"warehouse").ok and snap()==before,"sale cancel atomic")
	ck(t.transact(s,[bag],[],"warehouse",true).ok and s.containers.bag.width==3 and s.items[cargo].container_id=="warehouse","sale resize")
	bag = spawn("backpack_small")
	inv.equip(s,bag,"backpack")
	inv.move(s,cargo,"bag")
	inv.relocate(s,cargo,Vector2i(5,2),false)
	before=snap()
	ck(not w.modify(s,"building_4",bag,"dismantle") and snap()==before,"dismantle cancel")
	ck(w.modify(s,"building_4",bag,"dismantle","",true) and s.containers.bag.width==3,"dismantle resize")
	reset()
	var battery := spawn("battery_basic")
	s.base.energy_store.energy=500
	var r := t.transact(s,[battery],[],"warehouse")
	ck(r.ok and r.storage_delta==10 and s.base.energy_store.energy==510 and s.items[battery].energy==0,"battery sale")
	ck(t.transact(s,[],[battery],"warehouse").ok and s.base.energy_store.energy==500,"battery buyback")
	ck(inv.move(s,battery,"bag").ok and s.items[battery].energy==100 and s.base.energy_store.energy==400,"bag charge")
	ck(t.transact(s,[battery],[],"warehouse").ok and s.items[battery].energy==100,"charged sale retains")
	ck(t.transact(s,[],[battery],"warehouse").ok and s.base.energy_store.energy==500 and s.items[battery].energy==0,"charged buyback conservation")
	reset()
	var gun := spawn("rifle_basic")
	var scope := spawn("scope_basic")
	spawn("scrap","warehouse",100)
	ck(w.modify(s,"building_4",gun,"install",scope),"install")
	var gun2 := spawn("rifle_basic")
	before=snap()
	ck(not w.modify(s,"building_4",gun2,"install",scope) and snap()==before,"single parent")
	ck(not w.modify(s,"building_4",gun,"dismantle") and snap()==before,"plugin blocks dismantle")
	s.items[gun].energy=25
	s.base.technology={"storage":true}
	var energy: float=s.base.energy_store.energy
	var materials := inv.count(s,"scrap","warehouse")
	ck(w.modify(s,"building_4",gun,"upgrade","rifle_advanced"),"upgrade")
	ck(s.items[gun].energy==25 and s.items[gun].plugins.scope==scope and s.items[gun].durability==150 and energy-s.base.energy_store.energy==20 and materials-inv.count(s,"scrap","warehouse")==10,"upgrade difference matches direct 40/20 minus basic 20/10")
	s.items[gun].durability=75
	materials=inv.count(s,"scrap","warehouse")
	ck(w.modify(s,"building_4",gun,"repair") and materials-inv.count(s,"scrap","warehouse")==3 and s.items[gun].energy==25,"repair cost")
	var original: Dictionary=s.items[gun].duplicate(true)
	ck(t.transact(s,[gun],[],"warehouse").ok,"sell gun")
	ck(t.transact(s,[],[gun],"warehouse").ok and s.items[gun].plugins==original.plugins and s.items[gun].energy==25 and s.items[gun].durability==150,"original instance")
	ck(w.modify(s,"building_4",gun,"uninstall","scope") and s.items[scope].container_id=="warehouse","uninstall")
	reset()
	var unique: String=s.unique_items.nightvision
	before=snap()
	ck(not t.refresh(s,3) and snap()==before,"once per day")
	for item: Dictionary in inv.items_in(s,"shop"):
		ck(item.energy==0 and item.durability==float(inv.definitions[item.definition_id].get("durability",0)),"new goods empty full durability")
	s.day+=1
	ck(t.refresh(s,3) and not s.items.has(unique) and s.unique_items.nightvision!=unique,"unique release refresh")
	var sell := spawn("knife_basic")
	var buy := spawn("knife_basic","shop")
	s.base.energy_store.energy=s.base.energy_store.capacity
	ck(t.transact(s,[sell],[buy],"warehouse").ok and s.base.energy_store.energy==990,"net barter no spurious overflow")
	sell=spawn("knife_basic")
	s.base.energy_store.energy=1000
	before=snap()
	ck(not t.transact(s,[sell],[],"warehouse").ok and snap()==before,"overflow cancel")
	r=t.transact(s,[sell],[],"warehouse",true)
	ck(r.ok and r.lost_energy==10 and r.actual_net==0,"overflow accept")
	ck(t.transact(s,[],[sell],"warehouse").ok and s.base.energy_store.energy==990,"original sale price after overflow")
	reset()
	# Fill real warehouse and bag cells through normal spawn, no fake capacity.
	while not inv.spawn(s,"armor_basic","warehouse").is_empty(): pass
	while not inv.spawn(s,"scope_basic","warehouse").is_empty(): pass
	buy=spawn("knife_basic","shop")
	r=t.transact(s,[],[buy],"warehouse")
	ck(r.ok and r.destinations[buy].destination=="bag" and r.destinations[buy].fallback,"warehouse to bag fallback")
	while not inv.spawn(s,"scope_basic","bag").is_empty(): pass
	buy=spawn("knife_basic","shop")
	r=t.transact(s,[],[buy],"warehouse")
	ck(r.ok and r.destinations[buy].destination=="ground","both full ground")
	# Full warehouse blocks plugin return atomically.
	reset()
	gun=spawn("rifle_basic")
	scope=spawn("scope_basic")
	ck(w.modify(s,"building_4",gun,"install",scope),"full test setup")
	while not inv.spawn(s,"scope_basic","warehouse").is_empty(): pass
	before=snap()
	ck(not w.modify(s,"building_4",gun,"uninstall","scope") and snap()==before,"full uninstall atomic")
	reset()
	gun=spawn("rifle_basic")
	s.base.technology={"storage":true}
	before=snap()
	ck(not w.modify(s,"building_4",gun,"upgrade","rifle_advanced") and snap()==before,"missing materials atomic")
	s.items[gun].durability=50
	before=snap()
	ck(not w.modify(s,"building_4",gun,"repair") and snap()==before,"repair insufficient atomic")
	reset()
	unique=s.unique_items.nightvision
	ck(t.transact(s,[],[unique],"warehouse").ok,"buy unique")
	ck(t.transact(s,[unique],[],"warehouse").ok and inv.spawn(s,"nightvision","warehouse").is_empty(),"buyback retains uniqueness")
	s.day+=1
	ck(t.refresh(s,3) and not s.items.has(unique) and s.trade.buyback_prices.is_empty(),"buyback daily destruction")
	print("QA_TRADE_R1_OK checks=",checks)
	quit()

