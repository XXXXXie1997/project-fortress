extends SceneTree
func _initialize():call_deferred('run')
func run():
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 for i in range(6):await physics_frame
 await a.depart('suburbs','south')
 for i in range(5):await physics_frame
 var q:=PhysicsRayQueryParameters2D.create(Vector2(-577,1174.79),Vector2(-480,1176),9)
 var hit=a.get_world_2d().direct_space_state.intersect_ray(q)
 print('BLOCKER ',hit)
 for t in a.targets: t.collision_layer=0;t.set_physics_process(false)
 a.player.position=Vector2(-577,1174.79)
 Input.action_press('move_right')
 for i in range(120):await physics_frame
 Input.action_release('move_right')
 print('NO ENEMIES RIGHT END ',a.player.position)
 if not hit.is_empty():
  print('BODY ',hit.collider.get_path())
  for c in hit.collider.get_children():
   if c is CollisionPolygon2D: print('POLYGON ',c.polygon,' BODY_POSITION ',hit.collider.position)
 quit()

