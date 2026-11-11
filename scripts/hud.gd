extends Control

const FRENZY_FONT_ZH = preload("res://assets/fonts/GlowSansSC-Frenzy.otf")
const SKULL_ICON = preload("res://assets/ui/skull.svg")
const DAMAGE_IMPACT = preload("res://assets/ui/damage-impact.svg")
const AIM_WARNING = preload("res://assets/ui/aim-warning.svg")
const YARD_THUMBNAIL = preload("res://assets/ui/maps/yard.webp")
const PARK_THUMBNAIL = preload("res://assets/ui/maps/amusement-park.webp")
const FERRY_THUMBNAIL = preload("res://assets/ui/maps/last-ferry.webp")
const STUDIO_THUMBNAIL = preload("res://assets/ui/maps/night-studio.webp")
const SANDGATE_THUMBNAIL = preload("res://assets/ui/maps/sandgate.webp")
const OFFICE_THUMBNAIL = preload("res://assets/ui/maps/bb-office.webp")
const RAIN_THUMBNAIL = preload("res://assets/ui/maps/rain_market.webp")
const BAGGAGE_THUMBNAIL = preload("res://assets/ui/maps/baggage_below.webp")
const SNOWLINE_THUMBNAIL = preload("res://assets/ui/maps/snowline.webp")
const HOGWARTS_THUMBNAIL = preload("res://assets/ui/maps/hogwarts.webp")
const PALM_THUMBNAIL = preload("res://assets/ui/maps/palm_house.webp")
const GINZA_THUMBNAIL = preload("res://assets/ui/maps/ginza_station.webp")
const COMEDY_ICON = preload("res://assets/ui/settings/comedy.svg")
const ROACH_ICON = preload("res://assets/ui/settings/roach.svg")
const BadgeCatalog = preload("res://scripts/achievements.gd")
const TITLE_WORDS = ["NO","ART","FPS"]
# Rajdhani Bold stroke joins in em units, relative to each word's baseline.
const BADGE_ANCHORS = [
	[Vector2(.15,-.57),Vector2(.46,-.08),Vector2(1.01,-.56),Vector2(1.01,-.08)],
	[Vector2(.28,-.57),Vector2(.16,-.18),Vector2(.94,-.28),Vector2(1.31,-.58)],
	[Vector2(.13,-.58),Vector2(.59,-.27),Vector2(1.37,-.56),Vector2(1.14,-.08)],
]
const EXTRA_BADGE_ANCHORS = [Vector2(.15,-.08),Vector2(.53,-.30),Vector2(1.50,-.12),Vector2(.14,-.10)]
const BADGE_TOAST_DURATION = 1.8
const MAP_HOLD_MS = 540
const PAUSE_ICON = preload("res://assets/ui/settings/pause.svg")
const AIM_ICON = preload("res://assets/ui/settings/aim.svg")
const MOTION_ICON = preload("res://assets/ui/settings/motion.svg")
const MUSIC_ICON = preload("res://assets/ui/settings/music.svg")
const ONE_HIT_ICON = preload("res://assets/ui/settings/one_hit.svg")
const INSET_ICON = preload("res://assets/ui/settings/inset.svg")
const GYRO_ICON = preload("res://assets/ui/settings/gyro.svg")
const RESUME_ICON = preload("res://assets/ui/settings/resume.svg")
const RESTART_ICON = preload("res://assets/ui/settings/restart.svg")
const PAUSE_HOME_ICON = preload("res://assets/ui/settings/home.svg")
const SLIDER_GRIP = preload("res://assets/ui/settings/grip.svg")
const MEDAL_ICON = preload("res://assets/ui/maps/best-medal.svg")
const GRENADE_ICONS = {
	"": preload("res://assets/ui/frag-grenade.svg"),
	"comedy": preload("res://assets/ui/stink-bomb.svg"),
	"roach": preload("res://assets/ui/roach-bomb.svg"),
}
# Visible vertical fraction of each SVG with its safety pin in place.
const GRENADE_ART_HEIGHT = {"":.84,"comedy":.90,"roach":.87}
const GRENADE_KEY_G = preload("res://assets/ui/grenade-key-g.svg")
const GRENADE_PIN = preload("res://assets/ui/grenade-pin.svg")
const GRENADE_EJECT_DURATION = .13
var game: Node
var touch_inset_available = false
var font: Font
var hit = 0.0
var kill_pop = 0.0
var kill_group = 1
var multi_time = 0.0
var damage = 0.0
var damage_source: Variant = null
var shot = 0.0
var time_pulse = 0.0
var go_time = 0.0
var destroy_time = 0.0
const GO_DURATION = .8
const DESTROY_NOTICE_DURATION = 1.2
var health_shade = 0.0
var feed_shift = 0.0
var ejections: Array[float] = []
var grenade_eject_time = 0.0
var loading_cover: ColorRect
var vignette: ColorRect
var menu: Control
var menu_state = ""
var menu_size = Vector2.ZERO
var sensitivity_slider: HSlider
var motion_button: Button
var body_shot_button: Button
var music_slider: HSlider
var fire_button: Button
var comedy_buttons: Dictionary = {}
var badge_toasts: Array[String] = []
var badge_toast_time = 0.0
var title_badge_buttons: Array[TextureButton] = []
var hovered_badge: TextureButton
var selected_badge: TextureButton
var badge_detail: PanelContainer
var badge_pointer = Vector2.ZERO
var fire_progress: ProgressBar
var title_frame: ImageTexture
var title_previews: Dictionary = {}
var title_gutter_ratios = Vector4.ZERO
var web_title_layout_callback: JavaScriptObject
var web_touch_stick_callback: JavaScriptObject
var touch_stick_ratios := Rect2()
var web_comedy_callback: JavaScriptObject
var results_frame: ImageTexture
var results_frame_pending = false
var results_frame_ticket = 0
var map_scroll: ScrollContainer
var map_grid: Control
var map_scroll_offset := 0
var map_touch_index := -1
var map_touch_origin := Vector2.ZERO
var map_touch_scroll := 0
var map_touch_dragged := false
var map_touch_started_at := 0
var map_touch_opened_options := false
var park_options: PanelContainer
const TOP_HUD_SCALE = 1.5
const TITLE_SHADE_OPACITY = .55
const FIRE_PURPLE = Color("754c87")
const FIRE_PROGRESS_TRACK = Color("452d53")
const WHITE = Color("fff8e8")
const INK = Color("243440")
const GOLD = Color("f2d084")
const MAGAZINE_ATLAS = preload("res://assets/ui/magazine-atlas.png")
const WATER_ROUND = preload("res://assets/ui/water-round.svg")
const SLIPPER_ROUND = preload("res://assets/ui/slipper-round.svg")
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

