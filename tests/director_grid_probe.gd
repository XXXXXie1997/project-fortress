extends SceneTree
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
func _initialize() -> void:
	var grid = load("res://scripts/world/grid/grid_projection.gd").new(48.0, Vector2(96,48), Vector2(300,-120))
	check(grid.cell_to_world(Vector2i.ZERO, false).is_equal_approx(Vector2(300,-120)), "origin")
	check(grid.cell_to_world(Vector2i(1,0), false).is_equal_approx(Vector2(348,-96)), "right diagonal")
	check(grid.cell_to_world(Vector2i(0,1), false).is_equal_approx(Vector2(252,-96)), "left diagonal")
	check(grid.cell_to_world(Vector2i.ZERO).is_equal_approx(Vector2(300,-96)), "cell center")
	for x in range(-12,13):
		for y in range(-12,13):
			var cell := Vector2i(x,y)
			check(grid.world_to_cell(grid.cell_to_world(cell)) == cell, "negative/positive picking %s" % cell)
			var logical := Vector2(x*48+7.5,y*48+31.25)
			check(grid.world_to_logical(grid.logical_to_world(logical)).is_equal_approx(logical), "continuous roundtrip")
	var bounds: Rect2 = grid.world_bounds(Rect2(0,0,96,48))
	check(bounds.position.is_equal_approx(Vector2(252,-120)) and bounds.size.is_equal_approx(Vector2(144,72)), "projected bounds")
	var footprint: PackedVector2Array = grid.rect_polygon(Rect2(0,0,96,48))
	check(Geometry2D.is_point_in_polygon(grid.cell_to_world(Vector2i(1,0)),footprint), "2x1 footprint inside")
	check(not Geometry2D.is_point_in_polygon(grid.cell_to_world(Vector2i(0,1)),footprint), "2x1 footprint outside")
	var nav = load("res://scripts/world/grid/projected_navigation.gd").new()
	nav.projection=grid
	nav.region=Rect2i(0,0,5,5)
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	check(is_equal_approx(nav._compute_cost(Vector2i(1,1),Vector2i(2,2)),48.0), "short screen diagonal")
	check(is_equal_approx(nav._compute_cost(Vector2i(1,2),Vector2i(2,1)),96.0), "long screen diagonal")
	nav.set_point_solid(Vector2i(1,0),true)
	nav.set_point_solid(Vector2i(0,1),true)
	check(nav.get_id_path(Vector2i(0,0),Vector2i(2,2)).is_empty(), "no corner cutting")
	print("GRID_PROBE_FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
