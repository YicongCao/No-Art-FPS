extends Control

const REAR_THREAT = preload("res://assets/ui/rear-threat.svg")
const SKULL_ICON = preload("res://assets/ui/skull.svg")
var rear_markers: Array[TextureRect] = []
var rear_threats: Array[Dictionary] = []
var rear_sample_time = 0.0
var game: Node
var font: Font
var hit = 0.0
var kill_pop = 0.0
var kill_group = 1
var multi_time = 0.0
var damage = 0.0
var shot = 0.0
var time_pulse = 0.0
var go_time = 0.0
var destroy_time = 0.0
const GO_DURATION = .8
var health_shade = 0.0
var feed_shift = 0.0
var ejections: Array[float] = []
var loading_cover: ColorRect
var vignette: ColorRect
var menu: Control
var menu_state = ""
var menu_size = Vector2.ZERO
var sensitivity_slider: HSlider
var motion_button: Button
var music_slider: HSlider
var fire_button: Button
var title_frame: ImageTexture
var results_frame: ImageTexture
var results_frame_pending = false
var results_frame_ticket = 0
const TOP_HUD_SCALE = 1.5
const TITLE_SHADE_OPACITY = .55
const WHITE = Color("fff8e8")
const INK = Color("243440")
const GOLD = Color("f2d084")
const MAGAZINE_ATLAS = preload("res://assets/ui/magazine-atlas.png")
const DEFUSE_ICON = preload("res://assets/ui/defuse-grenade.svg")
const DUST_RADAR = preload("res://assets/ui/dust-radar.svg")
const RETRY_ICON = preload("res://assets/ui/results/retry.png")
const HOME_ICON = preload("res://assets/ui/results/home.png")
const KILLS_ICON = preload("res://assets/ui/results/kills.png")
const TROPHY_ICON = preload("res://assets/ui/results/trophy.png")
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
	if game.touch_mode:
		extent *= .72
		return Rect2(Vector2((size.x-extent.x)*.5,size.y-extent.y-28+dip*.72),extent)
	return Rect2(size-Vector2(28,32)-extent+Vector2(0,dip*MAGAZINE_SCALE),extent)

func cartridge_rect(index: int) -> Rect2:
	# A single horizontal row feeds right; each sprite points up.
	return round_rect(magazine_rect(),index)

func round_rect(body: Rect2, index: int) -> Rect2:
	var scale_factor = body.size.x/420.0
	return Rect2(body.position+Vector2(368-index*16,24)*scale_factor,Vector2(12.15,45)*scale_factor)

func ammo_fired() -> void:
	feed_shift = FEED_TIME
	ejections.append(0.0)

func reset_magazine() -> void:
	feed_shift = 0
	ejections.clear()

