extends SceneTree
func _initialize():
 var a=load('res://scripts/world/enemies/enemy_arena.gd').new();root.add_child(a)
 for i in 20:await physics_frame
 for enemy in a.targets:enemy.set_physics_process(false)
 var p=a.player
 p.set_physics_process(false)
 var bridge=p.growth_bridge
 var s:Dictionary=a.state
 var cfg:Dictionary=p.effective_config()
 var hp:float=s.player.vitals.hp
 var stamina:float=s.player.combat.stamina
 assert(bridge.growth.award(s,'quest',1200,'check').ok)
 for id in ['vitality','stamina','accuracy','stealth','hurt_speed']:assert(bridge.growth.invest(s,id).ok)
 cfg=p.effective_config()
 assert(s.player.vitals.max_hp==hp+10 and s.player.vitals.hp==hp)
 assert(cfg.max_stamina==a.config.max_stamina+5 and s.player.combat.stamina==stamina)
 assert(s.player.vitals.visual_accumulation_factor==0.8)
 var gun:Dictionary=a.config.weapons.rifle
 var base:float=WeaponRules.spread(gun,0,false,false)
 var better:float=WeaponRules.spread(gun,0,false,false,bridge.spread_factor(s))
 assert(better<base)
 assert(is_equal_approx(WeaponRules.spread(gun,0.3,false,false,bridge.spread_factor(s))-better,0.3))
 s.player.combat.hurt_iframe=0;s.player.combat.hurt_boost=0
 var armor_result:Dictionary=p.receive_attack({'damage':1.0,'penetration':0.0})
 assert(armor_result.hp_loss==0 and armor_result.armor_loss>0 and s.player.combat.hurt_boost==0)
 s.player.equipment.armor='';s.player.combat.hurt_iframe=0;s.player.combat.dodge_left=0
 p.receive_attack({'damage':1.0,'penetration':10.0},Vector2.ZERO,true)
 assert(s.player.combat.hurt_boost==2.0)
 assert(ActionRules.movement_factor(s.player.combat,p.effective_config())==1.2)
 s.player.combat.hurt_boost=0.5;s.player.combat.hurt_iframe=0
 p.receive_attack({'damage':1.0},Vector2.ZERO,true)
 assert(s.player.combat.hurt_boost==2.0)
 var timer:float=s.player.combat.hurt_boost
 ActionRules.tick(s.player.combat,1,p.effective_config(),false,false,false,true)
 assert(s.player.combat.hurt_boost==timer)
 var ui=p.progression_panel;ui.open_view('talents')
 assert(ui.visible and p.progression_ui_blocked and not paused)
 ui.close();assert(not p.progression_ui_blocked)
 var quote:Dictionary=bridge.growth.preview_reset(s,true)
 var before:=JSON.stringify(s)
 assert(not bridge.reset(s,a.inventory,quote,false));assert(JSON.stringify(s)==before)
 assert(bridge.reset(s,a.inventory,quote,true))
 cfg=p.effective_config()
 assert(s.player.vitals.max_hp==hp and is_equal_approx(s.player.vitals.hp,hp-0.7))
 assert(not s.player.vitals.hurt_speed_talent and s.player.combat.hurt_boost==0)
 print('DEV313 REAL PLAYER EFFECTS RESET PASS')
 quit()


