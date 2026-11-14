extends Node
# Separate entry while the production bootstrap remains frozen.
const Coordinator = preload("res://scripts/game/session/session_coordinator.gd")
var coordinator
var overlay: CanvasLayer
var panel: PanelContainer
var rows: VBoxContainer
var status: Label
var slot_picker: OptionButton
var world_host: Node
var mount_world: Callable
var arena: Node2D
var mounting := false
var mount_queued := false
var save_notice: HBoxContainer
var save_notice_text: Label
var phase_actions:Array[Callable]=[]
var phases: VBoxContainer
var phase_signature := ""
var autosave_elapsed := 0.0
var observed_inventory: InventoryPanel
var overlay_mode := "start"
var selected_slot := "slot_1"
var audio_manager
var preferences := ConfigFile.new()
var tutorial_enabled := true
var tutorial_page := 0
var tutorial_return := "game"
var exiting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputBindings.install()
	coordinator = Coordinator.new()
	audio_manager = preload("res://scripts/game/session/session_audio.gd").new()
	add_child(audio_manager)
	preferences.load("user://session-settings.cfg")
	for key in audio_manager.levels: audio_manager.levels[key] = preferences.get_value("audio", key, audio_manager.levels[key])
	audio_manager.apply_levels()
	mount_world = Callable(self, "queue_mount")
	coordinator.world_replaced.connect(_world_replaced)
	coordinator.save_error.connect(_save_error)
	coordinator.committed.connect(func(_revision): audio_manager.click())
	world_host = Node.new()
	world_host.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world_host)
	overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	panel = PanelContainer.new()
	panel.position = Vector2(390, 70)
	panel.custom_minimum_size = Vector2(480, 480)
	overlay.add_child(panel)
	panel.visibility_changed.connect(_overlay_visibility)
	save_notice = HBoxContainer.new()
	save_notice.position = Vector2(250, 20)
	overlay.add_child(save_notice)
	save_notice.visibility_changed.connect(_overlay_visibility)
	save_notice_text = Label.new(); save_notice.add_child(save_notice_text)
	var retry := Button.new(); retry.text = "重试保存"; save_notice.add_child(retry)
	retry.pressed.connect(func():
		if coordinator.shutdown().ok: save_notice.hide())
	save_notice.hide()
	phases = VBoxContainer.new(); phases.position = Vector2(1022, 438);phases.custom_minimum_size=Vector2(224,184); overlay.add_child(phases)
	var shortcuts=preload("res://scripts/ui/action_shortcuts.gd").new();shortcuts.shell=self;overlay.add_child(shortcuts)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	panel.add_child(rows)
	show_start()
	get_tree().auto_accept_quit = false

func clear(title: String) -> void:
	panel.position=Vector2(56,44) if overlay_mode!="start" else Vector2(390,70)
	panel.custom_minimum_size=Vector2(1168,632) if overlay_mode!="start" else Vector2(480,480)
	panel.size=panel.custom_minimum_size
	call_deferred("_arrange_reference_overlay")
	panel.theme=preload("res://scripts/ui/wasteland_theme.gd").get_theme() if overlay_mode!="start" else null
	panel.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST if overlay_mode!="start" else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	if overlay_mode!="start":
		var frame=preload("res://scripts/ui/wasteland_theme.gd").box("panel_normal").duplicate()
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:frame.set_content_margin(side,24)
		panel.add_theme_stylebox_override("panel",frame)
	else:panel.remove_theme_stylebox_override("panel")
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	panel.show()
	if is_instance_valid(arena) and is_instance_valid(arena.player): arena.player.progression_ui_blocked = true
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 28)
	rows.add_child(label)

func button(label: String, action: Callable) -> void:
	var control := Button.new()
	control.text = label
	control.custom_minimum_size.y = 40
	control.pressed.connect(action)
	rows.add_child(control)

func message_line() -> void:
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(450, 64)
	rows.add_child(status)

func show_start() -> void:
	overlay_mode = "start"
	get_tree().paused = true
	clear("幸存者基地")
	slot_picker = OptionButton.new()
	for n in 3: slot_picker.add_item("存档栏位 %d" % (n + 1))
	slot_picker.select(clampi(int(selected_slot.trim_prefix("slot_")) - 1, 0, 2))
	slot_picker.item_selected.connect(func(index: int): selected_slot = "slot_%d" % (index + 1))
	rows.add_child(slot_picker)
	button("继续当前栏位", func(): report(load_selected(false)))
	button("开始新过程", confirm_new)
	button("退出游戏", request_exit)
	button("设置与帮助", show_settings)
	message_line()

