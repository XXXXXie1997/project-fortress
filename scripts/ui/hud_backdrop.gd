extends Node2D
var extra_top:=0.0
var style:StyleBoxTexture
static func attach(target:Control,top:float=0.0):
 var backdrop=load("res://scripts/ui/hud_backdrop.gd").new();backdrop.extra_top=top;target.add_child(backdrop)
func _ready():
 show_behind_parent=true
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 style=preload("res://scripts/ui/wasteland_theme.gd").box("panel_normal")
func _process(_dt):queue_redraw()
func _draw():
 if style==null:return
 var target:Control=get_parent()
 if target is Label and target.text.is_empty():return
 var dimensions:Vector2=target.size
 if target is RichTextLabel:
  if target.text.is_empty():return
  dimensions.y=minf(dimensions.y,target.get_content_height()+4)
 style.draw(get_canvas_item(),Rect2(Vector2(-10,-8-extra_top),dimensions+Vector2(20,16+extra_top)))
