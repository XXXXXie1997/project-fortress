extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var shell = load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell)
	shell.coordinator.saver = SaveService.new("user://session-injection-%s" % Time.get_ticks_usec())
	assert(shell.coordinator.create_world(25).ok)
	while shell.arena == null or shell.mounting or shell.mount_queued: await process_frame
	assert(shell.arena.state == shell.coordinator.state)
	assert(shell.coordinator.state.base.residents.is_empty())
	assert(shell.coordinator.state.base.buildings.size() == 6)
	assert(shell.coordinator.services.inventory.items_in(shell.coordinator.state, "ground").is_empty())
	var id_count: int = shell.coordinator.state.next_id
	var spawn_id: String = shell.coordinator.services.exploration.maps.suburbs.initial_spawn
	assert(shell.coordinator.depart("suburbs", spawn_id).ok)
	shell.queue_mount()
	while shell.mounting or shell.mount_queued: await process_frame
	assert(shell.arena.state.expedition.active)
	shell.arena.player.position = Vector2(420, 310)
	shell.arena.player.cooldown = 0.7
	shell.arena.process_mode = Node.PROCESS_MODE_DISABLED
	assert(shell.coordinator.shutdown().ok)
	var captured: Dictionary = shell.coordinator.state.session.runtime.duplicate(true)
	assert(shell.coordinator.restore().ok)
	while shell.mounting or shell.mount_queued: await process_frame
	assert(shell.arena.player.position.distance_to(Vector2(420,310)) < 2)
	assert(shell.arena.player.cooldown > 0.5)
	assert(shell.coordinator.state.session.runtime.player.position == captured.player.position)
	assert(shell.coordinator.finish_exploration(true,[420,310]).ok)
	shell.queue_mount()
	while shell.mounting or shell.mount_queued: await process_frame
	assert(shell.arena.state.phase == "dusk")
	assert(shell.arena.state.base.residents.is_empty())
	assert(shell.arena.state.base.buildings.size() == 6)
	assert(shell.arena.state.next_id > id_count) # only actual expedition loot allocated IDs
	assert(shell.coordinator.shutdown().ok)
	print("SESSION_REAL_WORLD_INJECTION_PASS")
	quit()
