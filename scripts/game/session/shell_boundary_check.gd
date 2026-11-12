extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var shell = load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell)
	shell.coordinator.saver = SaveService.new("user://shell-boundary-%s" % Time.get_ticks_usec())
	assert(shell.coordinator.create_world(3).ok)
	while shell.arena == null or shell.mounting or shell.mount_queued: await process_frame
	shell.coordinator.state.session.owner_probe = "slot_one_only"
	shell.show_start()
	shell.selected_slot = "slot_2"
	shell.confirm_new()
	shell.show_start()
	assert(shell.slot_picker.selected == 1)
	assert(shell.coordinator.slot == "slot_1")
	assert(not shell.load_selected(false).ok)
	assert(shell.coordinator.slot == "slot_1")
	assert(shell.coordinator.shutdown().ok)
	assert(not shell.coordinator.saver.load_snapshot("slot_2").ok)
	assert(shell.coordinator.saver.load_snapshot("slot_1").state.session.owner_probe == "slot_one_only")
	shell.panel.hide()
	shell._save_error({"ok":false})
	assert(shell.save_notice.is_visible_in_tree())
	assert(not shell.panel.visible)
	print("SESSION_SLOT_CANCEL_FAILURE_ISOLATION_PASS")
	quit()
