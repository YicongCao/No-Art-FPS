extends Control

var game: Node
var font: Font
var hit = 0.0
var kill_pop = 0.0
var damage = 0.0
var shot = 0.0
var time_pulse = 0.0
var health_shade = 0.0
var feed_shift = 0.0
var ejections: Array[float] = []
var vignette: ColorRect
var menu: Control
var menu_state = ""
var menu_size = Vector2.ZERO
var sensitivity_slider: HSlider
var motion_button: Button
var music_slider: HSlider
var fire_button: TextureButton
const WHITE = Color("fff8e8")
const INK = Color("243440")
const GOLD = Color("f2d084")
const MAGAZINE_ATLAS = preload("res://assets/ui/magazine-atlas.png")
const TITLE_ART = preload("res://assets/ui/title/no-art-fps.png")
const FIRE_ART = preload("res://assets/ui/title/fire.png")
const MAGAZINE_REGION = Rect2(104,112,458,1056)
const CARTRIDGE_REGION = Rect2(773,574,400,108)
const CASING_REGION = Rect2(773,574,280,108)
const TIP_REGION = Rect2(1053,586,120,84)
const MAGAZINE_SCALE = sqrt(.8)
const FEED_TIME = .085
const EJECTION_TIME = .48
const RELOAD_FEED_START = .04
const RELOAD_FEED_END = .68
const RELOAD_DIP_END = .82

func reload_elapsed() -> float:
	return game.RELOAD_DURATION-game.reload_time if game.reload_time>0 else 0.0

func reload_rounds_fed() -> float:
	if game.reload_time<=0:return 0.0
	var progress = clampf((reload_elapsed()-RELOAD_FEED_START)/(RELOAD_FEED_END-RELOAD_FEED_START),0,1)
	return (game.MAGAZINE_SIZE-game.reload_start_ammo)*progress

func reload_seating_offset() -> float:
	var elapsed = reload_elapsed()
	if elapsed<=RELOAD_FEED_END:return 0.0
	var depth = 3.0 if game.reduced_motion else 11.0
	if elapsed<RELOAD_DIP_END:
		return depth*smoothstep(RELOAD_FEED_END,RELOAD_DIP_END,elapsed)
	# A fast eased return ends exactly when the gun becomes ready to fire.
	return depth*pow(1-clampf((elapsed-RELOAD_DIP_END)/(game.RELOAD_DURATION-RELOAD_DIP_END),0,1),3)

func magazine_rect() -> Rect2:
	var dip = reload_seating_offset()
	var extent = Vector2(420,92)*MAGAZINE_SCALE
	return Rect2(size-Vector2(28,32)-extent+Vector2(0,dip*MAGAZINE_SCALE),extent)

func cartridge_rect(index: int) -> Rect2:
	# A single horizontal row feeds right; each sprite points up.
	return Rect2(magazine_rect().position+Vector2(368-index*16,24)*MAGAZINE_SCALE,Vector2(12.15,45)*MAGAZINE_SCALE)

func ammo_fired() -> void:
	feed_shift = FEED_TIME
	ejections.append(0.0)

func reset_magazine() -> void:
	feed_shift = 0
	ejections.clear()

