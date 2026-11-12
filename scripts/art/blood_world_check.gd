extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 var arena=load('res://scenes/maps/exploration.tscn').instantiate()
 root.add_child(arena)
 for i in range(12):await physics_frame
 await arena.depart('suburbs','south')
 for i in range(12):await physics_frame
 var enemy=arena.targets[1]
 arena.player.position=enemy.position+Vector2(60,80)
 await process_frame
 arena.hit(enemy,10000,{'penetration':10000})
 for i in range(6):await process_frame
 assert(arena.blood_visual.stains.size()==1)
 # Bursts may already expire during slow first render; timing tested separately.
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/art/integration/ART-107-world-kill.png')
 print('ART107 controlled hit: ',enemy.record().vitals.hp,' action=',enemy.art_visual.action)
 print('scene nodes: ',arena.get_child_count())
 quit()


