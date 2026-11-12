extends SceneTree
func _initialize():call_deferred("run")
func run():
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://warning-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	var state:Dictionary=shell.coordinator.state
	var rules:=DefenseResolution.new()
	assert(not rules.warning_state(state).visible)
	for b in state.base.buildings.values():b.durability=1.0
	assert(not rules.warning_state(state).visible)
	var frozen:Dictionary=rules.capture(state,10,"warning_fixture")
	state.phase="night";state.cycle.night={"mode":"manual","snapshot":frozen}
	var originals:Dictionary=state.base.buildings.duplicate(true)
	for b in state.base.buildings.values():
		if b.type in ["warehouse","generator"]:b.durability=0.0
	var before:=WorldState.encode(state)
	var warning:=rules.warning_state(state)
	assert(warning.visible and warning.destroyed_weight==8 and warning.total_weight==12)
	assert(WorldState.encode(state)==before)
	assert(rules.warning_state(JSON.parse_string(before))==warning)
	var current_snapshot:Dictionary={"weights":frozen.weights,"base":state.base}
	assert(rules.lost(current_snapshot)==warning.threshold_reached)
	state.base.buildings.test_addition={"type":"generator","durability":100}
	assert(rules.warning_state(state).total_weight==12)
	state.base.buildings.erase("test_addition")
	var damaged_normals:=0
	for b in state.base.buildings.values():
		if b.type=="generator":b.durability=1.0
		elif b.type!="warehouse" and damaged_normals<2:
			b.durability=0.0;damaged_normals+=1
	assert(rules.warning_state(state).visible and not rules.warning_state(state).threshold_reached)
	for i in 4:await process_frame
	assert(shell.arena.hud.loss_warning.visible)
	assert(shell.arena.hud.loss_warning.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	if DisplayServer.get_name()!="headless":
		shell.arena.management.root_panel.hide()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/game/session/base-warning.png")
	state.base.buildings=originals
	for i in 4:await process_frame
	assert(not shell.arena.hud.loss_warning.visible)
	assert(shell.coordinator.shutdown().ok)
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout
	print("BASE_WARNING_CURRENT_DURABILITY_FROZEN_WEIGHTS_PASS")
	quit()

