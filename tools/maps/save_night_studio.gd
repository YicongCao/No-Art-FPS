extends SceneTree

const Studio = preload("res://scripts/maps/night_studio.gd")
const Destructible = preload("res://scripts/destructible.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const MODEL_PATH = "res://assets/models/studio/"
var studio: Node3D
var models: Dictionary = {}

func _initialize() -> void:
	build.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node)
	node.owner = studio
	return node

func model(parent: Node3D, asset: String, label: String) -> Node3D:
	if not models.has(asset):models[asset] = load(MODEL_PATH+asset+".glb")
	return add(parent,models[asset].instantiate(),label)

func collider(parent: Node3D, shape: Shape3D, center: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = center
	body.collision_mask = 0
	add(parent,body,"Body%d"%parent.get_child_count())
	var node = CollisionShape3D.new()
	node.shape = shape
	add(body,node,"Collision")
	return body

func box(parent: Node3D, center: Vector3, size: Vector3) -> StaticBody3D:
	var shape = BoxShape3D.new()
	shape.size = size
	return collider(parent,shape,center)

func prism(parent: Node3D, outline: PackedVector3Array, thickness: Vector3) -> void:
	var shape = ConvexPolygonShape3D.new()
	var points = outline.duplicate()
	for point in outline:points.append(point+thickness)
	shape.points = points
	collider(parent,shape)

func place_props(items: Array) -> void:
	var props = add(studio,Node3D.new(),"Props")
	for item in items:
		var part = Destructible.new()
		part.position = vec(item.at)
		part.rotation.y = float(item.angle)
		part.scenery = not item.structural
		part.paper = item.paper
		part.local_bounds = true
		part.palette = Color("46727a") if item.paper else Color("82638a")
		add(props,part,item.name)
		var visual = model(part,item.asset,"Model")
		var size = vec(item.size)
		var body = box(part,Vector3.UP*size.y*.5,size)
		if item.shoot_only:body.collision_layer = 16
		part.bounds = AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
		part.saved_parts.append(part.get_path_to(visual))
		part.saved_parts.append(part.get_path_to(body))
		studio.structure_paths.append(studio.get_path_to(part))

func light_beams(spots: Array) -> void:
	var rig = add(studio,Node3D.new(),"PracticalLighting")
	for i in range(spots.size()):
		var origin = vec(spots[i][0])
		var target = vec(spots[i][1])
		var spot = SpotLight3D.new()
		spot.position = origin
		spot.light_color = Color("ffe5b3")
		spot.light_energy = .65
		spot.spot_range = origin.distance_to(target)+1.8
		spot.spot_angle = 32.0
		add(rig,spot,"StageSpot%d"%i)
		spot.look_at_from_position(origin,target)


func window(parent: Node3D, center: Vector3, extent: Vector2, label: String) -> void:
	var pane = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = extent
	var paint = StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.albedo_color = Color(.4,.7,.87,.12)
	pane.mesh = quad
	pane.material_override = paint
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pane.position = center
	add(parent,pane,label)
	box(parent,center,Vector3(extent.x,extent.y,.08))

func markers(parent: Node3D, label: String, positions: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in range(positions.size()):
		var marker = Marker3D.new()
		marker.position = vec(positions[i])
		add(parent,marker,label+str(i))
		if label=="Opening":marker.set_meta("fast",i>=6)
		paths.append(studio.get_path_to(marker))
	return paths

func build() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/night_studio_layout.json"))
	studio = Studio.new()
	studio.name = "NightStudio"
	studio.map_id = "night_studio"
	studio.sun_energy = .13
	studio.sun_color = Color("ffe8c7")
	studio.sun_rotation_degrees = Vector3(-64,18,0)
	studio.fall_limit = -3.0
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("182541")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4eaff")
	env.ambient_light_energy = .88
	studio.environment_override = env
	var architecture = add(studio,Node3D.new(),"Architecture")
	for asset in layout.fixed:model(architecture,asset,asset.capitalize().replace(" ",""))
	for entry in layout.boxes:box(architecture,vec(entry[0]),vec(entry[1]))
	for points in layout.ramps:
		var outline = PackedVector3Array()
		for point in points:outline.append(vec(point))
		prism(architecture,outline,Vector3.DOWN*.23)
	for ends in layout.ramp_rails:
		var a = vec(ends[0])
		var b = vec(ends[1])
		var height = Vector3.UP*1.13
		prism(architecture,PackedVector3Array([a,b,b+height,a+height]),Vector3.RIGHT*.10)
	window(architecture,Vector3(-17.75,1.83,-14.24),Vector2(7.53,1.96),"ControlRoomGlass")
	window(architecture,Vector3(-17.15,1.73,14.78),Vector2(7.48,2.06),"NewsroomGlass")
	place_props(layout.props)
	light_beams(layout.spots)
	for at in [Vector3(12.7,0,-2.65),Vector3(-12.2,0,11.4),Vector3(6.2,0,12.1)]:
		var barrel = Barrel.new()
		barrel.position = at
		add(studio,barrel,"Barrel%d"%studio.barrel_paths.size())
		studio.barrel_paths.append(studio.get_path_to(barrel))
	var routes = add(studio,Node3D.new(),"Markers")
	studio.start_path = markers(routes,"PlayerStart",[layout.start])[0]
	studio.get_node(studio.start_path).rotation.y = -.48
	studio.opening_paths = markers(routes,"Opening",layout.opening)
	studio.reinforcement_paths = markers(routes,"Reinforcement",layout.spawns)
	studio.respawn_paths = markers(routes,"Respawn",layout.respawns)
	studio.route_paths = markers(routes,"Tour",layout.route)

	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .5
	mesh.agent_height = 2.0
	mesh.agent_max_climb = .25
	mesh.agent_max_slope = 39
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = "studio_navigation"
	mesh.filter_baking_aabb = AABB(Vector3(-22.5,-.6,-17.5),Vector3(45,6.4,35))
	nav.navigation_mesh = mesh
	add(studio,nav,"Navigation")
	studio.navigation_path = studio.get_path_to(nav)
	studio.add_to_group("studio_navigation",true)
	root.add_child(studio)
	nav.bake_navigation_mesh(false)
	assert(mesh.get_polygon_count()>0,"Studio navigation bake is empty")
	for _tick in range(30):
		await physics_frame
		var map = studio.get_world_3d().navigation_map
		if NavigationServer3D.map_get_iteration_id(map)>0 and NavigationServer3D.map_get_closest_point_owner(map,studio.player_start().origin)==nav.get_rid():break
	if not studio.validate_navigation():
		quit(1)
		return
	for node in studio.find_children("*","",true,false):
		if node.has_meta("structure"):node.remove_meta("structure")
	var scene = PackedScene.new()
	assert(scene.pack(studio)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/night_studio.tscn")==OK)
	print("STUDIO_SCENE_READY ",mesh.get_polygon_count()," navigation polygons")
	quit()
