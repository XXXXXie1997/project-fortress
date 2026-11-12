extends SceneTree
var shots:=0
func _initialize():call_deferred("run")
func run():
	var arena=load("res://scenes/base/base_defense.tscn").instantiate();root.add_child(arena)
	for i in 10:await physics_frame
	arena.start_fixture_wave()
	for i in 60:await physics_frame
	var turret
	for fixture in arena.fixtures:
		if fixture.kind=="turret":turret=fixture
	for child in arena.get_children():child.set_physics_process(false)
	arena.set_physics_process(false);turret.set_physics_process(true)
	var enemy=arena.targets[0]
	enemy.position=turret.position+Vector2(180,0)
	assert(arena.nearest_enemy(turret.position,360)!=null)
	turret.data().capacitor={"energy":0.0,"capacity":60.0}
	turret.cooldown=0.0
	arena.presentation_sound.connect(func(event,_pos,_spatial,id):
		if id==turret.id and event=="shot_rifle":shots+=1)
	var initial:float=arena.state.base.energy_store.energy
	for i in 12:
		await physics_frame
		print("TURRET_FRAME ",i," cap=",turret.data().capacitor.energy," shots=",shots)
	if "--reproduce" not in OS.get_cmdline_user_args():
		assert(shots==0)
		var remaining:float=arena.state.base.energy_store.energy
		arena.state.base.energy_store.energy=0.0
		var cap:float=turret.data().capacitor.energy
		for i in 8:await physics_frame
		assert(turret.data().capacitor.energy==cap and shots==0)
		arena.state.base.energy_store.energy=remaining
		var station:Dictionary={}
		for b in arena.state.base.buildings.values():
			if b.type=="warehouse":station=b;break
		var health:float=station.durability;station.durability=0.0
		for i in 8:await physics_frame
		assert(turret.data().capacitor.energy==cap and shots==0)
		station.durability=health
		paused=true
		for i in 8:await process_frame
		assert(turret.data().capacitor.energy==cap and shots==0)
		paused=false
		arena.state.session={}
		var snapshot=preload("res://scripts/game/session/runtime_snapshot.gd")
		snapshot.capture(arena,arena.state)
		var encoded:=WorldState.encode(arena.state)
		var file:=FileAccess.open("user://turret-cycle-snapshot.json",FileAccess.WRITE)
		file.store_string(encoded);file.close()
		arena.state=JSON.parse_string(FileAccess.get_file_as_string("user://turret-cycle-snapshot.json"))
		snapshot.restore(arena,arena.state)
		assert(turret.data().capacitor.charging)
		while turret.data().capacitor.energy<60:
			assert(shots==0)
			await physics_frame
		for i in 4:await physics_frame
		assert(shots>0 and not turret.data().capacitor.charging)
		assert(is_equal_approx(initial,arena.state.base.energy_store.energy+turret.data().capacitor.energy+shots))
		print("TURRET_FULL_CYCLE_RESTORE_PASS")
	quit()
