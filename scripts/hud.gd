extends Control

var game: Node
var font: Font
var hit = 0.0
var kill_pop = 0.0
var damage = 0.0
var shot = 0.0
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
	font = ThemeDB.fallback_font
	menu = Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

func _process(delta: float) -> void:
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
	button.add_theme_font_size_override("font_size",21)
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
		label("BEST %02d"%game.best,Vector2(c.x,c.y+72),20,GOLD,true)
		return
	if state == "PAUSED":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.76))
		label("Sensitivity",Vector2(c.x-200,c.y+65),20)
		label("Camera motion",Vector2(c.x-200,c.y+128),20)
		return
	var seconds = ceili(game.rules.remaining())
	var time_text = "%02d:%02d"%[seconds/60,seconds%60]
	label(time_text,Vector2(c.x-40,64),32,GOLD if seconds<=10 else WHITE,true)
	draw_line(Vector2(c.x+23,37),Vector2(c.x+23,65),Color(1,1,1,.4),1)
	label("%02d"%game.rules.kills,Vector2(c.x+64,64),32+int(kill_pop*12),WHITE,true)
	label("KILLS",Vector2(c.x+118,61),12,WHITE,true)
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
	elif game.ammo<30:
		label("%02d"%game.ammo,Vector2(size.x-72,size.y-66),26,GOLD if game.ammo<=8 else WHITE,true)
	if game.armor<3:
		for i in range(3):draw_rect(Rect2(c.x-30+i*22,size.y-40,16,3),GOLD if i<game.armor else Color(.2,.25,.28,.7))
	if game.respawn_time>0:label("BACK IN A BEAT",Vector2(c.x,c.y+65),18,GOLD,true)
	if damage>0:
		draw_line(Vector2(c.x-30,c.y+44),Vector2(c.x+30,c.y+44),Color(1,.35,.2,damage),3)
