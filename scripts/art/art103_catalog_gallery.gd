extends Node2D
const Art=preload("res://scripts/art/fortress_art.gd")
const Enemy=preload("res://scripts/art/enemy_visual.gd")
const Hero=preload("res://scripts/art/survivor_visual.gd")
var page:=0
var content:Node2D
func _ready()->void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color("1c292e"))
 build(0)
 if "--capture" in OS.get_cmdline_user_args():
  for p in 3:
   build(p)
   await get_tree().create_timer(0.35).timeout
   await RenderingServer.frame_post_draw
   print("ART103_PAGE ",p," ",get_viewport().get_texture().get_image().save_png("res://docs/art/integration/ART-103-page%d.png"%p))
  get_tree().quit()
func build(p:int)->void:
 if content!=null:remove_child(content);content.queue_free()
 content=Node2D.new();add_child(content)
 text("ART103 / "+["ENEMY STATES","FACILITIES","CROPS & INVENTORY ICONS"][p],Vector2(30,20),24)
 if p==0:
  var kinds=["basic","fast","armored","ranged","boss"]
  for row in 4:
   for col in 5:
    var e=Enemy.new();e.kind=kinds[col];e.facing=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][row];e.action=["walk","windup","strike","dead"][row];e.position=Vector2(260+col*200,175+row*155);content.add_child(e)
   text(["walk/down","windup/left","strike/right","dead/up"][row],Vector2(25,130+row*155),17)
  var h=Hero.new();h.position=Vector2(130,115);h.scale=Vector2(3,3);content.add_child(h)
 else:
  var names=Art.FACILITIES.keys() if p==1 else Art.ITEMS.keys()
  for i in names.size():
   var s:=Sprite2D.new();s.texture=Art.facility_texture(names[i]) if p==1 else Art.item_icon(names[i]);s.position=Vector2(120+(i%6)*205,140+(i/6)*180);s.scale=Vector2(2,2) if p==1 else Vector2(3,3);content.add_child(s)
   text(names[i],s.position+Vector2(-80,70),15)
  if p==2:
   for i in 6:
    var s:=Sprite2D.new();s.texture=Art.crop_texture("catalyst" if i<3 else "material",i%3);s.position=Vector2(120+i*205,620);s.scale=Vector2(2,2);content.add_child(s)
 text("SPACE: next page / visual inspection only; no gameplay damage or collision",Vector2(30,685),16)
func _unhandled_key_input(event:InputEvent)->void:
 if event.is_pressed() and not event.is_echo() and event.physical_keycode==KEY_SPACE:page=(page+1)%3;build(page)
func text(value:String,at:Vector2,size:int)->void:
 var l:=Label.new();l.text=value;l.position=at;l.add_theme_font_size_override("font_size",size);content.add_child(l)

