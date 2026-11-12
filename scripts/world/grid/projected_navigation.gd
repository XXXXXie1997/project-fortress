extends AStarGrid2D
var projection:GridProjection
func _compute_cost(from_id:Vector2i,to_id:Vector2i)->float:
 return projection.cell_to_world(from_id).distance_to(projection.cell_to_world(to_id))
func _estimate_cost(from_id:Vector2i,to_id:Vector2i)->float:
 return _compute_cost(from_id,to_id)
