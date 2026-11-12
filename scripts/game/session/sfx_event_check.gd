extends SceneTree
var events:Array[String]=[]
func _initialize():call_deferred("run")
func tap(action:String):
	for pressed in [true,false]:
		var e:=InputEventAction.new();e.action=action;e.pressed=pressed;Input.parse_input_event(e)
func run():
	var shell=load("res://scenes/game/session/session_shell.tscn").instantiate()
	root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://sfx-events-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	shell.arena.management.root_panel.hide()
	for i in 3:await physics_frame
	shell.arena.presentation_sound.connect(func(event,_position,_spatial,_source):events.append(event))
	var player=shell.arena.player
	# Empty weapon input cannot emit a successful shot.
	Input.action_press("fire")
	for i in 3:await physics_frame
	Input.action_release("fire")
	assert(not events.has("shot_rifle"))
	tap("charge")
	for i in 90:await physics_frame
	tap("charge")
	var energy:float=player.item().energy
	assert(energy>0)
	Input.action_press("fire")
	for i in 2:await physics_frame
	Input.action_release("fire")
	assert(events.count("shot_rifle")==1 and player.item().energy<energy)
	assert(shell.audio_manager.sfx.last.has("shot_rifle:player"))
	tap("dodge")
	for i in 3:await physics_frame
	print("SFX_DODGE events=",events," action=",shell.coordinator.state.player.combat," blocked=",player.progression_ui_blocked," hud=",shell.arena.hud.opened)
	assert(events.count("dodge")==1)
	tap("dodge")
	for i in 3:await physics_frame
	assert(events.count("dodge")==1)
	tap("weapon_next")
	for i in 3:await physics_frame
	assert(events.count("weapon_switch")==1)
	for i in 40:await physics_frame
	Input.action_press("fire")
	for i in 2:await physics_frame
	Input.action_release("fire")
	assert(events.count("melee_swing")==1)
	var hurt:Dictionary=player.receive_attack({"damage":50,"penetration":100})
	assert(hurt.hp_loss>0 and events.count("hit_health")==1 and events.count("hit_armor")==0)
	Input.action_press("move_down")
	for i in 25:await physics_frame
	Input.action_release("move_down")
	assert(events.has("footstep"))
	assert(shell.coordinator.depart("suburbs","south").ok)
	shell.queue_mount()
	while shell.mounting or shell.mount_queued:await process_frame
	shell.arena.presentation_sound.connect(func(event,_position,_spatial,_source):events.append(event))
	var enemy=shell.arena.targets[0]
	var hits:=events.count("hit_enemy")
	var melee_hits:=events.count("melee_hit")
	shell.arena.hit(enemy,1,{"sfx_melee":true})
	assert(events.count("melee_hit")==melee_hits+1 and events.count("hit_enemy")==hits)
	shell.arena.player.tactical.explode(shell.arena.player.position+Vector2(300,0))
	assert(events.count("explosion")==1)
	shell.audio_manager.levels.effects=0.0;shell.audio_manager.apply_levels()
	assert(not shell.audio_manager.sfx.emit_event("shot_rifle"))
	for voice in shell.audio_manager.sfx.voices:assert(not voice.playing)
	assert(not shell.audio_manager.music.playing and not shell.audio_manager.ambience.playing)
	assert(shell.coordinator.shutdown().ok)
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout
	assert(not shell.audio_manager.sfx.loop.playing)
	print("SESSION_EXACT_SFX_ACTIONS_PASS")
	quit()
