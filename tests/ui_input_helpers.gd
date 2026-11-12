extends SceneTree
# Test-only input helpers. Product callbacks are never invoked by these helpers.
func click_at(point:Vector2, double_click:=false):
 var move:=InputEventMouseMotion.new();move.position=point;root.push_input(move,true)
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
  event.position=point;event.pressed=pressed;event.double_click=double_click and pressed
  root.push_input(event,true);await process_frame
func drag_between(start:Vector2,finish:Vector2):
 var down:=InputEventMouseButton.new();down.position=start;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
 root.push_input(down,true);await process_frame
 for step in range(1,13):
  var motion:=InputEventMouseMotion.new();motion.position=start.lerp(finish,float(step)/12)
  motion.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(motion,true);await process_frame
 var up:=InputEventMouseButton.new();up.position=finish;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false
 root.push_input(up,true);await process_frame
func find_button(node:Node,prefix:String):
 if node is Button and node.is_visible_in_tree() and node.text.begins_with(prefix):return node
 for child in node.get_children():
  var found=find_button(child,prefix)
  if found!=null:return found
 return null
