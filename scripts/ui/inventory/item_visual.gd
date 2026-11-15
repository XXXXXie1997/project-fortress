extends RefCounted
# Every inventory presentation uses the same icon size, independent of footprint.
const ICON_SIZE=Vector2(40,40)
static func draw_icon(canvas:CanvasItem,texture:Texture2D,center:Vector2,rotated:bool):
 if texture==null:return
 canvas.draw_set_transform(center,PI*.5 if rotated else 0.0)
 canvas.draw_texture_rect(texture,Rect2(-ICON_SIZE*.5,ICON_SIZE),false)
 canvas.draw_set_transform(Vector2.ZERO)
