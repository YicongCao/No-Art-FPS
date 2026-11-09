extends SceneTree

# Capture extra horizontal space so the opening camera also fits wide phones.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Title capture requires a renderer")
		quit(1)
		return
	root.size = Vector2i(3240,1080)
	root.content_scale_size = root.size
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for frame in range(900):
		await process_frame
		if not game.title_frame_ready:continue
		var image: Image = game.hud.title_frame.get_image()
		var result = image.save_webp("res://web/title-background.webp",true,.92)
		print("WEB_TITLE_CAPTURE ",image.get_size()," error=",result)
		quit(0 if result==OK else 1)
		return
	push_error("Opening camera did not become ready")
	quit(1)
