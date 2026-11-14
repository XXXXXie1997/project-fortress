extends Node2D
var extra_top:=0.0
var style:StyleBoxTexture
var owner_control:Control
static func attach(target:Control,top:float=0.0):
 var backdrop=load("res://scripts/ui/hud_backdrop.gd").new();backdrop.extra_top=top;backdrop.owner_control=target
 if target is RichTextLabel:
  target.get_parent().add_child(backdrop);target.get_parent().move_child(backdrop,0);backdrop.position=target.position
 else:target.add_child(backdrop)
func _ready():
 show_behind_parent=true
 if is_instance_valid(owner_control): preload("res://scripts/ui/wasteland_theme.gd").apply(owner_control)
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 style=preload("res://scripts/ui/wasteland_theme.gd").box("panel_normal")
func _process(_dt):
 if not is_instance_valid(owner_control):queue_free();return
 visible=owner_control.is_visible_in_tree()
 if owner_control is RichTextLabel:position=owner_control.position
 queue_redraw()
func _draw():
 if style==null:return
 if not is_instance_valid(owner_control):return
 var target:Control=owner_control
 if target is Label and target.text.is_empty():return
 var dimensions:Vector2=target.size
 if target is RichTextLabel:
  if target.text.is_empty():return
  dimensions.y=minf(dimensions.y,target.get_content_height()+4)
 style.draw(get_canvas_item(),target.get_meta("backdrop_rect",Rect2(Vector2(-10,-8-extra_top),dimensions+Vector2(20,16+extra_top))))
