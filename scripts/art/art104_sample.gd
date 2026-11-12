extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 RenderingServer.set_default_clear_color(Color('263135'))
 var world:=Node2D.new();world.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;world.y_sort_enabled=true;root.add_child(world)
 var grid:=GridProjection.new(48,Vector2(96,48),Vector2(640,40))
 for y in 12:
  for x in 12:
   var floor:=Polygon2D.new();floor.z_index=-1;floor.polygon=grid.rect_polygon(Rect2(x*48,y*48,48,48));floor.color=Color('46534b') if (x+y)%2==0 else Color('49574e');world.add_child(floor)
 for i in 4:
  var anchor:=Node2D.new();anchor.position=Vector2(260+i*230,310);world.add_child(anchor)
  var sprite:=Sprite2D.new();var tex:=AtlasTexture.new();tex.atlas=load('res://assets/runtime/environment_iso/nature/trees.png');tex.region=Rect2((i%2)*32,(i/2)*48,32,48);sprite.texture=tex;sprite.offset=Vector2(0,-24);sprite.scale=Vector2(3,3);anchor.add_child(sprite)
 var hero=load('res://scripts/art/survivor_visual.gd').new();hero.position=Vector2(480,430);hero.scale=Vector2(3,3);world.add_child(hero)
 for i in 3:
  var enemy=load('res://scripts/art/enemy_visual.gd').new();enemy.kind=['basic','fast','armored'][i];enemy.position=Vector2(620+120*i,430);enemy.action='walk';world.add_child(enemy)
 var facility=load('res://scripts/art/facility_visual.gd').new();facility.kind='warehouse';facility.position=Vector2(300,500);world.add_child(facility)
 var label:=Label.new();label.text='ART104 TREE SAMPLE / Kenney CC0 adaptation / 3x pixel scale\nGround is a contrast swatch, not final terrain artwork';label.position=Vector2(20,20);root.add_child(label)
 await create_timer(.4).timeout
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  print('CAPTURE ',root.get_texture().get_image().save_png('res://docs/art/integration/ART-104-tree-sample.png'))
 quit()
