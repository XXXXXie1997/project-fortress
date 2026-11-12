extends Node2D
const Grid=preload("res://scripts/world/grid/grid_projection.gd")
const Actor=preload("res://scripts/art/survivor_visual.gd")
var grid=Grid.new(48.0,Vector2(96,48),Vector2(640,110))
var roof:Sprite2D
var elapsed:=0.0
var infected:Array[Sprite2D]=[]
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color("141e25"))
 var ground:=Node2D.new();add_child(ground)
 for y in 8:
  for x in 8:
   var p:=Polygon2D.new();p.polygon=grid.rect_polygon(Rect2(x*48,y*48,48,48));p.color=Color("344348") if (x+y)%2==0 else Color("39494c");ground.add_child(p)
 var objects:=Node2D.new();objects.y_sort_enabled=true;add_child(objects)
 sprite("res://assets/runtime/environment_iso/warehouse.png",grid.cell_to_world(Vector2i(2,4))+Vector2(0,24),objects,Vector2(64,64))
 var anchor:Vector2=grid.cell_to_world(Vector2i(5,3))+Vector2(0,24)
 var block:=Node2D.new();block.position=anchor;objects.add_child(block)
 var wall_left:=Polygon2D.new();wall_left.polygon=PackedVector2Array([Vector2(-96,-48),Vector2(0,0),Vector2(0,-54),Vector2(-96,-102)]);wall_left.color=Color('65777b');block.add_child(wall_left)
 var wall_right:=Polygon2D.new();wall_right.polygon=PackedVector2Array([Vector2(0,0),Vector2(96,-48),Vector2(96,-102),Vector2(0,-54)]);wall_right.color=Color('47585f');block.add_child(wall_right)
 roof=sprite("res://assets/runtime/environment_iso/roof.png",Vector2(0,-54),block,Vector2(64,40))
 var hero:=Actor.new();hero.position=grid.cell_to_world(Vector2i(4,5));hero.scale=Vector2(3,3);hero.aim=Vector2.RIGHT;hero.moving=true;objects.add_child(hero)
 for i in 4:
  var e:=Sprite2D.new();e.texture=load("res://assets/runtime/enemies/infected.png");e.hframes=4;e.vframes=4;e.frame=i*4;e.offset=Vector2(0,-12);e.scale=Vector2(3,3);e.position=grid.cell_to_world(Vector2i(2+i,6));objects.add_child(e);infected.append(e)
 label("ART103 / DIAMOND SAMPLE - NOT FINAL MAP",Vector2(36,22),25)
 label("Warehouse + energy storage / independent roof / 24px survivor and infected",Vector2(36,62),18)
 label("R toggles roof. Same 3x pixel scale; world grid 96x48. No gameplay collision in this art scene.",Vector2(36,658),17)
 if "--capture" in OS.get_cmdline_user_args():
  await get_tree().create_timer(0.3).timeout
  await RenderingServer.frame_post_draw
  print("ISO_SAMPLE ",get_viewport().get_texture().get_image().save_png("res://docs/art/integration/ART-103-sample.png"))
  roof.visible=false
  await RenderingServer.frame_post_draw
  print("ISO_ROOF_HIDDEN ",get_viewport().get_texture().get_image().save_png("res://docs/art/integration/ART-103-roof-hidden.png"))
  get_tree().quit()
func _process(delta:float)->void:
 elapsed+=delta
 for i in infected.size():infected[i].frame=i*4+1+int(elapsed*6)%3
func _unhandled_key_input(event:InputEvent)->void:
 if event.is_pressed() and not event.is_echo() and event.physical_keycode==KEY_R:roof.visible=not roof.visible
func sprite(path:String,at:Vector2,parent:Node2D,size:Vector2)->Sprite2D:
 var s:=Sprite2D.new();s.texture=load(path);s.position=at;s.offset=Vector2(0,-size.y/2);s.scale=Vector2(3,3);parent.add_child(s);return s
func label(value:String,at:Vector2,size:int)->void:
 var l:=Label.new();l.text=value;l.position=at;l.add_theme_font_size_override("font_size",size);add_child(l)