func draw_round(region: Rect2, center: Vector2, extent: Vector2, angle: float = -PI*.5, alpha: float = 1.0, scale_factor: float = MAGAZINE_SCALE) -> void:
	draw_set_transform(center,angle)
	draw_texture_rect_region(MAGAZINE_ATLAS,Rect2(-extent*.5*scale_factor,extent*scale_factor),region,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func draw_magazine() -> void:
	var count = clampi(game.ammo,0,game.MAGAZINE_SIZE)
	var shift = 16*feed_shift/FEED_TIME
	var incoming = 0.0
	if game.reload_time>0:
		var fed = reload_rounds_fed()
		count = mini(game.MAGAZINE_SIZE,game.reload_start_ammo+int(fed))
		incoming = smoothstep(0,1,fmod(fed,1.0)) if count<game.MAGAZINE_SIZE else 0.0
		shift = 16*incoming
	draw_magazine_body(magazine_rect(),count,shift,incoming,true)

func draw_magazine_body(body: Rect2, count: int, shift: float, incoming: float, eject: bool = false) -> void:
	var scale_factor = body.size.x/420.0
	# Both loading and gameplay render exactly the same shell and cartridge geometry.
	draw_rect(Rect2(body.position+Vector2(30,16)*scale_factor,Vector2(376,60)*scale_factor),INK.darkened(.35))
	draw_set_transform(body.get_center(),PI*.5)
	draw_texture_rect_region(MAGAZINE_ATLAS,Rect2(-Vector2(body.size.y,body.size.x)*.5,Vector2(body.size.y,body.size.x)),MAGAZINE_REGION)
	draw_set_transform(Vector2.ZERO)
	for i in range(count):
		var center = round_rect(body,i).get_center()-Vector2(shift,0)*scale_factor
		draw_round(CARTRIDGE_REGION,center,Vector2(45,12.15),-PI*.5,1,scale_factor)
	if incoming>0:
		var center = round_rect(body,0).get_center()+Vector2(42*(1-incoming),0)*scale_factor
		draw_round(CARTRIDGE_REGION,center,Vector2(45,12.15),-PI*.5,minf(1,incoming*4),scale_factor)
	if not eject:return
	for age in ejections:
		var origin = round_rect(body,0).get_center()
		var t = age/EJECTION_TIME
		var alpha = 1.0-smoothstep(.6,1.0,t)
		var travel = Vector2(64*t,-105*t+150*t*t)
		var rotation_amount = t*6
		if game.reduced_motion:
			travel = Vector2(16*t,-10*t)
			rotation_amount = t*.5
		draw_round(CASING_REGION,origin+travel*scale_factor,Vector2(31.5,12.15),-PI*.5+rotation_amount,alpha,scale_factor)
		if age<.12:
			draw_round(TIP_REGION,origin+Vector2(0,-23-age*420)*scale_factor,Vector2(13.5,9.45),-PI*.5,1-age/.12,scale_factor)

func loading_magazine_rect() -> Rect2:
	var extent = Vector2(860,860.0*92/420)
	var start = Rect2(size*.5-extent*.5,extent)
	start.position.y += game.loading.seating_offset(game.reduced_motion)*extent.x/420.0
	var target = magazine_rect()
	var blend = game.loading.dock_progress()
	return Rect2(start.position.lerp(target.position,blend),start.size.lerp(target.size,blend))

func sync_loading_cover() -> void:
	if not is_instance_valid(loading_cover):return
	loading_cover.visible = game.state in ["TITLE","LOADING"] and title_frame!=null
	vignette.visible = game.state not in ["TITLE","LOADING","RESULTS"]
	loading_cover.material.set_shader_parameter("progress",game.loading.reveal_progress() if game.state=="LOADING" else 0.0)
	loading_cover.material.set_shader_parameter("viewport_size",size)

func set_title_frame(image: Image) -> void:
	title_frame = ImageTexture.create_from_image(image)
	loading_cover.material.set_shader_parameter("opening_frame",title_frame)
	loading_cover.material.set_shader_parameter("shade_opacity",TITLE_SHADE_OPACITY)
	sync_loading_cover()

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
	loading_cover = ColorRect.new()
	loading_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_cover.show_behind_parent = true
	var cover_material = ShaderMaterial.new()
	cover_material.shader = preload("res://assets/shaders/loading_reveal.gdshader")
	loading_cover.material = cover_material
	add_child(loading_cover)
	loading_cover.hide()
	menu = Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	for title in ["左后方敌人","正后方敌人","右后方敌人"]:
		var marker = TextureRect.new()
		marker.texture = REAR_THREAT
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.size = Vector2(44,44)
		marker.pivot_offset = marker.size*.5
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.accessibility_name = title
		marker.tooltip_text = title
		marker.hide()
		add_child(marker)
		rear_markers.append(marker)

func reset_results_frame() -> void:
	results_frame_ticket += 1
	results_frame = null
	results_frame_pending = false
	menu.show()

func capture_results_frame() -> void:
	reset_results_frame()
	if DisplayServer.get_name()=="headless":return
	var ticket = results_frame_ticket
	results_frame_pending = true
	menu.hide()
	vignette.hide()
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if ticket!=results_frame_ticket or game.state!="RESULTS":return
	results_frame = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	results_frame_pending = false
	menu.show()
	queue_redraw()

func _process(delta: float) -> void:
	sync_loading_cover()
	if game and game.state == "PAUSED":delta = 0
	if game and game.state=="RUNNING":go_time = maxf(0,go_time-delta)
	if game and game.state=="RUNNING":destroy_time = maxf(0,destroy_time-delta)
	feed_shift = maxf(0,feed_shift-delta)
	for i in range(ejections.size()):ejections[i] += delta
	ejections = ejections.filter(func(age):return age<EJECTION_TIME)
	time_pulse = maxf(0,time_pulse-delta*2.5)
	damage = maxf(0,damage-delta)
	if game:
		var target = clampf((50.0-game.health)/40.0,0,1) if game.state in ["RUNNING","PAUSED"] else 0.0
		health_shade = move_toward(health_shade,target,delta*.65)
		vignette.material.set_shader_parameter("severity",health_shade)
		vignette.material.set_shader_parameter("hit_flash",pow(clampf(damage/.8,0,1),2))
	hit = maxf(0,hit-delta)
	kill_pop = maxf(0,kill_pop-delta)
	multi_time = maxf(0,multi_time-delta)
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
	draw_string(font,pos+Vector2(0,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.08,.12,.15,.32*color.a))
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

func skull(center: Vector2, extent: float) -> void:
	var dimensions = Vector2.ONE*extent
	draw_texture_rect(SKULL_ICON,Rect2(center-dimensions*.5,dimensions),false)

func draw_respawn(center: Vector2) -> void:
	const ICON_SIZE = 84.0
	const RADIUS = 62.0
	const START = -PI*.5
	var remaining = clampf(game.respawn_time/game.RESPAWN_DELAY,0,1)
	var sweep = TAU*remaining
	var segments = maxi(2,ceili(96*remaining))
	if remaining>=1:
		skull(center,ICON_SIZE)
	else:
		# Use the same angular span for the textured sector and the ring.
		var points = PackedVector2Array([center])
		var uvs = PackedVector2Array([Vector2(.5,.5)])
		for index in range(segments+1):
			var offset = Vector2.from_angle(START+sweep*float(index)/segments)*RADIUS
			points.append(center+offset)
			uvs.append(Vector2(.5,.5)+offset/ICON_SIZE)
		draw_polygon(points,PackedColorArray([Color.WHITE]),uvs,SKULL_ICON)
	draw_arc(center,RADIUS,START,START+sweep,segments+1,WHITE,2.5,true)

func death_marks() -> void:
	var pending = game.respawn_time>0 and game.state!="RESULTS"
	var completed = maxi(0,game.rules.deaths-(1 if pending else 0))
	for i in range(completed):
		skull(Vector2(size.x-(128 if game.touch_mode else 38)-(completed-1-i)*27,50),20)

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
		fire_button = menu_button("FIRE",Rect2(64 if game.touch_mode else 104,size.y-156 if game.touch_mode else size.y-188,260 if game.touch_mode else 300,100 if game.touch_mode else 112),"play",false,"Enter")
		fire_button.name = "fire"
		fire_button.add_theme_font_size_override("font_size",68)
		fire_button.add_theme_constant_override("outline_size",0)
		for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			fire_button.add_theme_color_override(color_name,Color.WHITE)
		for style_name in ["normal","hover","pressed","focus"]:
			var style = StyleBoxFlat.new()
			style.bg_color = Color("754c87")
			if style_name=="hover":style.bg_color = style.bg_color.lightened(.12)
			if style_name=="pressed":style.bg_color = style.bg_color.darkened(.14)
			if style_name=="focus":
				style.bg_color = Color.TRANSPARENT
				style.set_border_width_all(2)
				style.border_color = Color.WHITE
			fire_button.add_theme_stylebox_override(style_name,style)
		fire_button.pivot_offset = fire_button.size*.5
		fire_button.button_down.connect(func():fire_button.scale = Vector2.ONE*.96)
		fire_button.button_up.connect(func():fire_button.scale = Vector2.ONE)
		if game.dust_unlocked:
			var mode_x = size.x-370 if not game.touch_mode else size.x-300
			menu_button("SCORE ATTACK",Rect2(mode_x,size.y*.5-75,260,62),"arena",not game.rules.mission)
			menu_button("DEFUSE C4",Rect2(mode_x,size.y*.5+5,260,62),"defuse",game.rules.mission)

	elif menu_state == "RESULTS":
		if game.rules.mission:
			menu_button("RETRY",Rect2(c.x-174,c.y+106,160,70),"retry",true,"重试 · Enter")
			menu_button("TITLE",Rect2(c.x+14,c.y+106,160,70),"menu",false,"返回标题 · Esc")
		else:
			results_button(RETRY_ICON,Rect2(c.x-174,c.y+106,160,88),"retry",true,"重试 · Enter")
			results_button(HOME_ICON,Rect2(c.x+14,c.y+106,160,88),"menu",false,"返回标题 · Esc")
	elif menu_state == "PAUSED":
		menu_button("RESUME",Rect2(c.x-200,c.y-150,400,64 if game.touch_mode else 60),"resume",true,"Esc")
		menu_button("RESTART",Rect2(c.x-200,c.y-74,400,64 if game.touch_mode else 56),"retry",false,"Enter")
		sensitivity_slider = HSlider.new()
		sensitivity_slider.name = "Sensitivity"
		sensitivity_slider.position = Vector2(c.x+10,c.y+44)
		sensitivity_slider.size = Vector2(190,48 if game.touch_mode else 28)
		sensitivity_slider.min_value = .0006
		sensitivity_slider.max_value = .006
		sensitivity_slider.step = .0002
		sensitivity_slider.value = game.player.sensitivity
		sensitivity_slider.value_changed.connect(func(value):
			game.player.sensitivity = value
			game.save_record())
		menu.add_child(sensitivity_slider)
		motion_button = menu_button("",Rect2(c.x+80,c.y+98,120,60 if game.touch_mode else 44),"motion",false,"M")
		music_slider = HSlider.new()
		music_slider.name = "Music"
		music_slider.position = Vector2(c.x+10,c.y+164)
		music_slider.size = Vector2(190,48 if game.touch_mode else 28)
		music_slider.min_value = 0
		music_slider.max_value = 1
		music_slider.step = .05
		music_slider.value = game.music_volume
		music_slider.value_changed.connect(func(value):
			game.set_music_volume(value)
			game.save_record())
		menu.add_child(music_slider)

func results_button(texture: Texture2D, rect: Rect2, action: String, primary: bool, tooltip: String) -> Button:
	var button = menu_button("",rect,action,primary,tooltip)
	for state_name in ["normal","hover","pressed","focus"]:
		var style = button.get_theme_stylebox(state_name).duplicate()
		style.set_corner_radius_all(8)
		if not primary and state_name!="focus":
			style.bg_color = Color("754c87")
			if state_name=="hover":style.bg_color = style.bg_color.lightened(.15)
			if state_name=="pressed":style.bg_color = style.bg_color.darkened(.15)
		button.add_theme_stylebox_override(state_name,style)
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(76,76)
	icon.position = (rect.size-icon.size)*.5
	button.add_child(icon)
	button.pivot_offset = button.size*.5
	button.button_down.connect(func():button.scale = Vector2.ONE*.96)
	button.button_up.connect(func():button.scale = Vector2.ONE)
	return button

func draw_results() -> void:
	var c = size*.5
	draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.38))
	var card = StyleBoxFlat.new()
	card.bg_color = Color(.08,.12,.17,.94)
	card.set_corner_radius_all(12)
	card.set_border_width_all(1)
	card.border_color = Color(GOLD,.5)
	card.shadow_color = Color(0,0,0,.25)
	card.shadow_size = 14
	draw_style_box(card,Rect2(c-Vector2(238,220),Vector2(476,440)))
	draw_line(c+Vector2(-46,-219),c+Vector2(46,-219),GOLD,3)
	if game.rules.mission:
		var success = game.rules.outcome=="SUCCESS"
		label("DEFUSED" if success else "FAILED",c+Vector2(0,-125),56,GOLD if success else WHITE,true)
		label("%d / 3 C4"%game.rules.completed.size(),c+Vector2(0,-53),34,WHITE,true)
		var detail = "%.1f s"%game.rules.elapsed if success else ("TIME EXPIRED" if game.rules.outcome=="TIMEOUT" else "KILLED")
		label(detail,c+Vector2(0,8),26,WHITE,true)
		if success and game.best_mission>0:label("BEST %.1f s"%game.best_mission,c+Vector2(0,54),20,GOLD,true)
		return
	var score = str(game.rules.kills)
	var score_size = 104 if score.length()<=3 else 80
	var width = font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x
	var left = c.x-(76+18+width)*.5
	draw_texture_rect(KILLS_ICON,Rect2(Vector2(left,c.y-146),Vector2(76,76)),false)
	label(score,Vector2(left+94,c.y-70),score_size,WHITE)
	var best = str(game.best)
	var best_width = font.get_string_size(best,HORIZONTAL_ALIGNMENT_LEFT,-1,34).x
	var row_left = c.x-(42+12+best_width)*.5
	var trophy_rect = Rect2(Vector2(row_left,c.y-17),Vector2(42,42))
	if game.new_record:
		draw_circle(trophy_rect.get_center(),31,Color(GOLD,.12))
		draw_arc(trophy_rect.get_center(),30,0,TAU,48,Color(GOLD,.6),1.5,true)
	draw_texture_rect(TROPHY_ICON,trophy_rect,false)
	label(best,Vector2(row_left+54,c.y+16),34,GOLD)
	draw_line(c+Vector2(-174,66),c+Vector2(174,66),Color(WHITE,.16),1)

