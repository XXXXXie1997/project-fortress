extends SceneTree
func _initialize():call_deferred("run")
func run():
	var shell=load("res://scenes/game/session/session_shell.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://ending-overlay-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	shell.arena.player.progression_panel.open_view("quests",true)
	# Fixture for modal lifecycle only; real quest completion is evidenced by R5 GUI.
	shell.coordinator.state.quests.ending="contact_restored"
	for i in 4:await process_frame
	assert(shell.panel.visible and not shell.arena.player.progression_panel.visible)
	assert(shell.arena.player.progression_ui_blocked)
	for child in shell.rows.get_children():
		if child is Button and child.text=="继续生存":child.pressed.emit()
	assert(not shell.panel.visible and not shell.arena.player.progression_ui_blocked)
	assert(shell.coordinator.shutdown().ok)
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout
	print("SESSION_ENDING_CLOSES_OLD_MODAL_PASS")
	quit()
