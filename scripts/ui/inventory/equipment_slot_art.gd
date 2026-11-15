extends Control
var panel:InventoryPanel
var slot:String
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(_dt):
 size=get_parent().size
 queue_redraw()
func _draw():
 if panel==null or panel.state.is_empty():return
 var item:Dictionary=panel.state.items.get(panel.state.player.equipment.get(slot,''),{})
 if slot.begins_with('weapon_'):
  for x in [64,128]:draw_line(Vector2(x,1),Vector2(x,size.y-1),Color('343d46'),1)
 if not item.is_empty():
  preload('res://scripts/ui/inventory/item_visual.gd').draw_icon(self,preload('res://scripts/art/fortress_art.gd').item_icon(item.definition_id),size*.5,item.rotated)
 elif not slot.begins_with('weapon_'):
  draw_string(panel.theme.default_font,size*.5+Vector2(-4,5),'+',HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color('68727a'))
 if slot.begins_with('weapon_'):
  var text_size:int=preload('res://scripts/ui/pixel_layout.gd').readable_size(self,14)
  draw_string(panel.theme.default_font,Vector2(6,text_size+2),slot.trim_prefix('weapon_'),HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color('a7b0aa'))
