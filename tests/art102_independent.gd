extends SceneTree
func _initialize():call_deferred('run')
func run():
 var gallery=load('res://scenes/art/actor_gallery.tscn').instantiate();root.add_child(gallery)
 await process_frame
 var hero=gallery.hero;gallery.set_process(false)
 var failures=0
 for direction in range(4):
  hero.fixed_direction=direction;hero.moving=true;hero.aim=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][direction]
  for i in range(12):await process_frame
  var old=hero.body.frame
  await create_timer(0.17).timeout
  var ok=hero.body.frame/4==direction and hero.body.frame!=old and hero.pivot.z_index==(-1 if direction==3 else 1)
  print('ART direction ',direction,' ',ok)
  if not ok:failures+=1
 for weapon in range(6):
  hero.weapon_index=weapon;hero.charging=true;hero.dodging=true
  for i in range(4):await process_frame
  var ok=hero.weapon.frame==(weapon if weapon<3 else weapon+1) and hero.battery.visible==(weapon<3) and hero.body.rotation!=0
  print('ART weapon/charge/dodge ',weapon,' ',ok)
  if not ok:failures+=1
 for attachment in range(3):
  hero.weapon_index=0;hero.attachment_index=attachment
  for i in range(3):await process_frame
  if hero.attachment.frame!=8+attachment:failures+=1
 hero.fixed_direction=2;hero.aim=Vector2.RIGHT
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/ART102-independent-dynamic.png')
 print('ART FAILURES ',failures);quit(failures)
