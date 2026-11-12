extends SceneTree
const Rules=preload('res://scripts/game/aim_camera_rules.gd')
var errors:=0
func ck(ok:bool,label:String):
 if not ok:errors+=1;push_error(label)
 else:print('PASS ',label)
func frames(n:=3):
 for i in range(n):await physics_frame
func _initialize():call_deferred('run')
func run():
 for viewport_size in [Vector2(1280,720),Vector2(960,540),Vector2(1920,1080)]:
  for cursor in [Vector2(0,0),Vector2(330,220),viewport_size]:
   for zoom in [1.0,.75]:
    var offset:Vector2=Rules.camera_offset(cursor,viewport_size,zoom,true)
    ck((offset-(offset+(cursor-viewport_size*.5)/zoom)*.5).length()<.001,'解析中点 '+str(viewport_size)+' / '+str(zoom))
 root.size=Vector2i(1280,720)
 var a=load('res://scripts/game/combat_arena.gd').new();root.add_child(a);await frames(5)
 a.weapons=JSON.parse_string(FileAccess.get_file_as_string('res://data/content/weapons.json')).weapons
 var gun:Dictionary=a.inventory.spawn(a.state,'sniper_basic','ground');a.inventory.equip(a.state,gun.id,'weapon_3',true);a.player.slot=3
 Input.action_press('aim');await frames()
 ck(a.player.camera.zoom==Vector2(.75,.75),'狙击实际相机扩大视野')
 var center:Vector2=a.player.camera.get_screen_center_position()
 ck(center.distance_to((a.player.global_position+a.player.get_global_mouse_position())*.5)<.01,'活相机实际鼠标反投影中点')
 Input.action_press('move_right');await frames(10);Input.action_release('move_right')
 center=a.player.camera.get_screen_center_position()
 ck(center.distance_to((a.player.global_position+a.player.get_global_mouse_position())*.5)<.01,'移动同帧实际中点稳定')
 a.hud.opened=true;await frames();ck(a.player.camera.zoom==Vector2.ONE and a.player.camera.position==Vector2.ZERO,'UI阻断复位')
 a.hud.opened=false;a.player.slot=1;await frames();ck(a.player.camera.zoom==Vector2.ONE,'切普通枪复位')
 a.player.slot=2;await frames();ck(a.player.camera.zoom==Vector2.ONE,'切近战复位')
 a.player.slot=3;await frames();Input.action_release('aim');await frames();ck(a.player.camera.zoom==Vector2.ONE,'松开瞄准复位')
 print('DEV507 HEADLESS ERRORS ',errors);quit(1 if errors else 0)
