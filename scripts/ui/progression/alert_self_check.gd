extends SceneTree
func _initialize():
 var a=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.player.set_physics_process(false)
 for enemy in a.targets:enemy.set_physics_process(false)
 var enemy=a.targets[0];enemy.position=a.player.position+Vector2(100,0)
 var r:Dictionary=enemy.record();r.alerted=false;r.meter=0;r.mode='idle'
 a.player.effective_config()
 enemy._physics_process(0.1)
 var plain:float=r.meter;assert(plain>0)
 r.alerted=false;r.meter=0;r.mode='idle';enemy.position=a.player.position+Vector2(100,0)
 a.player.growth_bridge.growth.award(a.state,'quest',200,'stealth_check')
 a.player.growth_bridge.growth.invest(a.state,'accuracy');a.player.growth_bridge.growth.invest(a.state,'stealth');a.player.effective_config()
 enemy._physics_process(0.1)
 assert(is_equal_approx(r.meter,plain*0.8))
 print('DEV313 REAL ENEMY ALERT ACCUMULATION PASS')
 quit()
