extends SceneTree
var arena
var ui:BaseManagementUI
func _initialize():call_deferred("run")
func mouse(pos:Vector2,down:bool):
	var motion:=InputEventMouseMotion.new();motion.position=pos;Input.parse_input_event(motion)
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=pos;e.pressed=down
	Input.parse_input_event(e)
	await process_frame
func tap(pos:Vector2):
	await mouse(pos,true)
	await mouse(pos,false)
func find_button(node:Node,text:String)->Button:
	for c in node.get_children():
		if c is Button and c.text.begins_with(text):return c
		var found:=find_button(c,text)
		if found!=null:return found
	return null
func click(text:String):
	await process_frame
	await process_frame
	var b:=find_button(ui.content,text)
	assert(b!=null,"Missing "+text)
	ui.scroll.ensure_control_visible(b)
	await process_frame
	await tap(b.get_global_rect().get_center())
func world_tap(cell:Vector2i):
	await tap(arena.get_canvas_transform()*arena.grid.cell_to_world(cell))
func run():
	root.gui_embed_subwindows=true
	arena=load("res://scenes/ui/base/base_management_arena.tscn").instantiate();root.add_child(arena)
	while arena.management==null:await process_frame
	ui=arena.management
	await create_timer(0.5).timeout
	var count:int=arena.state.base.buildings.size()
	await click("建造发电厂")
	await world_tap(Vector2i(14,7))
	assert(arena.state.base.buildings.size()==count+1,str(ui.message.text)+" mode="+arena.placing_type+" phase="+arena.state.phase)
	var generator:String=arena.state.base.buildings.keys().back()
	ui.show_buildings()
	await click("建造炮塔")
	await world_tap(Vector2i(14,7))
	assert(arena.state.base.buildings.size()==count+1,str(ui.message.text)+" mode="+arena.placing_type+" phase="+arena.state.phase)
	await world_tap(Vector2i(13,11))
	assert(arena.state.base.buildings.size()==count+2)
	ui.inspect(generator)
	await click("移动")
	await world_tap(Vector2i(16,7))
	assert(arena.state.base.buildings[generator].cell==[16,7])
	arena.state.base.buildings[generator].durability=0
	ui.inspect(generator)
	await click("维修")
	assert(arena.state.base.buildings[generator].durability>0)
	ui.inspect("building_4")
	await click("制作与订单")
	await click("制作 医疗针")
	assert(arena.state.base.buildings.building_4.has("order"))
	await click("取消订单")
	assert(not arena.state.base.buildings.building_4.has("order"))
	ui.show_trade()
	var energy:float=arena.state.base.energy_store.energy
	await click("电池")
	await click("统一成交")
	assert(arena.state.base.energy_store.energy>energy)
	ui.show_trade()
	if "--capture-ui" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/ui/base/management-preview.png")
	arena.queue_free()
	await process_frame
	print("BASE_MANAGEMENT_MOUSE_PASS")
	quit()



