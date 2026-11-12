extends SceneTree
func _initialize():
 var arena=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(arena)
 for i in 20:await physics_frame
 var player=arena.player
 player.set_physics_process(false)
 var turret:Node2D
 for fixture in arena.fixtures:
  if fixture.kind=='turret':turret=fixture
 var enemy:=StaticBody2D.new();enemy.collision_layer=4;enemy.position=arena.grid.logical_to_world(Vector2(1450,750))
 var cs:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=15;cs.shape=circle;enemy.add_child(cs);arena.add_child(enemy)
 await physics_frame
 for dodging in [false,true]:
  arena.state.player.combat.dodge_left=2.0 if dodging else 0.0
  arena.state.player.combat.dodge_direction=[1,0]
  player._physics_process(0.0)
  assert(player.collision_mask==(41 if dodging else 45))
  var start:Vector2=turret.position+Vector2(-160,0)
  assert(player.test_move(Transform2D(0,start),Vector2(160,0)))
  player.position=start;player.velocity=Vector2(200,0)
  for i in 48:
   await physics_frame
   player.move_and_slide()
  assert(player.position.distance_to(turret.position)>30)
  var wall_start:Vector2=arena.grid.logical_to_world(Vector2(1100,200))
  assert(player.test_move(Transform2D(0,wall_start),arena.grid.logical_vector_to_world(Vector2(100,0))))
  var shield_start:Vector2=arena.grid.logical_to_world(arena.gate_logical-Vector2(70,0))
  var travel:Vector2=arena.grid.logical_vector_to_world(Vector2(140,0))
  assert(not player.test_move(Transform2D(0,shield_start),travel))
  assert(not player.test_move(Transform2D(0,shield_start+travel),-travel))
  player.position=shield_start;player.velocity=travel.normalized()*180
  for i in 60:
   await physics_frame
   player.move_and_slide()
  assert(arena.grid.world_to_logical(player.position).x>arena.gate_logical.x)
  var enemy_start:Vector2=enemy.position-Vector2(70,0)
  assert(player.test_move(Transform2D(0,enemy_start),Vector2(140,0))==not dodging)
 print('DEV402 PLAYER NORMAL/DODGE BUILDING WALL SHIELD ENEMY PASS')
 quit()