func magazine_rect(seating: bool = true) -> Rect2:
	var dip = reload_seating_offset() if seating else 0.0
	var extent = Vector2(420,92)*MAGAZINE_SCALE
	if game.touch_mode:
		extent *= .72
		var hip := Rect2(Vector2((size.x-extent.x)*.5,size.y-extent.y-28),extent)
		var aim := smoothstep(0.0,1.0,game.player.aim_blend)
		if aim<=0.0:return Rect2(hip.position+Vector2(0,dip*.72),extent)
		var stick := Rect2(touch_stick_ratios.position*size,touch_stick_ratios.size*size)
		var right := size.x*.5-100.0
		var available := right-stick.end.x-14.0
		var aim_rect := hip
		if available>=extent.x*.60:
			aim_rect.size *= minf(1.0,available/extent.x)
			aim_rect.position = Vector2(right-aim_rect.size.x,size.y-aim_rect.size.y-28)
		else:
			var left := clampf(stick.get_center().x-extent.x*.5,12.0,maxf(12.0,right-extent.x))
			aim_rect.position = Vector2(left,stick.position.y-extent.y-16.0)
		var position := hip.position.lerp(aim_rect.position,aim)
		var shown_extent := extent.lerp(aim_rect.size,aim)
		position.y += dip*.72*shown_extent.x/extent.x
		return Rect2(position,shown_extent)
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

func grenade_stock_rect(index: int) -> Rect2:
	var magazine = magazine_rect(false)
	var round = round_rect(magazine,0)
	var extent = round.size.y
	var left = magazine.position.x if game.touch_mode else 28.0
	var top = magazine.position.y-extent-8 if game.touch_mode else round.position.y
	return Rect2(Vector2(left+index*(extent+8),top),Vector2.ONE*extent)

func draw_grenade_icon(icon: Texture2D, extent: float, tint: Color = Color.WHITE) -> void:
	var rect = Rect2(Vector2.ONE*(-extent*.5),Vector2.ONE*extent)
	draw_texture_rect(icon,rect,false,tint)
	if not game.touch_mode:draw_texture_rect(GRENADE_KEY_G,rect,false,tint)

func draw_grenade_stock() -> void:
	if game.rules.mission:return
	var stock: int = game.grenade_stock
	var icon = GRENADE_ICONS[game.comedy_mode]
	var art_height: float = GRENADE_ART_HEIGHT[game.comedy_mode]
	var release_at: float = game.GRENADE_WINDUP-game.GRENADE_RELEASE
	var pulling: bool = game.grenade_throw_time>release_at
	var windup = 1.0-(game.grenade_throw_time-release_at)/game.GRENADE_RELEASE if pulling else 0.0
	var motion = .42 if game.reduced_motion else 1.0
	for i in range(stock):
		var slot = grenade_stock_rect(i)
		var center = slot.get_center()
		var pulling_this = pulling and i==stock-1
		var pull = smoothstep(.04,.76,windup) if pulling_this else 0.0
		var extent = slot.size.x/art_height
		var body_center = center+Vector2(-4,2)*pull*motion
		draw_set_transform(body_center,-.18*pull*motion)
		draw_grenade_icon(icon,extent)
		draw_set_transform(Vector2.ZERO)
		var pin_size = Vector2(.40,.267)*extent
		var pin = body_center+Vector2(.18,-.31)*extent+Vector2(23,-20)*pull*motion
		var pin_alpha = 1.0-smoothstep(.58,1.0,windup) if pulling_this else 1.0
		draw_set_transform(pin,.42*pull*motion)
		draw_texture_rect(GRENADE_PIN,Rect2(-pin_size*.5,pin_size),false,Color(Color.WHITE,pin_alpha))
		draw_set_transform(Vector2.ZERO)
	if grenade_eject_time>0:
		var slot = grenade_stock_rect(stock)
		var t = 1.0-grenade_eject_time/GRENADE_EJECT_DURATION
		var center = slot.get_center()+Vector2(9+57*t,-7-26*t+9*t*t)*motion
		var extent = slot.size.x/art_height*(1.0-.27*t)
		var alpha = .9*(1.0-smoothstep(.25,1.0,t))
		if not game.reduced_motion:
			draw_line(center+Vector2(-23,9),center+Vector2(-11,5),Color(GOLD,alpha),2,true)
		draw_set_transform(center,.18+.8*t*motion)
		draw_grenade_icon(icon,extent,Color(Color.WHITE,alpha))
		draw_set_transform(Vector2.ZERO)

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
	var toy_round: Texture2D
	match game.comedy_mode:
		"comedy":toy_round = WATER_ROUND
		"roach":toy_round = SLIPPER_ROUND
	draw_rect(Rect2(body.position+Vector2(30,16)*scale_factor,Vector2(376,60)*scale_factor),INK.darkened(.35))
	draw_set_transform(body.get_center(),PI*.5)
	draw_texture_rect_region(MAGAZINE_ATLAS,Rect2(-Vector2(body.size.y,body.size.x)*.5,Vector2(body.size.y,body.size.x)),MAGAZINE_REGION)
	draw_set_transform(Vector2.ZERO)
	for i in range(count):
		var center = round_rect(body,i).get_center()-Vector2(shift,0)*scale_factor
		draw_ammo_round(toy_round,center,scale_factor,1)
	if incoming>0:
		var center = round_rect(body,0).get_center()+Vector2(42*(1-incoming),0)*scale_factor
		draw_ammo_round(toy_round,center,scale_factor,minf(1,incoming*4))
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
		if toy_round:
			draw_ammo_round(toy_round,origin+travel*scale_factor,scale_factor,alpha,rotation_amount)
			continue
		draw_round(CASING_REGION,origin+travel*scale_factor,Vector2(31.5,12.15),-PI*.5+rotation_amount,alpha,scale_factor)
		if age<.12:
			draw_round(TIP_REGION,origin+Vector2(0,-23-age*420)*scale_factor,Vector2(13.5,9.45),-PI*.5,1-age/.12,scale_factor)

