extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var s = load("res://scripts/audio/basic_sfx.gd").new()
	root.add_child(s)
	assert(s.emit_event("shot_rifle",Vector2.ZERO,false,0,"a"))
	assert(not s.emit_event("shot_rifle",Vector2.ZERO,false,0,"a"))
	assert(s.emit_event("shot_rifle",Vector2.ZERO,false,0,"b"))
	s.set_charge(true,false,true)
	s.set_charge(true,false,true)
	assert(s.charge_starts == 1)
	s.set_level(0)
	assert(not s.loop.playing)
	assert(not s.emit_event("explosion"))
	for v in s.voices: assert(not v.playing)
	s.set_level(1)
	s.set_paused(true)
	assert(not s.emit_event("explosion"))
	s.shutdown_audio()
	s.set_paused(false)
	for i in range(4): assert(s.emit_event("ui_confirm",Vector2.ZERO,false,0,str(i)))
	for i in range(4): assert(s.emit_event("shot_heavy",Vector2.ZERO,false,0,str(i)))
	assert(s.emit_event("explosion"))
	s.shutdown_audio()
	assert(not s.charging and not s.loop.playing)
	s.free()
	await create_timer(0.15).timeout
	print("AUDIO101 SELF CHECK PASS")
	quit()


