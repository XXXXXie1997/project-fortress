extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.player.set_physics_process(false)
 var f=a.fixtures[0]
 for candidate in a.fixtures:
  if candidate.kind=='turret':f=candidate
 var p=f.position+Vector2(-160,0)
 a.player.position=p
 var hit=a.player.test_move(Transform2D(0,p),Vector2(160,0))
 print('QA_BUILDING_PLAYER blocked=',hit,' player_mask=',a.player.collision_mask,' building_layer=',f.collision_layer,' building=',f.kind)
 a.player.velocity=Vector2(200,0)
 for i in 48:
  await physics_frame
  a.player.move_and_slide()
 print('QA_BUILDING_PLAYER final_distance_to_center=',a.player.position.distance_to(f.position))
 quit(0 if hit else 1)

