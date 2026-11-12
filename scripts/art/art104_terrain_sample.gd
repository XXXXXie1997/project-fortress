extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 RenderingServer.set_default_clear_color(Color('263135'))
 var terrain:Texture2D=load('res://assets/runtime/environment_iso/nature/terrain.png')
 var world:=Node2D.new();world.y_sort_enabled=true;world.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(world)
 for theme in 3:
  var grid:=GridProjection.new(48,Vector2(96,48),Vector2(220+420*theme,100))
  for y in 4:
   for x in 4:
    var floor:=Polygon2D.new();floor.z_index=-1;floor.polygon=grid.rect_polygon(Rect2(x*48,y*48,48,48));floor.texture=terrain
    var sy:=16 if y in [1,2] else 0
    var r:=Rect2(theme*16,sy,16,16)
    floor.uv=PackedVector2Array([r.position,r.position+Vector2(16,0),r.end,r.position+Vector2(0,16)]);world.add_child(floor)
  var tree:=Sprite2D.new();var tex:=AtlasTexture.new();tex.atlas=load('res://assets/runtime/environment_iso/nature/trees.png');tex.region=Rect2(theme%2*32,0,32,48);tree.texture=tex;tree.offset=Vector2(0,-24);tree.scale=Vector2(3,3);tree.position=Vector2(130+420*theme,240);world.add_child(tree)
  var hero=load('res://scripts/art/survivor_visual.gd').new();hero.position=Vector2(195+420*theme,245);hero.scale=Vector2(3,3);world.add_child(hero)
  var enemy=load('res://scripts/art/enemy_visual.gd').new();enemy.kind='fast';enemy.position=Vector2(275+420*theme,245);world.add_child(enemy)
  var label:=Label.new();label.text=['SUBURBS / dirt','ARMORY / asphalt','CITY / concrete'][theme];label.position=Vector2(45+420*theme,420);root.add_child(label)
 var facility=load('res://scripts/art/facility_visual.gd').new();facility.kind='warehouse';facility.position=Vector2(640,630);world.add_child(facility)
 await create_timer(.4).timeout
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  print('CAPTURE ',root.get_texture().get_image().save_png('res://docs/art/integration/ART-104-terrain-sample.png'))
 quit()


