extends SceneTree
var shell
func _initialize(): call_deferred("run")
func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix) and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var result := find_button(child, prefix)
		if result != null: return result
	return null
func click(prefix: String) -> void:
	await process_frame
	var button := find_button(shell, prefix)
	assert(button != null, prefix)
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.position = point; event.global_position = point; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
func mounted() -> void:
	while shell.arena == null or shell.mounting or shell.mount_queued: await process_frame
func run():
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	shell.coordinator.saver = SaveService.new("res://.godot-local/session-main-gui")
	if "--session-read" in OS.get_cmdline_user_args():
		await click("继续当前栏位")
		await mounted()
		assert(shell.coordinator.state.session.location == "exploration")
		assert(shell.arena.player.position.distance_to(Vector2(420,310)) < 2)
		assert(shell.arena.player.selected_charge_battery == shell.coordinator.state.session.probe_battery)
		assert(shell.arena.player.selected_charge_target == shell.coordinator.state.session.probe_gun)
		print("SESSION_MAIN_PROCESS_READ_PASS")
	else:
		assert(shell.coordinator.saver.reset_tutorial().ok)
		await click("开始新过程")
		await click("确认新建")
		await mounted()
		assert(shell.coordinator.state.base.residents.is_empty())
		for page in 3: await click("下一页")
		await click("开始游玩")
		await capture("main-base-preview")
		var gun: String = shell.coordinator.state.player.equipment.weapon_1
		shell.coordinator.state.items[gun].energy = 20.0
		await click("白天出发")
		var before: float = shell.coordinator.state.items[gun].energy
		Input.action_press("fire")
		for frame in 5: await physics_frame
		Input.action_release("fire")
		assert(shell.coordinator.state.items[gun].energy == before)
		await click("取消")
		assert(shell.coordinator.state.phase == "morning")
		await click("白天出发")
		await click("城郊")
		await mounted()
		assert(shell.coordinator.state.expedition.active)
		shell.arena.player.position = Vector2(420,310)
		var battery: String = ""
		for item in shell.coordinator.services.inventory.items_in(shell.coordinator.state,"bag"):
			if item.is_battery: battery = item.id; break
		shell.arena.player.selected_charge_battery = battery
		shell.arena.player.selected_charge_target = gun
		shell.coordinator.state.player.combat.charging = true
		shell.coordinator.state.session.probe_battery = battery
		shell.coordinator.state.session.probe_gun = gun
		# Freeze only via the real Esc menu before save, retaining action references.
		var esc := InputEventKey.new(); esc.keycode = KEY_ESCAPE; esc.pressed = true
		Input.parse_input_event(esc)
		await process_frame
		assert(paused)
		await click("保存进度")
		await capture("main-pause-preview")
		print("SESSION_MAIN_MOUSE_WRITE_PASS")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://scenes/game/session/main-session-preview.png")
	assert(shell.coordinator.shutdown().ok)
	quit()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://scenes/game/session/%s.png" % name)
