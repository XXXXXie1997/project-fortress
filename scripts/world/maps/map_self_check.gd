extends SceneTree
var arena
var checks:=0
func verify(value:bool,title:String):
 if not value:push_error(title);quit(1);return
 checks+=1;print('PASS ',title)
func frames(count:=3):
 for i in range(count):await physics_frame
func press(action:String):
 var event:=InputEventAction.new();event.action=action;event.pressed=true;Input.parse_input_event(event)
 event=InputEventAction.new();event.action=action;event.pressed=false;Input.parse_input_event(event)
 await frames()
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720);arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena);await frames(5)
 verify(arena.ready_world,'独立入口准备完成')
 verify(not arena.state.trade.is_empty(),'初始真实贸易刷新')
 verify(await arena.depart('suburbs','south'),'实际昼间出发')
 await frames()
 verify(arena.targets.size()==8,'8个实体敌人')
 var start:Vector2=arena.player.position
 Input.action_press('move_right');await frames(40);Input.action_release('move_right')
 verify(arena.player.position.x>start.x+80,'WASD真实物理位移')
 arena.player.position=arena.projection.logical_to_world(Vector2(1320,1190));await press('interact')
 verify(arena.hud.inventory_panel.visible and arena.player.inventory_movement_locked,'F打开真实搜刮界面并锁移动')
 arena.exploration.tick_search(arena.state,5)
 var got:Array=arena.exploration.take_all(arena.state,'key_cache')
 verify(got.size()==1,'钥匙真实搜索拾取')
 arena.hud.inventory_panel.close_panel()
 arena.player.position=arena.projection.logical_to_world(Vector2(1680,650));await press('interact')
 verify(arena.state.world.exploration.doors.has('suburbs:supply'),'F消耗钥匙永久开门')
 verify(not arena.geometry.doors.has('supply'),'门碰撞移除')
 arena.player.position=arena.projection.logical_to_world(Vector2(1360,860));await press('interact')
 verify(arena.state.quests.active.main_1.progress==1,'调查真实主线记录')
 var enemy=arena.targets[0];var dead_id:String=enemy.enemy_id
 arena.hit(enemy,10000,{'penetration':100})
 verify(arena.state.expedition.maps.suburbs.enemies[dead_id].dead,'真实击杀存会话')
 verify(not arena.exploration.box(arena.state,'loot_'+dead_id).is_empty(),'真实击杀掉落箱')
 var core:=false
 for item in arena.inventory.items_in(arena.state,arena.exploration.box(arena.state,'loot_'+dead_id).container_id):
  if item.definition_id=='boss_core':core=true
 verify(core,'首领专属材料来源')
 arena.player.position=arena.projection.logical_to_world(Vector2(2260,1200));await press('interact');await frames()
 verify(arena.state.expedition.map_id=='armory' and arena.targets.size()==7,'F跨图加载武器库实体')
 arena.player.position=arena.projection.logical_to_world(Vector2(110,1500));await press('interact');await frames()
 verify(arena.state.expedition.maps.suburbs.enemies[dead_id].dead,'跨图返回击杀未刷新')
 verify(arena.state.expedition.maps.suburbs.containers.key_cache.revealed.size()==1,'跨图搜刮进度未刷新')
 arena.player.position=arena.projection.logical_to_world(Vector2(100,1720));await press('interact')
 verify(arena.state.phase=='dusk' and not arena.state.expedition.active,'F实际撤离与黄昏结算')
 verify(arena.services.quests.deliver(arena.state,'main_1',true).ok,'主线真实交付')
 verify(not 'city' in arena.state.world.exploration.unlocked,'城区不会当场提前解锁')
 verify(not await arena.depart('suburbs','south',true),'弱势夜探未确认拒绝')
 # Fixture defenders allow testing the following morning without inventing automatic victories.
 arena.state.base.residents=[{'id':'test_guard','hp':100,'max_hp':100,'power':100}]
 verify(await arena.depart('suburbs','south',true,true),'确认后夜间出发')
 await frames()
 verify(arena.targets.size()==11 and arena.ambient_brightness<.2,'夜间额外实体与低照度')
 verify(not arena.geometry.doors.has('supply'),'新会话永久门仍开')
 var key_box:Dictionary=arena.exploration.box(arena.state,'key_cache')
 verify(arena.inventory.items_in(arena.state,key_box.container_id).is_empty(),'永久门后钥匙不刷新')
 arena.player.position=arena.projection.logical_to_world(Vector2(400,1600));var rifle:String=arena.state.player.equipment.weapon_1;arena.finish(true);await frames()
 verify(arena.state.day==2 and arena.state.phase=='morning','夜探死亡仍真实次晨结算')
 verify('city' in arena.state.world.exploration.unlocked,'主线阶段次晨解锁城区')
 verify(arena.state.player.equipment.weapon_1==rifle,'野外死亡装备留存')
 var bag:Dictionary=arena.state.world.exploration.death_bags.values()[0]
 verify(Vector2(bag.position[0],bag.position[1]).distance_to(arena.projection.logical_to_world(Vector2(400,1600)))<0.01,'死亡箱精确地点')
 verify(await arena.depart('suburbs','south'),'次日再出发')
 await frames()
 verify(not arena.exploration.box(arena.state,bag.container_id).is_empty(),'新会话死亡箱可检索')
 print('DEV203 SELF CHECK PASS ',checks)
 quit()

