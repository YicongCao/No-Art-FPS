extends SceneTree

const Sync = preload("res://scripts/performance/web_music_sync.gd")

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var player := AudioStreamPlayer.new()
	root.add_child(player)
	var sync := Sync.new()
	sync.player = player
	player.stream = preload("res://assets/music/bb_office.ogg")
	sync.start_track(0.0)
	assert(not sync.looped and sync.length==60.0)
	assert(sync.track_target(.1)<0.0 and sync.track_target(59.9)<0.0)
	assert(sync.track_target(45.0)==45.0,"A full-round cue does not restart at frenzy")
	assert(not sync.observe(5.0,4.5))
	assert(not sync.observe(5.5,5.0))
	assert(not sync.observe(6.0,5.95),"A transient hitch must not trigger correction")
	assert(not sync.observe(6.5,6.0))
	assert(not sync.observe(7.0,7.5),"A sign reversal resets confirmation")
	sync.set_volume(-12.0)
	sync.suspend()
	assert(sync.streak==0 and player.volume_db==-12.0)
	# A cue stopped unexpectedly in mid-round is recovered with a fade, not
	# started from the beginning. Use the real stream but control game time.
	for time in [7.5,8.0,8.5]:assert(not sync.update(.5,time))
	assert(sync.fade==-1 and sync.seeks==0)
	assert(not sync.update(.03,8.53) and player.volume_db<-12.0)
	sync.suspend()
	assert(sync.seeks==0 and sync.fade==0 and player.volume_db==-12.0,"Pause cancels a pending seek")
	for time in [9.0,9.5,10.0]:assert(not sync.update(.5,time))
	assert(sync.update(.08,10.08) and player.playing)
	assert(sync.seeks==1 and sync.cooldown==Sync.COOLDOWN)
	assert(not sync.update(.08,10.16) and player.volume_db==-12.0)
	player.stop()
	for i in range(8):assert(not sync.update(.5,10.66+i*.5),"Cooldown blocks repeat recovery")
	player.stream = preload("res://assets/music/ferry_last_call.ogg")
	sync.start_track(45.0)
	assert(sync.looped and sync.cooldown==0.0 and sync.streak==0)
	assert(is_equal_approx(sync.track_target(47.0),2.0),"Frenzy cue uses its phase origin")
	assert(is_equal_approx(sync.track_target(45.0+sync.length+.6),.6))
	assert(not sync.observe(.07,sync.length-.05),"Wrapping at the loop edge is not drift")
	assert(not sync.observe(.5,0.0) and not sync.observe(1.0,.5) and sync.observe(1.5,1.0))
	player.queue_free()
	await create_timer(.25).timeout
	print("WEB_MUSIC_SYNC_PASS: continuous and phase cues, loop edge, fade, pause and cooldown")
	quit()
