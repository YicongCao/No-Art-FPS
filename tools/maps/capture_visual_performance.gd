extends SceneTree
## Fixed-resolution, reproducible render workload with live enemies and a gentle camera sweep.
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 for i in range(900):
  await process_frame
  if game.title_frame_ready:break
 game.qa_mode=true
 var sessions: Dictionary=game.TITLE_SESSIONS.duplicate()
 sessions.merge(game.CONCEPT_SESSIONS)
 var selected := OS.get_environment("PERF_MAPS").split(",",false)
 var seconds := float(OS.get_environment("PERF_SECONDS"))
 if seconds<1:seconds=20
 var frenzy := OS.get_environment("PERF_FRENZY")=="1"
 var transition := OS.get_environment("PERF_TRANSITION")=="1"
 var results: Array=[]
 for id in sessions:
  if id=="rain_market" or (not selected.is_empty() and not id in selected):continue
  game.state="TITLE"
  await game.select_session(sessions[id],id)
  assert(game.arena.map_id==("yard" if id=="score_attack" else id))
  game.start_run();game.begin_running();game.invulnerable=999
  game.player.enabled=false
  if frenzy:
   game.rules.elapsed=game.rules.duration-game.rules.destroy_duration
   game.set_destroy_active(true)
  var yaw: float=game.player.rotation.y
  for i in range(60):await process_frame
  var frame_ms: Array[float]=[]
  var draws: Array[float]=[]
  var objects: Array[float]=[]
  var primitives: Array[float]=[]
  var start:=Time.get_ticks_usec()
  var last:=start
  if transition:
   game.rules.elapsed=game.rules.duration-game.rules.destroy_duration
   game.set_destroy_active(true)
  while (Time.get_ticks_usec()-start)/1000000.0<seconds:
   game.player.rotation.y=yaw+sin((Time.get_ticks_usec()-start)/1000000.0*.45)*.55
   await process_frame
   var now:=Time.get_ticks_usec()
   frame_ms.append((now-last)/1000.0);last=now
   draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
   objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
   primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
  frame_ms.sort();draws.sort();objects.sort();primitives.sort()
  var row={"map":id,"phase":"transition" if transition else ("frenzy" if frenzy else "normal"),"seconds":seconds,"frames":frame_ms.size(),"frame_ms_max":frame_ms[-1],"frame_ms_p50":percentile(frame_ms,.5),"frame_ms_p95":percentile(frame_ms,.95),"frame_ms_p99":percentile(frame_ms,.99),"draw_calls_p50":percentile(draws,.5),"draw_calls_p95":percentile(draws,.95),"objects_p50":percentile(objects,.5),"primitives_p50":percentile(primitives,.5),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"end_state":game.state}
  results.append(row);print("VISUAL_PERF ",JSON.stringify(row))
 var path:=OS.get_environment("PERF_OUTPUT")
 if path.is_empty():path="res://artifacts/local/visual-perf.json"
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 var file:=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(JSON.stringify({"renderer":"Compatibility","display":DisplayServer.get_name(),"gpu":RenderingServer.get_video_adapter_name(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"note":"Live AI, stationary player, gentle camera yaw. Frame intervals include CPU/GPU scheduling and VSync; not GPU timer queries. Memory counters are engine process totals, not incremental per-map allocations.","maps":results},"  "))
 quit()
func percentile(values: Array[float], p: float) -> float:
 return values[mini(int(values.size()*p),values.size()-1)]