func _draw() -> void:
	if game == null:return
	var c = size*.5
	var state = game.state
	if state=="LOADING":
		var fed = game.loading.rounds
		var count = mini(20,int(fed))
		var incoming = smoothstep(0,1,fmod(fed,1.0)) if count<20 else 0.0
		draw_magazine_body(loading_magazine_rect(),count,16*incoming,incoming)
		return
	if state == "TITLE":
		var words = ["NO","ART","FPS"]
		for i in range(words.size()):
			var pos = Vector2(64,116+i*100) if game.touch_mode else Vector2(104,220+i*150)
			draw_string(font,pos,words[i],HORIZONTAL_ALIGNMENT_LEFT,-1,106 if game.touch_mode else 160,Color.WHITE)
		return
	if state == "RESULTS":
		if results_frame_pending:
			draw_finale_edges()
			return
		if results_frame:draw_texture_rect(results_frame,Rect2(Vector2.ZERO,size),false)
		draw_results()
		return
	if state == "PAUSED":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.76))
		death_marks()
		label("Sensitivity",Vector2(c.x-200,c.y+65),20)
		label("Camera motion",Vector2(c.x-200,c.y+128),20)
		label("Music",Vector2(c.x-200,c.y+185),20)
		return
	draw_finale_edges()
	if game.respawn_time>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.28))
	death_marks()
	draw_top_summary()
	if game.respawn_time<=0:
		var gap = 5+shot*24
		if hit>0:
			var col = GOLD if kill_pop>0 else WHITE
			for a in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(c+a*7,c+a*12,col,2)
		else:
			draw_circle(c,2,INK)
			draw_circle(c,1,WHITE)
			for a in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(c+a*gap,c+a*(gap+4),WHITE,1)
	if game.respawn_time>0:
		draw_respawn(c)
	else:draw_magazine()
	if state=="RUNNING" and game.respawn_time<=0 and go_time>0:
		var opacity = smoothstep(0,.65,go_time)
		label("GO",c+Vector2(0,22),70,Color(WHITE,opacity),true)
	if state=="RUNNING" and destroy_time>0:
		label("DESTROY",c+Vector2(0,22),64,Color(GOLD,smoothstep(0,.8,destroy_time)),true)
	if game.rules.mission:
		draw_mission_radar()
		for objective in game.arena.objectives:
			if objective.available():
				var center = c+Vector2(0,112)
				var progress = clampf(objective.progress/objective.defuse_duration,0,1)
				draw_circle(center,39,Color(INK,.88))
				draw_texture_rect(DEFUSE_ICON,Rect2(center-Vector2(24,24),Vector2(48,48)),false)
				draw_arc(center,36,-PI*.5,TAU-PI*.5,96,Color(WHITE,.25),4,true)
				if progress>0:draw_arc(center,36,-PI*.5,-PI*.5+progress*TAU,96,GOLD,5,true)
				draw_style_box(mission_time_style(),Rect2(center+Vector2(-35,46),Vector2(70,24)))
				label("HOLD" if game.touch_mode else "HOLD E",center+Vector2(0,64),18,WHITE,true)
				break
	if damage>0:
		draw_line(Vector2(c.x-30,c.y+44),Vector2(c.x+30,c.y+44),Color(1,.35,.2,damage),3)

