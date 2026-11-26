extends "res://scripts/world/maps/map_arena.gd"
## Standalone art review. The formal session mounts the same geometry and actors.
func _ready():
	await super._ready()
	await depart("suburbs","south")
	player.position=projection.logical_to_world(Vector2(740,1510))
	player.camera.force_update_scroll()
