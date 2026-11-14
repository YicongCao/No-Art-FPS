extends SceneTree
var game: Node3D
var before="--before" in OS.get_cmdline_user_args()
var out="res://docs/art/space/review-e/"
func _initialize():run.call_deferred()
func shot(label: String):
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(out+label+".png")==OK)
func run():
 out+="before/" if before else "after/"
 game=load("res://scenes/moonbase.tscn").instantiate();root.add_child(game)
 while not game.title_frame_ready:await process_frame
 if "--baseline-earth" in OS.get_cmdline_user_args():
  var old=load("res://artifacts/local/earth-baseline.tscn").instantiate()
  var planet=old.get_node("OrbitalPlanet").duplicate()
  game.arena.get_node("OrbitalPlanet").free();game.arena.add_child(planet);old.free()
  game.player.gun.hide();game.hud.hide();game.player.camera.fov=12
  aim_earth();out="res://docs/art/space/review-e/before/";await shot("earth-detail")
  game.queue_free();await process_frame;quit();return
 game.qa_mode=true;game.start_run();game.begin_running();game.invulnerable=999
 game.set_physics_process(false);game.player.set_physics_process(false)
 for actor in game.live_enemies():actor.set_physics_process(false)
 game.hud.go_time=0;game.rules.elapsed=18;game.rules.kills=8
 await shot("gameplay")
 game.player.set_aim_requested(true);await create_timer(.4).timeout
 var sight=game.player.gun.to_global(game.session.visual_profile.sight_front)
 var error=game.player.camera.unproject_position(sight).distance_to(root.get_visible_rect().size*.5)
 assert(error<2)
 var reticle=game.player.gun.find_child("Reticle",true,false)
 if reticle:
  var visual_error=game.player.camera.unproject_position(reticle.global_transform*reticle.mesh.get_aabb().get_center()).distance_to(root.get_visible_rect().size*.5)
  assert(visual_error<2);print("RETICLE_OFFSET_PX ",visual_error)
 await shot("ads")
 game.player.set_aim_requested(false);await create_timer(.3).timeout
 game.reload_time=game.RELOAD_DURATION*.5;await shot("reload");game.reload_time=0
 for ammo in [0,1,4,20]:
  game.ammo=ammo;await shot("ammo-"+str(ammo))
 game.rules.kills=999;await shot("hud-999");game.rules.kills=8
 game.set_destroy_active(true);await shot("overload");game.set_destroy_active(false)
 game.player.gun.hide();game.hud.hide();game.player.camera.fov=12
 aim_earth()
 await shot("earth-detail")
 FileAccess.open(out+"check.json",FileAccess.WRITE).store_string(JSON.stringify({"ads_error_pixels":error,"states":["opening","ADS","reload","0/1/4/20 ammo","999 kills","overload","earth detail"],"note":"Fixed-camera native renderer; Earth detail uses 12 degree FOV for asset inspection only."},"  "))
 print("PRESENTATION_PASS before=",before," ADS=",error)
 game.queue_free();await process_frame;quit()

func aim_earth():
 var direction=game.player.camera.global_position.direction_to(game.arena.get_node("OrbitalPlanet").global_position)
 game.player.rotation.y=atan2(-direction.x,-direction.z)
 game.player.pitch=asin(direction.y);game.player.camera.rotation.x=game.player.pitch