func draw_ammo_round(icon: Texture2D, center: Vector2, scale_factor: float, alpha: float, angle: float = 0) -> void:
	if not icon:
		draw_round(CARTRIDGE_REGION,center,Vector2(45,12.15),-PI*.5,alpha,scale_factor)
		return
	var extent = Vector2(15,34)*scale_factor
	draw_set_transform(center,angle)
	draw_texture_rect(icon,Rect2(-extent*.5,extent),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

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
	# The opaque title snapshot already supplies every scene pixel. A new
	# preview is rendered independently, and gameplay keeps its live viewport.
	var title_only = game.state=="TITLE" and loading_cover.is_visible_in_tree()
	if get_viewport().disable_3d!=title_only:get_viewport().disable_3d = title_only
	vignette.visible = game.state not in ["TITLE","LOADING","RESULTS"]
	loading_cover.material.set_shader_parameter("progress",game.loading.reveal_progress() if game.state=="LOADING" else 0.0)
	loading_cover.material.set_shader_parameter("viewport_size",size)

func set_title_frame(image: Image, preview_key: String = "") -> void:
	if image==null or image.is_empty():return
	var texture = ImageTexture.create_from_image(image)
	var tints = PackedStringArray()
	if OS.has_feature("web"):
		# Reuse the existing opening capture and avoid the mast or sun skewing the tint.
		var samples: Array[Color] = []
		for i in range(7):
			samples.append(image.get_pixel(roundi(image.get_width()*(.14+i*.12)),0))
		samples.sort_custom(func(a: Color,b: Color):return a.get_luminance()<b.get_luminance())
		var sky = samples[3]
		var menu_sky = sky.darkened(TITLE_SHADE_OPACITY)
		tints = PackedStringArray([menu_sky.to_html(false),sky.to_html(false)])
	if not preview_key.is_empty() and image.get_width()*image.get_height()<=2560*1440:
		title_previews[preview_key] = {"texture":texture,"tints":tints}
	show_title_frame(texture,tints)

func reuse_title_frame(preview_key: String) -> bool:
	if not title_previews.has(preview_key):return false
	var preview: Dictionary = title_previews[preview_key]
	if Vector2i(preview.texture.get_size())!=game.preview_size():
		title_previews.erase(preview_key)
		return false
	show_title_frame(preview.texture,preview.tints)
	return true

func show_title_frame(texture: ImageTexture, tints: PackedStringArray) -> void:
	title_frame = texture
	loading_cover.material.set_shader_parameter("opening_frame",title_frame)
	loading_cover.material.set_shader_parameter("shade_opacity",TITLE_SHADE_OPACITY)
	sync_loading_cover()
	if not tints.is_empty():
		JavaScriptBridge.eval("window.noArtSetSky?.('#%s','#%s')"%[tints[0],tints[1]])

func save_web_title_preview(map_id: String, default_preview_key: String = "") -> void:
	var encoded := ""
	var source: ImageTexture = title_frame
	if not default_preview_key.is_empty():
		source = title_previews.get(default_preview_key,{}).get("texture")
	if source:
		var preview := source.get_image()
		if preview and not preview.is_empty():
			var scale := minf(1.0,minf(1200.0/preview.get_width(),810.0/preview.get_height()))
			if scale<1.0:
				preview.resize(maxi(1,roundi(preview.get_width()*scale)),
					maxi(1,roundi(preview.get_height()*scale)),Image.INTERPOLATE_LANCZOS)
			encoded = Marshalls.raw_to_base64(preview.save_webp_to_buffer(true,.78))
	JavaScriptBridge.get_interface("window").noArtRememberTitle(map_id,encoded)

func update_web_title_layout(args: Array) -> void:
	if menu_state=="PAUSED" and args.size()>4 and touch_inset_available!=bool(args[4]):
		menu_size = Vector2.ZERO
	var next = Vector4(args[0],args[1],args[2],args[3])
	if next==title_gutter_ratios:return
	title_gutter_ratios = next
	if menu_state=="TITLE":menu_size = Vector2.ZERO

func title_gutters() -> Vector4:
	if title_gutter_ratios==Vector4.ZERO:return Vector4.ONE*(40.0 if game.touch_mode else 56.0)
	return title_gutter_ratios*Vector4(size.x,size.x,size.y,size.y)

func title_word_position(row: int, gutters: Vector4) -> Vector2:
	var baseline = maxf(116,gutters.w+90) if game.touch_mode else maxf(220,gutters.w+144)
	return Vector2(gutters.x,baseline+row*(100 if game.touch_mode else 150))

func queue_badge_toast(id: String) -> void:
	if game.state!="RUNNING":return
	if badge_toasts.is_empty():badge_toast_time = BADGE_TOAST_DURATION
	badge_toasts.append(id)

func reset_badge_toasts() -> void:
	badge_toasts.clear()
	badge_toast_time = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web"):
		web_title_layout_callback = JavaScriptBridge.create_callback(update_web_title_layout)
		var browser = JavaScriptBridge.get_interface("window")
		browser.noArtTitleLayoutChanged = web_title_layout_callback
		web_touch_stick_callback = JavaScriptBridge.create_callback(func(args):
			touch_stick_ratios = Rect2(float(args[0]),float(args[1]),float(args[2]),float(args[3])))
		browser.noArtTouchStickChanged = web_touch_stick_callback
		web_comedy_callback = JavaScriptBridge.create_callback(func(args):
			if args.size()==1 and str(args[0]) in ["comedy","roach"]:game.menu_action(str(args[0])))
		browser.noArtToggleComedy = web_comedy_callback
		JavaScriptBridge.eval("window.noArtSyncTitleLayout?.()")
	font = preload("res://assets/fonts/Rajdhani-Bold.ttf")
	font.fallbacks = [preload("res://assets/fonts/GlowSansSC-UI.otf")]
	theme = Theme.new()
	theme.default_font = font
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
	if game and game.state=="RUNNING":grenade_eject_time = maxf(0,grenade_eject_time-delta)
	if game and game.state=="RUNNING":go_time = maxf(0,go_time-delta)
	if game and game.state=="RUNNING":destroy_time = maxf(0,destroy_time-delta)
	if game and game.state=="RUNNING" and not badge_toasts.is_empty():
		badge_toast_time -= delta
		if badge_toast_time<=0:
			badge_toasts.pop_front()
			badge_toast_time = BADGE_TOAST_DURATION
	feed_shift = maxf(0,feed_shift-delta)
	for i in range(ejections.size()):ejections[i] += delta
	ejections = ejections.filter(func(age):return age<EJECTION_TIME)
	time_pulse = maxf(0,time_pulse-delta*2.5)
	damage = maxf(0,damage-delta)
	if game:
		var target = clampf(1.0-game.health/game.MAX_HEALTH,0,1) if game.state in ["RUNNING","PAUSED","CAPTURING"] else 0.0
		health_shade = move_toward(health_shade,target,delta*(1.15 if target>health_shade else .85))
		vignette.material.set_shader_parameter("severity",health_shade)
		vignette.material.set_shader_parameter("hit_flash",pow(clampf(damage/.8,0,1),2))
	hit = maxf(0,hit-delta)
	kill_pop = maxf(0,kill_pop-delta)
	multi_time = maxf(0,multi_time-delta)
	shot = maxf(0,shot-delta)
	if game and (menu_state != game.state or menu_size != size):
		rebuild_menu()
	if menu_state=="TITLE":
		update_map_hold()
	if is_instance_valid(fire_progress):
		fire_progress.value = game.map_switch_progress
	if game and game.state == "PAUSED":
		sensitivity_slider.set_value_no_signal(game.player.sensitivity)
		motion_button.text = tr("LOW" if game.reduced_motion else "FULL")
		music_slider.set_value_no_signal(game.music_volume)
		if game.touch_mode:body_shot_button.text = tr("ON" if game.touch_body_one_shot else "OFF")
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
	var remaining = clampf(game.respawn_time/game.respawn_duration,0,1)
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

func map_button(node_name: String, map_name: String, action: String, thumbnail: Texture2D,
		rect: Rect2, selected: bool, best_kills: int) -> Button:
	var card = Button.new()
	card.name = node_name
	card.accessibility_name = map_name
	card.accessibility_description = tr("Best kills %d")%best_kills
	card.position = rect.position
	card.size = rect.size
	card.disabled = game.switching_session
	var image = StyleBoxTexture.new()
	image.texture = thumbnail
	for state_name in ["normal","hover","pressed","disabled"]:
		card.add_theme_stylebox_override(state_name,image)
	var focus = StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.set_expand_margin_all(4)
	focus.border_color = Color.WHITE
	card.add_theme_stylebox_override("focus",focus)
	if selected:
		var outline = Panel.new()
		outline.name = "Selected"
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var border = StyleBoxFlat.new()
		border.draw_center = false
		border.set_border_width_all(4)
		border.border_color = Color("ffe445")
		outline.add_theme_stylebox_override("panel",border)
		card.add_child(outline)
		outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.pressed.connect(func():game.menu_action(action))
	map_grid.add_child(card)
	map_record(card,best_kills)
	return card

func map_record(card: Button, best_kills: int) -> void:
	var record = PanelContainer.new()
	record.name = "Record"
	record.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing = StyleBoxFlat.new()
	backing.bg_color = Color("15222eee")
	backing.set_corner_radius_all(5)
	backing.content_margin_left = 5
	backing.content_margin_right = 8
	record.add_theme_stylebox_override("panel",backing)
	card.add_child(record)
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",4)
	record.add_child(row)
	var medal = TextureRect.new()
	medal.texture = MEDAL_ICON
	medal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(medal)
	var score = Label.new()
	score.name = "Score"
	score.text = str(best_kills)
	score.add_theme_font_size_override("font_size",26)
	score.add_theme_color_override("font_color",WHITE)
	score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(score)
	record.reset_size()
	record.scale = Vector2.ONE*.5
	record.position = Vector2(card.size.x-record.size.x*record.scale.x-8,8)

func sync_comedy_buttons() -> void:
	for action in comedy_buttons:
		comedy_buttons[action].set_pressed_no_signal(game.comedy_mode==action)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.noArtSetComedy?.(%s)"%JSON.stringify(game.comedy_mode))

func badge_copy(title: String, description: String, font_size: int, wrap_width: float = 0.0) -> VBoxContainer:
	var column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",1)
	for i in range(2):
		var text = Label.new()
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.size.x = wrap_width
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = title if i==0 else description
		text.add_theme_font_size_override("font_size",font_size-i*4)
		text.add_theme_color_override("font_color",GOLD if i==0 else WHITE)
		column.add_child(text)
	return column

func title_badges(gutters: Vector4) -> void:
	var ids = BadgeCatalog.BADGES.keys()
	var text_size = 106 if game.touch_mode else 160
	var extent = roundf(text_size*.24)
	for i in range(ids.size()):
		var id: String = ids[i]
		if not game.achievements.unlocked_badge(id):continue
		var row = floori(i*.25) if i<12 else mini(i-12,2)
		var anchor: Vector2 = BADGE_ANCHORS[row][i%4] if i<12 else EXTRA_BADGE_ANCHORS[i-12]
		var center = title_word_position(row,gutters)+anchor*text_size
		var badge: Array = BadgeCatalog.BADGES[id]
		var button = TextureButton.new()
		button.name = "Badge_"+id
		button.texture_normal = badge[3]
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size = Vector2.ONE*extent
		button.position = center-button.size*.5
		button.accessibility_name = tr(badge[0])
		button.accessibility_description = tr(badge[1])
		menu.add_child(button)
		title_badge_buttons.append(button)
		button.gui_input.connect(func(event: InputEvent):
			if not event is InputEventMouseMotion or event.device==InputEvent.DEVICE_ID_EMULATION:return
			badge_pointer = button.get_transform()*event.position
			if hovered_badge==button:
				place_badge_detail()
				return
			hovered_badge = button
			update_badge_detail())
		button.mouse_exited.connect(func():
			if hovered_badge!=button:return
			hovered_badge = null
			update_badge_detail())
		button.pressed.connect(func():
			selected_badge = null if selected_badge==button else button
			update_badge_detail())

func _input(event: InputEvent) -> void:
	if menu_state=="TITLE" and handle_park_options(event):return
	if menu_state=="TITLE" and handle_map_touch(event):return
	if menu_state!="TITLE" or not is_instance_valid(selected_badge):return
	var pointer_down = (event is InputEventScreenTouch and event.pressed) or (
		event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
	if not pointer_down:return
	for button in title_badge_buttons:
		if button.get_global_rect().has_point(event.position):return
	selected_badge = null
	update_badge_detail()

func park_card_at(point: Vector2) -> bool:
	if not is_instance_valid(map_scroll) or not map_scroll.get_global_rect().has_point(point):return false
	var card := map_grid.get_node("MapPark") as Control
	return card.get_global_rect().has_point(point)

func handle_park_options(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		if not game.switching_session and park_card_at(event.position):
			if game.park_experiment_unlocked:open_park_options(event.position)
			get_viewport().set_input_as_handled()
			return true
	if not is_instance_valid(park_options):return false
	if event.is_action_pressed("pause"):
		close_park_options()
		get_viewport().set_input_as_handled()
		return true
	var pointer_down = (event is InputEventScreenTouch and event.pressed) or (
		event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
	if pointer_down and not park_options.get_global_rect().has_point(event.position):
		close_park_options()
	return false

func update_map_hold() -> void:
	if not game.park_experiment_unlocked or map_touch_index<0 or map_touch_dragged or map_touch_opened_options or game.switching_session:return
	if Time.get_ticks_msec()-map_touch_started_at>=MAP_HOLD_MS and park_card_at(map_touch_origin):
		map_touch_opened_options = true
		open_park_options(map_touch_origin)

func open_park_options(point: Vector2) -> void:
	close_park_options()
	park_options = PanelContainer.new()
	park_options.name = "ParkTextureOptions"
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("1b2937")
	backing.border_color = GOLD
	backing.set_border_width_all(1)
	backing.set_corner_radius_all(7)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:backing.set_content_margin(side,10)
	park_options.add_theme_stylebox_override("panel",backing)
	var toggle := CheckButton.new()
	toggle.name = "ExperimentalTextures"
	toggle.text = tr("Experimental textures")
	toggle.add_theme_font_override("font",font)
	toggle.add_theme_font_size_override("font_size",26)
	toggle.custom_minimum_size = Vector2(232,40)
	toggle.set_pressed_no_signal(game.park_experimental_textures)
	toggle.toggled.connect(func(enabled: bool):
		game.set_park_experimental_textures(enabled)
		toggle.set_pressed_no_signal(game.park_experimental_textures))
	park_options.add_child(toggle)
	menu.add_child(park_options)
	park_options.reset_size()
	var bounds := park_options.get_combined_minimum_size()
	park_options.position = (point+Vector2(8,12)).clamp(Vector2.ONE*8,(size-bounds-Vector2.ONE*8).max(Vector2.ONE*8))

func close_park_options() -> void:
	if not is_instance_valid(park_options):return
	menu.remove_child(park_options)
	park_options.queue_free()
	park_options = null

func handle_map_touch(event: InputEvent) -> bool:
	if not game.touch_mode or not is_instance_valid(map_scroll):return false
	var visible_grid := map_scroll.get_global_rect()
	if is_instance_valid(park_options) and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if park_options.get_global_rect().has_point(event.position) and map_touch_index<0:return false
	if (event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION
			and event.button_index==MOUSE_BUTTON_LEFT and visible_grid.has_point(event.position)):
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventScreenTouch:
		if event.pressed and map_touch_index<0 and visible_grid.has_point(event.position):
			map_touch_index = event.index
			map_touch_origin = event.position
			map_touch_scroll = map_scroll.scroll_vertical
			map_touch_dragged = false
			map_touch_started_at = Time.get_ticks_msec()
			map_touch_opened_options = false
		elif not event.pressed and event.index==map_touch_index:
			if not event.canceled:update_map_hold()
			map_touch_index = -1
			var tapped := Time.get_ticks_msec()-map_touch_started_at<MAP_HOLD_MS and not map_touch_dragged
			if not event.canceled and tapped and visible_grid.has_point(event.position):
				for card: Button in map_grid.get_children():
					if not card.disabled and card.get_global_rect().has_point(event.position):
						card.grab_focus()
						card.pressed.emit()
						break
			get_viewport().set_input_as_handled()
			return true
		if event.index!=map_touch_index:return false
	elif event is InputEventScreenDrag and event.index==map_touch_index:
		var offset: Vector2 = event.position-map_touch_origin
		if offset.length()>=12.0:map_touch_dragged = true
		if map_touch_dragged and not map_touch_opened_options:
			map_scroll.scroll_vertical = map_touch_scroll-roundi(offset.y)
	else:return false
	get_viewport().set_input_as_handled()
	return true

func update_badge_detail() -> void:
	if is_instance_valid(badge_detail):
		menu.remove_child(badge_detail)
		badge_detail.queue_free()
		badge_detail = null
	var active = hovered_badge if is_instance_valid(hovered_badge) else selected_badge
	if not is_instance_valid(active):return
	var gutters = title_gutters()
	var detail = PanelContainer.new()
	detail.name = "BadgeDetail"
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color("17242f")
	style.border_color = Color(GOLD,.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		style.set_content_margin(side,12)
	detail.add_theme_stylebox_override("panel",style)
	var width = minf(272,size.x-gutters.x-gutters.y-24)
	var column = badge_copy(active.accessibility_name,active.accessibility_description,24,width)
	column.custom_minimum_size.x = width
	detail.add_child(column)
	menu.add_child(detail)
	badge_detail = detail
	detail.resized.connect(place_badge_detail)
	detail.reset_size()
	place_badge_detail()

func place_badge_detail() -> void:
	if not is_instance_valid(badge_detail):return
	const GAP = 12.0
	var anchor = Rect2(badge_pointer,Vector2.ZERO)
	if not is_instance_valid(hovered_badge):
		if not is_instance_valid(selected_badge):return
		anchor = selected_badge.get_rect()
	var gutters = title_gutters()
	var first = Vector2(gutters.x,gutters.w)
	var last = (size-Vector2(gutters.y,gutters.z)-badge_detail.size).max(first)
	var pos = anchor.end+Vector2.ONE*GAP
	if pos.x>last.x:pos.x = anchor.position.x-GAP-badge_detail.size.x
	if pos.y>last.y:pos.y = anchor.position.y-GAP-badge_detail.size.y
	badge_detail.position = pos.clamp(first,last)

func results_badges(center: Vector2) -> void:
	var list = ScrollContainer.new()
	list.name = "ResultBadges"
	list.position = center+Vector2(-250,-40)
	list.size = Vector2(500,184)
	list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu.add_child(list)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",5)
	list.add_child(column)
	for id in game.achievements.run_unlocks:
		var badge: Array = BadgeCatalog.BADGES[id]
		var row = HBoxContainer.new()
		row.name = "Badge_"+id
		row.add_theme_constant_override("separation",12)
		column.add_child(row)
		var icon = TextureRect.new()
		icon.texture = badge[3]
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36,36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var copy = badge_copy(tr(badge[0]),tr(badge[1]),20)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)

func rebuild_menu() -> void:
	map_touch_index = -1
	park_options = null
	if is_instance_valid(map_scroll):
		map_scroll_offset = map_scroll.scroll_vertical
	map_scroll = null
	map_grid = null
	title_badge_buttons.clear()
	hovered_badge = null
	selected_badge = null
	badge_detail = null
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	fire_progress = null
	comedy_buttons.clear()
	menu_state = game.state
	menu_size = size
	var c = size*.5
	if menu_state == "TITLE":
		var gutters = title_gutters()
		var bottom = size.y-gutters.z
		var fire_height = 100 if game.touch_mode else 112
		fire_button = menu_button("FIRE",Rect2(gutters.x,bottom-fire_height,260 if game.touch_mode else 300,fire_height),"play",false,tr("Enter"))
		fire_button.name = "fire"
		fire_button.disabled = game.switching_session
		fire_button.add_theme_font_size_override("font_size",68)
		fire_button.add_theme_constant_override("outline_size",0)
		for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
			fire_button.add_theme_color_override(color_name,Color.WHITE)
		for style_name in ["normal","hover","pressed","focus"]:
			var style = StyleBoxFlat.new()
			style.bg_color = FIRE_PURPLE
			if style_name=="hover":style.bg_color = style.bg_color.lightened(.12)
			if style_name=="pressed":style.bg_color = style.bg_color.darkened(.14)
			if style_name=="focus":
				style.bg_color = Color.TRANSPARENT
				style.set_border_width_all(2)
				style.border_color = Color.WHITE
			fire_button.add_theme_stylebox_override(style_name,style)
		if game.switching_session:
			fire_button.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
			fire_progress = ProgressBar.new()
			fire_progress.accessibility_name = tr("Map loading progress")
			fire_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fire_progress.show_percentage = false
			fire_progress.show_behind_parent = true
			fire_progress.max_value = 1.0
			fire_progress.step = 0.0
			fire_progress.value = game.map_switch_progress
			var track = StyleBoxFlat.new()
			track.bg_color = FIRE_PROGRESS_TRACK
			var fill = StyleBoxFlat.new()
			fill.bg_color = FIRE_PURPLE
			fire_progress.add_theme_stylebox_override("background",track)
			fire_progress.add_theme_stylebox_override("fill",fill)
			fire_button.add_child(fire_progress)
			fire_progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fire_button.pivot_offset = fire_button.size*.5
		fire_button.button_down.connect(func():fire_button.scale = Vector2.ONE*.96)
		fire_button.button_up.connect(func():fire_button.scale = Vector2.ONE)
		var gap = 10.0 if game.touch_mode else 12.0
		var grid_room = bottom-gutters.w-64.0
		var row_room = size.x-gutters.x-gutters.y-fire_button.size.x-32.0
		var width = minf(176.0 if game.touch_mode else 216.0,(grid_room-2*gap)*16/27)
		width = minf(width,(row_room-2*gap)/3.0)
		var height = width*9/16
		var viewport_extent = Vector2(3*width+2*gap,3*height+2*gap)
		var corner = Vector2(size.x-gutters.y,bottom)-viewport_extent
		map_scroll = ScrollContainer.new()
		map_scroll.name = "MapScroll"
		map_scroll.position = corner
		map_scroll.size = viewport_extent
		map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		map_scroll.scroll_deadzone = 12
		map_scroll.follow_focus = true
		menu.add_child(map_scroll)
		map_grid = Control.new()
		map_grid.name = "MapGrid"
		map_grid.mouse_filter = Control.MOUSE_FILTER_PASS
		map_grid.custom_minimum_size = Vector2(viewport_extent.x,4*height+3*gap)
		map_scroll.add_child(map_grid)
		map_scroll.set_deferred("scroll_vertical",map_scroll_offset)
		var maps = [
			["MapYard",tr("Container Yard"),"arena",YARD_THUMBNAIL,"score_attack"],
			["MapPark",tr("Sunset Park"),"amusement_park",PARK_THUMBNAIL,"amusement_park"],
			["MapFerry",tr("Last Ferry"),"last_ferry",FERRY_THUMBNAIL,"last_ferry"],
			["MapStudio",tr("Night Studio"),"night_studio",STUDIO_THUMBNAIL,"night_studio"],
			["MapSandgate",tr("Sandgate"),"sandgate",SANDGATE_THUMBNAIL,"sandgate"],
			["MapOffice",tr("BB Office"),"bb_office",OFFICE_THUMBNAIL,"bb_office"],
			["MapRainMarket",tr("Hong Kong Rain Market"),"rain_market",RAIN_THUMBNAIL,"rain_market"],
			["MapBaggage",tr("Baggage Below"),"baggage_below",BAGGAGE_THUMBNAIL,"baggage_below"],
			["MapSnowline",tr("Snowline Observatory"),"snowline",SNOWLINE_THUMBNAIL,"snowline"],
			["MapHogwarts",tr("Hogwarts"),"hogwarts",HOGWARTS_THUMBNAIL,"hogwarts"],
			["MapPalmHouse",tr("Palm House"),"palm_house",PALM_THUMBNAIL,"palm_house"],
			["MapGinza",tr("Ginza Station"),"ginza_station",GINZA_THUMBNAIL,"ginza_station"],
		]
		var tab_order = [fire_button]
		for i in range(maps.size()):
			var item: Array = maps[i]
			var column = i%3
			var row = floori(i/3.0)
			var position = Vector2(column*(width+gap),row*(height+gap))
			tab_order.append(map_button(item[0],item[1],item[2],item[3],Rect2(position,Vector2(width,height)),
				game.title_session_id==item[4],game.map_best_score(item[4])))
		if not OS.has_feature("web"):
			var modes = [["comedy",tr("Poop Mode"),COMEDY_ICON,Color("62412f")],
				["roach",tr("Cockroach Mode"),ROACH_ICON,Color("533c65")]]
			for i in range(modes.size()):
				var mode: Array = modes[i]
				var button = menu_button("",Rect2(size.x-gutters.y-112+60*i,gutters.w,52,52),mode[0],false,mode[1])
				button.accessibility_name = mode[1]
				button.toggle_mode = true
				button.icon = mode[2]
				button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				button.add_theme_constant_override("icon_max_width",32)
				var style = StyleBoxFlat.new()
				style.bg_color = mode[3]
				style.border_color = GOLD
				style.set_border_width_all(2)
				button.add_theme_stylebox_override("pressed",style)
				comedy_buttons[mode[0]] = button
				tab_order.append(button)
			sync_comedy_buttons()
		title_badges(gutters)
		tab_order.append_array(title_badge_buttons)
		for i in range(tab_order.size()):
			tab_order[i].focus_next = tab_order[i].get_path_to(tab_order[(i+1)%tab_order.size()])
			tab_order[i].focus_previous = tab_order[i].get_path_to(tab_order[i-1])
		if game.dust_unlocked:
			menu_button(tr("SCORE ATTACK"),Rect2(c.x-130,c.y-75,260,62),"arena",game.title_session_id=="score_attack")
			menu_button(tr("DEFUSE C4"),Rect2(c.x-130,c.y+5,260,62),"defuse",game.title_session_id=="defuse_mission")

	elif menu_state == "RESULTS":
		if game.rules.mission:
			menu_button(tr("RETRY"),Rect2(c.x-174,c.y+106,160,70),"retry",true,tr("Retry · Enter"))
			menu_button(tr("TITLE"),Rect2(c.x+14,c.y+106,160,70),"menu",false,tr("Title · Esc"))
		else:
			var earned_badges = not game.achievements.run_unlocks.is_empty()
			var actions_y = c.y+(156 if earned_badges else 106)
			var button_height = 78 if earned_badges else 88
			results_button(RETRY_ICON,Rect2(c.x-174,actions_y,160,button_height),"retry",true,tr("Retry · Enter"))
			results_button(HOME_ICON,Rect2(c.x+14,actions_y,160,button_height),"menu",false,tr("Title · Esc"))
			if earned_badges:results_badges(c)
	elif menu_state == "PAUSED":
		touch_inset_available = game.touch_mode and OS.has_feature("web") and bool(JavaScriptBridge.eval("window.noArtHasControlInset?.()"))
		var card = pause_card()
		sensitivity_slider = pause_slider("Touch sensitivity" if game.touch_mode else "Sensitivity",pause_row(card,0),Vector3(.0006,.006,.0002),game.player.sensitivity,func(value):
			game.player.sensitivity = value
			game.save_record())
		var motion_row = pause_row(card,1)
		motion_button = pause_button("",Rect2(motion_row.end.x-136,motion_row.position.y+3,124,48),"motion",false,"M")
		motion_button.accessibility_description = tr("Camera motion")
		music_slider = pause_slider("Music",pause_row(card,2),Vector3(0,1,.05),game.music_volume,func(value):
			game.set_music_volume(value)
			game.save_record())
		if game.touch_mode:
			var body_row = pause_row(card,3)
			var body_toggle = Rect2(body_row.end.x-136,body_row.position.y+3,124,48)
			body_shot_button = pause_button(tr("ON" if game.touch_body_one_shot else "OFF"),body_toggle,"touch_body_shots",false,"")
			body_shot_button.accessibility_name = tr("One-hit body shots")
			body_shot_button.toggle_mode = true
			body_shot_button.set_pressed_no_signal(game.touch_body_one_shot)
			var enabled_style = body_shot_button.get_theme_stylebox("pressed").duplicate()
			enabled_style.bg_color = Color("453b2b")
			enabled_style.set_border_width_all(1)
			enabled_style.border_color = Color(GOLD,.5)
			body_shot_button.add_theme_stylebox_override("pressed",enabled_style)
			var gyro_row = 4
			if touch_inset_available:
				var inset = float(JavaScriptBridge.eval("window.noArtGetControlInset()"))
				pause_slider("Control inset",pause_row(card,4),Vector3(0,96,4),inset,func(value):
					JavaScriptBridge.eval("window.noArtSetControlInset(%d)"%roundi(value)))
				gyro_row += 1
			pause_button(tr("GYRO AIM"),pause_row(card,gyro_row),"gyro",false,"",GYRO_ICON)
		var language = pause_button(tr("语言：英文"),Rect2(card.end.x-238,card.position.y+17,214,44),"language",false,"")
		language.add_theme_font_size_override("font_size",21)
		var footer = card.position+Vector2(24,card.size.y-76)
		var button_size = Vector2((card.size.x-68)/3,52)
		var step = Vector2(button_size.x+10,0)
		var actions = [
			[tr("RESUME"),"resume","Esc",RESUME_ICON],
			[tr("RESTART"),"retry",tr("Enter"),RESTART_ICON],
			[tr("HOME"),"menu","",PAUSE_HOME_ICON],
		]
		for i in range(actions.size()):
			var item: Array = actions[i]
			var button = pause_button(item[0],Rect2(footer+step*i,button_size),item[1],i==0,item[2],item[3])
			button.add_theme_font_size_override("font_size",21)
			button.size = button_size

func pause_card() -> Rect2:
	var extent = Vector2(520,492 if game.touch_mode else 364)
	if touch_inset_available:extent.y = 520
	return Rect2((size-extent)*.5,extent)

func pause_row(card: Rect2, index: int) -> Rect2:
	var top = 76+index*58 if touch_inset_available else 82+index*64
	return Rect2(card.position+Vector2(24,top),Vector2(card.size.x-48,54))

func pause_button(text: String, rect: Rect2, action: String, primary: bool, shortcut: String, icon: Texture2D = null) -> Button:
	var button = menu_button(text,rect,action,false,shortcut)
	button.icon = icon
	if icon:button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width",24)
	button.add_theme_constant_override("h_separation",12)
	for state_name in ["normal","hover","pressed","focus"]:
		var style = button.get_theme_stylebox(state_name).duplicate()
		style.set_corner_radius_all(6)
		style.set_content_margin(SIDE_LEFT,14)
		style.set_content_margin(SIDE_RIGHT,14)
		if state_name!="focus":
			style.bg_color = Color("754c87") if primary else Color("263645")
			if state_name=="hover":style.bg_color = style.bg_color.lightened(.12)
			if state_name=="pressed":style.bg_color = style.bg_color.darkened(.14)
		button.add_theme_stylebox_override(state_name,style)
	return button

func pause_slider(title: String, row: Rect2, limits: Vector3, value: float, on_change: Callable) -> HSlider:
	var slider = HSlider.new()
	slider.name = title
	slider.accessibility_name = tr(title)
	slider.position = Vector2(row.end.x-186,row.position.y+3)
	slider.size = Vector2(170,48)
	slider.min_value = limits.x
	slider.max_value = limits.y
	slider.step = limits.z
	slider.value = value
	slider.add_theme_icon_override("grabber",SLIDER_GRIP)
	slider.add_theme_icon_override("grabber_highlight",SLIDER_GRIP)
	for style_name in ["slider","grabber_area","grabber_area_highlight"]:
		var track = StyleBoxFlat.new()
		track.bg_color = Color("46586a") if style_name=="slider" else GOLD
		track.set_corner_radius_all(2)
		track.set_content_margin(SIDE_TOP,2)
		track.set_content_margin(SIDE_BOTTOM,2)
		slider.add_theme_stylebox_override(style_name,track)
	slider.value_changed.connect(on_change)
	menu.add_child(slider)
	return slider

func draw_pause() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.58))
	death_marks()
	var card = pause_card()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("17242f")
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(GOLD,.48)
	style.shadow_color = Color(0,0,0,.32)
	style.shadow_size = 12
	draw_style_box(style,card)
	var top = card.position
	draw_line(top+Vector2(24,1),top+Vector2(100,1),GOLD,3)
	draw_texture_rect(PAUSE_ICON,Rect2(top+Vector2(24,24),Vector2(30,30)),false)
	label(tr("PAUSED"),top+Vector2(64,52),34)
	var names = ["Touch sensitivity" if game.touch_mode else "Sensitivity","Camera motion","Music"]
	var icons = [AIM_ICON,MOTION_ICON,MUSIC_ICON]
	if game.touch_mode:
		names.append("One-hit body shots")
		icons.append(ONE_HIT_ICON)
	if touch_inset_available:
		names.append("Control inset")
		icons.append(INSET_ICON)
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color("1f2e3c")
	row_style.set_corner_radius_all(6)
	for index in range(names.size()):
		var row = pause_row(card,index)
		draw_style_box(row_style,row)
		draw_texture_rect(icons[index],Rect2(row.position+Vector2(14,14),Vector2(26,26)),false)
		label(tr(names[index]),row.position+Vector2(52,36),24)

func results_button(texture: Texture2D, rect: Rect2, action: String, primary: bool, tooltip: String) -> Button:
	var button = menu_button("",rect,action,primary,tooltip)
	button.accessibility_name = tooltip.get_slice(" · ",0)
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
	var earned_badges = not game.rules.mission and not game.achievements.run_unlocks.is_empty()
	var half = Vector2(276,250) if earned_badges else Vector2(238,220)
	draw_style_box(card,Rect2(c-half,half*2))
	draw_line(c+Vector2(-46,1-half.y),c+Vector2(46,1-half.y),GOLD,3)
	if game.rules.mission:
		var success = game.rules.outcome=="SUCCESS"
		label(tr("DEFUSED" if success else "FAILED"),c+Vector2(0,-125),56,GOLD if success else WHITE,true)
		label("%d / 3 C4"%game.rules.completed.size(),c+Vector2(0,-53),34,WHITE,true)
		var detail = tr("%.1f s")%game.rules.elapsed if success else tr("TIME EXPIRED" if game.rules.outcome=="TIMEOUT" else "KILLED")
		label(detail,c+Vector2(0,8),26,WHITE,true)
		if success and game.best_mission>0:label(tr("BEST %.1f s")%game.best_mission,c+Vector2(0,54),20,GOLD,true)
		return
	if earned_badges:c.y -= 90
	var score = str(game.rules.kills)
	var score_size = 104 if score.length()<=3 else 80
	var width = font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x
	var left = c.x-(76+18+width)*.5
	draw_texture_rect(KILLS_ICON,Rect2(Vector2(left,c.y-146),Vector2(76,76)),false)
	label(score,Vector2(left+94,c.y-70),score_size,WHITE)
	if earned_badges:c.y -= 28
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

func draw_destroy_notice(center: Vector2) -> void:
	var text_size = 66 if game.touch_mode else 82
	var opacity = smoothstep(0,.22,destroy_time)
	var settle = smoothstep(0,.12,DESTROY_NOTICE_DURATION-destroy_time)
	var scale_factor = 1.0 if game.reduced_motion else lerpf(1.08,1,settle)
	var notice = tr("DESTROY ALL")
	var notice_font: Font = font if notice=="DESTROY ALL" else FRENZY_FONT_ZH
	var words = notice.split(" ")
	var widths: Array[float] = []
	var gap = text_size*.2
	var width = gap*(words.size()-1)
	for word in words:
		var extent = notice_font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x
		widths.append(extent)
		width += extent
	var baseline = Vector2(-width*.5,text_size*.32)
	draw_set_transform(center-Vector2(0,96),0,Vector2.ONE*scale_factor)
	for i in range(words.size()):
		draw_string_outline(notice_font,baseline,words[i],HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,3,Color(INK,.85*opacity))
		draw_string(notice_font,baseline,words[i],HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color(WHITE if i==0 else Color("ffb557"),opacity))
		baseline.x += widths[i]+gap
	draw_set_transform(Vector2.ZERO)

func draw_badge_toast() -> void:
	if badge_toasts.is_empty():return
	var badge: Array = BadgeCatalog.BADGES[badge_toasts[0]]
	var alpha = smoothstep(0,.24,badge_toast_time)*(1-smoothstep(1.62,BADGE_TOAST_DURATION,badge_toast_time))
	var title = tr(badge[0])
	var width = font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x+66
	var pos = Vector2(size.x-38-width,91)
	if not game.reduced_motion:pos.x += 12*(1-alpha)
	draw_rect(Rect2(pos,Vector2(width,46)),Color(INK,.92*alpha))
	draw_rect(Rect2(pos,Vector2(3,46)),Color(GOLD,alpha))
	draw_texture_rect(badge[3],Rect2(pos+Vector2(9,7),Vector2(32,32)),false,Color(WHITE,alpha))
	label(title,pos+Vector2(49,31),24,Color(WHITE,alpha))

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
		var gutters = title_gutters()
		for i in range(TITLE_WORDS.size()):
			draw_string(font,title_word_position(i,gutters),TITLE_WORDS[i],HORIZONTAL_ALIGNMENT_LEFT,-1,106 if game.touch_mode else 160,Color.WHITE)
		return
	if state == "RESULTS":
		if results_frame_pending:
			draw_finale_edges()
			return
		if results_frame:draw_texture_rect(results_frame,Rect2(Vector2.ZERO,size),false)
		draw_results()
		return
	if state == "PAUSED":
		draw_pause()
		return
	draw_finale_edges()
	if game.finale_active:
		draw_top_summary()
		return
	if game.respawn_time>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.28))
	death_marks()
	draw_top_summary()
	if game.respawn_time<=0:
		var gap = 5+shot*24
		var aim_center = c+game.player.crosshair_offset
		if hit>0:
			var col = GOLD if kill_pop>0 else WHITE
			for a in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(aim_center+a*7,aim_center+a*12,col,2)
		elif game.player.aim_blend>=.5 and game.player.uses_iron_sights():
			# The aligned iron sights are the reticle; a faint dot marks the post tip.
			var settle := smoothstep(.5,.85,game.player.aim_blend)
			draw_circle(aim_center,2.5,Color(INK,.8*settle))
			draw_circle(aim_center,1.5,Color(GOLD,settle))
		elif game.player.aim_blend>=.5:
			for a in [Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]:
				draw_line(aim_center+a*8,aim_center+a*16,INK,4)
				draw_line(aim_center+a*9,aim_center+a*15,WHITE,2)
			draw_rect(Rect2(aim_center-Vector2(3,3),Vector2(6,6)),INK)
			draw_rect(Rect2(aim_center-Vector2(2,2),Vector2(4,4)),GOLD)
		else:
			draw_circle(aim_center,2,INK)
			draw_circle(aim_center,1,WHITE)
			for a in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(aim_center+a*gap,aim_center+a*(gap+4),WHITE,1)
	if game.respawn_time>0:
		draw_respawn(c)
	else:draw_magazine()
	draw_grenade_stock()
	if state=="RUNNING" and game.respawn_time<=0 and go_time>0:
		var opacity = smoothstep(0,.65,go_time)
		label(tr("GO"),c+Vector2(0,22),70,Color(WHITE,opacity),true)
	if state=="RUNNING" and destroy_time>0:draw_destroy_notice(c)
	if state=="RUNNING":draw_badge_toast()
	draw_rear_aim_warning()
	draw_damage_impact()
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
				label(tr("HOLD" if game.touch_mode else "HOLD E"),center+Vector2(0,64),18,WHITE,true)
				break

