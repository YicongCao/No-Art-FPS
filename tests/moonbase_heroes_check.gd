extends SceneTree
var game: Node3D
var OUT = "res://docs/art/space/review-d/" if "--review-d" in OS.get_cmdline_user_args() else "res://docs/art/space/review-b/"
func _initialize():
 if "--review-e" in OS.get_cmdline_user_args():OUT="res://docs/art/space/review-e/heroes/"
 if "--sensor-heads" in OS.get_cmdline_user_args():OUT="res://docs/art/space/sensor-heads/"
 run.call_deferred()
func pose(at: Vector3, target: Vector3):
 game.player.position=at
 var direction=game.player.camera.global_position.direction_to(target)
 game.player.rotation.y=atan2(-direction.x,-direction.z)
 game.player.pitch=asin(direction.y)
 game.player.camera.rotation.x=game.player.pitch
func shot(name: String):
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(OUT+name+".png")==OK)
func run():
 game=load("res://scenes/moonbase.tscn").instantiate();root.add_child(game)
 for i in 900:
  await process_frame
  if game.title_frame_ready:break
 assert(game.title_frame_ready and game.nav_ready)
 game.qa_mode=true;game.start_run();game.begin_running();game.invulnerable=999
 game.set_physics_process(false);game.player.enabled=true;game.player.set_physics_process(false)
 for actor in game.live_enemies():actor.set_physics_process(false)
 game.hud.go_time=0
 assert(game.player.magazine!=null and game.player.support_hand!=null)
 assert(game.session.visual_profile.rifle.ends_with("ion-rifle.glb"))
 await shot("gameplay")
 game.player.rotation.y=0
 await shot("comparison")
 game.player.rotation.y=.30
 game.hud.hide()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp(OUT+"title-background.webp")
 pose(Vector3(-3,.05,10),Vector3(-13,2.0,2))
 await shot("ship")
 game.clear_round();game.rules.start();game.state="RUNNING"
 pose(Vector3(3,.05,3),Vector3(3,1.0,-2.5))
 var actors=[]
 for spec in [[Vector3(1.8,.05,-2.5),false],[Vector3(4.1,.05,-2.5),true]]:
  var actor=game.spawn_enemy(spec[0],spec[1]);actor.set_physics_process(false)
  actor.look_at(Vector3(3,actor.position.y,3));actors.append(actor)
  for alias in ["Head","Helmet","Torso","LeftArm","RightArm","LeftLeg","RightLeg"]:assert(actor.visual.find_child(alias,true,false)!=null)
  assert(actor.space_visual)
 assert(actors[1].knife!=null and actors[0].enemy_gun!=null)
 game.player.gun.hide()
 await shot("mech-pair")
 if "--sensor-heads" in OS.get_cmdline_user_args():
  for actor in actors:assert(actor.visual.find_children("*Red*","MeshInstance3D",true,false).size()==4)
  pose(Vector3(3,.05,0),Vector3(3,1.55,-2.5));await shot("sensor-closeup")
  pose(Vector3(3,.05,3),Vector3(3,1.0,-2.5))
 for actor in actors:actor.set_physics_process(true)
 await create_timer(.45).timeout
 await shot("mechs-moving")
 for actor in actors:actor.set_physics_process(false)
 actors[1].start_slash();actors[1].process_rusher(.06)
 assert(actors[1].blade_meshes[0].material_overlay!=null)
 await shot("melee-windup")
 actors[1].process_rusher(.40)
 assert(actors[1].rush_state=="SLASH")
 assert(actors[1].blade_meshes[0].material_overlay==null)
 actors[1].process_rusher(.25)
 assert(actors[1].rush_state=="RECOVER")
 actors[1].process_rusher(.70)
 assert(actors[1].rush_state=="CHASE")
 game.player.gun.show();game.hud.show()
 pose(Vector3(3,.05,3),Vector3(3,1.65,-8))
 game.player.set_aim_requested(true)
 await create_timer(.4).timeout
 var sight=game.player.gun.to_global(game.session.visual_profile.sight_front)
 var projected=game.player.camera.unproject_position(sight)
 var center=root.get_visible_rect().size*.5
 assert(projected.distance_to(center)<2,"ADS sight axis must align with shot center")
 await shot("ads")
 game.player.set_aim_requested(false)
 await create_timer(.3).timeout
 game.reload_time=game.RELOAD_DURATION*.5
 await shot("reload")
 assert(game.player.magazine.position.distance_to(game.player.magazine_origin)>.2)
 game.reload_time=0
 await process_frame
 if "--review-d" in OS.get_cmdline_user_args():
  assert(game.sounds["shot"].resource_path.contains("/space/"))
  assert(game.session.round_music.resource_path.ends_with("lunar-round.wav"))
  assert(game.hud.font.has_char("月".unicode_at(0)))
  game.request_grenade();game.grenade_throw_time=game.GRENADE_WINDUP-.06
  game.player.animate_grenade_throw()
  assert(game.player.held_grenade.visible)
  await shot("grenade")
  game.clear_grenades()
  var kills=game.rules.kills;game.rules.kills=999
  await shot("hud-999");game.rules.kills=kills

 var target=actors[0].global_position+Vector3.UP*1.70
 pose(Vector3(3,.05,3),target)
 game.player.crosshair_offset=Vector2.ZERO;game.fire_time=0;game.ammo=20
 await physics_frame
 game.shoot()
 assert(actors[0].dead and actors[0].headshot_death)
 assert(not actors[0].visual.find_child("Helmet",true,false).visible)
 if "--sensor-heads" in OS.get_cmdline_user_args():
  for sensor in actors[0].visual.find_children("*Red*","MeshInstance3D",true,false):assert(not sensor.is_visible_in_tree())
 await shot("headshot")
 game.set_destroy_active(true);game.rules.elapsed=46
 game.fire_time=0;game.shoot()
 await shot("frenzy")
 FileAccess.open(OUT+("heroes-interaction-check.json" if "--review-d" in OS.get_cmdline_user_args() else "interaction-check.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":["navigation","hero profile","named rigid pivots","melee blade socket","windup warning / slash / recover","moving articulated actors","rifle socket","ADS projected error <2px","magazine motion","real bullet headshot","helmet removal","frenzy render"],"ads_error_pixels":projected.distance_to(center),"note":"Scripted native visual check; full-round timing is tested separately."},"  "))
 print("MOONBASE_HEROES_PASS ADS_error=",projected.distance_to(center))
 game.clear_round();game.queue_free()
 for i in 3:await process_frame
 quit()
