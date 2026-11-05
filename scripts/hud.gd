extends Control

var game: Node
var font: Font
var hit = 0.0
var kill_pop = 0.0
var damage = 0.0
var shot = 0.0
var time_pulse = 0.0
var health_shade = 0.0
var vignette: ColorRect
var menu: Control
var menu_state = ""
var menu_size = Vector2.ZERO
var sensitivity_slider: HSlider
var motion_button: Button
const WHITE = Color("fff8e8")
const INK = Color("243440")
const GOLD = Color("f2d084")

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
	queue_redraw()

func label(text: String, pos: Vector2, font_size: int, color: Color = WHITE, center: bool = false) -> void:
	if center:pos.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5
	draw_string(font,pos+Vector2(0,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.08,.12,.15,.32))
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

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
		menu_button("PLAY",Rect2(74,size.y-150,280,60),"play",true,"Enter")
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

func _draw() -> void:
	if game == null:return
	var c = size*.5
	var state = game.state
	if state == "TITLE":
		draw_rect(Rect2(0,0,size.x*.43,size.y),Color(.055,.08,.10,.86))
		label("NO",Vector2(68,227),102)
		label("ART",Vector2(68,330),102)
		label("FPS",Vector2(68,433),102)
		return
	if state == "RESULTS":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.80))
		label(str(game.rules.kills),Vector2(c.x,c.y-30),120,WHITE,true)
		label("KILLS",Vector2(c.x,c.y+12),24,WHITE,true)
		label("NEW RECORD" if game.new_record else "BEST %02d"%game.best,Vector2(c.x,c.y+72),23,GOLD,true)
		return
	if state == "PAUSED":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.76))
		label("Sensitivity",Vector2(c.x-200,c.y+65),20)
		label("Camera motion",Vector2(c.x-200,c.y+128),20)
		return
	var seconds = ceili(game.rules.remaining())
	var time_text = "%02d:%02d"%[seconds/60,seconds%60]
	var timer_center = Vector2(c.x-52,51)
	var timer_scale = 1.0+sin(time_pulse*PI)*.22
	var timer_color = WHITE.lerp(Color("ff3e40"),minf(1,time_pulse*2)) if seconds<=10 else WHITE
	draw_set_transform(timer_center,0,Vector2.ONE*timer_scale)
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
	else:
		var gap = 5+shot*24
		if hit>0:
			var col = GOLD if kill_pop>0 else WHITE
			for a in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(c+a*7,c+a*12,col,2)
		else:
			draw_circle(c,2,INK)
			draw_circle(c,1,WHITE)
			for a in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(c+a*gap,c+a*(gap+4),WHITE,1)
	if game.reload_time>0:
		label("RELOADING",Vector2(c.x+170,size.y-105),14,WHITE,true)
		draw_line(Vector2(c.x+120,size.y-90),Vector2(c.x+120+100*(1-game.reload_time/.9),size.y-90),GOLD,2)
	elif game.ammo<game.MAGAZINE_SIZE:
		label("%02d"%game.ammo,Vector2(size.x-72,size.y-66),26,GOLD if game.ammo<=8 else WHITE,true)
	if game.respawn_time>0:label("BACK IN A BEAT",Vector2(c.x,c.y+65),18,GOLD,true)
	if damage>0:
		draw_line(Vector2(c.x-30,c.y+44),Vector2(c.x+30,c.y+44),Color(1,.35,.2,damage),3)
