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
 cached.set_constant("separation","VBoxContainer",8)
 cached.set_constant("separation","HBoxContainer",8)
 return cached
static func apply(control:Control):
 control.theme=get_theme();control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
