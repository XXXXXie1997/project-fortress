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
 a.player.position=a.projection.logical_to_world(Vector2(1360,860));await press_f()
 ck(a.state.quests.active.main_1.progress==1,'F objective records actual quest')
 var boss=a.targets.filter(func(t):return t.kind=='boss')[0]
 a.hit(boss,100000,{'penetration':100})
 var loot=a.exploration.box(a.state,'loot_'+boss.enemy_id)
 ck(a.inventory.items_in(a.state,loot.container_id).any(func(item):return item.definition_id=='boss_core'),'actual boss death gives core')
 var session=a.state.expedition.id
 a.player.position=Vector2(a.catalog.suburbs.points.armory_road.position[0],a.catalog.suburbs.points.armory_road.position[1]);await press_f()
 ck(a.state.expedition.map_id=='armory','F crosses to armory')
 a.player.position=Vector2(a.catalog.armory.points.road.position[0],a.catalog.armory.points.road.position[1]);await press_f()
 ck(a.state.expedition.id==session and a.state.expedition.map_id=='suburbs','same expedition returns')
 ck(a.inventory.items_in(a.state,keybox.container_id).is_empty(),'cross map does not duplicate key')
 a.player.position=Vector2(a.catalog.suburbs.points.escape.position[0],a.catalog.suburbs.points.escape.position[1]);await press_f()
 ck(a.state.phase=='dusk','F extraction settles dusk')
 ck(a.services.quests.deliver(a.state,'main_1',true).ok,'actual quest delivery')
 ck(not 'city' in a.state.world.exploration.unlocked,'city not prematurely unlocked')
 a.state.base.residents=[{'id':'qa_guard','hp':100,'max_hp':100,'power':100}]
 pass
 var before=a.state.rng_state
 await a.depart('suburbs','south',true,true);await wait_frames()
 ck(a.targets.size()==11,'night has additional enemies')
 ck(not a.geometry.doors.has('supply'),'permanent door persists at night')
 var nextbox=a.exploration.box(a.state,'key_cache')
 ck(a.inventory.items_in(a.state,nextbox.container_id).is_empty(),'opened door suppresses repeated key')
 var equip=a.state.player.equipment.duplicate(true)
 a.player.position=Vector2(381,901);a.state.player.vitals.hp=0;await wait_frames(12)
 print('AFTER ZERO ',a.state.phase,' ACTIVE ',a.state.expedition.get('active'),' HP ',a.state.player.vitals.hp,' CYCLE ',a.state.cycle)
 ck(a.state.player.equipment==equip,'actual hp zero preserves equipment')
 ck(a.state.phase=='morning' and a.state.day==2,'actual night settlement next morning')
 ck('city' in a.state.world.exploration.unlocked,'quest stage unlocks city next morning')
 var bag=a.state.world.exploration.death_bags.values()[0]
 ck(Vector2(bag.position[0],bag.position[1]).distance_to(Vector2(381,901))<1,'death bag world location exact')
 print('QA FLOW FAILURES ',failed);quit(1 if failed else 0)




