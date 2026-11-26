extends SceneTree
var panel: InventoryPanel
func _initialize():call_deferred("run")
func mouse(point: Vector2, down: bool, double: bool = false):
	var e := InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.position=point
	e.pressed=down
	e.double_click=double
	root.push_input(e,true)
	await process_frame
func point(id: String, right: bool) -> Vector2:
	return panel.grid.get_global_transform_with_canvas()*(panel.item_rect(panel.state.items[id],panel.state.items[id].container_id,right).position+Vector2(10,10))
func run():
	var s := WorldState.fresh()
	var inv := InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	var pack := inv.spawn(s,"backpack_small","warehouse")
	inv.equip(s,pack.id,"backpack")
	var gun := inv.spawn(s,"rifle_basic","warehouse")
	panel=InventoryPanel.new()
	panel.bind_state(s,inv)
	root.add_child(panel)
	panel.open_panel()
	await process_frame
	await process_frame
	var start := point(gun.id,true)
	# Full first click + double press + matching release.
	await mouse(start,true)
	await mouse(start,false)
	assert(s.items[gun.id].container_id=="warehouse")
	await mouse(start,true,true)
	await mouse(start,false)
	assert(s.items[gun.id].container_id=="bag")
	var back := point(gun.id,false)
	await mouse(back,true,true)
	await mouse(back,false)
	assert(s.items[gun.id].container_id=="warehouse")
	# Tiny movement is selection only, never relocation.
	start=point(gun.id,true)
	var snapshot := WorldState.encode(s)
	await mouse(start,true)
	await mouse(start+Vector2(2,1),false)
	assert(WorldState.encode(s)==snapshot)
	# Explicit drag exactly once; duplicate release cannot undo it.
	await mouse(start,true)
	var drop := panel.grid.get_global_transform_with_canvas()*(panel.grid_origin(false)+Vector2(3,2)*panel.cell_size(false)+Vector2(10,10))
	await mouse(drop,false)
	assert(s.items[gun.id].container_id=="bag" and s.items[gun.id].cell==[3,2])
	snapshot=WorldState.encode(s)
	await mouse(start,false)
	assert(WorldState.encode(s)==snapshot)
	# Empty-space click cannot drag a stale selection.
	await mouse(panel.grid.get_global_transform_with_canvas()*Vector2(446,452),true)
	await mouse(start,false)
	assert(WorldState.encode(s)==snapshot)
	# Rotated explicit transfer uses requested cell atomically.
	await mouse(point(gun.id,false),true)
	var pointer:=point(gun.id,false)+Vector2(12,8)
	var motion:=InputEventMouseMotion.new()
	motion.position=pointer
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true)
	var rotate:=InputEventMouseButton.new()
	rotate.position=pointer
	rotate.button_index=MOUSE_BUTTON_RIGHT
	rotate.pressed=true
	root.push_input(rotate,true)
	rotate.pressed=false
	root.push_input(rotate,true)
	await process_frame
	await mouse(panel.grid.get_global_transform_with_canvas()*(panel.grid_origin(true)+Vector2(3,1)*panel.cell_size(true)+Vector2(panel.gesture.grab)+Vector2(1,1)),false)
	assert(s.items[gun.id].container_id=="warehouse" and s.items[gun.id].cell==[3,1] and s.items[gun.id].rotated)
	panel.queue_free()
	await process_frame
	print("INVENTORY_GESTURE_CYCLE_PASS")
	quit()