func draw_round(region: Rect2, center: Vector2, extent: Vector2, angle: float = -PI*.5, alpha: float = 1.0) -> void:
	draw_set_transform(center,angle)
	draw_texture_rect_region(MAGAZINE_ATLAS,Rect2(-extent*.5*MAGAZINE_SCALE,extent*MAGAZINE_SCALE),region,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func draw_magazine() -> void:
	var body = magazine_rect()
	# The generated chamber has soft alpha; keep world/gun colors from bleeding through.
	draw_rect(Rect2(body.position+Vector2(30,16)*MAGAZINE_SCALE,Vector2(376,60)*MAGAZINE_SCALE),INK.darkened(.35))
	# Rotate the generated empty shell so its feed lips face the right edge.
	draw_set_transform(body.get_center(),PI*.5)
	draw_texture_rect_region(MAGAZINE_ATLAS,Rect2(-Vector2(body.size.y,body.size.x)*.5,Vector2(body.size.y,body.size.x)),MAGAZINE_REGION)
	draw_set_transform(Vector2.ZERO)
	var count = clampi(game.ammo,0,game.MAGAZINE_SIZE)
	var shift = 16*feed_shift/FEED_TIME
	var incoming = 0.0
	if game.reload_time>0:
		var fed = reload_rounds_fed()
		count = mini(game.MAGAZINE_SIZE,game.reload_start_ammo+int(fed))
		incoming = smoothstep(0,1,fmod(fed,1.0)) if count<game.MAGAZINE_SIZE else 0.0
		shift = 16*incoming
	for i in range(count):
		var center = cartridge_rect(i).get_center()-Vector2(shift,0)*MAGAZINE_SCALE
		draw_round(CARTRIDGE_REGION,center,Vector2(45,12.15))
	if incoming>0:
		var center = cartridge_rect(0).get_center()+Vector2(42*(1-incoming),0)*MAGAZINE_SCALE
		draw_round(CARTRIDGE_REGION,center,Vector2(45,12.15),-PI*.5,minf(1,incoming*4))
	for age in ejections:
		var origin = cartridge_rect(0).get_center()
		var t = age/EJECTION_TIME
		var alpha = 1.0-smoothstep(.6,1.0,t)
		var travel = Vector2(64*t,-105*t+150*t*t)
		var rotation_amount = t*6
		if game.reduced_motion:
			travel = Vector2(16*t,-10*t)
			rotation_amount = t*.5
		draw_round(CASING_REGION,origin+travel*MAGAZINE_SCALE,Vector2(31.5,12.15),-PI*.5+rotation_amount,alpha)
		if age<.12:
			draw_round(TIP_REGION,origin+Vector2(0,-23-age*420)*MAGAZINE_SCALE,Vector2(13.5,9.45),-PI*.5,1-age/.12)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = preload("res://assets/fonts/Rajdhani-Bold.ttf")
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://assets/shaders/low_health.gdshader")
	vignette.material = shader
	vignette.show_behind_parent = true
	add_child(vignette)
	menu = Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

func _process(delta: float) -> void:
	if game and game.state == "PAUSED":delta = 0
	feed_shift = maxf(0,feed_shift-delta)
	for i in range(ejections.size()):ejections[i] += delta
	ejections = ejections.filter(func(age):return age<EJECTION_TIME)
	time_pulse = maxf(0,time_pulse-delta*2.5)
	if game:
		var target = clampf((50.0-game.health)/40.0,0,1) if game.state in ["RUNNING","PAUSED"] else 0.0
		health_shade = move_toward(health_shade,target,delta*.65)
		vignette.material.set_shader_parameter("severity",health_shade)
	hit = maxf(0,hit-delta)
	kill_pop = maxf(0,kill_pop-delta)
	damage = maxf(0,damage-delta)
	shot = maxf(0,shot-delta)
	if game and (menu_state != game.state or menu_size != size):
		rebuild_menu()
	if game and game.state == "PAUSED":
		sensitivity_slider.set_value_no_signal(game.player.sensitivity)
		motion_button.text = "LOW" if game.reduced_motion else "FULL"
		music_slider.set_value_no_signal(game.music_volume)
	queue_redraw()

func label(text: String, pos: Vector2, font_size: int, color: Color = WHITE, center: bool = false) -> void:
	if center:pos.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5
	draw_string(font,pos+Vector2(0,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.08,.12,.15,.32))
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func stopwatch(pos: Vector2, color: Color) -> void:
	for shadow in [true,false]:
		var center = pos+Vector2(0,1) if shadow else pos
		var ink = Color(.08,.12,.15,.32) if shadow else color
		draw_arc(center,10,0,TAU,40,ink,2.4,true)
		draw_line(center+Vector2(0,-10),center+Vector2(0,-15),ink,2.4,true)
		draw_line(center+Vector2(-4,-15),center+Vector2(4,-15),ink,2.4,true)
		draw_line(center+Vector2(8,-8),center+Vector2(11,-11),ink,2.4,true)
		draw_line(center,center+Vector2(0,-6),ink,2.2,true)
		draw_line(center,center+Vector2(4,2),ink,2.2,true)

func skull(center: Vector2, extent: float, color: Color = WHITE) -> void:
	draw_set_transform(center,0,Vector2.ONE*extent/32.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12,-11),Vector2(-6,-16),Vector2(6,-16),Vector2(12,-11),
		Vector2(15,-3),Vector2(12,5),Vector2(8,7),Vector2(8,14),
		Vector2(-8,14),Vector2(-8,7),Vector2(-12,5),Vector2(-15,-3)]),color)
	draw_circle(Vector2(-6,-2),4.2,INK,true,-1,true)
	draw_circle(Vector2(6,-2),4.2,INK,true,-1,true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,2),Vector2(-2.5,6),Vector2(2.5,6)]),INK)
	for x in [-4,0,4]:draw_line(Vector2(x,10),Vector2(x,14),INK,1.6,true)
	draw_set_transform(Vector2.ZERO)

