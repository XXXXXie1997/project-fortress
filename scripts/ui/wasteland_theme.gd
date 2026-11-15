extends RefCounted
# Shared design tokens. Screens choose a role, never an unrelated local size/color.
const FONT_TITLE := 28
const FONT_SECTION := 20
const FONT_BODY := 16
const FONT_CAPTION := 14
const FONT_NUMBER := 28
const TEXT := Color("ddd9cc")
const MUTED := Color("a6aaa0")
const DISABLED := Color("777b74")
const ACCENT := Color("c5a065")
const HOVER := Color("e7c18a")
const WARNING := Color("e7b575")
const DANGER := Color("d58a80")
const SUCCESS := Color("9bb58f")
const GAP_SMALL := 8
const GAP := 16
const GAP_SECTION := 24
const PANEL_PADDING := 24
const BUTTON_HEIGHT := 36
const COMPACT_HEIGHT := 28
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
 cached=Theme.new();cached.default_font_size=FONT_BODY
 var font:=SystemFont.new();font.font_names=PackedStringArray(["SimHei","Microsoft YaHei"]);font.font_weight=400;font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
 cached.default_font=font
 for type in ["Label","Button","CheckButton","OptionButton","RichTextLabel","LineEdit","PopupMenu"]:
  cached.set_color("font_color",type,TEXT)
  cached.set_color("default_color",type,TEXT)
  cached.set_color("font_disabled_color",type,DISABLED)
  cached.set_color("font_hover_color",type,HOVER)
  cached.set_color("font_focus_color",type,HOVER)
 for type in ["PanelContainer","Panel","PopupPanel","Window","AcceptDialog","ConfirmationDialog"]:
  cached.set_stylebox("panel",type,box("panel_normal"))
  cached.set_stylebox("embedded_border",type,box("panel_normal"))
 for type in ["Button","OptionButton","CheckButton"]:
  for state in {"normal":"default","hover":"hover","pressed":"pressed","hover_pressed":"selected","disabled":"disabled","focus":"focus"}:
   var names={"normal":"default","hover":"hover","pressed":"pressed","hover_pressed":"selected","disabled":"disabled","focus":"focus"}
   cached.set_stylebox(state,type,box("button_"+names[state]))
 cached.set_constant("separation","VBoxContainer",GAP)
 cached.set_font_size("font_size","Button",FONT_BODY)
 cached.set_font_size("font_size","Label",FONT_BODY)
 cached.set_constant("separation","HBoxContainer",GAP_SMALL)
 for type in ["HSlider","VSlider"]:
  var track:=StyleBoxFlat.new();track.bg_color=Color("101314");track.border_color=Color("4b504b");track.set_border_width_all(1);track.content_margin_top=3;track.content_margin_bottom=3
  var fill:=StyleBoxFlat.new();fill.bg_color=Color("c5a065");fill.content_margin_top=3;fill.content_margin_bottom=3
  cached.set_stylebox("slider",type,track);cached.set_stylebox("grabber_area",type,fill);cached.set_stylebox("grabber_area_highlight",type,fill)
 for role in ["normal_font_size","bold_font_size","italics_font_size","bold_italics_font_size","mono_font_size"]:cached.set_font_size(role,"RichTextLabel",FONT_BODY)
 for type in ["GridContainer","HFlowContainer","VFlowContainer"]:
  for axis in ["h_separation","v_separation"]:cached.set_constant(axis,type,GAP_SMALL)
 cached.set_constant("line_spacing","Label",4)
 return cached
static func apply(control:Control):
 control.theme=get_theme();control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
