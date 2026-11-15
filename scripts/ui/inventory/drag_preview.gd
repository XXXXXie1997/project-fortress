extends Control
var panel:InventoryPanel
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 hide()
func _process(_dt):
 visible=is_instance_valid(panel) and panel.visible and not panel.closing and not panel.gesture.is_empty() and panel.gesture.get('dragging',false) and panel.accessible_item(panel.gesture.get('id',''))
 if not visible:return
 var factor:=preload('res://scripts/ui/pixel_layout.gd').ui_scale(get_viewport_rect().size)
 scale=Vector2.ONE*factor
 var item:Dictionary=panel.state.items[panel.gesture.id].duplicate(true);item.rotated=panel.rotated
 var extent:=Vector2(panel.inventory.dimensions(item))*panel.cell_size(false)*factor
 position=panel.drag_pointer+Vector2(12,12)*factor
 if position.x+extent.x>get_viewport_rect().size.x:position.x=panel.drag_pointer.x-extent.x-12*factor
 if position.y+extent.y>get_viewport_rect().size.y:position.y=panel.drag_pointer.y-extent.y-12*factor
 position=position.max(Vector2.ZERO)
 queue_redraw()
func _draw():
 if not visible or panel.gesture.is_empty():return
 var item:Dictionary=panel.state.items[panel.gesture.id].duplicate(true)
 item.rotated=panel.rotated
 var footprint:=Vector2(panel.inventory.dimensions(item))*panel.cell_size(false)
 draw_rect(Rect2(Vector2.ZERO,footprint),Color(0.07,0.10,0.13,0.8))
 draw_rect(Rect2(Vector2.ZERO,footprint),Color(0.65,0.85,0.88,0.9),false,1)
 var icon:Texture2D=preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id)
 if icon!=null:
  draw_set_transform(footprint*.5,PI*.5 if panel.rotated else 0.0)
  var extent:=minf(56,minf(footprint.x,footprint.y)-8)
  draw_texture_rect(icon,Rect2(Vector2.ONE*-extent*.5,Vector2.ONE*extent),false,Color(1,1,1,.92))
  draw_set_transform(Vector2.ZERO)
