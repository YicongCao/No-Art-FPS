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
 var out = "res://docs/updates/maps-lookdev-first-pass/after/"
 DirAccess.make_dir_recursive_absolute(out)
 for id in sessions:
  if id=="rain_market":continue
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
  game.set_destroy_active(true)
  for i in range(5):await process_frame
  game.start_run()
  print("MAP_LOOKDEV_PASS ",id," ",game.arena.get_meta("lookdev_materials"))
 quit()
