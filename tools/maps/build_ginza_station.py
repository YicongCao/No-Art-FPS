"""Build Tokyo Metro Ginza Station: island platform, two cross-track bridges and side passages."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P={
 "terrazzo":"cfcdd2","terrazzo_dark":"aeadb5","tactile":"f2c21b","tile":"efe3cc","tile_dark":"d8c7a8",
 "orange":"f39700","orange_dark":"c7780a","red":"e60012","silver":"9caeb7","grey":"7f8794","grey_dark":"5b6270",
 "concrete":"6c7280","ceiling":"5d6577","beam":"4a5160","navy":"1d2433","ink":"14171f","black":"1b1d22",
 "white":"f3f4f2","door":"dfe3e6","glass":("9fd4de",.3,0),"rail":"2e3440","ballast":"4b4a4e","sleeper":"6d5b4a",
 "steel":"a8b0ba","lemon":"f6d230","train_orange":"f08a1c","window":"283a4c","seat":"ef7d1a","vend_red":"d8262f",
 "vend_white":"eef0f2","bin_green":"2f9a52","bin_blue":"2b6fd6","bin_red":"d63a3a","locker":"b7c3cc","wood":"b98a5a",
 "gate_blue":"2b6fd6","lamp":("fff8e8",.5,.95),"green_lamp":("37d36a",.4,.9),"red_lamp":("ff2b2b",.4,1.0),
 "amber":("ffb21e",.4,.8),"express":"c9d1d8","express_window":("fff2c8",.4,1.0),"tunnel":"0e1118",
}
a=ArenaKit("ginza_station",P,{"sky":"10131a","ambient":"f1f4ff","energy":.8,"sun":"fff6e6",
                              "sun_energy":.18,"sun_rotation":[-62,-24,0]})
ground=a.kit("station_shell",True)
platform=a.kit("island_platform",True)
bridges=a.kit("bridges",True)
passages=a.kit("side_passages",True)
ceiling=a.kit("ceiling",True)
train=a.kit("ginza_train",True)
tubes=a.kit("fluorescent_tubes")
alarms=a.kit("alarm_lamps")
express=a.kit("express_train")

TRACK=-1.1
PW=5.0
TX=9.6
BY=3.6
CEIL=7.2
NB=(-19.5,-14.0)
MB=(-2.0,3.0)
H=22.0

# Floors: track beds sit 1.1 m below the platform and passages.
a.solid(ground,"Track bed base",(0,TRACK-.4,0),(2*H+1,.8,2*H+1),"ballast")
a.solid(platform,"Island platform",(0,(TRACK)/2,0),(2*PW,-TRACK,2*H),"terrazzo")
for side in (-1,1):
    a.solid(passages,"Passage floor",(side*(10+H)/2,TRACK/2,0),(H-10,-TRACK,2*H),"terrazzo")
    a.layout["boxes"].append([(side*(TX+.2),(TRACK+3.2)/2,0),(.4,3.2-TRACK,2*H),0])
    ground.box("Partition spine",(side*(TX+.2),(TRACK+3.2)/2,0),(.34,3.16-TRACK,2*H-.04),"tile_dark")
    for p_i in range(20):
        pz = -H + (p_i + .5) * (2*H / 20)
        ground.box("Track partition wall",(side*(TX+.2),(TRACK+3.12)/2,pz),(.40,2.92-TRACK,2*H/20-.03),"tile")
    ground.box("Partition orange band",(side*(TX+.2),2.35,0),(.415,.34,2*H),"orange" if side>0 else "red")
    ground.plinth("Partition skirting",(side*(TX+.2),.14,0),.46,.28,2*H,"grey_dark",flare=.025)
    ground.coping("Partition top cap",(side*(TX+.2),3.22,0),.48,.16,2*H,"grey",seg_len=2.2)
    a.solid(ground,"Outer wall",(side*(H+.3),CEIL/2,0),(.6,CEIL+2.2,2*H+1.2),"tile")
    ground.box("Outer wall line band",(side*(H-.02),2.35,0),(.08,.34,2*H),"orange" if side>0 else "red")
    ground.box("Outer wall skirting",(side*(H-.02),.14,0),(.10,.28,2*H),"grey_dark")
    a.solid(ground,"End wall",(0,CEIL/2,side*(H+.3)),(2*H+1.2,CEIL+2.2,.6),"tile")
    for x in (-7.3,7.3):
        ground.box("Tunnel mouth",(x,1.0,side*(H-.04)),(4.2,4.2,.08),"tunnel")
        ground.coping("Tunnel lintel",(x,3.24,side*(H-.10)),4.76,.34,.22,"concrete",seg_len=1.6)
        for dx in (-2.2,2.2):
            ground.box("Tunnel jamb",(x+dx,1.0,side*(H-.10)),(.34,4.2,.20),"concrete",taper=(.04,.04))
        ground.box("Signal mast",(x+1.6,1.4,side*(H-.6)),(.12,1.8,.12),"grey_dark")
        ground.box("Signal head",(x+1.6,2.5,side*(H-.6)),(.36,.8,.24),"black")
        ground.rod("Signal red lens",(x+1.6,2.7,side*(H-.6)),(x+1.6,2.7,side*(H-.74)),.11,"red_lamp",10)
        ground.rod("Signal green lens",(x+1.6,2.3,side*(H-.6)),(x+1.6,2.3,side*(H-.74)),.11,"grey_dark",10)
for x in (-7.3,7.3):
    for gauge in (-.72,.72):
        ground.box("Running rail",(x+gauge,TRACK+.18,0),(.09,.16,2*H),"steel")
    for i in range(36):
        ground.box("Concrete sleeper",(x,TRACK+.05,-H+.6+i*1.24),(2.3,.1,.32),"sleeper")
    ground.box("Third rail",(x+(1.25 if x>0 else -1.25),TRACK+.22,0),(.14,.12,2*H),"grey")

# Platform edge: tactile strips, half-height screen doors and car-position numbers.
for side in (-1,1):
    x=side*(PW-.75)
    platform.box("Tactile warning strip",(x,.012,0),(.32,.024,2*H-.6),"tactile")
    for i in range(88):
        platform.rod("Tactile dot",(x-.08+.16*(i%2),.024,-H+.6+i*.5),(x-.08+.16*(i%2),.04,-H+.6+i*.5),.035,"tactile",5)
    platform.box("Platform edge coping",(side*(PW-.08),.01,0),(.16,.02,2*H),"white")
    a.layout["boxes"].append([(side*(PW-.2),1.2,0),(.22,2.4,2*H),0])
    for car in range(6):
        z0=-18+car*6.6
        for d in (0,1,2):
            z=z0+d*2.2
            platform.plinth("Screen door shoe",(side*(PW-.2),.06,z-.85),.28,.12,.56,"grey_dark",flare=.02)
            platform.box("Screen door casing",(side*(PW-.2),.68,z-.85),(.25,1.26,.52),"door",taper=(.02,.02))
            platform.box("Screen door leaf",(side*(PW-.21),.62,z),(.13,1.2,1.2),"white")
            platform.box("Screen door window",(side*(PW-.28),.82,z),(.05,.5,.8),"glass")
            platform.box("Door lamp",(side*(PW-.33),1.36,z-.85),(.07,.09,.22),"green_lamp")
            alarms.box("Door lamp alarm",(side*(PW-.34),1.36,z-.85),(.08,.11,.24),"red_lamp")
        platform.box("Car position plate",(side*(PW-.34),1.05,z0-.85),(.05,.36,.32),"navy")
    platform.coping("Screen door top rail",(side*(PW-.2),1.35,0),.32,.09,2*H,"grey",seg_len=2.2)

# Columns: a centre row on the platform and one row per side passage.
def column(kit,x,z,band="orange"):
    under=any(z0-.5<z<z1+.5 for z0,z1 in (NB,MB))
    height=BY-.36 if under else CEIL
    a.layout["boxes"].append([(x,height/2,z),(.8,height,.8),0])
    kit.plinth("Column skirting",(x,.16,z),.88,.32,.88,"grey_dark",flare=.035)
    kit.box("Tiled column",(x,height/2+.04,z),(.79,height-.24,.79),"tile",taper=(.02,.02))
    kit.box("Column capital",(x,height-.12,z),(.90,.24,.90),"grey",taper=(-.05,-.05))
    kit.box("Column line band",(x,2.35,z),(.83,.40,.83),band)
    for k,(dx,dz,ang) in enumerate(((0,.43,0),(0,-.43,math.pi),(.43,0,math.pi/2),(-.43,0,-math.pi/2))):
        a.sign(f"Roundel{len(a.layout['signs'])}","ginza-roundel" if band=="orange" else "ginza-roundel-m",
               (x+dx,2.35,z+dz),(.32,.32),ang)
for z in (-20.6,-16.8,.5):
    column(platform,0,z)
for side in (-1,1):
    for z in (-17.0,.5,17.0):
        column(passages,side*13.4,z,"orange" if side>0 else "red")

# Bridges across the whole box. Stairs land on their south edges.
def bridge(z0,z1,label):
    zc=(z0+z1)/2
    a.solid(bridges,label,(0,BY-.18,zc),(2*H,.36,z1-z0),"terrazzo")
    for z_f in (z0, z1):
        bridges.box("Bridge fascia",(0,BY-.28,z_f),(2*H,.56,.12),"grey")
        bridges.coping("Bridge fascia lip",(0,BY-.56,z_f),2*H,.10,.18,"beam",seg_len=2.2)
    bridges.box("Bridge underside",(0,BY-.37,zc),(2*H,.04,z1-z0),"grey_dark")
    for x in (-H+1,-PW-2.3,PW+2.3,H-1):
        bridges.box("Bridge tactile guide",(x,BY+.012,zc),(.3,.024,z1-z0-.4),"tactile")
    bridges.box("Bridge tactile guide",(0,BY+.012,zc),(2*H-1,.024,.3),"tactile")
def balustrade(x0,x1,z,y=BY):
    if x1-x0<.2:
        return
    bridges.box("Glass balustrade",((x0+x1)/2,y+.55,z),(x1-x0,.9,.055),"glass")
    bridges.box("Balustrade handrail",((x0+x1)/2,y+1.06,z),(x1-x0,.10,.15),"grey_dark")
    bridges.box("Balustrade shoe",((x0+x1)/2,y+.07,z),(x1-x0,.14,.18),"grey")
    a.layout["boxes"].append([((x0+x1)/2,y+.55,z),(x1-x0,1.1,.14),0])
STAIRS={"platform_n":(-1.7,1.7,NB[1],-4.4),"platform_m":(-2.2,2.2,MB[1],12.6)}
for side,name in ((-1,"west"),(1,"east")):
    x0,x1=sorted((side*17.6,side*21.6))
    STAIRS[f"{name}_n"]=(x0,x1,NB[1],-4.4)
    STAIRS[f"{name}_m"]=(x0,x1,MB[1],12.6)
for (z0,z1),label in ((NB,"North bridge"),(MB,"Middle bridge")):
    bridge(z0,z1,label)
    balustrade(-H,H,z0)
    gaps=sorted((s[0],s[1]) for s in STAIRS.values() if s[2]==z1)
    edge=-H
    for g0,g1 in gaps:
        balustrade(edge,g0,z1)
        edge=g1
    balustrade(edge,H,z1)
    for x in (-11.8,11.8):
        zc=(z0+z1)/2
        bridges.plinth("Bridge pier foot",(x,.15,zc),.64,.30,.64,"grey_dark",flare=.04)
        bridges.box("Bridge support pier",(x,(BY-.36)/2,zc),(.52,BY-.52,.52),"grey",taper=(.05,.05))
        bridges.box("Bridge pier capital",(x,BY-.48,zc),(.66,.22,.66),"beam",taper=(-.06,-.06))
        a.layout["boxes"].append([(x,(BY-.36)/2,zc),(.5,BY-.36,.5),0])

def stair(x0,x1,z_top,z_foot,escalators=0):
    """Solid stair: treads drawn as stacked boxes, collision as one sloped prism."""
    a.layout["slabs"].append([[(x0,BY,z_top),(x1,BY,z_top),(x1,0,z_foot),(x0,0,z_foot)],BY+.6])
    n=22
    width=x1-x0
    stair_x1=x1-escalators*1.15
    for i in range(n):
        za=z_foot+(z_top-z_foot)*i/n
        zb=z_foot+(z_top-z_foot)*(i+1)/n
        y=BY*(i+1)/n
        bridges.box("Stair tread",((x0+stair_x1)/2,y/2,(za+zb)/2),(stair_x1-x0,y,abs(zb-za)+.01),"terrazzo" if i%2 else "terrazzo_dark")
        bridges.box("Yellow stair nosing",((x0+stair_x1)/2,y+.005,za+(zb-za)*.85),(stair_x1-x0,.02,.08),"tactile")
        for e in range(escalators):
            ex=stair_x1+.15+e*1.15+.45
            bridges.box("Escalator truss",(ex,y/2,(za+zb)/2),(.9,y,abs(zb-za)+.01),"grey")
            bridges.box("Escalator tread",(ex,y+.004,(za+zb)/2),(.86,.02,abs(zb-za)*.8),"rail")
            bridges.box("Escalator step edge",(ex,y+.005,za+(zb-za)*.85),(.9,.02,.05),"tactile")
    length=math.hypot(z_top-z_foot,BY)
    for x in [x0,x1]+[stair_x1+.075+e*1.15 for e in range(escalators)]:
        bridges.beam("Stair balustrade glass",(x,.55,z_foot),(x,BY+.55,z_top),.05,.9,"glass")
        bridges.beam("Stair handrail",(x,1.06,z_foot),(x,BY+1.06,z_top),.1,.08,"black" if escalators else "grey_dark")
        bridges.beam("Stair stringer",(x,.0,z_foot),(x,BY-.1,z_top),.14,.18,"grey")
    for x in (x0,x1):
        dx=.05
        a.layout["slabs"].append([[(x-dx,1.1,z_foot),(x+dx,1.1,z_foot),(x+dx,BY+1.1,z_top),(x-dx,BY+1.1,z_top)],1.14])
    return length
for key,(x0,x1,z_top,z_foot) in STAIRS.items():
    stair(x0,x1,z_top,z_foot,2 if key=="platform_m" else 0)

# Ceiling, beams and fluorescent tubes. The lit tubes go dark during frenzy.
a.solid(ceiling,"Station ceiling slab",(0,CEIL+.2,0),(2*H+1,.4,2*H+1),"ceiling")
for z in range(-20,22,4):
    ceiling.box("Ceiling beam",(0,CEIL-.25,z),(2*H,.5,.4),"beam")
for x in (-16,-12.5,-2.5,2.5,12.5,16):
    for z in range(-20,21,3):
        ceiling.box("Tube fixture",(x,CEIL-.08,z+.5),(.3,.12,2.2),"grey")
        tubes.box("Fluorescent tube",(x,CEIL-.16,z+.5),(.18,.06,2.0),"lamp")
a.moving("fluorescent_tubes",(0,0,0))

# Stopped Ginza Line train on track 1.
TZ=(-18.6,18.6)
def car(kit,x,z0,z1,y0,body,stripe,window,lit=False):
    zc=(z0+z1)/2
    kit.box("Car body",(x,y0+1.6,zc),(2.62,2.9,z1-z0-.28),body,taper=(.04,0.0))
    kit.box("Car roof",(x,y0+3.12,zc),(2.42,.18,z1-z0-.38),"grey",taper=(.06,0.0))
    for ac_z in (zc-2.8, zc+2.8):
        kit.box("Car AC pod",(x,y0+3.28,ac_z),(1.55,.20,2.10),"silver",taper=(.08,.06))
    kit.box("Car stripe",(x,y0+1.0,zc),(2.65,.24,z1-z0-.28),stripe)
    kit.box("Car underframe",(x,y0+.1,zc),(2.24,.32,z1-z0-.48),"black")
    for side in (-1,1):
        kit.box("Window band",(x+side*1.31,y0+2.0,zc),(.06,.82,z1-z0-1.0),window)
        for d in range(3):
            dz=z0+1.4+d*(z1-z0-2.8)/2
            kit.box("Car door",(x+side*1.32,y0+1.5,dz),(.06,2.22,1.32),"grey" if not lit else body)
            kit.box("Door window",(x+side*1.35,y0+1.95,dz),(.04,.8,1.0),window)
for c in range(3):
    z0=TZ[0]+c*(TZ[1]-TZ[0])/3
    car(train,-7.3,z0,z0+(TZ[1]-TZ[0])/3,TRACK+.3,"lemon","train_orange","window")
for end,sign in ((TZ[0],-1),(TZ[1],1)):
    train.box("Train flat front",(-7.3,TRACK+1.9,end+sign*.02),(2.5,2.5,.1),"lemon")
    train.box("Front windscreen",(-7.3,TRACK+2.35,end+sign*.08),(2.1,.8,.04),"window")
    for dx in (-.8,.8):
        train.box("Headlight",(-7.3+dx,TRACK+1.35,end+sign*.08),(.3,.16,.04),"lamp")
a.layout["boxes"].append([(-7.3,TRACK+1.75,0),(2.6,3.2,TZ[1]-TZ[0]),0])

# Out-of-service express that rushes through track 2 during frenzy.
for c in range(4):
    car(express,7.3,-c*13,-c*13+13,TRACK+.3,"express","orange","express_window",True)
express.box("Express nose",(7.3,TRACK+1.9,13.05),(2.5,2.6,.1),"express")
express.box("Express headlights",(7.3,TRACK+1.4,13.1),(1.9,.18,.05),"lamp")
a.moving("express_train",(0,0,-80))

# Red rotating beacons only light up during frenzy.
for x in (-2.5,2.5,-15,15):
    for z in (-10,8):
        alarms.rod("Alarm beacon",(x,CEIL-.5,z),(x,CEIL-.2,z),.16,"red_lamp",8)
a.moving("alarm_lamps",(0,0,0))

# East passage: automatic ticket gates, ticket machines, station office, exit A2.
for i in range(4):
    x=10.2+i*1.9
    a.layout["boxes"].append([(x,.52,-8),(.32,1.04,1.7),0])
    passages.plinth("Gate foot",(x,.06,-8),.36,.12,1.74,"grey_dark",flare=.02)
    passages.box("Automatic ticket gate",(x,.54,-8),(.32,.96,1.68),"grey",taper=(.04,.02))
    passages.box("Gate top",(x,1.06,-8),(.36,.08,1.74),"white")
    for dz in (-.86,.86):
        passages.box("IC card reader",(x,1.1,-8+dz*.8),(.3,.05,.3),"gate_blue")
        passages.box("Gate arrow lamp",(x,.8,-8+dz),(.2,.2,.04),"green_lamp" if dz<0 else "red_lamp")
    passages.box("Open gate flap",(x+.24,.85,-8),(.16,.3,.07),"orange")
a.solid(passages,"Gate end cabinet",(17.3,.52,-8),(.6,1.04,1.7),"grey")
a.solid(passages,"Station office",(19.8,1.6,-19.8),(4.4,3.2,4.4),"tile")
passages.plinth("Office plinth",(17.64,.14,-19.8),.20,.28,4.46,"grey_dark",flare=.025)
passages.box("Office window",(17.58,1.5,-19.6),(.08,1.1,2.6),"glass")
passages.box("Office counter",(17.38,1.0,-19.6),(.46,.12,2.72),"grey")
passages.coping("Office orange fascia",(17.54,2.9,-19.8),.14,.42,4.46,"orange",seg_len=1.5)
a.sign("OfficeSign","ginza-office",(17.5,2.42,-19.8),(2.0,.5),-math.pi/2)
for i in range(4):
    z=-20.8+i*1.1
    a.solid(passages,"Ticket machine",(10.5,.8,z),(.7,1.6,.95),"white")
    passages.box("Ticket screen",(10.87,1.15,z),(.04,.5,.6),"gate_blue")
    passages.box("Ticket slot",(10.87,.75,z),(.04,.08,.4),"black")
a.sign("FareMap","ginza-fare-map",(10.03,2.3,-19.15),(4.4,1.1),math.pi/2)
# Exit A2 rises south out of the box behind a security grille.
for i in range(14):
    y=(i+1)*.28
    passages.box("Exit stair step",(14,y/2,H+.6+i*.32),(4,y,.33),"terrazzo" if i%2 else "terrazzo_dark")
passages.box("Exit grille",(14,1.5,H+.62),(4.2,3.0,.04),"grey_dark")
for i in range(14):
    passages.box("Grille bar",(12.1+i*.29,1.5,H+.58),(.04,3.0,.04),"steel")
a.sign("ExitA2","ginza-exit",(14,3.7,H-.05),(2.6,.65),math.pi)
a.sign("ExitA2North","ginza-exit",(14,3.7,H-.07),(2.6,.65),0)
a.sign("Hibiya","ginza-hibiya",(17.0,2.7,-8.9),(2.4,.6),0)

# West passage: Marunouchi transfer with lockers, vending machines and a gate line.
for i in range(4):
    x=-10.2-i*1.9
    a.solid(passages,"Transfer gate",(x,.52,8),(.32,1.04,1.7),"grey")
    passages.box("Transfer gate top",(x,1.06,8),(.36,.06,1.74),"white")
    passages.box("Transfer gate reader",(x,1.1,8.7),(.3,.04,.3),"red")
a.solid(passages,"Transfer gate end",(-17.3,.52,8),(.6,1.04,1.7),"grey")
passages.box("Marunouchi passage opening",(-15,1.6,-H+.04),(5.4,3.2,.06),"tunnel")
passages.box("Marunouchi passage frame",(-15,3.3,-H+.08),(5.8,.3,.1),"red")
for dx in (-2.8,2.8):
    passages.box("Marunouchi passage jamb",(-15+dx,1.6,-H+.08),(.3,3.2,.1),"red")
a.sign("Marunouchi","ginza-marunouchi",(-15,4.0,-H+.12),(2.8,.7),0)
a.sign("MarunouchiHang","ginza-marunouchi",(-13.8,2.75,8.9),(2.4,.6),math.pi)

# Hanging signs: station name on the partitions, departures and exits from the ceiling.
for side in (-1,1):
    for i,z in enumerate((-10,7,17.5)):
        a.sign(f"StationName{side+1}{i}","ginza-station-name",(side*(TX-.02),2.3,z),(4.0,1.0),-side*math.pi/2)
def hang(label,asset,at,size,angle,double=True,top=CEIL):
    x,y,z=at
    for dx in (-size[0]*.4,size[0]*.4):
        ceiling.rod("Sign hanger",(x+dx*math.cos(angle),y+size[1]/2,z-dx*math.sin(angle)),
                    (x+dx*math.cos(angle),top,z-dx*math.sin(angle)),.025,"grey_dark",4)
    ceiling.box("Sign housing",(x,y,z),(size[0]+.1 if angle in (0,math.pi) else .16,size[1]+.1,.16 if angle in (0,math.pi) else size[0]+.1),"black")
    a.sign(label,asset,(x+.09*math.sin(angle),y,z+.09*math.cos(angle)),size,angle)
    if double:
        a.sign(label+"Back",asset,(x-.09*math.sin(angle),y,z-.09*math.cos(angle)),size,angle+math.pi)
hang("Departures0","ginza-departures",(0,2.75,15.6),(3.2,.8),0)
hang("Passing0","ginza-passing",(0,2.75,15.601),(3.2,.8),0)
for i,x in enumerate((-3.4,3.4)):
    hang(f"Departures{i+1}","ginza-departures",(x,2.7,MB[0]-.12),(2.2,.55),math.pi,False,BY-.36)
    hang(f"Passing{i+1}","ginza-passing",(x,2.7,MB[0]-.121),(2.2,.55),math.pi,False,BY-.36)
for i,(x,z,ang) in enumerate([(0,14.2,0),(0,-3.3,0),(-19.6,-3.6,0),(19.6,-3.6,0),(-19.6,13.6,0),(19.6,13.6,0)]):
    hang(f"Exit{i}","ginza-exit",(x,2.7,z),(1.8,.45),ang)
for side,asset in ((-1,"ginza-track-1"),(1,"ginza-track-2")):
    for i,z in enumerate((-11,8)):
        hang(f"Track{side+1}{i}",asset,(side*3.4,2.75,z),(1.8,.45),0)
for side in (-1,1):
    for i,z in enumerate((-12,-1.0,9,19)):
        a.sign(f"Ad{side+1}{i}",f"ginza-ad-{i%3+1}",(side*(TX+.42),1.45,z),(2.4,1.35),side*math.pi/2)
        passages.box("Ad light box frame",(side*(TX+.43),1.45,z),(.06,1.5,2.56),"grey_dark")

# Destructible station furniture.
vend=a.kit("vending_machine")
vend.plinth("Vending plinth",(0,.07,0),1.04,.14,.78,"grey_dark",flare=.02)
vend.box("Vending cabinet",(0,.98,0),(1.0,1.78,.74),"vend_red",taper=(.02,.02))
vend.coping("Vending cap",(0,1.90,0),1.06,.10,.80,"vend_red",seg_len=1.06)
vend.box("Drink display",(0,1.32,.36),(.86,.92,.06),"white")
for r in range(3):
    for c in range(6):
        vend.box("Drink can",(-.36+c*.144,1.0+r*.3,.40),(.09,.2,.04),("red","gate_blue","bin_green","orange")[(r+c)%4])
vend.box("Coin panel",(.3,.62,.39),(.2,.3,.04),"grey_dark")
vend.box("Drink tray",(-.1,.25,.39),(.6,.18,.05),"black")
vend_w=a.kit("vending_machine_white")
vend_w.plinth("Vending plinth",(0,.07,0),1.04,.14,.78,"grey_dark",flare=.02)
vend_w.box("Vending cabinet",(0,.98,0),(1.0,1.78,.74),"vend_white",taper=(.02,.02))
vend_w.coping("Vending cap",(0,1.90,0),1.06,.10,.80,"vend_white",seg_len=1.06)
vend_w.box("Drink display",(0,1.32,.36),(.86,.92,.06),"glass")
for r in range(3):
    for c in range(6):
        vend_w.box("Bottle",(-.36+c*.144,1.0+r*.3,.40),(.09,.22,.04),("bin_green","white","orange","gate_blue")[(r+c)%4])
vend_w.box("Drink tray",(-.1,.25,.39),(.6,.18,.05),"black")
bench=a.kit("bench")
for i in range(4):
    bench.box("Orange bucket seat",(-.84+i*.56,.45,0),(.50,.11,.48),"seat",taper=(.04,.04))
    bench.box("Seat back",(-.84+i*.56,.73,-.22),(.50,.50,.09),"seat",taper=(.04,.08))
bench.box("Bench beam",(0,.36,0),(2.32,.10,.14),"grey_dark")
for x in (-.9,.9):
    bench.plinth("Bench leg foot",(x,.05,0),.16,.10,.46,"black",flare=.02)
    bench.box("Bench leg",(x,.20,0),(.12,.32,.40),"grey_dark",taper=(.06,.04))
kiosk=a.kit("kiosk")
kiosk.plinth("Kiosk plinth",(0,.09,0),2.26,.18,1.26,"grey_dark",flare=.03)
kiosk.box("Kiosk counter",(0,.58,0),(2.18,.96,1.18),"tile",taper=(.02,.02))
kiosk.coping("Kiosk counter top",(0,1.10,0),2.30,.10,1.30,"wood",seg_len=1.15)
kiosk.box("Kiosk orange fascia",(0,2.3,0),(2.42,.38,1.42),"orange",taper=(.02,.02))
kiosk.coping("Kiosk roof",(0,2.54,0),2.56,.14,1.56,"grey",seg_len=1.28)
for x in (-1.08,1.08):
    kiosk.box("Kiosk post",(x,1.7,.56),(.11,1.2,.11),"grey")
for r in range(3):
    for c in range(5):
        kiosk.box("Magazine",(-.85+c*.42,1.25+r*.3,.62),(.34,.26,.03),("red","gate_blue","tactile","bin_green","white")[(r+c)%5])
bins=a.kit("recycle_bins")
for i,color in enumerate(("bin_green","bin_blue","bin_red")):
    bins.box("Recycling bin",(-.42+i*.42,.5,0),(.4,1.0,.45),"grey")
    bins.box("Bin label panel",(-.42+i*.42,.7,.23),(.3,.3,.02),color)
    bins.box("Bin slot",(-.42+i*.42,1.0,0),(.24,.02,.12),"black")
lockers=a.kit("coin_lockers")
lockers.box("Locker frame",(0,1.0,0),(2.4,2.0,.6),"locker")
for r in range(4):
    for c in range(5):
        lockers.box("Locker door",(-.96+c*.48,.3+r*.46,.31),(.44,.42,.02),"white" if (r+c)%3 else "locker")
        lockers.box("Locker key",(-.8+c*.48,.36+r*.46,.33),(.04,.08,.02),"orange")
hoard=a.kit("hoarding")
hoard.box("Hoarding panels",(0,1.2,0),(2.5,2.4,.12),"white")
for x in (-1.2,1.2):
    hoard.box("Hoarding striped post",(x,1.2,0),(.12,2.4,.16),"bin_green")
hoard.box("Hoarding foot",(0,.08,0),(2.6,.16,.6),"grey")
for x in (-.8,.8):
    hoard.box("Barrier bar",(x*.4,.7,.3),(1.2,.16,.06),"orange")
a.sign("HoardingSign","ginza-construction",(3.5,1.25,8.08),(1.6,1.2),0)
a.sign("HoardingSignBack","ginza-construction",(3.5,1.25,7.92),(1.6,1.2),math.pi)

for asset,at,size,angle,name,effect,structural in [
    ("hoarding",(3.5,0,8.0),(2.6,2.4,.3),0,"Hoarding","station",True),
    ("vending_machine",(-3.9,0,-1.4),(1.0,1.9,.75),math.pi/2,"","station",False),
    ("vending_machine_white",(-3.9,0,-.3),(1.0,1.9,.75),math.pi/2,"","station",False),
    ("bench",(3.7,0,-9.5),(2.3,.95,.5),-math.pi/2,"","station",False),
    ("bench",(-3.7,0,17.6),(2.3,.95,.5),math.pi/2,"","station",False),
    ("bench",(3.7,0,17.6),(2.3,.95,.5),-math.pi/2,"","station",False),
    ("kiosk",(-3.6,0,-17.6),(1.2,2.6,2.2),math.pi/2,"","station",False),
    ("recycle_bins",(3.8,0,-.6),(1.3,1.0,.5),-math.pi/2,"","station",False),
    ("coin_lockers",(-21.4,0,17.0),(2.4,2.0,.6),math.pi/2,"","station",False),
    ("coin_lockers",(-21.4,0,19.6),(2.4,2.0,.6),math.pi/2,"","station",False),
    ("vending_machine",(-10.5,0,-14.0),(1.0,1.9,.75),math.pi/2,"","station",False),
    ("vending_machine_white",(-10.5,0,-12.9),(1.0,1.9,.75),math.pi/2,"","station",False),
    ("bench",(-10.4,0,15.0),(2.3,.95,.5),math.pi/2,"","station",False),
    ("recycle_bins",(10.4,0,4.6),(1.3,1.0,.5),-math.pi/2,"","station",False),
    ("vending_machine",(21.5,0,15.5),(1.0,1.9,.75),-math.pi/2,"","station",False),
    ("bench",(21.4,0,19.0),(2.3,.95,.5),-math.pi/2,"","station",False),
]:
    a.prop(asset,at,size,angle,name=name,effect=effect,structural=structural)

# Frenzy: red sweeping beacons over the platform and passages.
for x,z,tx,tz in [(-2.5,-10,-3,-4),(2.5,8,3,14),(-15,-10,-14,-4),(15,8,14,14),(2.5,-10,4,-16),(-2.5,8,-4,2)]:
    a.spot((x,CEIL-.7,z),(tx,0,tz),"ff2b2b",7.0,13,40,(3.0,0,3.0))

def g(x,z,y=0.0):
    return (x,y+.06,z)
def on_stair(key,t):
    x0,x1,z_top,z_foot=STAIRS[key]
    return ((x0+x1)/2,BY*t+.06,z_foot+(z_top-z_foot)*t)
top=BY
a.layout.update(
 start=g(0,19.6),heading=0,
 opening=[g(0,14.4),g(-3.4,9),g(3.6,15.2),g(-14,16),g(14,10),g(-3.6,-7),g(14,-14),g(-14,-17)],
 spawns=[g(x,z) for x,z in [(-3.6,-20),(3.6,-20),(-3.4,4),(3.5,-3),(-15,-20),(-12,-4),(-15,3),(-12,19),
                           (15,-20),(12,-3),(15,3),(12,19),(-3.6,12),(3.6,4.5)]]
        +[g(-7,-16.8,top),g(7,-16.8,top),g(-15,.5,top),g(15,.5,top)],
 respawns=[g(0,19.6),g(-14,19),g(14,19),g(-14,-19),g(14,-19),g(-3.6,-12),g(0,.5,top)],
 route=[g(-3.6,10),g(-3.4,0),g(-3.4,-8),g(0,-17.6),g(3.4,-12),g(0,-3.6),on_stair("platform_n",.5),g(0,-16.8,top),
        g(-14,-16.8,top),on_stair("west_n",.5),g(-19.6,-3.4),g(-13,-12),g(-13,-20),g(-13,18),g(-19.6,13.3),
        on_stair("west_m",.5),g(-19.6,.5,top),g(0,.5,top),g(19.6,.5,top),on_stair("east_m",.5),g(19.6,13.3),
        g(14,19),g(14,-4),g(13,-14),g(19.6,-3.4),on_stair("east_n",.5),g(14,-16.8,top),g(3.6,13.4),g(0,13.4),
        on_stair("platform_m",.5)],
 barrels=[g(-14.5,-12),g(14.6,6.5),g(11.2,15.4)],comedy=(-13.8,0,-7.0,0),
 cameras={
  "platform":[[-2.6,1.72,21.2],[.6,2.6,0],74],
  "exit-gates":[[15.6,1.72,2.2],[13.0,2.2,-20],74],
  "bridge":[[-14,BY+1.65,.6],[6,BY+.2,.4],74],
  "thumbnail":[[-2.4,1.9,21.0],[1.4,2.6,4],58],
  "passing-frenzy":[[3.0,1.72,1.2],[6.4,1.5,16],74],
 })
a.write()
