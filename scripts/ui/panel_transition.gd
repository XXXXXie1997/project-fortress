extends RefCounted
# Visual-only exit copies have no scripts, signals or input. Logical visibility
# changes immediately, preserving the existing pause and transaction lifecycle.
const ENTER_SECONDS:=0.09
const EXIT_SECONDS:=0.08
static func cancel(control:Control):
 var tween:Tween=control.get_meta('panel_fade') if control.has_meta('panel_fade') else null
 if tween!=null and tween.is_valid():tween.kill()
 var ghost=control.get_meta('panel_exit') if control.has_meta('panel_exit') else null
 if is_instance_valid(ghost):ghost.queue_free()
 if control.has_meta('panel_exit'):control.remove_meta('panel_exit')
static func reveal(control:Control):
 cancel(control)
 control.show()
 control.modulate.a=0.0
 var tween:=control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 control.set_meta('panel_fade',tween)
 tween.tween_property(control,'modulate:a',1.0,ENTER_SECONDS)
static func dismiss(control:Control):
 cancel(control)
 if control.is_visible_in_tree() and control.modulate.a>0.0:
  var layer:=CanvasLayer.new()
  var source_layer:=control.get_canvas_layer_node()
  layer.layer=source_layer.layer if source_layer!=null else 0
  layer.transform=control.get_global_transform_with_canvas()
  var copy:=control.duplicate(0) as Control
  inert(copy)
  copy.position=Vector2.ZERO;copy.rotation=0.0;copy.scale=Vector2.ONE
  copy.set_anchors_preset(Control.PRESET_TOP_LEFT)
  layer.add_child(copy)
  control.get_viewport().add_child(layer)
  control.set_meta('panel_exit',layer)
  control.tree_exiting.connect(layer.queue_free,CONNECT_ONE_SHOT)
  var tween:=layer.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
  tween.tween_property(copy,'modulate:a',0.0,EXIT_SECONDS)
  tween.tween_callback(layer.queue_free)
 control.hide()
 control.modulate.a=1.0
static func inert(node:Node):
 node.process_mode=Node.PROCESS_MODE_DISABLED
 if node is Control:
  node.mouse_filter=Control.MOUSE_FILTER_IGNORE
  node.focus_mode=Control.FOCUS_NONE
 for child in node.get_children():inert(child)
