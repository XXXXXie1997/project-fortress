extends "res://scripts/game/session/main_mouse_check.gd"
# Explicit test prerequisite: position beside each interaction to shorten travel.
# Quests, loot, keys, rewards, days and ending are never assigned by this driver.
func action(name:String):
	for down in [true,false]:
		var e:=InputEventAction.new();e.action=name;e.pressed=down;Input.parse_input_event(e)
		await process_frame
	for i in 3:await physics_frame
func click(prefix:String)->void:
	for i in 3:await process_frame
	var control:=find_button(shell,prefix);assert(control!=null,prefix)
	var node:Node=control.get_parent()
	while node!=null:
		if node is ScrollContainer:node.ensure_control_visible(control)
		node=node.get_parent()
	for i in 3:await process_frame
	await super.click(prefix)
func position_at(point:Vector2):
	shell.arena.player.position=point
	for i in 3:await physics_frame
func terminal():
	shell.arena.management.root_panel.hide()
	for building in shell.coordinator.state.base.buildings.values():
		if building.type=="quest":
			var size:Array=shell.coordinator.services.building.config.types.quest.size
			await position_at(shell.arena.grid.logical_to_world((Vector2(building.cell[0],building.cell[1])+Vector2(size[0],size[1])*.5)*48)+Vector2(0,60))
	await action("interact")
	assert(shell.arena.player.progression_panel.visible and shell.arena.player.progression_panel.terminal)
func at_box(id:String):
	var box:Dictionary=shell.coordinator.services.exploration.box(shell.coordinator.state,id)
	await position_at(Vector2(box.position[0],box.position[1])+Vector2(50,-20))
	await action("interact")
	assert(shell.arena.hud.inventory_panel.visible)
	for i in 240:await physics_frame
	await click("全部拾取")
	await action("cancel")
func objective():
	var entry:Dictionary=shell.arena.catalog[shell.coordinator.state.expedition.map_id].objectives[0]
	await position_at(Vector2(entry.position[0],entry.position[1]))
	await action("interact")
func deposit_scrap():
	await action("inventory")
	var panel=shell.arena.hud.inventory_panel
	var scrap:Dictionary={}
	for item in shell.coordinator.services.inventory.items_in(shell.coordinator.state,"bag"):
		if item.definition_id=="scrap":scrap=item;break
	assert(not scrap.is_empty())
	var point:Vector2=panel.grid.global_position+panel.item_rect(scrap,"bag",false).get_center()
	for double in [false,true]:
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=down;event.double_click=double and down;Input.parse_input_event(event)
			await process_frame
	await action("cancel")
	assert(shell.coordinator.services.inventory.count(shell.coordinator.state,"scrap","warehouse")>=5)
func extract():
	for point in shell.arena.catalog[shell.coordinator.state.expedition.map_id].points.values():
		if point.kind=="extraction":
			await position_at(Vector2(point.position[0],point.position[1]));break
	await action("interact");await mounted()
	assert(shell.coordinator.state.session.location=="base")
func run():
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://main-route-%s"%Time.get_ticks_usec())
	await click("开始新过程");await click("确认新建");await mounted()
	await terminal();await click("主线 · 调查郊区中继记录");await action("cancel")
	assert(shell.coordinator.state.quests.active.has("main_1"))
	await click("白天出发");await click("城郊");await mounted()
	await at_box("starter_cache")
	await objective()
	assert(shell.coordinator.state.quests.active.main_1.progress>=1)
	await extract();await terminal();await click("交付 调查郊区中继记录")
	assert(shell.coordinator.state.quests.completed.has("main_1"))
	await click("主线 · 恢复城区外界通信");await action("cancel")
	await click("自动休息");await click("确认行动");await mounted()
	assert(shell.coordinator.state.day==2 and not shell.coordinator.state.cycle.failed)
	assert("city" in shell.coordinator.state.world.exploration.unlocked)
	await click("白天出发");await click("废弃城区");await mounted()
	await at_box("apartment_key")
	for room in shell.arena.catalog.city.rooms:
		if room.id=="radio":
			var logical:=Rect2(room.door[0],room.door[1],room.door[2],room.door[3]).get_center()
			await position_at(shell.arena.projection.logical_to_world(logical+Vector2(0,35)))
	await action("interact")
	assert(not shell.arena.geometry.doors.has("radio"))
	await objective();await extract();await deposit_scrap();await terminal();await click("交付 恢复城区外界通信")
	assert(shell.coordinator.state.quests.ending=="contact_restored")
	await capture("main-contact-restored")
	await click("继续生存")
	assert(not shell.panel.visible and not shell.arena.player.progression_panel.visible and shell.coordinator.state.quests.completed.has("main_2"))
	print("SESSION_REAL_MAIN_QUEST_ROUTE_PASS positioning_prerequisite=true")
	assert(shell.coordinator.shutdown().ok)
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout;quit()


