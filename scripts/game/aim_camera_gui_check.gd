extends SceneTree
var a
var errors:=0
func ck(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:errors+=1
func frames(n:=4):
 for i in range(n):await process_frame
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a);await frames(10);await a.depart('suburbs','south');await frames()
 a.weapons=JSON.parse_string(FileAccess.get_file_as_string('res://data/content/weapons.json')).weapons
 var gun:Dictionary=a.inventory.spawn(a.state,'sniper_basic','ground');a.inventory.equip(a.state,gun.id,'weapon_3',true);a.player.slot=3
 for enemy in a.targets:enemy.set_physics_process(false)
 var target=a.targets[0]
 a.player.position=a.projection.logical_to_world(Vector2(1250,1150));target.position=a.player.position+Vector2(100,0)
 Input.action_press('aim')
 for cursor in [Vector2(700,350),Vector2(780,440),Vector2(580,290)]:
  Input.warp_mouse(cursor);await frames(8)
  var actual:Vector2=root.get_mouse_position();var world:Vector2=a.player.get_global_mouse_position();var center:Vector2=a.player.camera.get_screen_center_position()
  print('CURSOR ',actual,' WORLD ',world,' CENTER ',center)
  ck(center.distance_to((a.player.global_position+world)*.5)<.1,'实际鼠标反投影中点')
 ck(a.player.camera.zoom==Vector2(.75,.75),'正式武器狙击视野')
 a.ambient_brightness=.05;await frames();ck(not a.enemy_visible_to_player(target) and not target.visible,'黑暗实体/地图复合判定仍隐藏')
 a.ambient_brightness=1
 a.player.position=a.projection.logical_to_world(Vector2(1000,940));target.position=a.projection.logical_to_world(Vector2(1120,940));await frames();ck(not a.enemy_visible_to_player(target),'真实投影墙后目标不可见')
 a.player.position=a.projection.logical_to_world(Vector2(1250,1150))
 await frames();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://scenes/maps/DEV507-sniper.png')
 a.hud.open_inventory();await frames();ck(a.player.camera.zoom==Vector2.ONE,'实际库存组件阻断复位')
 a.hud.inventory_panel.close_panel();a.player.slot=1;await frames();ck(a.player.camera.zoom==Vector2.ONE,'切普通枪恢复')
 a.player.slot=3;await frames();Input.action_release('aim');await frames()
 a.state=WorldState.decode(WorldState.encode(a.state));await frames();ck(a.player.camera.zoom==Vector2.ONE,'状态恢复不保存旧zoom')
 print('DEV507 GUI ERRORS ',errors);quit(1 if errors else 0)
