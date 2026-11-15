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
