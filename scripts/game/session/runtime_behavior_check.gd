extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var shell = load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell); shell.tutorial_enabled = false
	shell.coordinator.saver = SaveService.new("user://runtime-behavior-%s" % Time.get_ticks_usec())
	assert(shell.coordinator.create_world(50).ok)
	while shell.arena == null or shell.mounting or shell.mount_queued: await process_frame
	assert(shell.coordinator.depart("suburbs","south").ok)
	shell.queue_mount()
	while shell.mounting or shell.mount_queued: await process_frame
	var gun: String = shell.coordinator.state.player.equipment.weapon_1
	var battery := ""
	for item: Dictionary in shell.coordinator.services.inventory.items_in(shell.coordinator.state,"bag"):
		if item.is_battery: battery = item.id; break
	shell.arena.player.selected_charge_battery = battery
	shell.arena.player.selected_charge_target = gun
	shell.coordinator.state.player.combat.charging = true
	shell.coordinator.state.player.vitals.hp = 60.0
	DamageRules.start_heal(shell.arena.player.heals,{"cast_time":3.0,"instant":10.0,"duration":4.0,"rate":2.0})
	var bullet = load("res://scripts/game/projectile.gd").new()
	bullet.arena = shell.arena; bullet.position = shell.arena.player.position; bullet.direction = Vector2.UP; bullet.speed = 50.0; bullet.lifetime = 5.0
	shell.arena.add_child(bullet)
	shell.show_pause()
	assert(shell.coordinator.shutdown().ok)
	var captured: Dictionary = shell.coordinator.state.session.runtime.duplicate(true)
	assert(captured.projectiles.size() == 1)
	var total: float = shell.coordinator.state.items[gun].energy + shell.coordinator.state.items[battery].energy
	assert(shell.coordinator.restore().ok)
	while shell.mounting or shell.mount_queued: await process_frame
	var bullets: Array = shell.arena.get_children().filter(func(child): return child.get_script() == load("res://scripts/game/projectile.gd"))
	assert(bullets.size() == 1)
	assert(bullets[0].lifetime <= 5.0 and bullets[0].lifetime > 4.8)
	assert(shell.arena.player.heals.size() == 1)
	assert(shell.arena.player.heals[0].remaining_cast <= 3.0 and shell.arena.player.heals[0].remaining_cast > 2.8)
	for frame in 8: await physics_frame
	assert(shell.coordinator.state.items[gun].energy > 0)
	assert(is_equal_approx(total,shell.coordinator.state.items[gun].energy + shell.coordinator.state.items[battery].energy))
	shell.show_pause()
	await process_frame
	var energy: float = shell.coordinator.state.items[gun].energy
	var cast: float = shell.arena.player.heals[0].remaining_cast
	var starts: int = shell.audio_manager.charge_starts
	for frame in 10: await process_frame
	assert(shell.coordinator.state.items[gun].energy == energy)
	assert(shell.arena.player.heals[0].remaining_cast == cast)
	assert(shell.audio_manager.charge_loop.stream_paused)
	assert(shell.audio_manager.charge_starts == starts)
	assert(shell.coordinator.shutdown().ok)
	print("SESSION_RUNTIME_PROJECTILE_HEAL_CHARGE_PAUSE_PASS")
	shell.audio_manager.shutdown_audio()
	await create_timer(0.1,true).timeout
	quit()
