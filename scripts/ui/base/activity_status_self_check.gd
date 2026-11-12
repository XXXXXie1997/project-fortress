extends SceneTree
func _initialize():call_deferred("run")
func run():
	var a=load("res://scenes/ui/base/base_management_arena.tscn").instantiate()
	root.add_child(a)
	while a.management==null:await process_frame
	var u:BaseManagementUI=a.management
	var s:Dictionary=a.state
	assert(u.submit_order("building_4","medical",2))
	var before:=WorldState.encode(s)
	assert(u.production_status("building_4").contains("医疗针"))
	assert(u.production_status("building_4").contains("已产 0 / 总量 2"))
	assert(WorldState.encode(s)==before)
	s.containers.warehouse.width=1;s.containers.warehouse.height=1
	assert(u.production_status("building_4").contains("满仓暂停"))
	s.base.buildings.building_4.durability=0
	assert(u.production_status("building_4").contains("废墟暂停"))
	s.base.buildings.building_4.durability=100
	s.containers.warehouse.width=12;s.containers.warehouse.height=8
	assert(u.services.production.settle(s,"status:test"))
	assert(u.production_status("building_4").contains("已产 1 / 总量 2"))
	var farm:String=a.building.build(s,"farm",[9,7],Rect2i(0,0,24,18))
	a.inventory.spawn(s,"seed_material","warehouse")
	assert(u.services.farming.plant(s,farm,"material"))
	assert(u.farm_status(farm).contains("阶段 0 / 2"))
	s.containers.warehouse.width=1;s.containers.warehouse.height=1
	u.services.farming.settle(s,"status:one",true);u.services.farming.settle(s,"status:two",true)
	assert(u.farm_status(farm).contains("成熟待收") and u.farm_status(farm).contains("满仓留田"))
	s.phase="night"
	assert(u.farm_status(farm).contains("仅清晨或黄昏"))
	if "--capture-ui" in OS.get_cmdline_user_args():
		u.show_farm(farm)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/ui/base/farming-status-preview.png")
		u.show_production("building_4")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/ui/base/production-status-preview.png")
	s.phase="morning"
	s.containers.warehouse.width=12;s.containers.warehouse.height=8
	assert(u.services.farming.collect_ready(s)==1)
	assert(u.farm_status(farm).contains("当前没有作物"))
	a.queue_free()
	await process_frame
	print("BASE_ACTIVITY_STATUS_PASS")
	quit()
