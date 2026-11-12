extends SceneTree
var arena
func _initialize():call_deferred('run')
func snap(name:String):
 for i in 12:await process_frame
 await RenderingServer.frame_post_draw
 print(name,' ',root.get_texture().get_image().save_png('res://docs/art/integration/ART-103-base-'+name+'.png'))
func run():
 root.size=Vector2i(1280,720)
 arena=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(arena)
 for i in 6:await physics_frame
 arena.player.position=arena.grid.logical_to_world(Vector2(400,160))
 await snap('facilities')
 arena.player.position=arena.grid.logical_to_world(Vector2(1050,460))
 await snap('shield')
 arena.state.base.shield.energy=0
 await snap('shield-disabled')
 arena.state.base.shield.energy=100
 arena.start_fixture_wave(12)
 await create_timer(2).timeout
 await snap('combat')
 print('ART103 BASE CAPTURE DONE')
 quit()