func death_marks() -> void:
	var pending = game.respawn_time>0 and game.state!="RESULTS"
	var completed = maxi(0,game.rules.deaths-(1 if pending else 0))
	for i in range(completed):
		skull(Vector2(size.x-38-(completed-1-i)*27,50),20)

func menu_button(text: String, rect: Rect2, action: String, primary: bool = false, shortcut: String = "") -> Button:
	var button = Button.new()
	button.name = action
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = shortcut
	button.add_theme_font_size_override("font_size",23)
	button.add_theme_font_override("font",font)
	for state_name in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = GOLD if primary else Color(1,1,1,.07)
		if state_name == "hover":style.bg_color = GOLD.lightened(.15) if primary else Color(1,1,1,.15)
		if state_name == "pressed":style.bg_color = GOLD.darkened(.1) if primary else Color(1,1,1,.2)
		if state_name == "focus":
			style.bg_color = Color.TRANSPARENT
			style.set_border_width_all(2)
			style.border_color = WHITE
		button.add_theme_stylebox_override(state_name,style)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(color_name,INK if primary else WHITE)
	button.pressed.connect(func():game.menu_action(action))
	menu.add_child(button)
	return button

func rebuild_menu() -> void:
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu_state = game.state
	menu_size = size
	var c = size*.5
	if menu_state == "TITLE":
		fire_button = TextureButton.new()
		fire_button.name = "fire"
		fire_button.texture_normal = FIRE_ART
		fire_button.ignore_texture_size = true
		fire_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		fire_button.position = Vector2(104,size.y-188)
		fire_button.size = Vector2(300,112)
		fire_button.pivot_offset = fire_button.size*.5
		fire_button.tooltip_text = "Enter"
		fire_button.mouse_entered.connect(func():fire_button.self_modulate = Color(1.15,1.15,1.15))
		fire_button.mouse_exited.connect(func():fire_button.self_modulate = Color.WHITE)
		fire_button.button_down.connect(func():fire_button.scale = Vector2.ONE*.96)
		fire_button.button_up.connect(func():fire_button.scale = Vector2.ONE)
		fire_button.pressed.connect(func():game.menu_action("play"))
		menu.add_child(fire_button)
	elif menu_state == "RESULTS":
		menu_button("RETRY",Rect2(c.x-200,c.y+145,190,56),"retry",true,"Enter")
		menu_button("MENU",Rect2(c.x+10,c.y+145,190,56),"menu",false,"Esc")
	elif menu_state == "PAUSED":
		menu_button("RESUME",Rect2(c.x-200,c.y-150,400,60),"resume",true,"Esc")
		menu_button("RESTART",Rect2(c.x-200,c.y-74,400,56),"retry",false,"Enter")
		sensitivity_slider = HSlider.new()
		sensitivity_slider.name = "Sensitivity"
		sensitivity_slider.position = Vector2(c.x+10,c.y+44)
		sensitivity_slider.size = Vector2(190,28)
		sensitivity_slider.min_value = .0006
		sensitivity_slider.max_value = .006
		sensitivity_slider.step = .0002
		sensitivity_slider.value = game.player.sensitivity
		sensitivity_slider.value_changed.connect(func(value):
			game.player.sensitivity = value
			game.save_record())
		menu.add_child(sensitivity_slider)
		motion_button = menu_button("",Rect2(c.x+80,c.y+98,120,44),"motion",false,"M")
		music_slider = HSlider.new()
		music_slider.name = "Music"
		music_slider.position = Vector2(c.x+10,c.y+164)
		music_slider.size = Vector2(190,28)
		music_slider.min_value = 0
		music_slider.max_value = 1
		music_slider.step = .05
		music_slider.value = game.music_volume
		music_slider.value_changed.connect(func(value):
			game.set_music_volume(value)
			game.save_record())
		menu.add_child(music_slider)

