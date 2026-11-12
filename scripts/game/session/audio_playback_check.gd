extends SceneTree
func _initialize():call_deferred("run")
func run():
	var audio=load("res://scripts/game/session/session_audio.gd").new();root.add_child(audio)
	for context in ["base","field","battle"]:
		audio.play_context(context)
		await process_frame
		assert(not audio.music.playing and not audio.ambience.playing)
	audio.set_charge(true,false)
	await create_timer(.1,true).timeout
	assert(audio.charge_loop.playing)
	var starts:int=audio.charge_starts
	audio.set_charge(true,true)
	assert(audio.charge_loop.stream_paused)
	audio.set_charge(true,false)
	assert(audio.charge_starts==starts)
	audio.set_charge(false,false)
	assert(not audio.charge_loop.playing and audio.sfx.last.has("charge_out:player"))
	audio.shutdown_audio();await create_timer(.1,true).timeout
	print("SESSION_BACKGROUND_DISABLED_CHARGE_AUDIO_PASS")
	quit()
