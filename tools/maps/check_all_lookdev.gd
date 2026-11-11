extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 for i in range(900):
  await process_frame
  if game.title_frame_ready:break
 game.qa_mode = true
 game.set_physics_process(false)
 var sessions: Dictionary = game.TITLE_SESSIONS.duplicate()
 sessions.merge(game.CONCEPT_SESSIONS)
 var out = OS.get_environment("LOOKDEV_CAPTURE_DIR")
 if out.is_empty():out="res://docs/updates/maps-custom-lookdev/after/"
 DirAccess.make_dir_recursive_absolute(out)
 for id in sessions:
  if id=="rain_market":continue
  if not OS.get_cmdline_user_args().is_empty() and not id in OS.get_cmdline_user_args():continue
  game.state = "TITLE"
  await game.select_session(sessions[id],id)
  assert(game.nav_ready)
  assert(game.arena.map_id==("yard" if id=="score_attack" else id))
  assert(game.arena.has_meta("lookdev_v1"),id)
  assert(game.arena.get_meta("lookdev_materials")>0,id)
  game.start_run()
  game.begin_running()
  assert(game.rules.duration==60 and game.live_enemies().size()==8)
  game.player.enabled = false
  game.invulnerable = 999
  for enemy in game.live_enemies():enemy.set_physics_process(false)
  for i in range(25):await process_frame
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+id+".png")
  print("FIXTURES ",id," ",game.arena.get_meta("lookdev_fixtures"))
  if id in ["bb_office","amusement_park","last_ferry","snowline","ginza_station","baggage_below","hogwarts"]:assert(game.arena.get_meta("lookdev_fixtures")>0,id)
  var original_yaw: float = game.player.rotation.y
  for view in [-1,1]:
   game.player.rotation.y=original_yaw+view*.7
   for i in range(3):await process_frame
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+id+("-left" if view<0 else "-right")+".png")
  game.player.rotation.y=original_yaw
  var focus = {"last_ferry":[Vector3(-12,2,0),Vector3(-38,-3,-48)],"amusement_park":[Vector3(0,2,9),Vector3(0,2,1)],"palm_house":[Vector3(0,1.7,7),Vector3(0,3,0)],"hogwarts":[Vector3(-25.3,2.1,24),Vector3(-25.3,5,31.6)],"night_studio":[Vector3(0,1.7,5),Vector3(0,3,-4)],"bb_office":[Vector3(-3.78,1.7,-8),Vector3(-3.78,1.93,-11.94)]}
  if focus.has(id) and DisplayServer.get_name()!="headless":
   var pose: Transform3D = game.player.camera.global_transform
   game.player.camera.global_position=focus[id][0]
   game.player.camera.look_at(focus[id][1])
   for i in range(5):await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+id+"-feature.png")
   if id=="last_ferry":
    var capture = game.arena.get_node("MapLookdev")
    assert(capture.water.get_shader_parameter("harbor_capture_active"))
    capture.reflection.get_texture().get_image().save_png(out+id+"-reflection.png")
   game.player.camera.global_transform=pose
  game.set_destroy_active(true)
  for i in range(5):await process_frame
  assert(game.arena.get_node("MapLookdev").frenzy)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out+id+"-frenzy.png")
  game.start_run()
  assert(not game.arena.get_node("MapLookdev").frenzy)
  print("MAP_LOOKDEV_PASS ",id," ",game.arena.get_meta("lookdev_materials"))
 quit()