func draw_top_summary() -> void:
	var origin = Vector2(size.x*.5,0)
	var scale = Vector2.ONE*TOP_HUD_SCALE
	draw_set_transform(origin,0,scale)
	var seconds = ceili(game.rules.remaining())
	var time_text = "%02d:%02d"%[seconds/60,seconds%60]
	if game.rules.mission:
		draw_style_box(mission_time_style(),Rect2(Vector2(-137,26),Vector2(300,52)))
	var timer_center = Vector2(-52,51)
	var timer_scale = 1.0+sin(time_pulse*PI)*.22
	var timer_color = WHITE.lerp(Color("ff3e40"),minf(1,time_pulse*2)) if seconds<=10 else WHITE
	draw_set_transform(origin+timer_center*TOP_HUD_SCALE,0,scale*timer_scale)
	var timer_half_width = font.get_string_size(time_text,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x*.5
	stopwatch(Vector2(-timer_half_width-23,2),timer_color)
	label(time_text,Vector2(0,13),38,timer_color,true)
	if time_pulse>0 and seconds<=10:
		draw_arc(Vector2.ZERO,30+(1-time_pulse)*24,0,TAU,48,Color(1,.12,.15,time_pulse*.6),2)
	draw_set_transform(origin,0,scale)
	draw_line(Vector2(18,33),Vector2(18,64),Color(1,1,1,.4),1)
	var score_center = Vector2(65,51)
	if game.rules.mission:
		label("%d/3 C4"%game.rules.completed.size(),score_center+Vector2(22,13),32,GOLD,true)
	else:
		var burst = kill_pop/.5
		var strength = .65+float(mini(kill_group,3)-1)*.4
		if game.reduced_motion:strength *= .25
		var score_scale = 1.0+sin(burst*PI)*strength
		draw_set_transform(origin+score_center*TOP_HUD_SCALE,0,scale*score_scale)
		label("%02d"%game.rules.kills,Vector2(0,13),38,WHITE.lerp(GOLD,burst),true)
		draw_set_transform(origin,0,scale)
		if burst>0:
			var rays = 8+2*(mini(kill_group,3)-1)
			for i in range(rays):
				var direction = Vector2.from_angle(float(i)*TAU/rays)
				var radius = 27+(1-burst)*(40+10*(mini(kill_group,3)-1))
				draw_line(score_center+direction*radius,score_center+direction*(radius+8*burst),Color(1,.83,.44,burst),2)
		if multi_time>0:
			var alpha = smoothstep(0,.35,multi_time)
			var offset = (1-multi_time/.65)*16
			label("+"+str(kill_group),score_center+Vector2(0,64-offset),30,Color(GOLD,alpha),true)
		label("KILLS",Vector2(122,61),14,WHITE,true)
	draw_set_transform(Vector2.ZERO)

func draw_finale_edges() -> void:
	if not game.finale_active:return
	var age = clampf(game.FINALE_DURATION-game.rules.remaining(),0,1)
	var expansion = smoothstep(0,.28,age)
	if expansion<=0:return
	for i in range(24):
		var side = i/6
		var fraction = (float(i%6)+.5)/6
		var center: Vector2
		if side==0:center = Vector2(size.x*fraction,-12)
		elif side==1:center = Vector2(size.x+12,size.y*fraction)
		elif side==2:center = Vector2(size.x*(1-fraction),size.y+12)
		else:center = Vector2(-12,size.y*(1-fraction))
		var radius = (56+float((i*7)%5)*13)*expansion
		for layer in range(3):
			var points = PackedVector2Array()
			var extent = radius*(1-float(layer)*.22)
			for corner in range(12):
				var angle = corner*TAU/12+float(i)*.7
				var reach = extent*(1.0 if corner%2==0 else .68)
				points.append(center+Vector2.from_angle(angle)*reach)
			var color = [Color("573e37"),Color("ef7833"),Color("f2d084")][layer]
			draw_colored_polygon(points,color)

func radar_rect() -> Rect2:
	var width = 178.0 if game.touch_mode else 252.0
	return Rect2(Vector2(20,22),Vector2(width,width*96.0/119.0))

func radar_position(world: Vector3) -> Vector2:
	var rect = radar_rect()
	var local = game.arena.to_local(world)
	var uv = (Vector2(local.x,local.z)-game.arena.radar_bounds.position)/game.arena.radar_bounds.size
	return rect.position+uv.clamp(Vector2.ZERO,Vector2.ONE)*rect.size

func draw_mission_radar() -> void:
	var rect = radar_rect()
	draw_texture_rect(DUST_RADAR,rect,false)
	draw_rect(rect,Color(WHITE,.35),false,1)
	for i in range(game.arena.objectives.size()):
		var objective = game.arena.objectives[i]
		var point = radar_position(objective.global_position)
		var complete = game.rules.completed.has(objective.objective_id)
		if complete:
			draw_circle(point,4,Color("74bfa4"))
		else:
			draw_circle(point,11,Color(INK,.9))
			draw_circle(point,9,GOLD)
			label(str(i+1),point+Vector2(0,4),15,INK,true)
	var player_point = radar_position(game.player.global_position)
	var direction = -game.player.global_basis.z
	var angle = atan2(direction.z,direction.x)
	var tip = Vector2.from_angle(angle)*8
	var side = Vector2.from_angle(angle+PI*.5)*5
	draw_colored_polygon(PackedVector2Array([player_point+tip,player_point-tip*.7+side,player_point-tip*.7-side]),WHITE)
	draw_circle(player_point,2,INK)

func mission_time_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(INK,.88)
	style.set_corner_radius_all(6)
	return style

func rear_sector(world_position: Vector3) -> int:
	var local = game.player.global_basis.inverse()*(world_position-game.player.global_position)
	var distance = Vector2(local.x,local.z).length()
	if local.z<=distance*.1 or distance<.1:return -1
	if local.x<-distance*.38:return 0
	if local.x>distance*.38:return 2
	return 1

func refresh_rear_threats() -> void:
	rear_threats.clear()
	if game.state!="RUNNING" or game.respawn_time>0 or game.finale_active:return
	var by_sector: Dictionary = {}
	for enemy in game.live_enemies():
		var distance = enemy.global_position.distance_to(game.player.global_position)
		if distance>24:continue
		var sector = rear_sector(enemy.global_position)
		if sector<0:continue
		var sight = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,enemy.global_position+Vector3.UP*1.4,1)
		if not game.get_world_3d().direct_space_state.intersect_ray(sight).is_empty():continue
		var urgent = distance<9 or enemy.windup>0
		if by_sector.has(sector):
			by_sector[sector].urgent = by_sector[sector].urgent or urgent
			by_sector[sector].distance = minf(distance,by_sector[sector].distance)
		else:by_sector[sector] = {"sector":sector,"distance":distance,"urgent":urgent}
	for threat in by_sector.values():rear_threats.append(threat)

func _physics_process(delta: float) -> void:
	if not game or rear_markers.is_empty():return
	rear_sample_time -= delta
	if rear_sample_time<=0:
		rear_sample_time = .1
		refresh_rear_threats()
	for marker in rear_markers:marker.hide()
	if game.state!="RUNNING" or game.respawn_time>0 or game.finale_active:return
	var centers = [Vector2(44,size.y*.67),Vector2(size.x*.5,size.y-66),Vector2(size.x-44,size.y*.67)]
	for threat in rear_threats:
		var marker = rear_markers[threat.sector]
		marker.position = centers[threat.sector]-marker.size*.5
		marker.rotation = [.65,0.0,-.65][threat.sector]
		var tint = Color("ee795d") if threat.urgent else GOLD
		tint.a = clampf(1.15-threat.distance/40.0,.5,1)
		marker.modulate = tint
		marker.show()
