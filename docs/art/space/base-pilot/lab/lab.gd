extends Node3D
# Standalone asset inspection, not gameplay or a benchmark of the full map.
var camera: Camera3D
func _ready() -> void:
 get_viewport().msaa_3d = Viewport.MSAA_4X
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("18232e")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("a8bfd6")
 env.environment.ambient_light_energy = 0.5
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-38,-145,0)
 sun.light_color = Color("fff2de")
 sun.light_energy = 1.0
 sun.shadow_enabled = true
 add_child(sun)
 var floor_mesh := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(80,80)
 floor_mesh.mesh = plane
 var floor_mat := StandardMaterial3D.new()
 floor_mat.albedo_color = Color("747b80")
 floor_mat.roughness = 0.95
 floor_mesh.material_override = floor_mat
 floor_mesh.position.y = -0.02
 add_child(floor_mesh)
 var model: Node3D = load("res://model.glb").instantiate()
 add_child(model)
 camera = Camera3D.new()
 camera.fov = 63
 camera.far = 150
 add_child(camera)
 camera.current = true
 var views := [
  ["front",Vector3(10,7,-13),Vector3(0,3,0)],
  ["rear",Vector3(-11,8,13),Vector3(0,3,0)],
  ["side",Vector3(17,6,0),Vector3(0,3,0)],
  ["fps",Vector3(0,1.65,-12),Vector3(0,2.5,0)],
  ["detail",Vector3(5,4,-9),Vector3(2,3,-2)]
 ]
 for view in views:
  camera.position = view[1]
  camera.look_at(view[2])
  for i in range(12): await get_tree().process_frame
  await RenderingServer.frame_post_draw
  var err := get_viewport().get_texture().get_image().save_png("res://../godot-"+view[0]+".png")
  print("PILOT_CAPTURE ",view[0]," ",err)
 var clay := StandardMaterial3D.new()
 clay.albedo_color = Color(0.65,0.65,0.65)
 clay.roughness = 0.8
 clay.cull_mode = BaseMaterial3D.CULL_DISABLED
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  mesh.material_override = clay
 for view in [views[0], views[1]]:
  camera.position = view[1]
  camera.look_at(view[2])
  for i in range(12): await get_tree().process_frame
  await RenderingServer.frame_post_draw
  var err := get_viewport().get_texture().get_image().save_png("res://../godot-clay-"+view[0]+".png")
  print("PILOT_CLAY_CAPTURE ",view[0]," ",err)
 get_tree().quit()
