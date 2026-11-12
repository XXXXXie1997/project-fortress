extends SceneTree
func _initialize():call_deferred("run")
func run():
	var shell=load("res://scenes/game/session/session_shell.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://plugin-boundary-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	shell.arena.management.root_panel.hide()
	var actor=shell.arena.player
	actor.position=shell.arena.station+Vector2(24,55)
	var id:String=shell.arena.inventory.spawn(shell.coordinator.state,"tactical_light","warehouse",1).id
	assert(not id.is_empty())
	for i in 3:await physics_frame
	var before:Dictionary=actor.item().plugins.duplicate(true)
	for pressed in [true,false]:
		var e:=InputEventAction.new();e.action="interact";e.pressed=pressed;Input.parse_input_event(e)
		await process_frame
	for i in 3:await physics_frame
	print("FORMAL_F plugins_before=",before," after=",actor.item().plugins," selected_container=",shell.coordinator.state.items[id].container_id)
	if "--reproduce" not in OS.get_cmdline_user_args():
		assert(actor.item().plugins==before)
		var encoded:=WorldState.encode(shell.coordinator.state)
		assert(not actor.tactical.install_fixture_plugin(id))
		actor.tactical.install_next_fixture()
		assert(WorldState.encode(shell.coordinator.state)==encoded)
		actor.tactical.fixture_shortcuts_enabled=true
		for location in ["bag","warehouse","ground","shop"]:
			var plugin:Dictionary=shell.arena.inventory.spawn(shell.coordinator.state,"tactical_light",location,1)
			assert(not plugin.is_empty())
			encoded=WorldState.encode(shell.coordinator.state)
			assert(not actor.tactical.install_fixture_plugin(plugin.id))
			actor.tactical.install_next_fixture()
			assert(WorldState.encode(shell.coordinator.state)==encoded)
		var station:=""
		for b in shell.coordinator.state.base.buildings.values():
			if b.type=="workstation":station=b.id
		var gun:String=actor.item().id
		assert(shell.coordinator.services.workstation.modify(shell.coordinator.state,station,gun,"install",id))
		encoded=WorldState.encode(shell.coordinator.state)
		assert(not actor.tactical.install_fixture_plugin(id))
		assert(WorldState.encode(shell.coordinator.state)==encoded)
		assert(shell.coordinator.services.workstation.modify(shell.coordinator.state,station,gun,"uninstall","tactical"))
		assert(shell.coordinator.state.items[id].container_id=="warehouse")
		assert(shell.coordinator.depart("suburbs","south").ok);shell.queue_mount()
		while shell.mounting or shell.mount_queued:await process_frame
		actor=shell.arena.player;actor.tactical.fixture_shortcuts_enabled=true
		encoded=WorldState.encode(shell.coordinator.state)
		assert(not actor.tactical.install_fixture_plugin(id));actor.tactical.install_next_fixture()
		assert(WorldState.encode(shell.coordinator.state)==encoded)
		# Explicit opt-in is necessary even in a standalone fixture.
		var saved_context:Dictionary=actor.arena.session_context
		actor.arena.session_context={}
		actor.tactical.fixture_shortcuts_enabled=false
		assert(not actor.tactical.fixture_shortcuts_allowed())
		actor.tactical.fixture_shortcuts_enabled=true
		assert(actor.tactical.fixture_shortcuts_allowed())
		actor.arena.session_context=saved_context
		print("FORMAL_PLUGIN_BOUNDARY_PASS")
	assert(shell.coordinator.shutdown().ok)
	shell.audio_manager.shutdown_audio();await create_timer(.1,true).timeout
	quit()

