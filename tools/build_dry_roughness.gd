extends SceneTree
func _initialize() -> void:
 var im=Image.load_from_file("res://assets/textures/rain_market/surface_noise.png")
 for y in range(im.get_height()):
  for x in range(im.get_width()):
   var v=.65+.35*im.get_pixel(x,y).r
   im.set_pixel(x,y,Color(v,v,v,1))
 im.save_png("res://assets/textures/rain_market/dry_roughness.png")
 quit()
