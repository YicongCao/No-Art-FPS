extends Node3D

const Catalog = preload("res://scripts/maps/interactive_prop_catalog.gd")
const Prop = preload("res://scripts/maps/interactive_prop.gd")
var props: Array[Node3D] = []

func setup(map: Node3D) -> void:
	name = "InteractiveProps"
	for entry in Catalog.PLACEMENTS.get(map.map_id,[]):
		var prop := Node3D.new()
		prop.set_script(Prop)
		prop.name = "%s_%02d"%[entry.kind,props.size()]
		add_child(prop)
		prop.position = Vector3(entry.at[0],entry.at[1],entry.at[2])
		prop.rotation.y = entry.yaw
		prop.setup(map.game,entry.kind,Catalog.MODELS[entry.kind])
		props.append(prop)

func restore() -> void:
	for prop in props:prop.restore()

func blast(center: Vector3, radius: float) -> void:
	for prop in props:prop.blast(center,radius)
