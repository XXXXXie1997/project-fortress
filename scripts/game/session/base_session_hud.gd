extends "res://scripts/ui/combat_hud.gd"
var loss_warning:=Label.new()
var warning_rules:=DefenseResolution.new()
func _ready():
	super._ready()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	charge_title.position = Vector2(950, 680)
	charge_title.text = "仓库附近无线充能 · R 持续插电充能"
	loss_warning.position=Vector2(365,100)
	loss_warning.size=Vector2(550,60)
	loss_warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	loss_warning.mouse_filter=Control.MOUSE_FILTER_IGNORE
	loss_warning.add_theme_color_override("font_color",Color("#ffb07b"))
	loss_warning.add_theme_font_size_override("font_size",22)
	loss_warning.add_theme_color_override("font_shadow_color",Color.BLACK)
	loss_warning.add_theme_constant_override("shadow_offset_x",2)
	loss_warning.add_theme_constant_override("shadow_offset_y",2)
	add_child(loss_warning);loss_warning.hide()
func _process(delta):
	super._process(delta)
	var shell=arena.session_context.shell
	var covered:bool=shell.interface_open()
	# Keep the inventory and its children alive/visible; only suppress ambient HUD.
	for element in [label,card,quick,weapon_icon,tactical_icon,task_tracker,charge_title]:
		element.visible=not covered
	arena.status_label.visible=false
	charge_title.visible=false
	arena.management.presentation_obscured=shell.panel.visible or arena.player.progression_panel.visible
	var warning:Dictionary=warning_rules.warning_state(arena.state)
	loss_warning.visible=warning.visible and not covered
	loss_warning.text="基地危急：损毁已达失守阈值" if warning.threshold_reached else "基地危急：接近失守"
	loss_warning.text+="\n请保护核心设施；准备阶段可修复废墟"
func _input(event):
	if arena.session_context.shell.panel.visible:
		if event.is_action_pressed("cancel") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_P and arena.session_context.shell.overlay_mode=="player"): arena.session_context.shell.cancel_overlay()
		if event is InputEventKey or event is InputEventAction: get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("cancel"):
		if inventory_panel != null and inventory_panel.visible:
			inventory_panel.close_panel()
		elif arena.player.progression_panel.visible: arena.player.progression_panel.handle_input(event)
		elif arena.management.is_modal_open(): return
		elif arena.management.root_panel.visible: arena.management.root_panel.hide()
		elif not arena.placing_type.is_empty(): arena.placing_type = ""; arena.moving_id = ""
		else: arena.session_context.shell.show_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not opened and not arena.session_context.shell.near_candidate().is_empty():
		arena.session_context.shell.show_candidate(arena.session_context.shell.near_candidate())
		get_viewport().set_input_as_handled()
		return
	super._input(event)

