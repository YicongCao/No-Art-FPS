extends SceneTree
const OUT = "res://docs/art/space/review-b/asset-views/"
func _initialize():run.call_deferred()
func run():
 DirAccess.make_dir_recursive_absolute(OUT)
 root.size=Vector2i(1200,900)
 var stage=Node3D.new();root.add_child(stage)
 var world=WorldEnvironment.new();world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color("111a25")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color("c6d3df")
 world.environment.ambient_light_energy=.35;stage.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-155,0);sun.light_energy=.65;stage.add_child(sun)
 var camera=Camera3D.new();camera.fov=40;stage.add_child(camera);camera.current=true
 for name in ["interceptor","rifle-mech","assault-mech","ion-rifle"]:
  var model=load("res://assets/models/space/"+name+".glb").instantiate();stage.add_child(model)
  if name=="ion-rifle":
   model.find_child("RightHand",true,false).hide();model.find_child("SupportHand",true,false).hide()
  for side in ["front","rear"]:
   var target=Vector3(0,1,0)
   camera.position=Vector3(2.8,1.8,-4 if side=="front" else 4)
   if name=="interceptor":
    camera.position=Vector3(12,10,-18 if side=="front" else 18);target=Vector3(0,2,0)
   elif name=="ion-rifle":
    camera.position=Vector3(1.9,.7,-1.2 if side=="front" else 1);target=Vector3(0,0,-.2)
   camera.look_at(target)
   for i in 8:await process_frame
   await RenderingServer.frame_post_draw
   assert(root.get_texture().get_image().save_png(OUT+name+"-"+side+".png")==OK)
  model.queue_free();await process_frame
 print("MOONBASE_ASSET_VIEWS_PASS")
 quit()
