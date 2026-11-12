extends SceneTree
class CountingArena extends "res://scripts/ui/base/base_management_arena.gd":
	var charge_dispatches:=0
	var requested_target:=""
	var requested_battery:=""
	var lock_dispatches:=0
	func _on_inventory_charge(target_id:String,battery_id:String)->void:
		charge_dispatches+=1
		requested_target=target_id;requested_battery=battery_id
		super._on_inventory_charge(target_id,battery_id)
	func _on_inventory_movement_lock(locked:bool)->void:
		lock_dispatches+=1
		super._on_inventory_movement_lock(locked)
var arena:CountingArena
var panel:InventoryPanel
func _initialize():call_deferred("run")
func tap(point:Vector2):
	var motion:=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
func button(node:Node,prefix:String)->Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix):return child
		var found:=button(child,prefix)
		if found!=null:return found
	return null
func run():
	arena=CountingArena.new();root.add_child(arena)
	while arena.management==null:await process_frame
	await physics_frame
	panel=arena.management.inventory_panel
	arena.bind_inventory_player();arena.bind_inventory_player()
	arena.hud.open_inventory()
	await process_frame
	await process_frame
	var s:Dictionary=arena.state
	var target:String=arena.player.item().id
	s.items[target].energy=0
	var battery:String=""
	for item:Dictionary in arena.inventory.items_in(s,"bag"):
		if item.get("is_battery",false):
			item.energy=0
			if battery=="":battery=item.id
	s.items[battery].energy=17
	for resident in arena.residents:resident.set_physics_process(false)
	var total:float=s.items[battery].energy+s.items[target].energy
	await tap(panel.grid.global_position+panel.item_rect(s.items[battery],"bag",false).position+Vector2(8,8))
	await process_frame
	assert(panel.selected==battery)
	await process_frame
	await process_frame
	if DisplayServer.get_name()=="headless":button(panel.listing,"选择此电池供电").pressed.emit()
	else:await tap(button(panel.listing,"选择此电池供电").get_global_rect().get_center())
	await tap(panel.tabs_by_source.equipment.get_global_rect().get_center())
	await process_frame
	await tap(panel.grid.global_position+panel.item_rect(s.items[target],"equipment",false).position+Vector2(8,8))
	await process_frame
	assert(panel.selected==target and panel.battery_id==battery)
	if DisplayServer.get_name()=="headless":button(panel.listing,"使用").pressed.emit()
	else:await tap(button(panel.listing,"使用").get_global_rect().get_center())
	print("REQUEST target=",arena.requested_target," battery=",arena.requested_battery," player_battery=",arena.player.selected_charge_battery)
	assert(arena.charge_dispatches==1 and arena.requested_target==target and arena.requested_battery==battery and arena.player.selected_charge_battery==battery)
	for i in range(8):await physics_frame
	assert(s.items[target].energy>0 and s.items[target].energy<17)
	assert(is_equal_approx(s.items[battery].energy+s.items[target].energy,total))
	assert(s.items[battery].id==battery and s.items[target].id==target)
	panel.close_panel()
	s.world.exploration.used_slots=[]
	assert(arena.exploration.start(s,"suburbs","south","day"))
	var box_id:String=s.expedition.maps[s.expedition.map_id].containers.keys()[0]
	var dispatches:int=arena.lock_dispatches
	arena.hud.open_inventory(box_id)
	assert(arena.player.inventory_movement_locked)
	assert(arena.lock_dispatches==dispatches+1)
	var position_before:Vector2=arena.player.position
	Input.action_press("move_right")
	for i in range(8):await physics_frame
	assert(arena.player.position.is_equal_approx(position_before))
	panel.close_panel()
	assert(not arena.player.inventory_movement_locked)
	assert(arena.lock_dispatches==dispatches+2)
	for i in range(8):await physics_frame
	Input.action_release("move_right")
	assert(not arena.player.position.is_equal_approx(position_before))
	arena.queue_free()
	await process_frame
	print("BASE_INVENTORY_WIRING_BEHAVIOR_PASS")
	quit()




