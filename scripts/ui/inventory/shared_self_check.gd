extends SceneTree
var panel:InventoryPanel
var chosen := ""
func _initialize():call_deferred("run")
func click(point:Vector2,down:bool):
	var e:=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=down
	root.push_input(e,true)
	await process_frame
func run():
	root.size=Vector2i(1280,720)
	var s:=WorldState.fresh()
	var inv:=InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	var pack:=inv.spawn(s,"backpack_small","warehouse")
	inv.equip(s,pack.id,"backpack")
	var gun:=inv.spawn(s,"rifle_basic","bag")
	panel=InventoryPanel.new();panel.bind_state(s,inv);root.add_child(panel);panel.open_panel()
	await process_frame
	await process_frame
	await click(panel.grid.get_global_transform_with_canvas()*(panel.item_rect(s.items[gun.id],"bag",false).position+Vector2(10,10)),true)
	await click(panel.slot_buttons.weapon_1.get_global_transform_with_canvas()*(panel.slot_buttons.weapon_1.size*.5),false)
	assert(s.player.equipment.weapon_1==gun.id)
	await click(panel.slot_buttons.weapon_1.get_global_transform_with_canvas()*(panel.slot_buttons.weapon_1.size*.5),true)
	await click(panel.grid.get_global_transform_with_canvas()*(panel.grid_origin(false)+Vector2(1,65)+Vector2(panel.gesture.grab)),false)
	assert(s.items[gun.id].container_id=="bag" and s.player.equipment.weapon_1=="")
	var adapters=load("res://scripts/ui/inventory/consumer_adapters.gd")
	var product:=inv.spawn(s,"medical_needle","warehouse",5)
	adapters.production(panel,["medical_needle"])
	assert(panel.visible_items(panel.remote_location()).size()==1)
	await click(panel.grid.get_global_transform_with_canvas()*(panel.item_rect(s.items[product.id],"warehouse",true).position+Vector2(10,10)),true)
	await click(panel.grid.get_global_transform_with_canvas()*(panel.grid_origin(false)+Vector2(202,74)),false)
	assert(s.items[product.id].container_id=="bag")
	adapters.strengthening(panel,func(id):chosen=id,true)
	panel.source="bag";panel.selected=gun.id;panel.confirm_selection()
	assert(chosen==gun.id)
	adapters.strengthening(panel,func(id):chosen=id,true)
	panel.source="warehouse";panel.at_base=false;panel.refresh()
	assert(not panel.tabs_by_source.warehouse.visible)
	var hidden:=inv.spawn(s,"rifle_basic","warehouse")
	chosen="";panel.selected=hidden.id;panel.confirm_selection()
	assert(chosen=="")
	panel.queue_free()
	await process_frame
	print("INVENTORY_SHARED_COMPONENT_PASS")
	quit()
