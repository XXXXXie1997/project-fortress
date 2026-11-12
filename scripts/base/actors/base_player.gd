extends "res://scripts/game/player_actor.gd"
func _ready():
 super._ready()
 collision_mask=collision_mask_for_action(false)
func collision_mask_for_action(is_dodging:bool)->int:
 return super.collision_mask_for_action(is_dodging) | 32
func wireless_station_active()->bool:
 return arena.station_active()
