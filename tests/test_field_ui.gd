extends SceneTree

const Kit = preload("res://scripts/ui/keeper_theme.gd")
var shell

func _initialize():
	call_deferred("run")

func mounted():
	while shell.arena == null or shell.mounting or shell.mount_queued:
		await process_frame
	for frame in 6:
		await physics_frame

func tap(action: String):
	for down in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func run():
	root.size = Vector2i(1280,720)
	for glyph in [Kit.STATION, Kit.BATTERY, Kit.CAPACITOR, Kit.HEART]:
		assert(Kit.pixel_font().has_char(glyph.unicode_at(0)), "Missing instrument glyph")
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	shell.tutorial_enabled = false
	shell.coordinator.saver = SaveService.new("user://field-ui-%s" % Time.get_ticks_usec())
	assert(shell.coordinator.create_world(64).ok)
	await mounted()
	assert(shell.coordinator.depart("suburbs","south").ok)
	shell.queue_mount()
	await mounted()
	var hud = shell.arena.hud
	await tap("map")
	assert(hud.full_map and hud.map_view.is_visible_in_tree())
	assert(not hud.label.is_visible_in_tree())
	await tap("cancel")
	assert(not hud.full_map and hud.label.is_visible_in_tree())
	assert(not shell.panel.visible)
	hud.open_inventory()
	await tap("map")
	assert(hud.inventory_panel.visible and not hud.full_map)
	shell.audio_manager.shutdown_audio()
	print("FIELD_UI_GLYPHS_MAP_VISIBILITY_MODAL_PASS")
	quit()
