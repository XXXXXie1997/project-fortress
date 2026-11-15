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
 position=panel.drag_pointer-Vector2(panel.gesture.get('grab',Vector2.ZERO))*factor
 queue_redraw()
func _draw():
 if not visible or panel.gesture.is_empty():return
 var item:Dictionary=panel.state.items[panel.gesture.id].duplicate(true)
 item.rotated=panel.rotated
 var footprint:=Vector2(panel.inventory.dimensions(item))*panel.cell_size(false)
 draw_rect(Rect2(Vector2.ZERO,footprint),Color(0.07,0.10,0.13,0.8))
 draw_rect(Rect2(Vector2.ZERO,footprint),Color(0.65,0.85,0.88,0.9),false,1)
 var icon:Texture2D=preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id)
 preload('res://scripts/ui/inventory/item_visual.gd').draw_icon(self,icon,footprint*.5,panel.rotated)
