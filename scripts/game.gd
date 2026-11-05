extends Node3D

const Arena = preload("res://scripts/arena.gd")
const Player = preload("res://scripts/player.gd")
var arena: Node3D
var player: CharacterBody3D

func _ready() -> void:
	var env = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("5b7fc8")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dce8ff")
	settings.ambient_light_energy = .52
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-35,0)
	sun.light_color = Color("fff3d5")
	sun.light_energy = .22
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	arena = Arena.new()
	add_child(arena)
	player = Player.new()
	add_child(player)
	player.reset_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/visual-stage.png")
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
