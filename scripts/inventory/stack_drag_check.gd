extends SceneTree
func _initialize():call_deferred("run")
func mouse(point:Vector2,pressed:bool):
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.global_position=point;e.pressed=pressed;Input.parse_input_event(e)
	await process_frame
func run():
	var s:=WorldState.fresh();var inv:=InventoryService.new(preload("res://scripts/content/catalog.gd").items());inv.setup(s)
	var source:=inv.spawn(s,"scrap","warehouse",5)
	var existing:=inv.spawn(s,"scrap","bag",2)
	var panel:=InventoryPanel.new();panel.bind_state(s,inv);root.add_child(panel);panel.open_panel()
	for i in 3:await process_frame
	var start:Vector2=panel.grid.global_position+panel.item_rect(s.items[source.id],"warehouse",true).get_center()
	var drop:Vector2=panel.grid.global_position+Vector2(44+10,28+44+10)
	await mouse(start,true)
	var motion:=InputEventMouseMotion.new();motion.position=drop;motion.global_position=drop;motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion);await process_frame
	await mouse(drop,false)
	assert(s.items.has(source.id) and s.items[source.id].quantity==5 and s.items[source.id].cell==[1,1] and s.items[source.id].container_id=="bag")
	assert(s.items[existing.id].quantity==2 and s.items.size()==2)
	var before:=WorldState.encode(s)
	assert(not panel.transfer_item(source.id,"bag",Vector2i(0,0),true))
	assert(WorldState.encode(s)==before)
	assert(inv.move(s,source.id,"warehouse").ok)
	assert(inv.move(s,source.id,"bag").ok)
	assert(not s.items.has(source.id) and s.items[existing.id].quantity==7)
	assert(inv.definitions.scrap.category=="material" and not inv.definitions.scrap.has("suppress_stack_merge"))
	panel.queue_free();await process_frame
	print("MATERIAL_EXPLICIT_DRAG_ID_STACK_AUTOMERGE_ATOMIC_PASS")
	quit()
