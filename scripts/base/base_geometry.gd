extends RefCounted
## One logical geometry contract for walls, navigation and construction.
const CELL := 48.0
const GATE := Vector2(1152, 470)
const OPEN_TOP := 405.0
const OPEN_BOTTOM := 535.0
const WALL := 30.0

static func bounds_rect(bounds: Array) -> Rect2:
	return Rect2(float(bounds[0]) * CELL, float(bounds[1]) * CELL, float(bounds[2]) * CELL, float(bounds[3]) * CELL)

static func entrance_reservation(bounds: Array) -> Rect2:
	var area := bounds_rect(bounds)
	return Rect2(GATE.x - 9, OPEN_TOP - WALL, maxf(WALL, area.end.x - GATE.x + 9), OPEN_BOTTOM - OPEN_TOP + WALL * 2)

static func wall_rects(bounds: Array) -> Array[Rect2]:
	var area := bounds_rect(bounds)
	var front := area.end.x - 9
	var walls: Array[Rect2] = [
		Rect2(front, area.position.y, WALL, OPEN_TOP - area.position.y),
		Rect2(front, OPEN_BOTTOM, WALL, area.end.y - OPEN_BOTTOM),
		Rect2(area.position.x, area.position.y, WALL, area.size.y),
		Rect2(area.position.x, area.position.y, area.size.x, WALL),
		Rect2(area.position.x, area.end.y - WALL, area.size.x, WALL)]
	# Expanded wings flank a passage leading back to the original shield.
	if area.end.x > GATE.x:
		walls.append(Rect2(GATE.x - 9, OPEN_TOP - WALL, area.end.x - GATE.x + 9, WALL))
		walls.append(Rect2(GATE.x - 9, OPEN_BOTTOM, area.end.x - GATE.x + 9, WALL))
	return walls

static func approach_side(point: Vector2, bounds: Array) -> bool:
	var area := bounds_rect(bounds)
	return point.x > area.end.x + 21 or (point.x > GATE.x + 21 and point.y >= OPEN_TOP and point.y <= OPEN_BOTTOM)

static func navigation_rect(bounds: Array) -> Rect2:
	var area := bounds_rect(bounds)
	# The eastern apron includes existing wave spawn positions, not a build area.
	return Rect2(area.position, area.size + Vector2(528, 0))