func damage_edge_direction() -> Vector2:
	if damage<=0 or damage_source==null or game.finale_active:return Vector2.ZERO
	return source_edge_direction(damage_source)

func source_edge_direction(source: Vector3) -> Vector2:
	var camera = game.player.camera
	if camera.is_position_in_frustum(source):return Vector2.ZERO
	var local: Vector3 = camera.to_local(source)
	if local.z>=0:return Vector2(local.x,maxf(.05,local.z)).normalized()
	return Vector2(local.x,-local.y).normalized()

func edge_position(direction: Vector2) -> Vector2:
	var half = size*.5
	var distance = minf(half.x/maxf(.001,absf(direction.x)),half.y/maxf(.001,absf(direction.y)))
	return half+direction*distance

func draw_rear_aim_warning() -> void:
	if game.state!="RUNNING" or not game.rules.active or game.respawn_time>0:return
	var enemy = game.rear_aiming_enemy()
	if not is_instance_valid(enemy) or not enemy.rear_warned:return
	var direction = source_edge_direction(enemy.ranged_origin())
	if direction==Vector2.ZERO:return
	var center = edge_position(direction)
	if game.touch_mode and center.y>=size.y-1:
		var ammo_top = magazine_rect(false).position.y if game.rules.mission else grenade_stock_rect(0).position.y
		center.y = ammo_top-8
	var elapsed: float = enemy.aim_duration-enemy.windup
	var opacity = lerpf(.96,.54,smoothstep(.07,.23,elapsed))
	var extent = minf(1,size.y/810.0)*.92
	draw_set_transform(center,(-direction).angle(),Vector2.ONE*extent)
	draw_texture_rect(AIM_WARNING,Rect2(-5,-60,90,120),false,Color(Color.WHITE,opacity))
	draw_set_transform(Vector2.ZERO)

func draw_damage_impact() -> void:
	var direction = damage_edge_direction()
	if direction==Vector2.ZERO:return
	var center = edge_position(direction)
	var extent = minf(1,size.y/810.0)
	var pulse = 1.0 if game.reduced_motion else lerpf(1,1.1,smoothstep(.56,.8,damage))
	draw_set_transform(center,(-direction).angle(),Vector2.ONE*extent*pulse)
	draw_texture_rect(DAMAGE_IMPACT,Rect2(-5,-67,101,134),false,Color(1,1,1,smoothstep(0,.23,damage)))
	draw_set_transform(Vector2.ZERO)

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
		label(tr("KILLS"),Vector2(122,61),14,WHITE,true)
	draw_set_transform(Vector2.ZERO)

func draw_finale_edges() -> void:
	if not game.finale_active:return
	var age = game.finale_elapsed
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
	label(tr("MID"),rect.position+Vector2(60.0/119,65.0/96)*rect.size,roundi(rect.size.x*5.0/119))
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
