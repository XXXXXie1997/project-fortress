extends SceneTree
var arena
func _initialize():call_deferred('run')
func snap(name:String):
 for i in 8:await process_frame
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  print(name,' ',root.get_texture().get_image().save_png('res://docs/art/integration/ART-103-farm-'+name+'.png'))
func run():
 root.size=Vector2i(1280,720)
 arena=load('res://scenes/ui/base/base_management_arena.tscn').instantiate();root.add_child(arena)
 while arena.management==null:await process_frame
 var id:String=arena.building.build(arena.state,'farm',[9,7],Rect2i(0,0,24,18))
 assert(not id.is_empty())
 arena.sync_layout()
 arena.player.position=arena.grid.logical_to_world(Vector2(480,480))
 await snap('empty')
 # Explicit isolated visual fixtures; business settlement is independently tested.
 var farm:Dictionary=arena.state.base.buildings[id]
 for stage in 3:
  farm.batches=[{'crop':'catalyst','age':stage,'harvest':{'catalyst':1} if stage==2 else {}},{'crop':'material','age':stage,'harvest':{'scrap':1} if stage==2 else {}}]
  await snap('stage'+str(stage))
  var visual:Node2D
  for fixture in arena.fixtures:
   if fixture.id==id:visual=fixture.art_visual
  assert(visual!=null and not visual.body.visible)
  assert(visual.crops[0].visible and visual.crops[1].visible)
  assert(int(visual.crops[0].texture.region.position.x)==stage*64)
 farm.durability=0
 await snap('ruined')
 print('ART103 FARM ACTUAL ID VISUAL PASS')
 quit()
