extends SceneTree
var arena
func _initialize():call_deferred('run')
func snap(name:String):
 for i in range(12):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/art/integration/ART-103-world-'+name+'.png')
func run():
 root.size=Vector2i(1280,720)
 arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena)
 for i in range(5):await physics_frame
 await snap('departure')
 await arena.depart('suburbs','south')
 arena.player.position=arena.projection.logical_to_world(Vector2(1240,1120))
 await snap('suburbs-outside')
 arena.player.position=arena.projection.logical_to_world(Vector2(1250,940))
 await snap('suburbs-inside')
 arena.exploration.exit_map(arena.state,'armory_road');await arena.rebuild_map()
 arena.player.position=arena.projection.logical_to_world(Vector2(1000,970))
 await snap('armory')
 arena.exploration.unlock_map(arena.state,'city')
 arena.exploration.exit_map(arena.state,'road');await arena.rebuild_map()
 arena.exploration.exit_map(arena.state,'city_road');await arena.rebuild_map()
 arena.player.position=arena.projection.logical_to_world(Vector2(1630,1050))
 await snap('city')
 arena.ambient_brightness=.13
 arena.player.tactical.toggle()
 await snap('city-night')
 print('ART103 WORLD CAPTURES SAVED')
 quit()


