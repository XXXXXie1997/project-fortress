extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 RenderingServer.set_default_clear_color(Color('263135'))
 var actors:Array=[]
 for row in 3:
  for direction in 4:
   var visual=load('res://scripts/art/survivor_visual.gd').new()
   visual.position=Vector2(240+direction*250,190+row*190)
   visual.scale=Vector2(3,3);visual.fixed_direction=direction
   visual.aim=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][direction]
   visual.charging=row==1;visual.dodging=row==2
   root.add_child(visual);actors.append(visual)
 var label:=Label.new();label.text='ART104 QA01 / DOWN   LEFT   RIGHT   UP\nRows: weapon / charging battery / dodge';label.position=Vector2(20,20);root.add_child(label)
 # Use the real resident ready path without running its unrelated arena simulation.
 var resident=load('res://scripts/base/actors/resident_actor.gd').new()
 resident.position=Vector2(70,400);root.add_child(resident);resident.set_physics_process(false)
 await create_timer(.24).timeout
 for visual in actors:
  assert(visual.pivot.z_index==0 and visual.body.z_index==0)
  assert(visual.pivot.get_index()==(0 if visual.fixed_direction==3 else 1))
  assert(visual.battery.visible==visual.charging)
  assert(visual.body.rotation!=0 if visual.dodging else visual.body.rotation==0)
 assert(resident.visual.get_script()==load('res://scripts/art/survivor_visual.gd'))
 assert(resident.visual.pivot.z_index==0)
 print('PASS 12 direction/state samples; battery/dodge/sibling order; actual resident ready reference')
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/art/integration/ART-104-QA01-layers.png')
 quit()

