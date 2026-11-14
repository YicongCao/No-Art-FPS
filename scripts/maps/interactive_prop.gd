extends Node3D

const Debris = preload("res://scripts/combat_fx.gd")
const SHOT_LAYER = 32
const COLORS = {"ceramic":Color("cc805d"),"wood":Color("c79464"),"glass":Color("b5e3ef"),"metal":Color("acc4d7"),"paper":Color("efe8cf"),"soft":Color("eaa5c3"),"soil":Color("856647")}
var game: Node
var kind: String
var material_kind: String
var targets: Array[Dictionary] = []
var pending: Array[Dictionary] = []
var broken_count := 0

func setup(context: Node, family: String, model: PackedScene) -> void:
	game = context
	kind = family
	material_kind = "wood"
	if kind.begins_with("space_"):material_kind = "metal"
	elif kind in ["pots","seedlings"]:material_kind = "ceramic"
	elif kind in ["popcorn","bottles","icicles","frost","vending"]:material_kind = "glass"
	elif kind in ["vests","balloons","snowman","figures"]:material_kind = "soft"
	elif kind in ["cans","armor","chairs","screens","umbrellas","nozzles"]:material_kind = "metal"
	elif kind in ["clapper","paper_roll","takeout","newspapers"]:material_kind = "paper"
	elif kind=="soilbags":material_kind = "soil"
	set_process(false)
	var visual = model.instantiate()
	add_child(visual)
	for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("Remnant"):mesh.hide()
		if not str(mesh.name).begins_with("Target"):continue
		var id := int(str(mesh.name).trim_prefix("Target"))
		var area := mesh.get_aabb()
		var body := StaticBody3D.new()
		body.name = "ShotTarget"
		body.collision_layer = SHOT_LAYER
		body.collision_mask = 0
		body.set_meta("interactive_prop",self)
		body.set_meta("target_id",id)
		mesh.add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = area.size.max(Vector3.ONE*.045)
		shape.shape = box
		shape.position = area.get_center()
		body.add_child(shape)
		var remnant = visual.find_child("Remnant%d"%id,true,false)
		targets.append({"id":id,"mesh":mesh,"body":body,"remnant":remnant,"pose":mesh.transform,"hits":0,"broken":false})

func hit(id: int, point: Vector3, burning: bool = false) -> void:
	if game.state!="RUNNING" or not game.rules.active:return
	for target in targets:
		if target.id!=id or target.broken:continue
		target.hits += 1
		var strength := 2 if kind in ["slats","foam","screens","vending","frost","space_console","space_supply"] else 1
		if burning or target.hits>=strength:
			break_target(target,point)
		else:
			target.mesh.rotation.z += .065
			emit_fragments(point,2)
			game.play_world_sound("prop_"+material_kind,point,-20,1.2)
		return

func break_target(target: Dictionary, point: Vector3) -> void:
	if target.broken:return
	target.broken = true
	broken_count += 1
	target.mesh.hide()
	target.body.collision_layer = 0
	if target.remnant:target.remnant.show()
	emit_fragments(point,4 if game.reduced_motion else 8)
	game.play_world_sound("prop_"+material_kind,point,-15,1.35 if kind=="balloons" else 1.0)
	if kind=="space_battery":
		for next in targets:
			if next.id!=target.id and not next.broken and not pending.any(func(entry):return entry.id==next.id):
				pending.append({"time":.18+next.id*.09,"id":next.id})
				set_process(true)
	if kind=="cans" and target.id<3:
		for next in targets:
			if next.id>=3 and not next.broken:
				if pending.any(func(entry):return entry.id==next.id):continue
				pending.append({"time":.10+next.id*.055,"id":next.id})
				set_process(true)

func _process(delta: float) -> void:
	if game.state!="RUNNING" or not game.rules.active:return
	for i in range(pending.size()-1,-1,-1):
		pending[i].time -= delta
		if pending[i].time>0:continue
		var id: int = pending[i].id
		pending.remove_at(i)
		for target in targets:
			if target.id==id and not target.broken:break_target(target,target.body.global_position)
	if pending.is_empty():set_process(false)

func emit_fragments(point: Vector3, count: int) -> void:
	# A shared cap also covers grenade bursts across neighbouring groups.
	var count_active := get_tree().get_nodes_in_group("prop_debris").size()
	if count_active>=10:return
	var fx = Debris.new()
	fx.add_to_group("prop_debris")
	fx.game = game
	fx.duration = .65 if kind=="balloons" else 1.25
	game.effects.add_child(fx)
	var tint: Color = COLORS[material_kind]
	for i in range(count):
		var angle = i*2.39996
		var extent = Vector3(.09,.06,.12)
		if material_kind in ["paper","glass"]:extent = Vector3(.15,.012,.12)
		if kind=="balloons":extent = Vector3(.07,.012,.05)
		var velocity = Vector3(cos(angle)*1.8,1.4+(i%3)*.4,sin(angle)*1.8)
		if kind in ["nozzles","space_valves"]:
			extent = Vector3(.035,.09,.035)
			tint = Color("9cddea")
			velocity = Vector3(2.5,1.6+i*.15,sin(angle)*.5)
		if kind=="fruit":
			fx.add_piece(Debris.Shape.ORB,point,Vector3.ONE*.11,Color("e9a34d") if i%2 else Color("8cbb62"),velocity,Vector3.ZERO,global_position.y+.08)
		else:fx.chunk(point,extent,tint,velocity,global_position.y+.05)
	if kind in ["space_battery","space_console"]:
		fx.bloom(point,.05,Color("c5f4ff"))
		for i in range(2 if game.reduced_motion else 5):
			var angle=i*TAU/5
			fx.add_piece(Debris.Shape.FLAME,point,Vector3(.018,.12,.018),Color("54d6e8"),Vector3(cos(angle)*2,1.4,sin(angle)*2))
	fx.show_pieces()

func blast(center: Vector3, radius: float) -> void:
	if game.state!="RUNNING" or not game.rules.active:return
	for target in targets:
		if target.broken:continue
		var aim: Vector3 = target.body.global_transform*target.body.get_child(0).position
		if aim.distance_to(center)>radius:continue
		# Obstacles shield props, while decorative shot targets do not shield explosions.
		var excluded: Array[RID] = []
		if game.blast_clear(center,aim,excluded):break_target(target,aim)

func restore() -> void:
	set_process(false)
	pending.clear()
	broken_count = 0
	for target in targets:
		target.broken = false
		target.hits = 0
		target.mesh.transform = target.pose
		target.mesh.show()
		target.body.collision_layer = SHOT_LAYER
		if target.remnant:target.remnant.hide()
