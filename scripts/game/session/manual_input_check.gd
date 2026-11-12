extends SceneTree
var shell
func _initialize(): call_deferred("run")
func run():
	shell = load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell); shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://manual-input-%s" % Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena == null or shell.mounting or shell.mount_queued: await process_frame
	# Real preparation: close construction UI, walk beside the live warehouse,
	# and let normal wireless physics spend base energy. No state injection.
	shell.arena.management.root_panel.hide()
	var starting_position:Vector2=shell.arena.player.position
	await walk_to(shell.arena.station+Vector2(24,60))
	for frame in 240:await physics_frame
	await walk_to(starting_position)
	var prepared_energy:=carried_energy()
	print("MANUAL_PREPARED energy=",prepared_energy," base=",shell.coordinator.state.base.get("energy",{}))
	await click("留在基地至黄昏")
	await click("亲自守夜")
	while shell.mounting or shell.mount_queued: await process_frame
	var frames:=0
	while shell.coordinator.state.phase=="night" and not shell.coordinator.state.cycle.failed and frames<4200:
		frames+=1
		if shell.mounting or shell.mount_queued: await physics_frame; continue
		var player=shell.arena.player
		var weapon:Dictionary=player.item()
		if weapon.definition_id=="rifle_basic" and carried_energy()<5:
			tap("weapon_next")
			weapon=player.item()
		var melee:bool=weapon.get("definition_id","")=="knife_basic"
		var target=null
		var distance:=INF
		for enemy in shell.arena.targets:
			if enemy.record().vitals.hp<=0:continue
			var d:float=player.position.distance_to(enemy.position)
			if d<distance:distance=d;target=enemy
		if target!=null:
			var mouse:=InputEventMouseMotion.new();mouse.position=shell.arena.get_canvas_transform()*target.position;mouse.global_position=mouse.position;Input.parse_input_event(mouse)
		if not melee and weapon.energy<5 and not shell.coordinator.state.player.combat.charging:tap("charge")
		if shell.coordinator.state.player.vitals.hp<65 and player.heals.is_empty():tap("quick_1")
		var can_see:bool=target!=null and shell.arena.clear_line(player.position,target.position,41)
		if target!=null and can_see and distance<400 and not shell.coordinator.state.player.combat.charging:Input.action_press("fire")
		else:Input.action_release("fire")
		var escape:=Vector2.ZERO
		if target!=null and (not can_see or distance>(40 if melee else 350)):escape=shell.arena.walk_direction(player.position,target.position)
		elif not melee and target!=null and distance<130:
			escape=target.position.direction_to(player.position)
			if not shell.arena.clear_line(player.position,player.position+escape*90,33):
				escape=escape.orthogonal()
				if not shell.arena.clear_line(player.position,player.position+escape*90,33):escape=-escape
		move(escape)
		if escape==Vector2.ZERO:Input.action_press("aim")
		else:Input.action_release("aim")
		if target!=null and distance<95 and frames%30==0:tap("dodge")
		await physics_frame
	Input.action_release("fire");Input.action_release("aim");move(Vector2.ZERO)
	print("MANUAL_INPUT_RESULT frames=",frames," day=",shell.coordinator.state.day," failed=",shell.coordinator.state.cycle.failed," hp=",shell.coordinator.state.player.vitals.hp)
	assert(shell.coordinator.state.day==2 and not shell.coordinator.state.cycle.failed)
	assert(shell.coordinator.state.session.last_night.manual_complete and not shell.coordinator.state.session.last_night.downed)
	for enemy:Dictionary in shell.coordinator.state.expedition.maps.base.enemies.values():assert(enemy.ai.vitals.hp<=0)
	assert(shell.coordinator.state.expedition.maps.base.enemies.size()==shell.coordinator.state.base.wave_plan.entries.size())
	var remaining_energy:=0.0
	for item:Dictionary in shell.coordinator.state.items.values():
		if item.container_id in ["bag","equipment"]:remaining_energy+=float(item.energy)
	assert(remaining_energy<prepared_energy)
	while shell.mounting or shell.mount_queued:await process_frame
	assert(shell.coordinator.shutdown().ok)
	print("SESSION_MANUAL_REAL_PROJECTILES_PASS")
	shell.audio_manager.shutdown_audio();await create_timer(0.1,true).timeout
	quit()

func carried_energy()->float:
	var energy:=0.0
	for item:Dictionary in shell.coordinator.state.items.values():
		if item.container_id in ["bag","equipment"]:energy+=float(item.energy)
	return energy
func tap(action:String):
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action=action;event.pressed=pressed;Input.parse_input_event(event)
func move(direction:Vector2):
	for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
	if direction.x<-.15:Input.action_press("move_left",absf(direction.x))
	if direction.x>.15:Input.action_press("move_right",direction.x)
	if direction.y<-.15:Input.action_press("move_up",absf(direction.y))
	if direction.y>.15:Input.action_press("move_down",direction.y)
func walk_to(goal:Vector2):
	var frames:=0
	while shell.arena.player.position.distance_to(goal)>15 and frames<1200:
		move(shell.arena.walk_direction(shell.arena.player.position,goal))
		frames+=1;await physics_frame
	move(Vector2.ZERO)
	assert(shell.arena.player.position.distance_to(goal)<=15,"Preparation route unreachable")

func button_in(node:Node,prefix:String)->Button:
	if node is Button and node.text.begins_with(prefix) and node.is_visible_in_tree():return node
	for child in node.get_children():
		var found:=button_in(child,prefix)
		if found!=null:return found
	return null
func click(prefix:String):
	for frame in 3:await process_frame
	var button:=button_in(shell,prefix);assert(button!=null)
	var point:=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed;Input.parse_input_event(event)
		await process_frame
