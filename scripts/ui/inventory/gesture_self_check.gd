extends SceneTree
var panel: InventoryPanel
func _initialize():call_deferred("run")
func mouse(point: Vector2, down: bool, double: bool = false):
	var e := InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.position=point
	e.pressed=down
	e.double_click=double
	Input.parse_input_event(e)
	await process_frame
func point(id: String, right: bool) -> Vector2:
	return panel.grid.global_position+panel.item_rect(panel.state.items[id],panel.state.items[id].container_id,right).position+Vector2(10,10)
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
	var drop := panel.grid.global_position+Vector2(3*44+10,28+2*44+10)
	await mouse(drop,false)
	assert(s.items[gun.id].container_id=="bag" and s.items[gun.id].cell==[3,2])
	snapshot=WorldState.encode(s)
	await mouse(start,false)
	assert(WorldState.encode(s)==snapshot)
	# Empty-space click cannot drag a stale selection.
	await mouse(panel.grid.global_position+Vector2(300,300),true)
	await mouse(start,false)
	assert(WorldState.encode(s)==snapshot)
	# Rotated explicit transfer uses requested cell atomically.
	await mouse(point(gun.id,false),true)
	var r := InputEventKey.new()
	r.keycode=KEY_R;r.pressed=true
	Input.parse_input_event(r)
	await process_frame
	await mouse(panel.grid.global_position+Vector2(338+3*40+10,28+40+10),false)
	assert(s.items[gun.id].container_id=="warehouse" and s.items[gun.id].cell==[3,1] and s.items[gun.id].rotated)
	panel.queue_free()
	await process_frame
	print("INVENTORY_GESTURE_CYCLE_PASS")
	quit()
