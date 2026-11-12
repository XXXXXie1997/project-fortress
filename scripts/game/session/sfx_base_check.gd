extends SceneTree
var heard:Dictionary={}
func _initialize():call_deferred("run")
func run():
	# Existing defense fixture provides residents/turrets; not normal starting content.
	var arena=load("res://scenes/base/base_defense.tscn").instantiate();root.add_child(arena)
	var sound=load("res://scripts/game/session/session_audio.gd").new();root.add_child(sound)
	arena.presentation_sound.connect(sound.receive_event)
	arena.presentation_sound.connect(func(event,_point,spatial,id):
		if event in ["shot_rifle","charge_in"]:
			assert(spatial and id!="player")
			heard[id+":"+event]=int(heard.get(id+":"+event,0))+1)
	for i in 10:await physics_frame
	arena.start_fixture_wave()
	for i in 900:
		sound.sfx.set_listener(arena.player.position)
		await physics_frame
	# Fixture turret is far from the normal gate. Position a living test target
	# in its clear firing lane; do not call fire or alter weapon energy/damage.
	for fixture in arena.fixtures:
		if fixture.kind!="turret":continue
		for enemy in arena.targets:
			if enemy.record().vitals.hp<=0:continue
			for offset in [Vector2(180,0),Vector2(-180,0),Vector2(0,180),Vector2(0,-180)]:
				if arena.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(fixture.position,fixture.position+offset,33)).is_empty():
					enemy.position=fixture.position+offset;break
			break
	for i in 30:await physics_frame
	var resident_shots:=0
	var turret_shots:=0
	for resident in arena.residents:resident_shots+=int(heard.get(resident.id+":shot_rifle",0))
	for fixture in arena.fixtures:
		if fixture.kind=="turret":turret_shots+=int(heard.get(fixture.id+":shot_rifle",0))
	print("BASE_SFX observed=",heard," resident=",resident_shots," turret=",turret_shots)
	assert(resident_shots>0 and turret_shots>0)
	assert(not sound.sfx.charging and sound.charge_starts==0)
	sound.shutdown_audio();await create_timer(.1,true).timeout
	print("SESSION_RESIDENT_TURRET_SPATIAL_SFX_PASS resident=",resident_shots," turret=",turret_shots)
	quit()
