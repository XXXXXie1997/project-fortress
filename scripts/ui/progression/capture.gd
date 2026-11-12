extends SceneTree
func _initialize():
 var a=load('res://scenes/ui/progression/demo.tscn').instantiate();root.add_child(a)
 for i in 10:await process_frame
 for mode in ['technology','quests']:
  a.player.progression_panel.open_view(mode,true)
  for i in 4:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://scenes/ui/progression/'+mode+'.png')
 quit()
