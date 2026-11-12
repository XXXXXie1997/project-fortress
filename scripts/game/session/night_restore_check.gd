extends SceneTree
var shell
func _initialize():call_deferred("run")
func wait_mount():
	while shell.mounting or shell.mount_queued:await process_frame
func run():
	shell=load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://night-restore-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(71).ok);await wait_mount()
	for building:Dictionary in shell.coordinator.state.base.buildings.values():building.durability=0
	assert(shell.coordinator.to_dusk().ok)
	assert(shell.coordinator.begin_night("rest",true).ok)
	assert(not shell.coordinator.finish_night().held)
	shell.queue_mount();await wait_mount()
	assert(shell.overlay_mode=="failure")
	var outcome:Dictionary=shell.coordinator.state.cycle.results.duplicate(true)
	assert(shell.coordinator.failure_choice("latest").ok)
	await wait_mount()
	assert(shell.overlay_mode=="failure" and shell.coordinator.state.cycle.failed)
	assert(shell.coordinator.state.cycle.results.size()==1)
	assert(shell.coordinator.state.cycle.results["night:1"].held==outcome["night:1"].held)
	# The dangerous last-valid rest is resumed once; it returns to failure choices.
	for frame in 15:await process_frame
	assert(shell.coordinator.state.cycle.results.size()==1)
	assert(shell.coordinator.failure_choice("new",72).ok);await wait_mount()
	assert(shell.coordinator.to_dusk().ok)
	assert(shell.coordinator.begin_night("manual").ok)
	shell.queue_mount();await wait_mount()
	for frame in 15:await physics_frame
	shell.show_pause();assert(shell.coordinator.shutdown().ok)
	var plan:Dictionary=shell.coordinator.state.base.wave_plan.duplicate(true)
	assert(shell.coordinator.restore().ok);await wait_mount()
	assert(shell.arena.running and shell.coordinator.state.phase=="night")
	assert(shell.coordinator.state.base.wave_plan.id==plan.id)
	assert(shell.coordinator.state.base.wave_plan.entries.size()==plan.entries.size())
	# New process for night exploration restores the active expedition rather than resting.
	assert(shell.coordinator.create_world(73).ok);await wait_mount()
	assert(shell.coordinator.to_dusk().ok)
	assert(shell.coordinator.begin_night("explore",true,"suburbs","south").ok)
	shell.queue_mount();await wait_mount()
	shell.show_pause();assert(shell.coordinator.shutdown().ok)
	var session_id= shell.coordinator.state.expedition.id
	assert(shell.coordinator.restore().ok);await wait_mount()
	assert(shell.coordinator.state.expedition.active and shell.coordinator.state.expedition.period=="night")
	assert(shell.coordinator.state.expedition.id==session_id)
	assert(shell.coordinator.state.cycle.results.is_empty())
	assert(shell.coordinator.shutdown().ok)
	print("SESSION_REST_MANUAL_NIGHT_EXPLORE_RESTORE_PASS")
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout
	quit()
