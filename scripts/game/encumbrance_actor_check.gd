extends SceneTree
var a
var failures:=0
func check(ok:bool,label:String):
 if not ok:failures+=1;push_error(label)
 else:print('PASS ',label)
func frames(n:int):
 for i in range(n):await physics_frame
func run_move(sprint:bool)->Dictionary:
 a.player.position=Vector2(300,500);a.state.player.combat=ActionRules.fresh(a.config)
 Input.action_press('move_right')
 if sprint:Input.action_press('sprint')
 await frames(12)
 Input.action_release('move_right');Input.action_release('sprint')
 return {'speed':a.player.velocity.length(),'spent':100-a.state.player.combat.stamina}
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720);a=load('res://scripts/game/combat_arena.gd').new();root.add_child(a);await frames(5)
 for item in a.inventory.items_in(a.state,'bag'):a.inventory.move(a.state,item.id,'ground')
 var light:Dictionary=await run_move(true)
 var maximum:float=a.state.containers.bag.maximum_weight
 a.inventory.definitions.test_weight={'size':[1,1],'weight':maximum,'category':'material'}
 var cargo:Dictionary=a.inventory.spawn(a.state,'test_weight','bag')
 check(not cargo.is_empty(),'真实容器装入极限负重')
 var heavy:Dictionary=await run_move(true)
 check(is_equal_approx(heavy.speed/light.speed,.7),'实际冲刺速度乘0.7')
 check(absf(heavy.spent/light.spent-1.5)<.03,'相同物理帧冲刺体耗乘1.5')
 var skeleton:Dictionary=a.inventory.spawn(a.state,'exoskeleton','ground');a.inventory.equip(a.state,skeleton.id,'extra_1',true);a.state.items[skeleton.id].energy=100
 check(is_equal_approx(a.inventory.weight(a.state,'bag'),maximum),'已装备额外装备不计包重')
 var equipped:Dictionary=await run_move(true)
 check(absf(equipped.spent/heavy.spent-.75)<.02,'实际冲刺外骨骼组合')
 Input.action_press('aim');Input.action_press('sprint');Input.action_press('move_right');await frames(3)
 check(a.state.player.combat.aiming and not a.state.player.combat.sprinting and absf(a.player.velocity.length()-75.6)<.1,'负重瞄准优先冲刺且倍率正确')
 Input.action_release('aim');Input.action_release('sprint');Input.action_release('move_right')
 var before:String=WorldState.encode(a.state)
 check(a.inventory.spawn(a.state,'scrap','bag').is_empty() and before==WorldState.encode(a.state),'极限负重拒绝保持原子')
 a.state.player.combat=ActionRules.fresh(a.config)
 var event:=InputEventAction.new();event.action='dodge';event.pressed=true;Input.parse_input_event(event)
 await frames(2)
 check(absf(a.state.player.combat.stamina-73)<.01,'实际闪避输入体耗24×1.5×0.75')
 check(a.player.collision_mask==9,'负重闪避保留穿敌且墙体碰撞')
 check(absf(a.player.velocity.length()-350)<.01,'负重闪避速度350')
 await frames(25)
 a.player.slot=2;a.player.cooldown=0;a.state.player.combat=ActionRules.fresh(a.config)
 Input.action_press('fire');await frames(1);Input.action_release('fire');await frames(1)
 var cost:float=a.weapons.knife_basic.stamina_cost
 check(absf(a.state.player.combat.stamina-(100-cost*1.5*.75))<.01,'实际近战输入组合体耗')
 a.state=WorldState.decode(WorldState.encode(a.state));check(not a.state.is_empty(),'真实状态序列化往返')
 check(is_equal_approx(a.player.encumbrance().speed_factor,.7),'读回当前库存立即计算负重')
 a.inventory.move(a.state,cargo.id,'ground');check(a.player.encumbrance().speed_factor==1,'移出背包立即恢复正常倍率')
 a.state.player.combat=ActionRules.fresh(a.config);a.state.player.combat.stamina=0;a.state.player.combat.exhausted=true
 await frames(5);check(a.state.player.combat.exhausted,'力竭未满仍锁定')
 await frames(190);check(not a.state.player.combat.exhausted,'回满后解除力竭')
 check(a.config.sprint_cost==16 and a.config.dodge_cost==24,'配置没有累乘污染')
 print('DEV504 ACTOR FAILURES ',failures);quit(1 if failures else 0)