func confirm_new() -> void:
	clear("建立新过程")
	var explanation := Label.new()
	explanation.text = "将覆盖所选栏位的最新进度。\n清晨回退和继承请在失守界面选择。"
	rows.add_child(explanation)
	button("确认新建", func(): report(load_selected(true)))
	button("取消", show_start)
	message_line()

func _world_replaced() -> void:
	if mount_world.is_valid():
		mount_world.call()
		panel.hide()
		get_tree().paused = false
	else:
		# Keep a truthful development boundary until the shared lifecycle is installed.
		clear("会话数据已加载")
		button("保存并返回开始菜单", func():
			if coordinator.shutdown().ok: show_start())
		message_line()
		status.text = "场景生命周期接线进行中，此独立入口尚不是完整游戏。"

func show_pause() -> void:
	overlay_mode = "pause"
	get_tree().paused = true
	clear("游戏已暂停")
	button("继续游戏", func(): panel.hide(); get_tree().paused = false)
	button("保存进度", func(): report(coordinator.shutdown()))
	button("设置与帮助", show_settings)
	button("保存并退出", request_exit)
	var options:=VBoxContainer.new();rows.add_child(options)
	var settings_title:=Label.new();settings_title.text="操作与声音";settings_title.add_theme_font_size_override("font_size",28);options.add_child(settings_title)
	var sprint:=CheckButton.new();sprint.text="Shift冲刺：切换式";sprint.button_pressed=bool(preferences.get_value("controls","sprint_toggle",false));options.add_child(sprint)
	sprint.toggled.connect(func(enabled):preferences.set_value("controls","sprint_toggle",enabled);arena.hud.sprint_toggle=enabled;save_preferences())
	for key in audio_manager.levels:
		var caption:=Label.new();caption.text={"effects":"基础音效","ambience":"环境音量","music":"背景音乐"}.get(key,key);options.add_child(caption)
		var slider:=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=0.05;slider.value=audio_manager.levels[key];options.add_child(slider)
		slider.value_changed.connect(func(value):audio_manager.levels[key]=value;audio_manager.apply_levels();preferences.set_value("audio",key,value);save_preferences())
	message_line()

func show_failure() -> void:
	overlay_mode = "failure"
	get_tree().paused = true
	clear("基地失守")
	for entry in [["重新开始", "new"], ["重新开始＋", "plus"], ["回到最后有效存档", "latest"], ["回到当天早晨", "morning"]]:
		button(entry[0], func(): report(coordinator.failure_choice(entry[1], int(Time.get_unix_time_from_system()))))
	message_line()

func report(result: Dictionary) -> void:
	if is_instance_valid(status): status.text = "操作完成" if result.get("ok", false) else "操作失败：%s" % result.get("reason", result.get("error", "未满足条件"))

func _save_error(_result: Dictionary) -> void:
	if is_instance_valid(status): status.text = "保存失败，可重试或取消退出继续游玩。"
	save_notice_text.text = "进度尚未保存到磁盘"
	save_notice.show()

func request_exit() -> void:
	if exiting:return
	exiting=true
	var previous_mode:=world_host.process_mode
	world_host.process_mode=Node.PROCESS_MODE_DISABLED
	var result: Dictionary = coordinator.shutdown()
	if result.ok:
		audio_manager.shutdown_audio()
		# Save captured the live effects before teardown. Free their owners instead
		# of allowing gameplay to advance during a fixed audio grace period.
		world_host.queue_free()
		audio_manager.queue_free()
		# Retain the existing bounded audio drain; the world is already disabled.
		await get_tree().create_timer(0.1,true).timeout
		get_tree().quit()
	else:
		world_host.process_mode=previous_mode
		exiting=false
		show_pause()
		_save_error(result)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: request_exit()

