extends SceneTree
var a
var errors:=0
func _initialize():call_deferred('run')
func frames(n:=8):
 for i in range(n):await physics_frame
func ck(ok:bool,s:String):
 print(('PASS ' if ok else 'FAIL ')+s)
 if not ok:errors+=1
func snap(s:String):
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/DEV-203-'+s+'.png')
func run():
 root.size=Vector2i(1280,720);a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a);await frames()
 await a.depart('suburbs','south');await frames()
 var seeds:Dictionary={}
 for box in a.state.expedition.maps.suburbs.containers.values():
  for item in a.inventory.items_in(a.state,box.container_id):
   if item.definition_id.begins_with('seed_'):seeds[item.definition_id]=true
 ck(seeds.has('seed_material') and seeds.has('seed_catalyst'),'both actual seed instances spawn')
 a.player.position=a.projection.logical_to_world(Vector2(1240,1120));await frames();await snap('qa-outside')
 var roof=a.geometry.roofs[0]
 a.player.position=a.projection.logical_to_world(roof.rect.get_center());await frames();await snap('qa-inside')
 ck(roof.node.modulate.a<0.1,'entered roof fades')
 for enemy in a.targets:ck(enemy.visible==a.enemy_visible_to_player(enemy),'actor visibility equals minimap predicate '+enemy.enemy_id)
 var dead=a.targets[0];var id:String=dead.enemy_id;a.hit(dead,100000,{'penetration':100})
 var projectile=load('res://scripts/game/projectile.gd').new();projectile.arena=a;projectile.position=a.player.position;projectile.speed=0;a.add_child(projectile)
 a.exploration.exit_map(a.state,'armory_road');await a.rebuild_map();await frames()
 ck(not is_instance_valid(projectile),'old projectile removed on transition')
 a.player.position=a.projection.logical_to_world(Vector2(1000,970));await snap('qa-armory')
 a.exploration.exit_map(a.state,'road');await a.rebuild_map();await frames()
 ck(a.state.expedition.maps.suburbs.enemies[id].dead,'killed enemy remains dead across maps')
 a.exploration.unlock_map(a.state,'city');a.exploration.exit_map(a.state,'city_road');await a.rebuild_map();await frames()
 a.player.position=a.projection.logical_to_world(Vector2(1630,1050));await snap('qa-city')
 a.hud.full_map=true;a.hud.map_view.position=Vector2(240,70);a.hud.map_view.size=Vector2(800,560);await snap('qa-fullmap')
 ck(a.hud.map_view.map_point(a.player.position).x>=6,'minimap maps projected world point')
 print('QA RENDER ERRORS ',errors);quit(1 if errors else 0)
