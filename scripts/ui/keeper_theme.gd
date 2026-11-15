extends RefCounted
const FONT_TITLE=24
const FONT_SECTION=24
const FONT_BODY=24
const FONT_CAPTION=24
const FONT_NUMBER=24
const GAP_SMALL=8
const BUTTON_HEIGHT=44
const COMPACT_HEIGHT=40
const PANEL_PADDING=16
const TEXT=Color('e9e2cc')
const MUTED=Color('a7b0aa')
const DISABLED=Color('727d82')
const ACCENT=Color('64d7df')
const HOVER=Color('a3eee4')
const WARNING=Color('d6b776')
const DANGER=Color('df7378')
static var cached:Theme
static var boxes:Dictionary={}
static func pixel_font(pixels:int=12)->FontFile:
 var font:FontFile=load('res://assets/runtime/ui/keeper/fusion-pixel-%dpx-proportional-zh_hans.otf'%pixels)
 font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
 font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
 font.hinting=TextServer.HINTING_NONE
 font.oversampling=1.0
 return font
static func box(asset:String,margin:int=8)->StyleBoxTexture:
 var aliases={'panel_normal':'panel','panel_inset':'inset','slot_normal':'slot','slot_selected':'selected','button_default':'button','button_hover':'hover','button_pressed':'pressed','button_focus':'focus','button_selected':'selected','button_disabled':'disabled'}
 var name:String=aliases.get(asset,asset)
 if boxes.has(name):return boxes[name]
 var s:=StyleBoxTexture.new();s.texture=load('res://assets/runtime/ui/keeper/'+name+'.png')
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  s.set_texture_margin(side,8);s.set_content_margin(side,10)
 if name=='pressed':s.content_margin_top=12;s.content_margin_bottom=8
 boxes[name]=s
 return s
static func get_theme()->Theme:
 if cached!=null:return cached
 cached=Theme.new();cached.default_font_size=24
 var font:=pixel_font()
 cached.default_font=font
 for role in ['normal_font','bold_font','italics_font','bold_italics_font','mono_font']:cached.set_font(role,'RichTextLabel',font)
 cached.set_stylebox('panel','TooltipPanel',box('panel'))
 cached.set_color('font_color','TooltipLabel',TEXT)
 cached.set_stylebox('hover','PopupMenu',box('hover'))
 for type in ['CheckButton','CheckBox','PopupMenu']:
  for state in ['checked','unchecked']:
   var icon:Texture2D=load('res://assets/runtime/ui/keeper/'+state+'.png')
   cached.set_icon(state,type,icon);cached.set_icon(state+'_disabled',type,icon)
 cached.set_icon('arrow','OptionButton',load('res://assets/runtime/ui/keeper/arrow.png'))
 cached.set_icon('updown','SpinBox',load('res://assets/runtime/ui/keeper/spin.png'))
 for type in ['Label','Button','RichTextLabel','CheckButton','OptionButton','LineEdit','TextEdit','PopupMenu','SpinBox']:
  cached.set_color('font_color',type,TEXT);cached.set_color('default_color',type,TEXT)
  cached.set_color('font_hover_color',type,TEXT);cached.set_color('font_pressed_color',type,TEXT)
  cached.set_color('font_focus_color',type,ACCENT);cached.set_color('font_disabled_color',type,DISABLED)
 for type in ['Panel','PanelContainer','PopupPanel','PopupMenu','Window','AcceptDialog','ConfirmationDialog']:
  cached.set_stylebox('panel',type,box('panel'))
  cached.set_stylebox('embedded_border',type,box('panel'))
 for type in ['LineEdit','TextEdit']:
  cached.set_stylebox('normal',type,box('inset'))
  cached.set_stylebox('focus',type,box('focus'))
  cached.set_stylebox('read_only',type,box('disabled'))
  cached.set_color('caret_color',type,TEXT)
  cached.set_color('selection_color',type,Color('28535e'))
 for type in ['HSlider','VSlider']:
  cached.set_stylebox('slider',type,box('bar'))
  cached.set_stylebox('grabber_area',type,box('energy'))
  cached.set_stylebox('grabber_area_highlight',type,box('energy'))
  for state in ['grabber','grabber_highlight','grabber_disabled']:cached.set_icon(state,type,load('res://assets/runtime/ui/keeper/thumb.png'))
 for type in ['HScrollBar','VScrollBar']:
  cached.set_stylebox('scroll',type,box('bar'))
  for state in ['grabber','grabber_highlight','grabber_pressed']:cached.set_stylebox(state,type,box('hover'))
 for type in ['GridContainer','HFlowContainer','VFlowContainer']:
  for axis in ['h_separation','v_separation']:cached.set_constant(axis,type,GAP_SMALL)
 for type in ['Button','OptionButton','CheckButton']:
  for state in {'normal':'button','hover':'hover','pressed':'pressed','hover_pressed':'pressed','focus':'focus','disabled':'disabled'}:
   var mapping={'normal':'button','hover':'hover','pressed':'pressed','hover_pressed':'pressed','focus':'focus','disabled':'disabled'}
   cached.set_stylebox(state,type,button_box(mapping[state]))
 for type in ['HBoxContainer','VBoxContainer']:cached.set_constant('separation',type,GAP_SMALL)
 for role in ['normal_font_size','bold_font_size','italics_font_size','mono_font_size']:cached.set_font_size(role,'RichTextLabel',24)
 cached.set_constant('line_spacing','Label',4)
 return cached
static func button_box(asset:String,compact:bool=false)->StyleBoxTexture:
 var key:=asset+('_compact' if compact else '_button')
 if boxes.has(key):return boxes[key]
 var style:=box(asset).duplicate() as StyleBoxTexture
 var padding:=4 if compact else 6
 style.content_margin_top=padding+(2 if asset=='pressed' else 0)
 style.content_margin_bottom=padding-(2 if asset=='pressed' else 0)
 boxes[key]=style
 return style
static func compact_button(button:Button):
 for state in {'normal':'button','hover':'hover','pressed':'pressed','hover_pressed':'pressed','focus':'focus','disabled':'disabled'}:
  var mapping={'normal':'button','hover':'hover','pressed':'pressed','hover_pressed':'pressed','focus':'focus','disabled':'disabled'}
  button.add_theme_stylebox_override(state,button_box(mapping[state],true))
 button.custom_minimum_size.y=COMPACT_HEIGHT
static func apply(control:Control):
 control.theme=get_theme();control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
static func configure_dialog(dialog:ConfirmationDialog):
 dialog.theme=get_theme()
 dialog.title='确认操作'
 dialog.ok_button_text='确认'
 dialog.cancel_button_text='取消'
 dialog.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 dialog.content_scale_factor=0.5
 dialog.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
static func meter(bar:ProgressBar,kind:String):
 bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override('background',box('bar'))
 var fill:=StyleBoxTexture.new();fill.texture=load('res://assets/runtime/ui/keeper/'+kind+'.png')
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:fill.set_expand_margin(side,-4)
 bar.add_theme_stylebox_override('fill',fill)
