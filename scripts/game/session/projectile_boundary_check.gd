extends SceneTree
func _initialize():call_deferred("run")
func run():
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
	shell.coordinator.saver=SaveService.new("user://wall-boundary-%s"%Time.get_ticks_usec())
	assert(shell.coordinator.create_world(11).ok)
	while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
	assert(shell.coordinator.depart("suburbs","south").ok);shell.queue_mount()
	while shell.mounting or shell.mount_queued:await process_frame
	var arena=shell.arena
	assert(not arena.state.world.has("combat_targets"))
	for target in arena.targets:target.set_physics_process(false)
	var wall:StaticBody2D
	for child in arena.geometry.get_children():
		if child is StaticBody2D:wall=child;break
	assert(wall!=null)
	var shape:CollisionPolygon2D=wall.get_child(0)
	var bounds:=Rect2(wall.to_global(shape.polygon[0]),Vector2.ZERO)
	for point in shape.polygon:bounds=bounds.expand(wall.to_global(point))
	var start:=bounds.get_center()-Vector2(bounds.size.x*.5+30,0)
	var finish:=bounds.get_center()+Vector2(bounds.size.x*.5+30,0)
	var contact:Dictionary=arena.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start,finish,1))
	assert(not contact.is_empty())
	start=contact.position-Vector2(20,0)
	# Real physics projectile in the formal world; no fixture target dictionary.
	var bullet=load("res://scripts/game/projectile.gd").new()
	bullet.arena=arena;bullet.position=start;bullet.direction=start.direction_to(finish)
	arena.add_child(bullet)
	for i in 30:await physics_frame
	assert(not is_instance_valid(bullet))
	assert(not arena.state.world.has("combat_targets"))
	print("FORMAL_WALL_PROJECTILE_DESTROYED_PASS")
	# Actual player fire input uses energy transferred from a real carried battery.
	arena.player.position=start-Vector2(45,0)
	assert(ChargingService.charge_weapon(arena.state,arena.player.item().id,10)>0)
	for i in 5:
		var motion:=InputEventMouseMotion.new();motion.position=arena.get_canvas_transform()*finish;motion.global_position=motion.position;Input.parse_input_event(motion)
		await physics_frame
	var power:float=arena.player.item().energy
	Input.action_press("fire")
	for i in 2:await physics_frame
	Input.action_release("fire")
	for i in 20:await physics_frame
	assert(arena.player.item().energy<power)
	assert(not arena.state.world.has("combat_targets"))
	print("FORMAL_PLAYER_FIRE_AT_WALL_PASS")
	var obstacles:Array=[]
	if not arena.geometry.doors.is_empty():obstacles.append(arena.geometry.doors.values()[0])
	for child in arena.geometry.get_children():
		if child is StaticBody2D and child.position.distance_to(arena.projection.logical_to_world(Vector2(arena.catalog.suburbs.trees[0][0]+8,arena.catalog.suburbs.trees[0][1]+8)))<1:obstacles.append(child)
	assert(obstacles.size()==2)
	for obstacle in obstacles:
		var polygon:CollisionPolygon2D=obstacle.get_child(0)
		var center:=Vector2.ZERO
		for point in polygon.polygon:center+=obstacle.to_global(point)/polygon.polygon.size()
		var ray:Dictionary=arena.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(center-Vector2(100,0),center,1))
		assert(not ray.is_empty())
		var shot=load("res://scripts/game/projectile.gd").new();shot.arena=arena;shot.position=ray.position-Vector2(20,0);shot.direction=Vector2.RIGHT;arena.add_child(shot)
		for i in 8:await physics_frame
		assert(not is_instance_valid(shot))
	var victim=arena.targets[0]
	arena.player.position=Vector2(400,400)
	victim.position=Vector2(470,400)
	for i in 3:await physics_frame
	var hp:float=victim.record().vitals.hp
	print("ENEMY_PROBE hp=",hp," layer=",victim.collision_layer," ray=",arena.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(victim.position-Vector2(victim.spec.radius+20,0),victim.position+Vector2(30,0),13)))
	var shot=load("res://scripts/game/projectile.gd").new();shot.arena=arena;shot.position=victim.position-Vector2(victim.spec.radius+20,0);shot.direction=Vector2.RIGHT;shot.attack={"penetration":100};arena.add_child(shot)
	for i in 8:await physics_frame
	print("ENEMY_AFTER alive_bullet=",is_instance_valid(shot)," hp=",victim.record().vitals.hp)
	assert(not is_instance_valid(shot) and victim.record().vitals.hp<hp)
	var after:float=victim.record().vitals.hp
	for i in 8:await physics_frame
	assert(victim.record().vitals.hp==after)
	print("FORMAL_DOOR_TREE_ENEMY_ONCE_PASS")
	var fixture=load("res://scripts/game/combat_arena.gd").new();fixture.position=Vector2(4000,0);root.add_child(fixture)
	for i in 5:await physics_frame
	fixture.player.set_physics_process(false)
	var target=fixture.targets[0]
	var target_hp:float=fixture.state.world.combat_targets[str(target.name)].vitals.hp
	var fixture_shot=load("res://scripts/game/projectile.gd").new();fixture_shot.arena=fixture;fixture_shot.position=target.position-Vector2(35,0);fixture_shot.direction=Vector2.RIGHT;fixture.add_child(fixture_shot)
	for i in 8:await physics_frame
	assert(not is_instance_valid(fixture_shot) and fixture.state.world.combat_targets[str(target.name)].vitals.hp<target_hp)
	fixture.queue_free();await process_frame
	print("EXPLICIT_FIXTURE_TARGET_HIT_PASS")
	shell.request_exit()
