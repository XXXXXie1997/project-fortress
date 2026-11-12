extends SceneTree
func _initialize():
 var arena=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(arena)
 for i in 20:await physics_frame
 assert(arena.y_sort_enabled)
 for cell in [Vector2i(1,2),Vector2i(8,9),Vector2i(20,4)]:
  assert(arena.grid.world_to_cell(arena.grid.cell_to_world(cell))==cell)
 var query:=PhysicsPointQueryParameters2D.new()
 query.position=arena.grid.logical_to_world(Vector2(1155,200));query.collision_mask=1
 assert(not arena.get_world_2d().direct_space_state.intersect_point(query).is_empty())
 query.position=arena.grid.logical_to_world(arena.gate_logical);query.collision_mask=16
 assert(not arena.get_world_2d().direct_space_state.intersect_point(query).is_empty())
 assert((arena.player.collision_mask & 16)==0)
 var fixture=arena.fixtures[0]
 var size:Array=arena.building.config.types[fixture.kind].size
 var record:Dictionary=arena.state.base.buildings[fixture.id]
 assert(fixture.logical_rect.position==Vector2(record.cell[0],record.cell[1])*48)
 assert(fixture.logical_rect.size==Vector2(size[0],size[1])*48)
 query.position=fixture.position;query.collision_mask=32
 assert(not arena.get_world_2d().direct_space_state.intersect_point(query).is_empty())
 var start:Vector2=arena.grid.logical_to_world(Vector2(1250,650))
 var goal:Vector2=arena.grid.logical_to_world(Vector2(950,650))
 var nav:AStar2D=arena.base_navigation
 var path:=nav.get_point_path(nav.get_closest_point(start),nav.get_closest_point(goal))
 assert(path.size()>2)
 for point in path:
  var logical:Vector2=arena.grid.world_to_logical(point)
  if logical.x>1143 and logical.x<1173:assert(logical.y>405 and logical.y<535)
 print('DEV402 DIAMOND GEOMETRY PASS')
 quit()
