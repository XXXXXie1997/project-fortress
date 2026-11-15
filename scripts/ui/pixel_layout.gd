extends Node
## 960x540 HD canvas tiers; 640x360 remains a compact compatibility window.
## UI keeps the 1280 coordinate grid; fonts rasterize at native window resolution.
var previous_size:=Vector2i.ZERO
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS
 get_window().min_size=Vector2i(640,360)
 get_window().set_meta('pixel_layout',true)
 get_window().canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
 get_window().size_changed.connect(resize)
 resize()
func _process(_dt):
 if get_window().size!=previous_size:resize()
 fit_readable_text(get_tree().root)
func resize():
 var window:=get_window()
 var requested:=window.size
 var units:=maxi(40,roundi(requested.x/16.0))
 if previous_size!=Vector2i.ZERO:
  var delta:=requested-previous_size
  if absi(delta.y)*16>absi(delta.x)*9:units=maxi(40,roundi(requested.y/9.0))
 var fitted:=Vector2i(units*16,units*9)
 previous_size=fitted
 if window.size!=fitted:window.size=fitted
 var tier:=maxi(1,floori(minf(window.size.x/960.0,window.size.y/540.0)))
 window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 window.content_scale_stretch=Window.CONTENT_SCALE_STRETCH_INTEGER
 window.content_scale_size=Vector2i(maxi(640,window.size.x/tier),maxi(360,window.size.y/tier))
 window.set_meta('pixel_tier',tier)
static func ui_scale(viewport_size:Vector2)->float:
 var tree:=Engine.get_main_loop() as SceneTree
 if tree!=null and tree.root.get_meta('pixel_layout',false):return maxf(0.5,minf(viewport_size.x/1280.0,viewport_size.y/720.0))
 return maxf(0.5,floorf(minf(viewport_size.x/640.0,viewport_size.y/360.0))*0.5)
static func world_scale()->float:
 var tree:=Engine.get_main_loop() as SceneTree
 return ui_scale(tree.root.get_visible_rect().size) if tree!=null and tree.root.get_meta('pixel_layout',false) else 1.0

# Keep reference-sized typography at normal resolutions; clamp only tiny windows.
static func readable_size(control:CanvasItem,requested:int)->int:
 var physical:Transform2D=control.get_viewport().get_stretch_transform()*control.get_global_transform_with_canvas()
 return maxi(requested,ceili(10.0/maxf(.01,physical.get_scale().y)))
static func fit_readable_text(node:Node):
 if node is CanvasItem and not node.is_visible_in_tree():return
 if node is Control and node.is_visible_in_tree() and (node is Label or node is Button or node is RichTextLabel):
  var roles:Array=['normal_font_size','bold_font_size','italics_font_size','mono_font_size'] if node is RichTextLabel else ['font_size']
  for role:String in roles:
   var current:int=node.get_theme_font_size(role)
   var key:String='readable_'+role
   var previous:Vector2i=node.get_meta(key,Vector2i(current,current))
   var requested:int=previous.x if current==previous.y else current
   var adjusted:int=readable_size(node,requested)
   if current!=adjusted:node.add_theme_font_size_override(role,adjusted)
   if previous!=Vector2i(requested,adjusted) or not node.has_meta(key):node.set_meta(key,Vector2i(requested,adjusted))
 for child in node.get_children():fit_readable_text(child)