func _process(delta: float) -> void:
	if exiting:return
	if coordinator != null: coordinator.tick(delta)
	if is_instance_valid(arena) and not mounting and not mount_queued:
		update_audio_context()
		autosave_elapsed += delta if not get_tree().paused else 0.0
		if autosave_elapsed >= float(preload("res://scripts/content/catalog.gd").read("scripts/game/session/session_config.json").autosave_seconds):
			autosave_elapsed = 0.0
			coordinator.request_save()
		if arena.hud.inventory_panel != null and arena.hud.inventory_panel != observed_inventory:
			observed_inventory = arena.hud.inventory_panel
			observed_inventory.visibility_changed.connect(func():
				if is_instance_valid(observed_inventory) and not observed_inventory.visible and not mounting: coordinator.request_save())
		var signature: String = str(coordinator.state.day) + coordinator.state.phase + str(coordinator.state.session.location)
		if signature != phase_signature:
			phase_signature = signature
			refresh_phase_controls()
		if coordinator.state.quests.get("ending", "") == "contact_restored" and not coordinator.state.session.get("ending_seen",false):
			coordinator.state.session.ending_seen = true
			arena.player.progression_panel.close()
			overlay_mode = "stage"
			clear("已恢复与外界的联系")
			var ending := Label.new(); ending.text = "信号已成功发出。你仍可继续经营基地、探索与守夜。"; ending.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; ending.custom_minimum_size.x=450; rows.add_child(ending)
			button("继续生存", func():panel.hide())
			message_line()
			coordinator.request_save()
	phases.visible = not interface_open() and not mounting and not coordinator.state.is_empty() and coordinator.state.session.location == "base" and coordinator.state.phase in ["morning", "dusk"]

# Presentation only: never hide a CanvasLayer that owns an active inventory.
func interface_open() -> bool:
	if panel.visible: return true
	if not is_instance_valid(arena): return false
	if is_instance_valid(arena.hud) and arena.hud.get("full_map")==true:return true
	var management = arena.get("management")
	if management != null and management.presentation_open(): return true
	if is_instance_valid(arena.hud) and arena.hud.inventory_panel != null and arena.hud.inventory_panel.visible: return true
	return is_instance_valid(arena.player) and is_instance_valid(arena.player.progression_panel) and arena.player.progression_panel.visible

func queue_mount() -> void:
	if mount_queued: return
	mount_queued = true
	coordinator.capture_runtime = Callable()
	if is_instance_valid(arena): arena.process_mode = Node.PROCESS_MODE_DISABLED
	call_deferred("mount_current")

func mount_current() -> void:
	if mounting: return
	mounting = true
	audio_manager.shutdown_audio()
	mount_queued = false
	coordinator.capture_runtime = Callable()
	observed_inventory = null
	if is_instance_valid(arena):
		if is_instance_valid(arena.hud) and arena.hud.inventory_panel != null: arena.hud.inventory_panel.close_panel()
		if is_instance_valid(arena.player) and is_instance_valid(arena.player.progression_panel): arena.player.progression_panel.close()
		arena.process_mode = Node.PROCESS_MODE_DISABLED
		world_host.remove_child(arena)
		arena.queue_free()
	if coordinator.state.get("cycle", {}).get("failed", false):
		mounting = false
		show_failure()
		return
	var path := "res://scripts/world/maps/map_arena.gd" if coordinator.state.session.location == "exploration" else "res://scripts/ui/base/base_management_arena.gd"
	var resource: Script = load(path)
	if resource == null or not resource.can_instantiate():
		mount_error("场景脚本无法加载")
		return
	arena = resource.new()
	arena.session_context = {"coordinator": coordinator, "shell": self, "ready": false}
	world_host.add_child(arena)
	var frames := 0
	while not arena.session_context.ready and frames < 600:
		await get_tree().process_frame
		frames += 1
	if not arena.session_context.ready:
		mount_error("场景初始化失败或超时；进度仍保留，可重试")
		return
	coordinator.capture_runtime = func(state: Dictionary): preload("res://scripts/game/session/runtime_snapshot.gd").capture(arena, state)
	arena.presentation_sound.connect(audio_manager.receive_event)
	arena.hud.sprint_toggle = bool(preferences.get_value("controls", "sprint_toggle", false))
	arena.player.progression_panel.committed.connect(func(_revision): coordinator.request_save())
	mounting = false
	phase_signature = ""
	panel.hide()
	get_tree().paused = false
	coordinator.request_save()
	audio_manager.resume_audio()
	audio_manager.set_charge(bool(coordinator.state.player.combat.charging),get_tree().paused,true)
	if coordinator.state.phase == "night" and coordinator.state.cycle.night.get("mode", "") == "rest":
		var resolution: Dictionary = coordinator.finish_night()
		if resolution.ok: queue_mount()
		else: mount_error("自动守夜结算未成功，保留当前进度以供重试。")
		return
	update_audio_context()
	if tutorial_enabled:
		var completed: Dictionary = coordinator.saver.load_tutorial()
		if not completed.get("ok",false) or not "basics_v1" in completed.state.get("completed",[]): show_tutorial(0)

