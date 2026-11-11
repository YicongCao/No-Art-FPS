extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 for i in range(900):
  await process_frame
  if game.title_frame_ready:break
 game.qa_mode=true;game.set_physics_process(false)
 var sessions: Dictionary=game.TITLE_SESSIONS.duplicate();sessions.merge(game.CONCEPT_SESSIONS)
 for id in ["score_attack","hogwarts","palm_house","night_studio","bb_office"]:
  game.state="TITLE";await game.select_session(sessions[id],id)
  for i in range(3):await process_frame
  var arena: Node3D=game.arena
  if id=="score_attack":
   assert(not game.world_environment.environment.glow_enabled)
   assert(game.world_environment.environment.background_color.is_equal_approx(Color("5b7fc8")))
  var double_faces:=0
  var white_frames:=0
  for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
   if not mesh.mesh or mesh.material_override:continue
   for surface in range(mesh.mesh.get_surface_count()):
    var original=mesh.mesh.surface_get_material(surface) as StandardMaterial3D
    var active=mesh.get_active_material(surface)
    if not original:continue
    if original.cull_mode==BaseMaterial3D.CULL_DISABLED and active is ShaderMaterial and active.shader.code.contains("uniform float metallic_value"):
     assert(active.shader.code.contains("cull_disabled"));double_faces+=1
    if id=="palm_house" and original.resource_name=="frame":
     assert(active is ShaderMaterial and active.shader.code.contains("Faithful painted coating"))
     assert(active.get_shader_parameter("base_color").is_equal_approx(original.albedo_color))
     assert(is_equal_approx(active.get_shader_parameter("metallic_value"),original.metallic));white_frames+=1
  if id=="hogwarts":assert(double_faces>0)
  if id=="palm_house":assert(white_frames>0)
  if id=="night_studio":assert(arena.get_node("StageKeySoftbox/Key").light_energy>0)
  if id=="bb_office":
   var gallery=arena.get_node("OfficePosters")
   assert(gallery.get_child_count()==4)
   var sources: Dictionary={}
   for mount in gallery.get_children():
    var face: MeshInstance3D=mount.get_node("Illustration")
    assert(is_equal_approx(face.mesh.size.x/face.mesh.size.y,9.0/16.0))
    var path: String=face.material_override.albedo_texture.resource_path
    assert(not sources.has(path));sources[path]=true
  game.start_run();game.begin_running();game.set_destroy_active(true);game.start_run()
  if id=="score_attack":assert(game.world_environment.environment.background_color.is_equal_approx(Color("5b7fc8")))
  print("COLOR_MATERIAL_PASS ",id)
 quit()
