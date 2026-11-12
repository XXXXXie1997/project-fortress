extends SceneTree
var a
var failed:=0
func _initialize():call_deferred('run')
func wait_frames(n:=5):
 for i in range(n):await physics_frame
func ck(ok:bool,label:String):
 print(('PASS ' if ok else 'FAIL ')+label)
 if not ok:failed+=1
func press_f():
 var e:=InputEventAction.new();e.action='interact';e.pressed=true;Input.parse_input_event(e)
 await physics_frame
 e=InputEventAction.new();e.action='interact';e.pressed=false;Input.parse_input_event(e)
 await wait_frames()
func run():
 root.size=Vector2i(1280,720);a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a);await wait_frames(8)
 await a.depart('suburbs','south');await wait_frames()
 var keybox:Dictionary=a.exploration.box(a.state,'key_cache')
 a.player.position=Vector2(keybox.position[0],keybox.position[1]);await press_f()
 ck(a.hud.inventory_panel.visible,'F opens common inventory')
 await wait_frames(220)
 var got=a.exploration.take_all(a.state,'key_cache');ck(got.size()==1,'actual time reveals key and take once')
 a.hud.inventory_panel.close_panel()
 a.player.position=a.projection.logical_to_world(Vector2(1680,650));await press_f()
 ck(a.state.world.exploration.doors.has('suburbs:supply'),'key opens permanent door')
 ck(a.inventory.items_in(a.state,keybox.container_id).is_empty(),'key box empty after pickup')
 var session=a.state.expedition.id
 a.player.position=Vector2(a.catalog.suburbs.points.armory_road.position[0],a.catalog.suburbs.points.armory_road.position[1]);await press_f()
 ck(a.state.expedition.map_id=='armory','F crosses to armory')
 a.player.position=Vector2(a.catalog.armory.points.road.position[0],a.catalog.armory.points.road.position[1]);await press_f()
 ck(a.state.expedition.id==session and a.state.expedition.map_id=='suburbs','same expedition returns')
 ck(a.inventory.items_in(a.state,keybox.container_id).is_empty(),'cross map does not duplicate key')
 a.player.position=Vector2(a.catalog.suburbs.points.escape.position[0],a.catalog.suburbs.points.escape.position[1]);await press_f()
 ck(a.state.phase=='dusk','F extraction settles dusk')
 a.state.threat.stage=100 # Explicit overwhelming threat fixture for failure branch
 for b in a.state.base.buildings.values(): b.durability=1.0 # Damaged base fixture
 var before=a.state.rng_state
 ck(not await a.depart('suburbs','south',true,false),'night requires second confirmation')
 ck(a.state.rng_state==before,'rejected night preserves RNG')
 await a.depart('suburbs','south',true,true);await wait_frames()
 ck(a.targets.size()==11,'night has additional enemies')
 ck(not a.geometry.doors.has('supply'),'permanent door persists at night')
 var nextbox=a.exploration.box(a.state,'key_cache')
 ck(a.inventory.items_in(a.state,nextbox.container_id).is_empty(),'opened door suppresses repeated key')
 var equip=a.state.player.equipment.duplicate(true)
 a.player.position=Vector2(381,901);a.state.player.vitals.hp=0;await wait_frames(12)
 print('AFTER ZERO ',a.state.phase,' ACTIVE ',a.state.expedition.get('active'),' HP ',a.state.player.vitals.hp,' CYCLE ',a.state.cycle)
 ck(a.state.player.equipment==equip,'actual hp zero preserves equipment')
 ck(a.state.cycle.failed,'undefended night produces base failure')
 ck(not await a.depart('suburbs','south'),'failed base cannot depart')
 for b in a.hud.choices.get_children():
  if b is Button:ck(not b.text.begins_with('白天出发'),'failed UI has no normal departure')
 print('QA FLOW FAILURES ',failed);quit(1 if failed else 0)



