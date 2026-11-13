extends "res://scripts/world/maps/map_hud.gd"
func _ready():
	super._ready()
	process_mode = Node.PROCESS_MODE_PAUSABLE
func _input(event):
	if arena.session_context.shell.panel.visible:
		if event.is_action_pressed("cancel") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_P and arena.session_context.shell.overlay_mode=="player"): arena.session_context.shell.cancel_overlay()
		if event is InputEventKey or event is InputEventAction: get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel") and not menu.visible and not full_map and (inventory_panel == null or not inventory_panel.visible) and not arena.player.progression_panel.visible:
		arena.session_context.shell.show_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not opened and not arena.session_context.shell.near_candidate().is_empty():
		arena.session_context.shell.show_candidate(arena.session_context.shell.near_candidate())
		get_viewport().set_input_as_handled()
		return
	super._input(event)

func _process(delta):
	super._process(delta)
	quest_list.visible = not arena.session_context.shell.interface_open() and not menu.visible and not full_map
	var phase: String = {"morning":"清晨","day":"白天","dusk":"黄昏","night":"夜晚"}.get(arena.state.phase,"当前阶段")
	label.text='生命 %.0f / %.0f'%[arena.state.player.vitals.hp,arena.state.player.vitals.max_hp]
