extends RefCounted
static var cached:Theme
static var boxes:Dictionary={}
static func box(asset:String,margin:int=8)->StyleBoxTexture:
 var key:=asset+str(margin)
 if boxes.has(key):return boxes[key]
 var s:=StyleBoxTexture.new();s.texture=load("res://assets/runtime/ui/wasteland/"+asset+".png")
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  s.set_texture_margin(side,margin);s.set_content_margin(side,8)
 boxes[key]=s;return s
static func get_theme()->Theme:
 if cached!=null:return cached
 cached=Theme.new();cached.default_font_size=16
 var font:=SystemFont.new();font.font_names=PackedStringArray(["SimHei","Microsoft YaHei"]);font.font_weight=400;font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
 cached.default_font=font
 for type in ["Label","Button","CheckButton","OptionButton","RichTextLabel","LineEdit","PopupMenu"]:
  cached.set_color("font_color",type,Color("ddd9cc"))
  cached.set_color("default_color",type,Color("ddd9cc"))
  cached.set_color("font_disabled_color",type,Color("777b74"))
  cached.set_color("font_hover_color",type,Color("e7c18a"))
  cached.set_color("font_focus_color",type,Color("e7c18a"))
 for type in ["PanelContainer","Panel","PopupPanel","Window","AcceptDialog","ConfirmationDialog"]:
  cached.set_stylebox("panel",type,box("panel_normal"))
  cached.set_stylebox("embedded_border",type,box("panel_normal"))
 for type in ["Button","OptionButton","CheckButton"]:
  for state in {"normal":"default","hover":"hover","pressed":"pressed","hover_pressed":"selected","disabled":"disabled","focus":"focus"}:
   var names={"normal":"default","hover":"hover","pressed":"pressed","hover_pressed":"selected","disabled":"disabled","focus":"focus"}
   cached.set_stylebox(state,type,box("button_"+names[state]))
 cached.set_constant("separation","VBoxContainer",16)
 cached.set_font_size("font_size","Button",16)
 cached.set_font_size("font_size","Label",16)
 cached.set_constant("separation","HBoxContainer",8)
 for type in ["HSlider","VSlider"]:
  var track:=StyleBoxFlat.new();track.bg_color=Color("101314");track.border_color=Color("4b504b");track.set_border_width_all(1);track.content_margin_top=3;track.content_margin_bottom=3
  var fill:=StyleBoxFlat.new();fill.bg_color=Color("c5a065");fill.content_margin_top=3;fill.content_margin_bottom=3
  cached.set_stylebox("slider",type,track);cached.set_stylebox("grabber_area",type,fill);cached.set_stylebox("grabber_area_highlight",type,fill)
 return cached
static func apply(control:Control):
 control.theme=get_theme();control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