func phase_button(label: String, action: Callable) -> void:
	var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if phases.get_child_count()>0:
		phase_actions.append(action)
		var icon:=TextureRect.new();var atlas:=AtlasTexture.new();atlas.atlas=load("res://assets/runtime/ui/action_icons.png");atlas.region=Rect2(120,0,24,24)
		icon.visible=false;icon.texture=atlas;icon.custom_minimum_size=Vector2(24,24);icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
	var caption:=Label.new();caption.text=("[F%d] "%phase_actions.size() if phases.get_child_count()>0 else "")+label;caption.add_theme_font_size_override("font_size",16);row.custom_minimum_size.y=24;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(caption)
	phases.add_child(row)

func refresh_phase_controls() -> void:
	phase_actions.clear()
	for child in phases.get_children(): phases.remove_child(child); child.queue_free()
	phase_button("第 %d 天 · %s" % [coordinator.state.day, "清晨" if coordinator.state.phase == "morning" else "黄昏"], func(): pass)
	if coordinator.state.phase == "morning":
		phase_button("白天出发", func(): show_departures(false))
		phase_button("留在基地至黄昏", func(): report(coordinator.to_dusk()))
	else:
		phase_button("亲自守夜", func():
			if coordinator.begin_night("manual").ok: queue_mount())
		phase_button("自动休息", func(): confirm_night("rest"))
		phase_button("夜间探索", func(): show_departures(true))
	phase_button("遗物与地面箱", show_base_containers)
	phase_button("补充基地护盾", func():
		report(coordinator.transact(func(trial: Dictionary) -> Dictionary:
			if not coordinator.services.building.preparation(trial): return {"ok":false}
			return {"ok": EnergyService.transfer(trial.base.energy_store,trial.base.shield,trial.base.shield.capacity) > 0})))
	if not coordinator.state.cycle.pending_loot.is_empty(): phase_button("领取守夜战利品", show_night_loot)

	preload("res://scripts/ui/hud_backdrop.gd").attach(phases)

func show_departures(night: bool) -> void:
	overlay_mode = "stage"
	clear("选择夜探地点" if night else "选择出发地点")
	for id: String in coordinator.state.world.exploration.unlocked:
		var map: Dictionary = coordinator.services.exploration.maps[id]
		for point: String in coordinator.state.world.exploration.spawns[id]:
			button("%s · %s" % [map.title, map.points[point].get("label", point)], func():
				if night: confirm_night("explore", id, point)
				elif coordinator.depart(id, point).ok: queue_mount())
	button("取消", func(): panel.hide())
	message_line()

func confirm_night(mode: String, map_id := "", point := "") -> void:
	overlay_mode = "stage"
	clear("夜间行动确认")
	var snapshot: Dictionary = coordinator.services.cycle.defense.capture(coordinator.state, coordinator.services.cycle.threat.strength(coordinator.state), "preview")
	var assessment: Dictionary = coordinator.services.cycle.defense.evaluate(snapshot)
	var info := Label.new(); info.text = "防守评估：%s\n弱势行动可能导致基地失守。" % {"weak":"劣势","advantage":"优势","critical":"临界"}.get(assessment.rating,"临界"); rows.add_child(info)
	button("确认行动", func():
		var result: Dictionary = coordinator.begin_night(mode, true, map_id, point)
		if result.ok and mode == "rest": result = coordinator.finish_night()
		if result.ok: queue_mount()
		else: report(result))
	button("取消", func(): panel.hide())
	message_line()

func _overlay_visibility() -> void:
	if not is_instance_valid(arena) or not is_instance_valid(arena.player): return
	arena.player.progression_ui_blocked = panel.visible or (is_instance_valid(arena.player.progression_panel) and arena.player.progression_panel.visible)
	# Pause freezes management processing, so suppress its feedback synchronously.
	var management = arena.get("management")
	if management != null:
		management.feedback_obscured = panel.visible or save_notice.visible
		management.message.visible = not management.feedback_obscured and not management.inventory_panel.visible and not arena.player.progression_panel.visible
	if not panel.visible: arena.player.progression_pointer_guard = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func cancel_overlay() -> void:
	if overlay_mode in ["stage", "pause", "player"]:
		panel.hide()
		get_tree().paused = false

