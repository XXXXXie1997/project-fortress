extends SceneTree
func _initialize():call_deferred("run")
func run():
	var arena=load("res://scenes/ui/base/base_management_arena.tscn").instantiate()
	root.add_child(arena)
	while arena.management==null:await process_frame
	await create_timer(0.5).timeout
	var ui:BaseManagementUI=arena.management
	assert(ui.services.inventory.definitions.has("rifle_advanced"))
	assert(ui.submit_order("building_4","medical",2))
	assert(arena.cycle.to_dusk(arena.state))
	assert(arena.inventory.count(arena.state,"medical_needle","warehouse")==1)
	assert(ui.services.production.cancel(arena.state,"building_4"))
	ui.show_trade()
	if "--capture-ui" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/ui/base/management-preview.png")
	var energy:float=arena.state.base.energy_store.energy
	var shop_items:Array=arena.inventory.items_in(arena.state,"shop")
	ui.buy_basket=[shop_items[0].id]
	ui.commit_trade(false)
	assert(ui.buy_basket.is_empty())
	assert(arena.state.base.energy_store.energy<energy)
	ui.show_workstation("building_4")
	arena.queue_free()
	await process_frame
	print("BASE_MANAGEMENT_SMOKE_PASS")
	quit()
