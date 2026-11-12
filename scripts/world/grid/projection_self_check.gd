extends SceneTree
var failures:=0
var checks:=0
func verify(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1;push_error(title)
 else:print('PASS ',title)
func _initialize():call_deferred('run')
func run():
 var p:=GridProjection.new()
 for point in [Vector2.ZERO,Vector2(48,48),Vector2(-120,500),Vector2(2400,1920),Vector2(5.75,-8.125)]:verify(p.world_to_logical(p.logical_to_world(point)).distance_to(point)<.001,'连续坐标往返 '+str(point))
 for cell in [Vector2i.ZERO,Vector2i(-2,4),Vector2i(49,39)]:verify(p.world_to_cell(p.cell_to_world(cell))==cell,'格心拾取 '+str(cell))
 verify(is_equal_approx((p.cell_to_world(Vector2i(1,-1))-p.cell_to_world(Vector2i.ZERO)).length(),2*(p.cell_to_world(Vector2i(1,1))-p.cell_to_world(Vector2i.ZERO)).length()),'两条菱形对角线世界长度不同')
 var other:=GridProjection.new(32,Vector2(72,40),Vector2(123,-52));var sample:=Vector2(813,-543)
 verify(other.world_to_logical(other.logical_to_world(sample)).distance_to(sample)<.001,'非2比1参数与原点可调')
 root.size=Vector2i(1280,720)
 var arena=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(arena)
 for i in range(5):await physics_frame
 await arena.depart('suburbs','south')
 for i in range(3):await physics_frame
 var a:Vector2=p.logical_to_world(Vector2(1000,940));var b:Vector2=p.logical_to_world(Vector2(1120,940))
 verify(not arena.clear_line(a,b,1),'投影后墙体真实LOS阻挡')
 var q:=PhysicsPointQueryParameters2D.new();q.position=p.logical_to_world(Vector2(1068,940));q.collision_mask=1
 verify(not arena.get_world_2d().direct_space_state.intersect_point(q).is_empty(),'投影墙足迹真实物理碰撞')
 var path:PackedVector2Array=arena.find_path(p.logical_to_world(Vector2(240,1700)),p.logical_to_world(Vector2(1320,1190)))
 verify(path.size()>4,'投影AStar有可行跨区域路线')
 var clear:=true
 for i in range(1,path.size()):
  if not arena.clear_line(path[i-1],path[i]):clear=false
 verify(clear,'返回世界路径不穿墙或低掩体')
 var start:Vector2=arena.player.position;Input.action_press('move_right')
 for i in range(30):await physics_frame
 Input.action_release('move_right')
 verify(arena.player.position.x>start.x+70 and absf(arena.player.position.y-start.y)<2,'WASD保持屏幕右而非逻辑斜向')
 verify(arena.y_sort_enabled and arena.geometry.y_sort_enabled,'实际实体与墙体开启同源脚底Y排序')
 verify(Vector2(arena.exploration.maps.suburbs.enemies[0].position[0],arena.exploration.maps.suburbs.enemies[0].position[1]).distance_to(p.logical_to_world(Vector2(430,380)))<.01,'敌人定义只投影一次')
 var indoor
 for enemy in arena.targets:
  if enemy.enemy_id=='s_station':indoor=enemy
 indoor.set_physics_process(false);indoor.position=p.logical_to_world(Vector2(1250,1000));arena.player.position=p.logical_to_world(Vector2(1250,1150))
 for i in range(3):await process_frame
 verify(indoor.visible_to_player() and not arena.enemy_visible_to_player(indoor),'门洞LOS成立但屋顶遮住时本体和地图共同隐藏')
 verify(not indoor.visible,'实际实体被屋顶显示规则隐藏')
 arena.player.position=p.logical_to_world(Vector2(1250,1020))
 for i in range(3):await process_frame
 verify(arena.enemy_visible_to_player(indoor) and indoor.visible,'进入房间淡化屋顶后本体可见')
 var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=arena;bullet.position=a;bullet.direction=a.direction_to(b);bullet.speed=900;arena.add_child(bullet)
 for i in range(10):await physics_frame
 verify(not is_instance_valid(bullet),'世界弹道命中投影高墙并销毁')
 print('GRID/DEV203 ',checks-failures,' / ',checks,' PASS')
 quit(1 if failures>0 else 0)
