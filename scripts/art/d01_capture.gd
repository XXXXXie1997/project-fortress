extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 var gallery=load('res://scenes/art/enemy_animation_gallery.tscn').instantiate()
 root.add_child(gallery)
 for phase in 5:
  gallery.manual=phase
  for frame in 2:
   await create_timer(.24).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png('res://docs/art/integration/ART-103-D01-animation-%d-%d.png'%[phase,frame])
 quit()