func _draw() -> void:
	if game == null:return
	var c = size*.5
	var state = game.state
	if state == "TITLE":
		draw_rect(Rect2(0,0,size.x*.43,size.y),Color(.055,.08,.10,.86))
		draw_texture_rect(TITLE_ART,Rect2(64,58,390,520),false)
		if is_instance_valid(fire_button) and fire_button.has_focus():
			draw_line(Vector2(140,size.y-68),Vector2(368,size.y-68),GOLD,2,true)
		return
	if state == "RESULTS":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.80))
		death_marks()
		label(str(game.rules.kills),Vector2(c.x,c.y-30),120,WHITE,true)
		label("KILLS",Vector2(c.x,c.y+12),24,WHITE,true)
		label("NEW RECORD" if game.new_record else "BEST %02d"%game.best,Vector2(c.x,c.y+72),23,GOLD,true)
		return
	if state == "PAUSED":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.76))
		death_marks()
		label("Sensitivity",Vector2(c.x-200,c.y+65),20)
		label("Camera motion",Vector2(c.x-200,c.y+128),20)
		label("Music",Vector2(c.x-200,c.y+185),20)
		return
	if game.respawn_time>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.28))
	death_marks()
	var seconds = ceili(game.rules.remaining())
	var time_text = "%02d:%02d"%[seconds/60,seconds%60]
	var timer_center = Vector2(c.x-52,51)
	var timer_scale = 1.0+sin(time_pulse*PI)*.22
	var timer_color = WHITE.lerp(Color("ff3e40"),minf(1,time_pulse*2)) if seconds<=10 else WHITE
	draw_set_transform(timer_center,0,Vector2.ONE*timer_scale)
	var timer_half_width = font.get_string_size(time_text,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x*.5
	stopwatch(Vector2(-timer_half_width-23,2),timer_color)
	label(time_text,Vector2(0,13),38,timer_color,true)
	if time_pulse>0 and seconds<=10:
		draw_arc(Vector2.ZERO,30+(1-time_pulse)*24,0,TAU,48,Color(1,.12,.15,time_pulse*.6),2)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(c.x+18,33),Vector2(c.x+18,64),Color(1,1,1,.4),1)
	var score_center = Vector2(c.x+65,51)
	var burst = kill_pop/.5
	var score_scale = 1.0+sin(burst*PI)*.65
	draw_set_transform(score_center,0,Vector2.ONE*score_scale)
	label("%02d"%game.rules.kills,Vector2(0,13),38,WHITE.lerp(GOLD,burst),true)
	draw_set_transform(Vector2.ZERO)
	if burst>0:
		for i in range(8):
			var direction = Vector2.from_angle(float(i)*TAU/8)
			var radius = 27+(1-burst)*40
			draw_line(score_center+direction*radius,score_center+direction*(radius+8*burst),Color(1,.83,.44,burst),2)
	label("KILLS",Vector2(c.x+122,61),14,WHITE,true)
	if state == "READY":
		label(str(ceili(game.ready_time)),Vector2(c.x,c.y),70,GOLD,true)
	elif game.respawn_time<=0:
		var gap = 5+shot*24
		if hit>0:
			var col = GOLD if kill_pop>0 else WHITE
			for a in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(c+a*7,c+a*12,col,2)
		else:
			draw_circle(c,2,INK)
			draw_circle(c,1,WHITE)
			for a in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(c+a*gap,c+a*(gap+4),WHITE,1)
	if game.respawn_time>0:
		skull(c,84)
		var remaining = game.respawn_time/game.RESPAWN_DELAY
		draw_arc(c,62,-PI*.5,-PI*.5+TAU*remaining,96,WHITE,2.5,true)
	else:draw_magazine()
	if damage>0:
		draw_line(Vector2(c.x-30,c.y+44),Vector2(c.x+30,c.y+44),Color(1,.35,.2,damage),3)
