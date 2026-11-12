extends SceneTree
func _initialize():call_deferred('run')
func run():
 var arena=load('res://scripts/game/combat_arena.gd').new();root.add_child(arena)
 for i in 8:await physics_frame
 var p=arena.player;p.set_physics_process(false)
 var rifle:Dictionary=arena.inventory.spawn(arena.state,'rifle_advanced','ground')
 arena.state.player.equipment.weapon_1=rifle.id;p.slot=1;arena.state.items[rifle.id].energy=30.0
 var count:int=arena.get_child_count()
 Input.action_press('fire');p._physics_process(.016);Input.action_release('fire')
 assert(arena.state.items[rifle.id].energy<30.0 and arena.get_child_count()>count)
 var blade:Dictionary=arena.inventory.spawn(arena.state,'trade_blade','ground')
 arena.state.player.equipment.weapon_1=blade.id;p.cooldown=0
 var target=arena.targets[0];target.position=p.position+(p.get_global_mouse_position()-p.global_position).normalized()*50
 var before:float=target.get_meta('hp')
 Input.action_press('fire');p._physics_process(.016);Input.action_release('fire')
 assert(target.get_meta('hp')<before and arena.state.items[blade.id].energy==0)
 print('CONTENT_PLAYER_ATTACK_PASS');quit()
