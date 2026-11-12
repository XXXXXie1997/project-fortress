extends SceneTree
func _initialize():
	var inv:=InventoryService.new(preload("res://scripts/content/catalog.gd").items())
	var state:=WorldState.fresh();inv.setup(state)
	assert(not inv.spawn(state,"battery_basic","bag",2).is_empty())
	for item in inv.items_in(state,"bag"):print("BATCH_BATTERY ",item.id," capacity=",item.capacity," battery=",item.get("is_battery",false))
	if "--reproduce" in OS.get_cmdline_user_args():quit();return
	for item in inv.items_in(state,"bag"):assert(item.capacity==100 and item.is_battery)
	state.base.energy_store.energy=200
	ChargingService.wireless(state,20,15,true,true,false)
	for item in inv.items_in(state,"bag"):assert(item.energy==100)
	assert(state.base.energy_store.energy==0)
	for definition in ["rifle_basic","armor_basic"]:
		var fresh:=WorldState.fresh();inv.setup(fresh)
		assert(not inv.spawn(fresh,definition,"warehouse",2).is_empty())
		assert(fresh.items.size()==2)
		for item in fresh.items.values():assert(item.durability==inv.definitions[definition].durability and item.quantity==1)
	var before:=WorldState.encode(state)
	for definition in inv.definitions:
		if inv.definitions[definition].get("unique",false):assert(inv.spawn(state,definition,"warehouse",2).is_empty())
	assert(WorldState.encode(state)==before)
	var ambiguous:=WorldState.fresh();inv.setup(ambiguous)
	var weapon:=inv.spawn(ambiguous,"rifle_basic","warehouse")
	ambiguous.items[weapon.id].quantity=2
	ambiguous.items[weapon.id].plugins={"tactical":"existing_plugin"}
	var ambiguous_before:=WorldState.encode(ambiguous)
	assert(not inv.move(ambiguous,weapon.id,"ground").ok)
	assert(WorldState.encode(ambiguous)==ambiguous_before)
	state.containers.bag=InventoryService.container(1,1,10)
	before=WorldState.encode(state)
	assert(inv.spawn(state,"battery_basic","bag",2).is_empty())
	assert(WorldState.encode(state)==before)
	var worn:=inv.spawn(state,"armor_basic","warehouse");worn.durability=0
	state.items[worn.id].durability=0
	var battery:Dictionary=state.items.values()[0];battery.capacity=0;battery.erase("is_battery");battery.energy=17
	state.run_start_snapshot=state.duplicate(true)
	var catalog=preload("res://scripts/content/catalog.gd")
	assert(catalog.migrate(state).ok)
	assert(state.items[battery.id].capacity==100 and state.items[battery.id].energy==17)
	assert(state.items[worn.id].durability==0)
	assert(state.run_start_snapshot.items[battery.id].capacity==100)
	before=WorldState.encode(state);assert(catalog.migrate(state).ok);assert(WorldState.encode(state)==before)
	state.items[battery.id].energy=101
	before=WorldState.encode(state);assert(not catalog.migrate(state).ok);assert(WorldState.encode(state)==before)
	if FileAccess.file_exists("res://.godot-local/dev510-old-latest.json"):
		var envelope:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://.godot-local/dev510-old-latest.json"))
		var old:Dictionary=JSON.parse_string(envelope.payload)
		var original:Dictionary=old.items.item_300.duplicate(true)
		assert(catalog.migrate(old).ok)
		assert(old.items.item_300.id==original.id and old.items.item_300.energy==original.energy and old.items.item_300.capacity==100 and old.items.item_300.is_battery)
		var total:float=old.base.energy_store.energy
		for item in inv.items_in(old,"bag"):total+=float(item.energy)
		ChargingService.wireless(old,1.0,15,true,true,false)
		var after:float=old.base.energy_store.energy
		for item in inv.items_in(old,"bag"):after+=float(item.energy)
		assert(is_equal_approx(total,after))
		print("QA604_COPIED_OLD_BATTERY_REPAIR_PASS")
	print("BATCH_STATE_PASS")
	quit()
