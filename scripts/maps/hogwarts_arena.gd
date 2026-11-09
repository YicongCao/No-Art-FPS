extends "res://scripts/maps/concept_arena.gd"

const CLOTH = preload("res://assets/shaders/hogwarts_cloth.gdshader")
const LAKE = preload("res://assets/shaders/hogwarts_lake.gdshader")
const HOUSES = ["gryffindor","hufflepuff","ravenclaw","slytherin"]
var house_cloth: Array[ShaderMaterial] = []
var lake_paint: ShaderMaterial
var sky_paint: ShaderMaterial
var idle_seconds := 0.0

func _ready() -> void:
	super._ready()
	if game==null:return
	sky_paint = environment_override.sky.sky_material.duplicate()
	environment_override.sky = environment_override.sky.duplicate()
	environment_override.sky.sky_material = sky_paint
	lake_paint = ShaderMaterial.new()
	lake_paint.shader = LAKE
	for mesh: MeshInstance3D in get_node("Architecture/lake").find_children("*","MeshInstance3D",true,false):
		mesh.material_override = lake_paint
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for house in HOUSES:
		var paint := ShaderMaterial.new()
		paint.shader = CLOTH
		paint.set_shader_parameter("crest",load("res://assets/art/arena_signs/hogwarts-%s.svg"%house))
		for mesh: MeshInstance3D in get_node("Moving/flag_"+house).find_children("*","MeshInstance3D",true,false):
			mesh.material_override = paint
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		house_cloth.append(paint)

func _process(delta: float) -> void:
	super._process(delta)
	if not lake_paint or game.reduced_motion:return
	var title: bool = game.state=="TITLE"
	if not title and not (game.state=="RUNNING" and game.rules.active):return
	if title:idle_seconds += delta
	var seconds: float = idle_seconds if title else game.rules.elapsed
	var speed := 1.85 if game.destroy_active else .89
	for i in range(house_cloth.size()):
		house_cloth[i].set_shader_parameter("breeze",seconds*speed+i*1.27)
	lake_paint.set_shader_parameter("ripple",seconds*.86)

func set_destroy_lighting(active: bool) -> void:
	super.set_destroy_lighting(active)
	if sky_paint:
		sky_paint.set_shader_parameter("frenzy",1.0 if active else 0.0)
		lake_paint.set_shader_parameter("frenzy",1.0 if active else 0.0)
		environment_override.ambient_light_color = Color("e8b5ff") if active else Color("ead1fb")
