extends SceneTree
var game: Node3D
const OUT="res://docs/art/space/review-d/"
func _initialize():run.call_deferred()
func shot(label: String):
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(OUT+label+".png")==OK)
func run():
 game=load("res://scenes/moonbase.tscn").instantiate();root.add_child(game)
 while not game.title_frame_ready:await process_frame
 game.qa_mode=true;game.start_run();game.begin_running();game.invulnerable=999
 game.set_physics_process(false);game.player.set_physics_process(false)
 game.clear_round();game.rules.start();game.state="RUNNING";game.player.enabled=true
 game.hud.go_time=0
 var actors=[]
 for spec in [[Vector3(0,.05,0),false],[Vector3(2,.05,0),true]]:
  var actor=game.spawn_enemy(spec[0],spec[1]);actor.set_physics_process(false);actor.rotation.y=PI;actors.append(actor)
 for distance in [8,15,20]:
  game.player.position=Vector3(1,.05,distance);game.player.rotation.y=0;game.player.pitch=0;game.player.camera.rotation=Vector3.ZERO
  await shot("readability-"+str(distance)+"m")
 game.player.position=Vector3(2,.05,13)
 assert(game.player.coil_materials.size()>0)
 game.set_destroy_active(true)
 for material in game.player.coil_materials:assert(material.emission.r>material.emission.b)
 game.set_destroy_active(false)
 for material in game.player.coil_materials:assert(material.emission.b>material.emission.r)
 game.request_grenade();game.update_grenades(.08)
 assert(game.grenade_stock==3 and game.grenades.is_empty())
 game.player.animate_grenade_throw();await shot("grenade-hand")
 game.update_grenades(.06)
 assert(game.grenade_stock==2 and game.grenades.size()==1)
 assert(game.grenades[0].visual.scene_file_path.ends_with("lunar-grenade.glb"))
 var fuse=game.grenades[0].fuse
 game.pause_run();game.set_physics_process(true)
 await create_timer(.3).timeout
 assert(game.grenades[0].fuse==fuse)
 game.set_physics_process(false);game.menu_action("resume")
 game.update_grenades(.2);assert(game.grenades.size()==1)
 game.start_run();game.begin_running();game.set_physics_process(false);game.player.set_physics_process(false)
 assert(game.grenades.is_empty() and game.grenade_stock==3 and game.grenade_throw_time==0)
 game.request_grenade();game.start_run()
 assert(game.grenades.is_empty() and game.grenade_stock==3 and game.grenade_throw_time==0)
 FileAccess.open(OUT+"finish-check.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":["8/15/20m rendered readability samples","local coil overload and reset","new projectile asset","single release stock debit","fuse freezes during actual pause","restart clears thrown grenade","cancel before release restores stock"],"note":"Automated functional checks and captured samples; not three manual playthroughs."},"  "))
 print("MOONBASE_FINISH_PASS")
 game.queue_free();await process_frame;quit()