func mount_error(reason: String) -> void:
	mounting = false
	if is_instance_valid(arena): arena.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = true
	clear("场景加载失败")
	button("重试加载当前进度", queue_mount)
	button("返回开始菜单", show_start)
	message_line()
	status.text = reason

func load_selected(new_game: bool) -> Dictionary:
	# The picker is a pending choice, never the destination of the live world's saves.
	if not coordinator.state.is_empty():
		var saved: Dictionary = coordinator.shutdown()
		if not saved.ok: return saved
	var previous_slot: String = coordinator.slot
	coordinator.slot = selected_slot
	var result: Dictionary = coordinator.create_world(int(Time.get_unix_time_from_system())) if new_game else coordinator.restore()
	if not result.ok: coordinator.slot = previous_slot
	return result

func show_base_containers() -> void:
	overlay_mode = "stage"
	clear("基地遗物与地面物品")
	for id: String in coordinator.state.containers:
		if id != "ground" and not id.begins_with("relics_"): continue
		var count: int = coordinator.services.inventory.items_in(coordinator.state,id).size()
		button(("前代幸存者遗物" if id.begins_with("relics_") else "基地地面箱") + " · %d 件" % count, func():
			panel.hide()
			var inventory: InventoryPanel = arena.management.inventory_panel
			inventory.at_base = true
			inventory.bind_external_container(id, func(): return coordinator.state.session.location == "base")
			inventory.open_panel())
	button("关闭", func(): panel.hide())
	message_line()

func show_night_loot() -> void:
	overlay_mode = "stage"
	clear("守夜战利品")
	for id: String in coordinator.state.cycle.pending_loot:
		button("领取一份守夜战利品", func():
			var result: Dictionary = coordinator.transact(func(trial: Dictionary) -> Dictionary: return {"ok": coordinator.services.cycle.claim_loot(trial,id)})
			if result.ok: show_night_loot()
			else: status.text = "仓库空间不足，战利品仍保留，可腾出空间后再领。")
	button("关闭", func(): panel.hide())
	message_line()

func near_candidate() -> String:
	if not is_instance_valid(arena): return ""
	for child in arena.get_children():
		if child.get_script() == preload("res://scripts/game/session/survivor_encounter.gd") and child.visible and child.position.distance_to(arena.player.position) < 70:
			var candidate: Dictionary = coordinator.state.world.recruitment.candidates.get(child.candidate_id,{})
			if not candidate.is_empty() and not candidate.accepted and arena.clear_line(arena.player.position,child.position,41): return child.candidate_id
	return ""

func show_candidate(id: String) -> void:
	overlay_mode = "stage"
	var candidate: Dictionary = coordinator.state.world.recruitment.candidates[id]
	clear(candidate.name)
	var description := Label.new()
	description.text = "生命上限 %d · 防守能力 %d\n免费邀请加入基地；满员时不会消耗此机会。" % [candidate.hp,candidate.power]
	rows.add_child(description)
	button("邀请加入基地", func():
		if near_candidate() != id: status.text = "请靠近这位幸存者再交谈。"; return
		var result: Dictionary = coordinator.transact(func(trial: Dictionary) -> Dictionary: return coordinator.services.recruitment.accept(trial,id,coordinator.services.inventory))
		if result.ok:
			panel.hide()
			if coordinator.state.session.location == "base": queue_mount()
		else: status.text = "基地满员或此人已加入，未重复招募。")
	button("暂不邀请", func(): panel.hide())
	message_line()

