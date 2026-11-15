extends "res://scripts/game/session/session_shell.gd"
func _ready():
	add_child(preload("res://scripts/ui/pixel_layout.gd").new())
	super._ready()
