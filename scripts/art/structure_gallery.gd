extends Node2D
const Structure=preload("res://scripts/art/structure_visual.gd")
const Facility=preload("res://scripts/art/facility_visual.gd")
const Hero=preload("res://scripts/art/survivor_visual.gd")
var roofs:Array=[]
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color("1c292e"))
 for i in 3:
  var theme:String=["suburbs","armory","city"][i]
  var projection:=GridProjection.new(48,Vector2(96,48),Vector2(220+i*410,145))
  var r:=Rect2(0,0,144,144)
  var points:=projection.rect_polygon(r)
  for edge in [1,2]:
   var next:int=(edge+1)%4
   add_child(Structure.polygon(PackedVector2Array([points[edge]-Vector2(0,44),points[next]-Vector2(0,44),points[next],points[edge]]),theme,true,Color(.8,.8,.8) if edge==2 else Color.WHITE))
  var h=Hero.new();h.position=projection.logical_to_world(Vector2(72,72));h.scale=Vector2(3,3);add_child(h)
  var roof=Structure.roof(projection,r,theme);add_child(roof);roofs.append(roof)
  var f=Facility.new();f.kind=["warehouse","turret","shield"][i];f.position=Vector2(220+i*410,590);add_child(f)
 if "--capture" in OS.get_cmdline_user_args():
  for hidden in [false,true]:
   for roof in roofs:roof.modulate.a=.06 if hidden else 1.0
   await get_tree().create_timer(.3).timeout
   await RenderingServer.frame_post_draw
   print("STRUCTURE_CAPTURE ",get_viewport().get_texture().get_image().save_png("res://docs/art/integration/ART-103-structure-"+("hidden" if hidden else "covered")+".png"))
  get_tree().quit()
func _unhandled_key_input(event):
 if event.is_pressed() and event.physical_keycode==KEY_SPACE:
  for roof in roofs:roof.modulate.a=.06 if roof.modulate.a>.5 else 1.0