func show_settings() -> void:
	get_tree().paused = true
	overlay_mode = "settings"
	clear("设置与帮助")
	var sprint := CheckButton.new(); sprint.text = "Shift 冲刺改为按一下切换"
	sprint.button_pressed = bool(preferences.get_value("controls","sprint_toggle",false))
	sprint.toggled.connect(func(enabled):
		preferences.set_value("controls","sprint_toggle",enabled)
		if is_instance_valid(arena): arena.hud.sprint_toggle = enabled
		save_preferences())
	rows.add_child(sprint)
	for key: String in audio_manager.levels:
		if key != "effects": continue
		var line := Label.new(); line.text = {"music":"配乐音量","ambience":"环境音量","effects":"音效音量"}[key]; rows.add_child(line)
		var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = 0.05; slider.value = audio_manager.levels[key]
		slider.value_changed.connect(func(value):
			audio_manager.levels[key] = value; audio_manager.apply_levels()
			preferences.set_value("audio",key,value); save_preferences())
		rows.add_child(slider)
	button("回看分页教学", func(): tutorial_return = "settings"; show_tutorial(0))
	button("重置教学完成记录", func(): report(coordinator.saver.reset_tutorial()))
	button("返回", func():
		if coordinator.state.is_empty(): show_start()
		else: show_pause())
	message_line()

func save_preferences() -> void:
	if preferences.save("user://session-settings.cfg") != OK:
		if is_instance_valid(status): status.text = "设置保存失败；当前会话仍按所选值运行。"

func show_tutorial(page: int) -> void:
	get_tree().paused = true
	overlay_mode = "tutorial"
	tutorial_page = page
	var config: Dictionary = preload("res://scripts/content/catalog.gd").read("scripts/game/session/tutorial.json")
	var entry: Dictionary = config.pages[page]
	clear("教学 %d / %d · %s" % [page+1,config.pages.size(),entry.title])
	var illustration:=preload("res://scripts/ui/reference_layout.gd").tutorial_diagram(page)
	rows.add_child(illustration)
	var body := Label.new(); body.text = entry.body; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(450,160); rows.add_child(body)
	if page > 0: button("上一页", func(): show_tutorial(page-1))
	if page+1 < config.pages.size(): button("下一页", func(): show_tutorial(page+1))
	else: button("开始游玩" if tutorial_return == "game" else "完成教学", finish_tutorial)
	message_line()

func finish_tutorial() -> void:
	var previous: Dictionary = coordinator.saver.load_tutorial()
	var completed: Array = previous.state.get("completed",[]) if previous.get("ok",false) else []
	if not "basics_v1" in completed: completed.append("basics_v1")
	var result: Dictionary = coordinator.saver.save_tutorial(completed)
	if not result.ok: report(result); return
	if tutorial_return == "settings": tutorial_return = "game"; show_settings()
	else: panel.hide(); get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_cancel"):
		cancel_overlay()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not coordinator.state.is_empty():
		show_pause()
		get_viewport().set_input_as_handled()

func update_audio_context() -> void:
	audio_manager.set_charge(bool(coordinator.state.player.combat.charging),get_tree().paused)
	var context := "field" if coordinator.state.session.location == "exploration" else "base"
	if context == "base" and coordinator.state.phase == "night" and float(coordinator.state.base.get("wave_plan",{}).get("budget",0)) >= 20.0:
		context = "battle"
	elif context == "field":
		for enemy in arena.targets:
			if enemy.kind == "boss" and enemy.record().get("alerted",false) and enemy.record().vitals.hp > 0 and enemy.position.distance_to(arena.player.position) < 600:
				context = "battle"; break
	audio_manager.play_context(context)
	audio_manager.sfx.set_listener(arena.player.global_position)

# Keyboard-first HUD: mouse remains an aiming device until a panel is opened.
func _input(event:InputEvent):
	if not event is InputEventKey or not event.pressed or event.echo:return
	if not is_instance_valid(arena) or mounting:return
	if panel.visible:
		if overlay_mode=="player" and event.physical_keycode==KEY_P:
			cancel_overlay();get_viewport().set_input_as_handled()
		return
	if interface_open():return
	if event.physical_keycode==KEY_P:
		overlay_mode="player";clear("玩家信息")
		var info:=Label.new()
		var player:Dictionary=coordinator.state.player
		info.text="生命 %.0f / %.0f\n\n关闭此面板后：Tab 查看背包与装备\nT 查看天赋成长\n\n[P] / [Esc] 返回"%[player.vitals.hp,player.vitals.max_hp]
		rows.add_child(info);get_viewport().set_input_as_handled()
	elif event.physical_keycode>=KEY_F1 and event.physical_keycode<=KEY_F6 and phases.visible:
		var index:int=event.physical_keycode-KEY_F1
		if index<phase_actions.size():phase_actions[index].call()
		get_viewport().set_input_as_handled()

func _arrange_reference_overlay():
	preload("res://scripts/ui/reference_layout.gd").session(rows,overlay_mode)
