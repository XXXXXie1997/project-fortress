extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var s := WorldState.fresh()
	var inv := InventoryService.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items)
	inv.setup(s)
	var pack := inv.spawn(s,"backpack_small","warehouse")
	inv.equip(s,pack.id,"backpack")
	var needle := inv.spawn(s,"medical_needle","bag",20)
	var panel := InventoryPanel.new()
	panel.bind_state(s,inv)
	root.add_child(panel)
	panel.open_panel()
	await process_frame
	await process_frame
	var pos := panel.grid.global_position+Vector2(15,43)
	var click := InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.position=pos
	click.pressed=true
	Input.parse_input_event(click)
	await process_frame
	assert(not panel.selected.is_empty())
	click=click.duplicate()
	click.pressed=false
	Input.parse_input_event(click)
	await process_frame
	s.player.quick[0]="medical_needle"
	assert(inv.quick_count(s,0)==20)
	var rotate := InputEventKey.new()
	rotate.keycode=KEY_R
	rotate.pressed=true
	Input.parse_input_event(rotate)
	await process_frame
	assert(panel.rotated)
	click=click.duplicate()
	click.pressed=true
	click.double_click=true
	Input.parse_input_event(click)
	await process_frame
	click=click.duplicate()
	click.pressed=false
	Input.parse_input_event(click)
	await process_frame
	assert(inv.count(s,"medical_needle","warehouse")==5)
	panel.close_panel()
	panel.queue_free()
	await process_frame
	print("INVENTORY_UI_INPUT_PASS")
	quit()



