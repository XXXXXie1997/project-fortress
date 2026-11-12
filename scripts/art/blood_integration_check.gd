extends SceneTree
var sounds:Array=[]
func _initialize():call_deferred('run')
func stop_sim(a):
 a.set_physics_process(false);a.player.set_physics_process(false)
 for e in a.targets:e.set_physics_process(false)
func capture(name:String):
 for i in 3:await process_frame
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/art/integration/ART-107-'+name+'.png')
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 while not a.ready_world:await process_frame
 assert(await a.depart('suburbs','south'))
 for i in 3:await physics_frame
 stop_sim(a)
 var e=a.targets[1];var id:String=e.enemy_id;var p:Vector2=e.position
 a.player.position=p+Vector2(60,80)
 a.hit(e,10000,{'penetration':10000})
 assert(a.blood_visual.stains.size()==1)
 await capture('live-death')
 var dead:Dictionary=a.state.expedition.maps.suburbs.enemies[id]
 var baseline:String=WorldState.encode(a.state)
 a.hit(e,10000,{'penetration':10000})
 assert(WorldState.encode(a.state)==baseline)
 a.clear_map_effects()
 for enemy in a.targets:enemy.queue_free()
 a.targets.clear();await process_frame
 a.spawn_enemy(dead);a.spawn_enemy(dead)
 assert(a.targets.is_empty() and a.blood_visual.corpses.size()==1)
 assert(WorldState.encode(a.state)==baseline)
 await capture('restored')
 # Real serialized state roundtrip; pure presentation reconstruction must not write it.
 var file:=FileAccess.open('user://art107-check.json',FileAccess.WRITE);file.store_string(baseline);file.close()
 a.state=WorldState.decode(FileAccess.get_file_as_string('user://art107-check.json'))
 assert(not a.state.is_empty())
 baseline=WorldState.encode(a.state)
 a.clear_map_effects();a.spawn_enemy(a.state.expedition.maps.suburbs.enemies[id])
 assert(WorldState.encode(a.state)==baseline and a.targets.is_empty())
 # Real exit service cross-map and return; all dead restoration stays read-only.
 for destination in ['armory','suburbs']:
  var exit_id:=''
  for key in a.catalog[a.state.expedition.map_id].points:
   var item:Dictionary=a.catalog[a.state.expedition.map_id].points[key]
   if item.kind=='exit' and item.target_map==destination:exit_id=key
  assert(not exit_id.is_empty());assert(a.exploration.exit_map(a.state,exit_id))
  a.clear_map_effects();await a.rebuild_map()
  if destination=='suburbs':
   var before:String=WorldState.encode(a.state)
   a.spawn_enemy(a.state.expedition.maps.suburbs.enemies[id]);assert(WorldState.encode(a.state)==before)
 assert(a.blood_visual.corpses.size()==1 and a.targets.is_empty())
 a.player.position=p+Vector2(60,80);await capture('roundtrip')
 # Passive blood underneath existing roof; occluded from outside, visible inside.
 var room:Dictionary=a.logical_catalog.suburbs.rooms[0]
 var rect:=Rect2(room.rect[0],room.rect[1],room.rect[2],room.rect[3]);var center:Vector2=a.projection.logical_to_world(rect.get_center())
 a.blood_layer().restore_dead('roof-check',center,'basic')
 a.player.position=a.projection.logical_to_world(rect.position-Vector2(100,100));await capture('roof-outside')
 assert(not a.blood_visual.corpses['roof-check'].visible)
 a.player.position=center+Vector2(0,25);await capture('roof-inside')
 assert(a.blood_visual.corpses['roof-check'].visible)
 # scene pause freezes effect time; scene cleanup discards all nodes.
 a.blood_visual.show_hit(2,center);paused=true
 var age:float=a.blood_visual.bursts.back().age
 await create_timer(.3,true).timeout
 assert(a.blood_visual.bursts.back().age==age);paused=false
 await create_timer(.3).timeout;assert(a.blood_visual.bursts.is_empty())
 a.clear_map_effects();assert(a.blood_visual.corpses.is_empty() and a.blood_visual.stains.is_empty())
 a.queue_free();await process_frame
 print('PASS exploration real HP/death; repeat reward/state equality; serialized read; cross-map return; roof visibility; pause/cleanup')
 quit()
