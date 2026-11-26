extends RefCounted
const FONT_TITLE=20
const FONT_SECTION=16
const FONT_BODY=16
const FONT_CAPTION=14
const FONT_NUMBER=20
const GAP_SMALL=4
const BUTTON_HEIGHT=36
const COMPACT_HEIGHT=32
const PANEL_PADDING=16
const TEXT=Color('e6e4dc')
const MUTED=Color('a6b7b6')
const DISABLED=Color('727d82')
const ACCENT=Color('64d7df')
const HOVER=Color('a3eee4')
const WARNING=Color('d6b776')
const DANGER=Color('df7378')
static var cached:Theme
static var boxes:Dictionary={}
static var regular_font:FontVariation
static func readable_sample()->bool:
 return true
static func pixel_font(_pixels:int=12)->Font:
 if regular_font!=null:return regular_font
 var source:FontFile=load('res://assets/runtime/ui/fonts/NotoSansSC.ttf')
 source.antialiasing=TextServer.FONT_ANTIALIASING_GRAY
 source.hinting=TextServer.HINTING_LIGHT
 source.oversampling=0.0
 regular_font=FontVariation.new()
 regular_font.base_font=source
 regular_font.fallbacks=[preload('res://assets/runtime/ui/field_kit/symbols.fnt')]
 regular_font.variation_opentype={TextServerManager.get_primary_interface().name_to_tag('wght'):400.0}
 return regular_font
# Names follow the hand-drawn tiles from left to right in the two atlases.
const FRAME_NAMES = ["panel", "inset", "slot", "button", "hover", "pressed", "selected", "disabled", "bar", "energy", "health", "focus"]
const SYMBOL_NAMES = ["station", "battery", "capacitor", "close", "back", "sort", "scope", "muzzle", "tactical", "next", "defense", "signal", "repair", "upgrade", "lock", "sun", "moon", "heart"]
const STATION = "\ue000"
const BATTERY = "\ue001"
const CAPACITOR = "\ue002"
const HEART = "\ue011"
static var symbols: Dictionary = {}
static var symbol_sheet: ImageTexture

static func symbol(id: String) -> Texture2D:
 if not symbols.has(id):
  var tile := AtlasTexture.new()
  if symbol_sheet == null:
   # The bitmap font importer embeds its page and marks the PNG as import-skip.
   var font := preload("res://assets/runtime/ui/field_kit/symbols.fnt")
   symbol_sheet = ImageTexture.create_from_image(font.get_texture_image(0,Vector2i(16,0),0))
  tile.atlas = symbol_sheet
  tile.region = Rect2(SYMBOL_NAMES.find(id) * 16, 0, 16, 16)
  symbols[id] = tile
 return symbols[id]

static func icon_button(button: Button, id: String, description: String):
 button.text = ""
 button.icon = symbol(id)
 button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
 button.tooltip_text = description
 button.accessibility_name = description
 button.custom_minimum_size = Vector2(32, 32)

static func box(asset: String, margin: int = 8) -> StyleBoxTexture:
 var aliases = {"panel_normal":"panel", "panel_inset":"inset", "slot_normal":"slot", "slot_selected":"selected", "button_default":"button", "button_hover":"hover", "button_pressed":"pressed", "button_focus":"focus", "button_selected":"selected", "button_disabled":"disabled"}
 var id: String = aliases.get(asset, asset)
 var key := "%s:%d" % [id, margin]
 if boxes.has(key): return boxes[key]
 var style := StyleBoxTexture.new()
 style.texture = preload("res://assets/runtime/ui/field_kit/frames.png")
 style.region_rect = Rect2(maxi(0, FRAME_NAMES.find(id)) * 32, 0, 32, 32)
 style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
 style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
 for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
  style.set_texture_margin(side, 6)
  style.set_content_margin(side, margin)
 boxes[key] = style
 return style

static func get_theme()->Theme:
 if cached!=null:return cached
 cached=Theme.new();cached.default_font_size=FONT_BODY
 var font:=pixel_font()
 cached.default_font=font
 for role in ['normal_font','bold_font','italics_font','bold_italics_font','mono_font']:cached.set_font(role,'RichTextLabel',font)
 cached.set_stylebox('panel','TooltipPanel',box('panel',12))
 cached.set_color('font_color','TooltipLabel',TEXT)
 cached.set_font_size('font_size','TooltipLabel',FONT_BODY)
 cached.set_icon('close','Window',symbol('close'))
 cached.set_icon('close_pressed','Window',symbol('close'))
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
 var title_frame:=box('panel').duplicate() as StyleBoxTexture
 title_frame.expand_margin_top=32
 for type in ['Window','AcceptDialog','ConfirmationDialog']:
  cached.set_stylebox('embedded_border',type,title_frame)
  cached.set_stylebox('embedded_unfocused_border',type,title_frame)
  cached.set_constant('title_height',type,32)
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
 for role in ['normal_font_size','bold_font_size','italics_font_size','mono_font_size']:cached.set_font_size(role,'RichTextLabel',FONT_BODY)
 cached.set_constant('line_spacing','Label',4)
 return cached
static func button_box(asset:String,compact:bool=false)->StyleBoxTexture:
 var key:=asset+('_compact' if compact else '_button')
 if boxes.has(key):return boxes[key]
 var style:=box(asset).duplicate() as StyleBoxTexture
 var padding:=2 if compact else 3
 style.content_margin_left=6
 style.content_margin_right=6
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
 dialog.content_scale_factor=1.0
 dialog.min_size=Vector2i(320,132)
 dialog.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 dialog.get_label().custom_minimum_size.x=280
 for button in [dialog.get_ok_button(),dialog.get_cancel_button()]:button.custom_minimum_size=Vector2(76,BUTTON_HEIGHT)
 dialog.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
static func meter(bar:ProgressBar,kind:String):
 bar.show_percentage=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override('background',box('bar'))
 var fill:=StyleBoxTexture.new();fill.texture=load('res://assets/runtime/ui/keeper/'+kind+'.png')
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:fill.set_expand_margin(side,-4)
 bar.add_theme_stylebox_override('fill',fill)
