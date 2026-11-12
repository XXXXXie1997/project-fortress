extends SceneTree
func _initialize():call_deferred("run")
func run():
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://exit-retry-valid")
	assert(shell.coordinator.create_world(811).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	var valid=shell.coordinator.saver
	var file:=FileAccess.open("user://exit-blocker",FileAccess.WRITE);file.store_string("block directory");file.close()
	shell.coordinator.saver=SaveService.new("user://exit-blocker/subfolder")
	shell.request_exit()
	assert(not shell.exiting and is_instance_valid(shell.world_host))
	assert(shell.world_host.process_mode==Node.PROCESS_MODE_PAUSABLE)
	assert(not shell.audio_manager.suspended and shell.save_notice.visible)
	shell.cancel_overlay()
	assert(not paused)
	var position:Vector2=shell.arena.player.position
	Input.action_press("move_down")
	for i in 10:await physics_frame
	Input.action_release("move_down")
	assert(shell.arena.player.position.distance_to(position)>1)
	shell.coordinator.saver=valid
	print("DEV508_WRITE_FAILURE_CONTINUE_RETRY_PASS")
	shell.request_exit();shell.request_exit()
