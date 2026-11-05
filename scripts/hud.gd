extends Control

var game: Node
var font: Font
var hit = 0.0
var kill_pop = 0.0
var damage = 0.0
var shot = 0.0
const WHITE = Color("fff8e8")
const INK = Color("243440")
const GOLD = Color("f2d084")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	hit = maxf(0,hit-delta)
	kill_pop = maxf(0,kill_pop-delta)
	damage = maxf(0,damage-delta)
	shot = maxf(0,shot-delta)
	queue_redraw()

func label(text: String, pos: Vector2, font_size: int, color: Color = WHITE, center: bool = false) -> void:
	if center:pos.x -= font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5
	draw_string(font,pos+Vector2(0,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.08,.12,.15,.32))
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func start_rect() -> Rect2:
	return Rect2(Vector2(74,size.y-158),Vector2(310,62))

func _draw() -> void:
	if game == null:return
	var c = size*.5
	var state = game.state
	if state == "TITLE":
		draw_rect(Rect2(0,0,size.x*.43,size.y),Color(.055,.08,.10,.86))
		label("THE SIXTY YARD",Vector2(76,100),18,GOLD)
		label("NO",Vector2(68,227),102)
		label("ART",Vector2(68,330),102)
		label("FPS",Vector2(68,433),102)
		draw_line(Vector2(76,469),Vector2(355,469),GOLD,2)
		label("60 seconds. Every shot counts.",Vector2(76,512),22)
		label("Move. Aim. Beat your best.",Vector2(76,545),18,Color("b8c4c6"))
		draw_rect(start_rect(),GOLD)
		label("PLAY  /  ENTER",start_rect().position+Vector2(155,40),21,INK,true)
		label("WASD move   /   MOUSE aim + fire",Vector2(76,size.y-62),16)
		label("SPACE jump   /   R reload   /   ESC pause",Vector2(76,size.y-36),16)
		label("01  /  LOCAL PLAYBOX",Vector2(size.x-240,size.y-36),14)
		return
	if state == "RESULTS":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.80))
		label("TIME'S UP",Vector2(c.x,c.y-160),20,GOLD,true)
		label(str(game.rules.kills),Vector2(c.x,c.y-15),120,WHITE,true)
		label("KILLS",Vector2(c.x,c.y+28),24,WHITE,true)
		var ratio = roundi(100.0*game.rules.headshots/maxi(1,game.rules.kills))
		label("BEST %02d     /     HEADSHOTS %d%%"%[game.best,ratio],Vector2(c.x,c.y+88),20,GOLD,true)
		label("ENTER  /  RUN IT BACK",Vector2(c.x,c.y+170),23,WHITE,true)
		label("ESC  /  BACK TO YARD",Vector2(c.x,c.y+215),16,Color("b8c4c6"),true)
		return
	if state == "PAUSED":
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.09,.12,.76))
		label("TAKE A BREATH",Vector2(c.x,c.y-100),40,WHITE,true)
		label("ESC resume   /   ENTER restart",Vector2(c.x,c.y-30),22,GOLD,true)
		label("Mouse sensitivity  %.1f   [ - / + ]"%(game.player.sensitivity/.0022),Vector2(c.x,c.y+30),20,WHITE,true)
		label("Camera motion  %s   [ M ]"%("LOW" if game.reduced_motion else "ON"),Vector2(c.x,c.y+75),20,WHITE,true)
		label("WASD move   /   SPACE jump   /   R reload",Vector2(c.x,c.y+140),18,WHITE,true)
		return
	var seconds = ceili(game.rules.remaining())
	var time_text = "%02d:%02d"%[seconds/60,seconds%60]
	label(time_text,Vector2(c.x-40,64),32,GOLD if seconds<=10 else WHITE,true)
	draw_line(Vector2(c.x+23,37),Vector2(c.x+23,65),Color(1,1,1,.4),1)
	label("%02d"%game.rules.kills,Vector2(c.x+64,64),32+int(kill_pop*12),WHITE,true)
	label("KILLS",Vector2(c.x+118,61),12,WHITE,true)
	if state == "READY":
		label(str(ceili(game.ready_time)),Vector2(c.x,c.y),70,GOLD,true)
		label("60 SECONDS. MAKE THEM COUNT.",Vector2(c.x,c.y+44),18,WHITE,true)
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
