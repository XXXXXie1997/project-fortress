extends SceneTree
var n:=0
func c(ok:bool,s:String):
 print(('PASS ' if ok else 'FAIL ')+s)
 if not ok:n+=1
func _initialize():
 var cfg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/combat.json'))
 var a:=ActionRules.fresh(cfg)
 a.stamina=1
 c(ActionRules.dodge(a,Vector2.ZERO,Vector2.RIGHT,cfg) and a.exhausted and a.dodge_direction==[-1.0,0.0],'last stamina dodge backward')
 c(not ActionRules.start_melee(a,1,cfg),'exhaust locked')
 ActionRules.tick(a,4,cfg,false,false,false)
 c(a.stamina==100 and not a.exhausted,'recover full')
 a.charging=true
 c(ActionRules.dodge(a,Vector2.UP,Vector2.RIGHT,cfg) and a.charging and not ActionRules.can_attack(a),'charging dodge preserved blocks fire')
 ActionRules.switch_weapon(a); c(not a.charging,'switch cancels charge')
 var b:=ActionRules.fresh(cfg); b.stamina=50; b.recovery_delay=0.35
 var d:=b.duplicate(true)
 ActionRules.tick(b,1,cfg,true,true,true)
 for i in range(10):ActionRules.tick(d,0.1,cfg,true,true,true)
 c(is_equal_approx(b.stamina,d.stamina) and not b.sprinting,'recovery timestep aim priority')
 var v:Dictionary={'hp':100.0,'max_hp':100.0,'hurt_speed_talent':true}
 a=ActionRules.fresh(cfg)
 var armor:Dictionary={'durability':100.0,'rating':10.0}
 var r:=DamageRules.hit(v,a,armor,{'damage':10,'penetration':0},cfg)
 c(r.hp_loss==0 and r.armor_loss>0 and a.hurt_iframe>0 and a.hurt_boost==0,'armor only protection no boost')
 a=ActionRules.fresh(cfg)
 r=DamageRules.hit(v,a,armor,{'damage':10,'penetration':100},cfg)
 c(r.hp_loss<10 and r.hp_loss>0,'high penetration retains mitigation')
 var heals:Array=[]
 DamageRules.start_heal(heals,{'cast_time':0.5,'duration':1,'rate':10,'instant':5,'interrupt_cast':false,'interrupt_hot':true})
 v.hp=20
 DamageRules.interrupt_heals(heals);c(heals.size()==1,'cast noninterrupt')
 DamageRules.tick_heals(v,heals,0.7);c(is_equal_approx(v.hp,27),'heal partial hot')
 DamageRules.interrupt_heals(heals);c(heals.is_empty(),'hot interruption')
 var w:Dictionary=cfg.weapons.rifle
 c(is_equal_approx(WeaponRules.spread(w,0.2,false,false,0.5)-WeaponRules.spread(w,0,false,false,0.5),0.2),'precision does not alter bloom')
 c(WeaponRules.attack_parameters({'durability':10,'energy':0},cfg.weapons.energy_blade).damage==12,'unpowered blade')
 a=ActionRules.fresh(cfg);v.hp=100
 r=DamageRules.hit(v,a,{}, {'damage':10},cfg,'player',true)
 c(is_equal_approx(r.hp_loss,10*cfg.self_damage_factor) and a.hurt_boost==cfg.hurt_boost_duration,'self damage boost')
 var old:=JSON.stringify(a)
 ActionRules.tick(a,1,cfg,false,false,false,true)
 c(old==JSON.stringify(a),'pause all action timers')
 c(DamageRules.hit(v,a,{}, {'damage':10},cfg).blocked,'iframe blocks repeat')
 ActionRules.tick(a,0.2,cfg,false,false,false)
 DamageRules.hit(v,a,{}, {'damage':10},cfg)
 c(a.hurt_boost==cfg.hurt_boost_duration,'boost refresh not stack')
 a=ActionRules.fresh(cfg);v.hp=100
 c(DamageRules.hit(v,a,{'durability':0,'rating':100},{'damage':10},cfg).hp_loss==10,'broken armor full damage')
 a=ActionRules.fresh(cfg);v.hp=100
 DamageRules.hit(v,a,{}, {'damage':10},cfg,'enemy')
 c(DamageRules.hit(v,a,{}, {'damage':10},cfg,'enemy').hp_loss==10,'enemy no protection')
 var hp_before:float=v.hp
 heals=[];DamageRules.start_heal(heals,{'instant':10});DamageRules.tick_heals(v,heals,1,true)
 c(v.hp==hp_before and heals.size()==1,'paused healing')
 c(WeaponRules.recover_bloom(0.2,w,1,true)==0.2,'paused bloom')
 var degraded:Dictionary=cfg.weapons.knife.duplicate(true);degraded.degrade_threshold=30;degraded.degraded_factor=0.5
 c(WeaponRules.attack_parameters({'durability':10,'energy':0},degraded).damage==6,'configured degradation')
 c(WeaponRules.attack_parameters({'durability':0,'energy':100},cfg.weapons.knife).is_empty(),'broken weapon disabled')

 print('FAILURES ',n);quit(1 if n else 0)


