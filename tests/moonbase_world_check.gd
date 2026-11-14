extends SceneTree
var game: Node3D
var OUT="res://docs/art/space/review-d/" if "--review-d" in OS.get_cmdline_user_args() else "res://docs/art/space/review-c/"
func _initialize():run.call_deferred()
func pose(at: Vector3, target: Vector3):
 game.player.position=at
 var direction=game.player.camera.global_position.direction_to(target)
 game.player.rotation.y=atan2(-direction.x,-direction.z)
 game.player.pitch=asin(direction.y);game.player.camera.rotation.x=game.player.pitch
func shot(label: String):
 for i in 8:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(OUT+label+".png")==OK)
func run():
 game=load("res://scenes/moonbase.tscn").instantiate();root.add_child(game)
 for i in 900:
  await process_frame
  if game.title_frame_ready:break
 assert(game.nav_ready and game.title_frame_ready)
 game.qa_mode=true;game.start_run();game.begin_running();game.invulnerable=999
 game.set_physics_process(false);game.player.set_physics_process(false)
 for actor in game.live_enemies():actor.set_physics_process(false)
 game.hud.go_time=0
 await shot("gameplay")
 game.hud.hide()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_webp(OUT+"title-background.webp")
 for view in [
  ["service",Vector3(4,.05,8),Vector3(10,2.5,16)],
  ["industrial",Vector3(4,.05,0),Vector3(13,3.3,-16)],
  ["landing",Vector3(-3,.05,10),Vector3(-13,2,2)],
  ["terrain",Vector3(-10,.05,8),Vector3(-32,7,-28)],
  ["overview",Vector3(22,15,27),Vector3(0,1,-2)]]:
  pose(view[1],view[2]);game.player.gun.visible=view[0]!="overview";await shot(view[0])
 game.player.gun.show();game.hud.show();game.clear_round();game.rules.start();game.state="RUNNING"
 var props=game.arena.interactive_props.props
 assert(props.size()==8)
 var count=0;var seen={}
 for prop in props:
  count+=prop.targets.size()
  var target=prop.targets[0]
  var point=target.body.global_transform*target.body.get_child(0).position
  var found=false
  for offset in [Vector3(0,.5,-3),Vector3(2,.5,-3),Vector3(-2,.5,-3),Vector3(0,.7,3),Vector3(3,.7,0),Vector3(-3,.7,0)]:
   var eye=point+prop.global_basis*offset
   var ray=PhysicsRayQueryParameters3D.create(eye,point,game.shot_collision_mask(false));ray.collide_with_areas=true
   var result=game.get_world_3d().direct_space_state.intersect_ray(ray)
   if result.is_empty() or result.collider!=target.body:continue
   pose(eye-Vector3.UP*1.65,point)
   await process_frame;await process_frame
   var clearance=PhysicsRayQueryParameters3D.create(eye,game.player.weapon_muzzle(),1)
   if not game.get_world_3d().direct_space_state.intersect_ray(clearance).is_empty():continue
   found=true;break
  assert(found,"At least one unobstructed shooting position for "+prop.name)
  await physics_frame;await physics_frame
  if not seen.has(prop.kind):await shot(prop.kind+"-before")
  game.fire_time=0;game.ammo=24;game.player.recoil=0;game.shoot()
  if prop.kind in ["space_console","space_supply"]:
   assert(not target.broken and target.hits==1)
   game.fire_time=0;game.player.recoil=0;game.shoot()
  assert(target.broken,"Real bullet must hit breakable target "+prop.name)
  assert(target.body.collision_layer==0 and not target.mesh.visible and target.remnant.visible)
  if not seen.has(prop.kind):await shot(prop.kind+"-after")
  seen[prop.kind]=true
  if prop.kind=="space_battery":
   game.state="PAUSED";var broken=prop.broken_count
   await create_timer(.6).timeout;assert(prop.broken_count==broken)
   game.state="RUNNING";await create_timer(.7).timeout;assert(prop.broken_count==3)
 assert(count==20)
 game.arena.interactive_props.restore()
 for prop in props:
  assert(prop.broken_count==0)
  for target in prop.targets:assert(not target.broken and target.mesh.visible and target.body.collision_layer==32 and not target.remnant.visible)
 var target=props[0].targets[0]
 var blast_at=target.body.global_transform*target.body.get_child(0).position+Vector3(0,0,-.3)
 game.arena.interactive_props.blast(blast_at,2.0)
 assert(props[0].broken_count>0)
 game.start_run();assert(game.arena.interactive_props.props[0].broken_count==0)
 game.begin_running();game.player.set_physics_process(false);game.set_physics_process(false)
 for actor in game.live_enemies():actor.set_physics_process(false)
 game.set_destroy_active(true);game.rules.elapsed=46;await shot("frenzy")
 FileAccess.open(OUT+"interaction-check.json",FileAccess.WRITE).store_string(JSON.stringify({"groups":props.size(),"targets":count,"checks":["navigation ready","all four families real bullet hits","two-hit panels","broken remnant visible","hit collider disabled","battery chain reaction","pause freezes chain","blast response","round reset restores all props"],"note":"Scripted actual rendering and raycast interaction, not manual playtest."},"  "))
 print("MOONBASE_WORLD_PASS groups=8 targets=20")
 game.clear_round();game.queue_free();await process_frame;quit()
