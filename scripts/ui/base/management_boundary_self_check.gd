extends SceneTree
func _initialize():call_deferred("run")
func run():
	var arena=load("res://scenes/ui/base/base_management_arena.tscn").instantiate()
	root.add_child(arena)
	while arena.management==null:await process_frame
	var ui:BaseManagementUI=arena.management
	var s:Dictionary=arena.state
	var inv:InventoryService=arena.inventory
	var farm:String=arena.building.build(s,"farm",[9,7],Rect2i(0,0,24,18))
	assert(not farm.is_empty())
	inv.spawn(s,"seed_material","warehouse",1)
	assert(ui.services.farming.plant(s,farm,"material"))
	s.containers.warehouse.width=1;s.containers.warehouse.height=1
	assert(ui.services.farming.settle(s,"self:day",true))
	assert(ui.services.farming.settle(s,"self:night",true))
	assert(s.base.buildings[farm].batches.size()==1)
	s.containers.warehouse.width=12;s.containers.warehouse.height=8
	assert(ui.services.farming.collect_ready(s)==1)
	assert(ui.services.farming.collect_ready(s)==0)
	var gun:String=inv.spawn(s,"rifle_basic","bag").id
	s.items[gun].durability=25
	ui.show_workstation("building_4")
	var before:=WorldState.encode(s)
	ui.select_item(func(i):return i.id==gun,func(id):ui.services.workstation.modify(s,"building_4",id,"repair"))
	ui.inventory_panel.selected=gun
	ui.inventory_panel.close_panel()
	assert(WorldState.encode(s)==before)
	ui.select_item(func(i):return i.id==gun,func(id):ui.services.workstation.modify(s,"building_4",id,"repair"))
	ui.inventory_panel.selected=gun;ui.inventory_panel.confirm_selection()
	assert(s.items[gun].durability==100)
	s.items[gun].energy=23;s.base.technology={"storage":true}
	assert(not inv.spawn(s,"boss_core","warehouse",1).is_empty())
	assert(ui.services.workstation.modify(s,"building_4",gun,"upgrade","rifle_advanced"))
	assert(s.items[gun].energy==23)
	var shop:Dictionary=inv.spawn(s,"battery_basic","shop")
	ui.buy_basket=[shop.id]
	before=WorldState.encode(s)
	s.base.energy_store.energy=0
	var zero_before:=WorldState.encode(s)
	ui.commit_trade(false)
	assert(WorldState.encode(s)==zero_before)
	arena.queue_free()
	await process_frame
	print("BASE_MANAGEMENT_BOUNDARIES_PASS")
	quit()
