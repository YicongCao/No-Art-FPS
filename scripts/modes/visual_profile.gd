extends Resource

# Paths permit lazy loading; export manifests must explicitly include these resources.
@export_file("*.glb") var rifle_enemy = ""
@export_file("*.glb") var rusher_enemy = ""
@export_file("*.glb") var rifle = ""

@export var legacy_toy_materials = true
@export var rifle_muzzle = Vector3(0,.015,-1.0)
@export var sight_rear = Vector3(0,.269,-.17)
@export var sight_front = Vector3(0,.205,-.65)
