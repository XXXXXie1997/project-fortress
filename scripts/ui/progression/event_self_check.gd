extends SceneTree
func _initialize():
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 for i in 10:await physics_frame
 a.state.quests.offers['check']='daily_kill';a.state.quests.refresh_day=a.state.day
 assert(a.services.quests.accept(a.state,'check',true).ok)
 await a.depart('suburbs','south')
 for i in 10:await physics_frame
 for enemy in a.targets:enemy.set_physics_process(false)
 a.player.set_physics_process(false)
 var bridge=a.player.growth_bridge
 bridge.observe(a.state,a.inventory)
 var xp:int=bridge.growth.snapshot(a.state).xp
 var enemy=a.targets[0]
 a.hit(enemy,100000,{'penetration':1000})
 bridge.observe(a.state,a.inventory);bridge.observe(a.state,a.inventory)
 assert(a.state.quests.active.check.progress==1)
 assert(a.state.player.growth.xp==xp+10)
 InventoryService.commit(a.state,JSON.parse_string(JSON.stringify(a.state)))
 bridge.observe(a.state,a.inventory)
 assert(a.state.quests.active.check.progress==1 and a.state.player.growth.xp==xp+10)
 a.state.player.erase('growth_events')
 bridge.observe(a.state,a.inventory)
 assert(a.state.player.growth.xp==xp+10)
 a.state.day+=1;bridge.observe(a.state,a.inventory);bridge.observe(a.state,a.inventory)
 assert(a.state.player.growth.xp==xp+30)
 print('DEV313 REAL MAP KILL QUEST XP LOAD ONCE PASS')
 quit()
