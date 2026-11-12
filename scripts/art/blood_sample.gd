extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720);RenderingServer.set_default_clear_color(Color('414c45'))
 var effects=load('res://scripts/art/blood_effects.gd').new();root.add_child(effects)
 for i in 4:
  var v=load('res://scripts/art/enemy_visual.gd').new();v.kind=['basic','fast','armored','ranged'][i];v.position=Vector2(300+i*210,390);v.action='dead';root.add_child(v)
  effects.show_death(str(i),v.position)
 var hero=load('res://scripts/art/survivor_visual.gd').new();hero.scale=Vector2(3,3);hero.position=Vector2(180,390);root.add_child(hero)
 effects.show_hit(0,hero.position);assert(effects.bursts.is_empty())
 for i in 100:effects.show_death('stress'+str(i),Vector2(-100,-100))
 assert(effects.stains.size()==64)
 effects.show_death('0',Vector2.ZERO);assert(effects.stains.size()==64)
 for i in 100:effects.show_hit(1,Vector2(-100,-100))
 assert(effects.bursts.size()==24)
 await create_timer(.3).timeout;assert(effects.bursts.is_empty())
 for i in 4:effects.show_hit(5,Vector2(300+i*210,360),Vector2.RIGHT)
 await create_timer(.06).timeout
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/art/integration/ART-107-sample.png')
 effects.clear_effects();assert(effects.stains.is_empty() and effects.bursts.is_empty())
 print('PASS armor-only zero / caps / dedup / expiry / clear; visual sample needs review')
 quit()
