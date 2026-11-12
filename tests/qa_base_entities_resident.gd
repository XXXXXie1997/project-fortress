extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.start_wave();a.queue.clear();a.spawn_timer=999
 var p=a.grid.logical_to_world(Vector2(1600,700));var d={'id':'hold','type':'basic','position':[p.x,p.y]}
 a.state.expedition.maps.base.enemies.hold=d.duplicate(true);a.spawn_enemy(d)
 a.targets[0].set_physics_process(false);a.player.set_physics_process(false)
 var r=a.residents[0];var arrived=false;var returned=false;var maxx=0.0
 var dest=a.station+a.grid.logical_vector_to_world(Vector2(0,90))
 for i in 1800:
  await physics_frame
  maxx=max(maxx,a.grid.world_to_logical(r.position).x)
  if r.position.distance_to(dest)<13:arrived=true
  if arrived and not r.returning and r.position.distance_to(r.post)<13:returned=true;break
 print('QA_RESIDENT_TRIP arrived=',arrived,' returned=',returned,' max_logical_x=',maxx,' energy=',a.state.items[r.data().weapon_instance].energy)
 assert(arrived and returned and maxx<=1115)
 quit()
