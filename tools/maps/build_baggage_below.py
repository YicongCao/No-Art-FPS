"""Build the arrivals hall, sorter and maintenance routes from the airport concepts."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P={
 "navy":"22314d","blue":"244d9c","cobalt":"325bbb","steel":"667687","black":"252a38",
 "metal":("a6b7c9",.31,0),"rubber":"343c4d","slat":"3e4758","concrete":"b7afb6",
 "white":"e7ebef","sand":"d9cab6","teal":"329eaa","turquoise":"4abdc5","glass":"8ccee2",
 "skyglass":("81c5e8",.52,.32),"orange":"f08b3b","amber":"e3a337","yellow":"f6c84d",
 "red":"b84153","green":"4e8a70","mint":"84bfb4","case_blue":"416cca","case_red":"b94851",
 "case_green":"40957c","light":("fff2ce",.45,.73),"signal":("fb6077",.5,.5),"cyan":("6feafc",.45,.55),
 "sea":("6ebadf",.65,.16),"hill":"587b8a","pavement":"a8a4a3",
}
a=ArenaKit("baggage_below",P,{"sky":"8cc5f2","ambient":"e6f0ff","energy":.86,"sun":"fff1cf","sun_energy":.45,"sun_rotation":[-44,30,0]})
floor=a.kit("terminal_floors",True)
hall=a.kit("terminal_shell",True)
machines=a.kit("sorter",True)
apron=a.kit("apron",True)
a.solid(floor,"Sorting floor",(0,-.26,-5),(44,.52,34),"concrete")
a.solid(floor,"Baggage reclaim floor",(0,-.26,17),(44,.52,12),"teal")
for x in range(-21,22,2):
    for z in range(12,23,2):
        floor.box("Glazed turquoise floor tile",(x,.009,z),(1.98,.017,1.98),("teal","turquoise")[(x+z//4)%2])
for x in (-14.8,-11.4,-2.2,2.2,11.7,14.4):
    for z in range(-19,11,2):
        floor.box("Service lane paint",(x,.012,z),(.08,.025,1.48),"yellow")
for x in (-4.5,4.5):
    floor.box("Arrivals guide line",(x,.019,17),(.12,.017,12),"yellow")
for i in range(11):
    floor.box("Door threshold hazard mark",(-3.65+i*.73,.019,11.01),(.19,.019,1.0),"yellow",-.46)
a.solid(hall,"Sorting hall ceiling",(0,8.22,-5),(44,.35,34),"navy")
a.solid(hall,"Arrivals ceiling",(0,5.5,17),(44,.3,12.1),"navy")
for x in (-22,22):
    a.solid(hall,"Sorting hall wall",(x,4.05,-5),(.36,8.1,34),"white")
    for z in (-18,-12,-6,0,6,10):
        hall.box("Blue structural column",(x-math.copysign(.42,x),4.05,z),(.61,8.1,.56),"blue")
        hall.box("Impact bollard",(x-math.copysign(.73,x),.52,z),(.25,1.02,.21),"yellow")
for z in (-18,-12,-6,0,6,10,15,21):
    y=7.92 if z<12 else 5.24
    hall.box("Transverse ceiling girder",(0,y,z),(44,.45,.44),"blue")
    for x in (-13,-6,2,10,17):
        hall.box("Industrial LED strip",(x,y-.32,z),(2.65,.15,.3),"light")
for x in (-15.5,-8,8,15.5):
    hall.box("Longitudinal overhead girder",(x,7.75,-4.7),(.42,.45,33.2),"blue")

# The outer windows retain the runway view while providing a solid boundary.
for x in (-22,22):
    a.layout["boxes"].append([(x,2.65,17),(.18,5.3,12),0])
    hall.box("Glazing foot rail",(x,.34,17),(.19,.68,12),"steel")
    hall.box("Glazing top rail",(x,5.15,17),(.19,.34,12),"blue")
    for z in (11.4,14.2,17.0,19.8,22.6):
        hall.box("Blue glazing mullion",(x,2.7,z),(.19,5.25,.17),"blue")
    hall.box("Window transom",(x,2.13,17),(.19,.16,12),"blue")
a.layout["boxes"].append([(0,2.65,22.9),(44,5.3,.15),0])
for x in range(-22,23,3):
    hall.box("Apron-facing mullion",(x,2.66,22.91),(.14,5.15,.21),"blue")
for y in (.28,2.2,5.05):
    hall.box("Front glazing transom",(0,y,22.91),(44,.18,.23),"blue")
a.layout["glass"]=[[(x,2.7,17),(11.7,4.7),math.pi/2] for x in (-22,22)]
a.layout["glass"].append([(0,2.7,22.9),(43.8,4.7),0])
for x in (-13.05,13.05):
    a.solid(hall,"Secure area divider",(x,2.68,11),(17.9,5.36,.46),"white")
    hall.box("Turquoise public-side window",(x,2.9,11.25),(15.7,2.26,.10),"skyglass")
    for dx in (-6,-3,0,3,6):
        hall.box("Window mullion",(x+dx,2.9,11.33),(.095,2.29,.08),"blue")
    hall.box("Sorting-side impact rail",(x,1.1,10.72),(16.7,.12,.15),"yellow")
a.solid(hall,"Orange employee doorway header",(0,4.52,11),(8.35,1.68,.49),"blue")
for x in (-4.13,4.13):
    hall.box("Orange doorway trim",(x,1.91,11.04),(.24,3.85,.53),"orange")
    a.solid(hall,"Propped service door",(x*.94,1.48,11.86),(.19,2.95,1.78),"orange",.20*math.copysign(1,x))
    hall.box("Door window",(x*.94,1.96,12.35),(.21,.64,.62),"glass")
hall.box("Orange doorway top trim",(0,3.70,11.28),(8.35,.14,.15),"orange")
a.sign("ArrivalsBoard","arrivals",(0,4.38,11.27),(4.8,.67))
for x in (-16.8,16.8):
    a.solid(hall,"Rear service wall",(x,4.1,-21.8),(10.4,8.2,.36),"white")
for x in (-9.05,9.05):
    a.solid(hall,"Roller dock pillar",(x,4.1,-21.8),(5.45,8.2,.36),"steel")
a.solid(hall,"Dock shutter header",(0,6.77,-21.8),(13,2.86,.38),"metal")
for i in range(10):
    hall.box("Roller door slat",(0,5.36+i*.26,-21.55),(12.86,.075,.16),"steel")
a.layout["boxes"].append([(0,2.63,-21.85),(13,5.2,.18),0])
for x in (-6.47,6.47):
    for i in range(7):
        hall.box("Dock hazard stripe",(x,.42+i*.68,-21.54),(.27,.43,.08),"yellow",.24)
for x in (-19,19):
    for z in (-18,-8,2):
        hall.box("Steel service door",(x,1.31,z),(1.42,2.62,.27),"teal")
        hall.box("Panic bar",(x,1.10,z+.15),(1.01,.10,.075),"metal")

# Walkable maintenance deck and two genuine access ramps beneath visual stairs.
a.solid(machines,"Rear maintenance bridge",(0,2.95,-15),(35,.34,3.6),"steel")
a.solid(machines,"West inspection deck",(-16,2.95,-10.5),(3.0,.34,9.0),"steel")
a.solid(machines,"East inspection deck",(16,2.95,-10.5),(3.0,.34,9.0),"steel")
for x in (-16,16):
    a.slope(machines,"Maintenance stair ramp",x-1.50,x+1.50,-6,3,3.12,0,.28,"steel")
    for i in range(18):
        z=-6+(i+.5)*.5
        y=3.12*(3-z)/9
        machines.box("Stair tread nosing",(x,y+.008,z+.22),(2.90,.045,.055),"metal")
    for offset in (-1.50,1.50):
        xr=x+offset
        for z in (-6,-3,0,3):
            yy=3.12*(3-z)/9
            machines.box("Stair rail post",(xr,yy+.54,z),(.10,1.09,.09),"yellow")
        for dy in (.55,1.05):
            machines.beam("Stair safety rail",(xr,3.12+dy,-6),(xr,dy,3),.08,.08,"yellow")
        a.layout["slabs"].append([[(xr-.06,4.17,-6),(xr+.06,4.17,-6),(xr+.06,1.05,3),(xr-.06,1.05,3)],1.02])
    for z in (-15.8,-10.4):
        machines.box("Catwalk blue support",(x,1.55,z),(.27,3.10,.27),"blue")
for x,w,z,d in [(0,35,-16.77,.14),(0,28.7,-13.23,.14),(-17.49,.14,-9.72,7.25),
                (-14.51,.14,-9.72,7.25),(17.49,.14,-9.72,7.25),(14.51,.14,-9.72,7.25)]:
    a.layout["boxes"].append([(x,3.66,z),(w,1.08,d),0])
    for dy in (.10,.61,1.05):
        machines.box("Yellow catwalk rail",(x,3.12+dy,z),(w,.075,d),"yellow")
    n=round(max(w,d)/.80)
    for i in range(n):
        dx=(i+.5-n*.5)*w/n if w>d else 0
        dz=(i+.5-n*.5)*d/n if d>w else 0
        machines.box("Catwalk picket",(x+dx,3.64,z+dz),(.064,1.03,.064),"yellow")

for i,x in enumerate((-4.6,4.6)):
    color="turquoise" if i==0 else "amber"
    for edge in (-1,1):
        machines.box("Opposing belt casing",(x+edge*1.70,.44,-1.3),(.25,.81,17.5),color)
        machines.box("Dark belt frame",(x+edge*1.70,.19,-1.3),(.31,.30,17.5),"blue")
    for z in (-9,-6,-3,0,3,6):
        for dx in (-1.25,1.25):
            machines.box("Belt pedestal",(x+dx,.35,z),(.17,.71,.22),"steel")
    a.layout["belts"].append([[x,.73,-1.3],[3.19,.18,17.5],-1 if i==0 else 1])
    a.slope(machines,"Belt step-on ramp",x-1.59,x+1.59,7.45,9.7,.82,0,.19,"rubber")
    a.slope(machines,"Rear belt run-off",x-1.59,x+1.59,-12.3,-10.05,0,.82,.19,"rubber")
for z in (-9,-5,-1,3,7):
    for x,c in [(-6.37,"4eeafa"),(6.37,"ffbd55")]:
        a.spot((x,1.11,z),(x+(-1.5 if x<0 else 1.5),0,z+.1),c,4.0,4.0,54,(0,0,.7))

# An elevated feeder carries bags while the stairs provide the playable ascent.
machines.box("Inclined sorter top frame",(10.8,2.85,-15),(3.1,.34,2.1),"blue")
machines.slab("Inclined baggage feeder",[(9.28,.85,-4.3),(12.32,.85,-4.3),(12.32,3.10,-14.8),(9.28,3.10,-14.8)],.29,"rubber")
for x in (9.16,12.44):
    machines.beam("Feeder side channel",(x,.92,-4.3),(x,3.23,-14.8),.23,.28,"cobalt")
for i in range(18):
    z=-4.3-i*.57
    y=.85+(-z-4.3)*2.25/10.5
    machines.box("Inclined rubber strip",(10.8,y+.028,z),(2.96,.047,.048),"slat")
for z in (-6,-10,-14):
    yy=.85+(-z-4.3)*2.25/10.5
    machines.box("Feeder support",(10.8,yy*.5,z),(.23,yy,.26),"steel")
a.layout["boxes"].append([(10.8,.93,-9.6),(3.30,1.85,10.6),0])

scanner=a.kit("scanner")
scanner.box("Scanner base",(0,.50,0),(2.15,.80,2.2),"steel")
for x in (-.91,.91):
    scanner.box("Scanner upright",(x,1.27,0),(.36,1.64,2.19),"white")
scanner.box("Scanner roof",(0,1.98,0),(2.18,.43,2.19),"white")
for x in (-.63,-.38,-.13,.12,.37,.62):
    scanner.box("Scanner soft-strip curtain",(x,1.28,1.12),(.205,1.00,.047),"glass" if int((x+.7)*10)%2 else "blue")
scanner.box("Scan status lamp",(0,2.25,.10),(.17,.15,.17),"signal")
scanner.box("Operator terminal",(-1.17,1.17,.62),(.50,.44,.24),"black")
scanner.box("Operator LCD",(-1.17,1.18,.755),(.41,.31,.028),"cyan")
a.prop("scanner",(10.6,0,3.4),(2.45,2.24,2.26),effect="metal")
for z in (1,-2,-5):
    machines.box("Dispatch chute",(19.8,.86,z),(2.0,.29,1.3),"steel")
    machines.box("Dispatch sidewall",(19.8,1.06,z+.62),(2.0,.41,.10),"blue")
    for y in (.6,1.04,1.48):
        machines.box("Strip-curtain translucent panel",(21.72,y,z),(.07,.42,1.05),"skyglass")
    machines.box("Red chute status",(21.70,1.79,z),(.13,.12,1.14),"signal")
    a.layout["boxes"].append([(20.8,.78,z),(2.24,1.55,1.29),0])
for x,z in [(-13,-4),(-13,5),(12.1,6)]:
    machines.box("Infrared arch header",(x,2.02,z),(1.6,.18,.20),"black")
    machines.box("Infrared arch light",(x,1.92,z),(1.40,.05,.13),"signal")
    for dx in (-.78,.78):
        machines.box("Sensor gate post",(x+dx,1.01,z),(.17,2.02,.19),"steel")
        a.layout["boxes"].append([(x+dx,1.01,z),(.19,2.02,.21),0])

case=a.kit("suitcase")
case.box("Molded hard case shell",(0,.27,0),(1.1,.54,.65),"case_red")
case.box("Hard case front",(0,.27,.332),(.99,.47,.036),"red")
for x in (-.34,-.17,0,.17,.34):
    case.box("Press-molded suitcase rib",(x,.25,.358),(.038,.33,.034),"case_red")
for x in (-.30,.30):
    case.box("Black zipper catch",(x,.44,.362),(.10,.10,.055),"black")
case.box("Top suitcase carry handle",(0,.57,0),(.29,.081,.10),"black")
case.box("Hanging baggage tag",(.28,.34,.385),(.17,.24,.032),"white",.22)
for i in range(4):
    case.box("Tag barcode",(.22+i*.027,.33,.403),(.014,.08,.012),"navy")
a.prop("suitcase",(-4.6,.82,4.5),(1.11,.6,.71),name="BurstCase",effect="luggage")
for x,y,z in [(4.6,.82,-4.3),(12.7,0,6.1),(-12.3,0,2),(-8.3,0,16),(6.9,0,18.5)]:
    a.prop("suitcase",(x,y,z),(1.11,.60,.71),effect="luggage")

tug=a.kit("tractor")
tug.box("Airport electric tow tractor base",(0,.44,0),(1.52,.56,2.63),"yellow")
tug.box("Tow tractor cab",(0,1.19,.35),(1.42,1.31,1.27),"white")
tug.box("Cab front windscreen",(0,1.37,1.0),(1.13,.62,.043),"glass")
for x in (-.74,.74):
    tug.box("Tow cab side glazing",(x,1.41,.36),(.054,.60,.81),"glass")
    for z in (-.84,.76):
        tug.rod("Tow tractor tire",(x-.11,.37,z),(x+.11,.37,z),.34,"black",10)
        tug.rod("Wheel center",(x,.37,z),(x+math.copysign(.135,x),.37,z),.18,"metal",8)
tug.box("Amber roof beacon",(0,1.96,.37),(.29,.15,.23),"orange")
tug.box("Tow bumper",(0,.46,1.32),(1.47,.19,.15),"black")
a.prop("tractor",(-17.8,0,4.3),(1.68,2.03,2.77),effect="metal")
cart=a.kit("baggage_cart")
cart.box("Baggage cart tub",(0,.57,0),(1.65,.69,2.35),"blue")
cart.box("Hollow cart top",(0,.93,0),(1.39,.044,2.11),"navy")
for x in (-.84,.84):
    cart.box("Baggage cart side rim",(x,.99,0),(.087,.13,2.38),"turquoise")
    for z in (-.79,.79):
        cart.rod("Baggage cart wheel",(x-.085,.20,z),(x+.085,.20,z),.175,"black",8)
cart.beam("Dolly tongue",(0,.37,-1.2),(0,.25,-1.65),.13,.09,"metal")
for x,z in [(-18,-.2),(-18,-4.0),(-18,-7.7),(18,6.2),(18,-9.5),(11,-16.5)]:
    a.prop("baggage_cart",(x,0,z),(1.79,1.06,2.41),effect="metal")

# A rounded stainless reclaim carousel, with a walkable perimeter on all sides.
cx,cz=0,17.6
for i in range(32):
    t0,t1=i*math.tau/32,(i+1)*math.tau/32
    segment=[(cx+8.0*math.cos(t0),.65,cz+2.28*math.sin(t0)),
             (cx+8.0*math.cos(t1),.65,cz+2.28*math.sin(t1)),
             (cx+5.85*math.cos(t1),.65,cz+1.10*math.sin(t1)),
             (cx+5.85*math.cos(t0),.65,cz+1.10*math.sin(t0))]
    machines.slab("Carousel rubber sector",segment[::-1],.32,"rubber" if i%2 else "slat")
    p0,p1=segment[0],segment[1]
    machines.beam("Stainless carousel lip",p0,p1,.14,.19,"metal")
machines.box("Carousel center island",(0,.48,17.6),(11.65,.94,2.16),"white")
a.layout["boxes"].append([(0,.42,17.6),(13.45,.84,4.07),0])
for x in (-3.4,3.4):
    machines.box("Reclaim carousel planter",(x,.92,17.6),(1.19,.42,.90),"sand")
    for i in range(3):
        xx=x+(i-1)*.30
        machines.rod("Faceted lobby plant",(xx,1.06,17.62),(xx+.07,1.65+i*.09,17.57),.27,"green",4,.02)
for x in (-12.9,12.9):
    for i in range(4):
        z=18.0+i*.63
        machines.box("Nested luggage trolley base",(x,.27,z),(.71,.07,.89),"metal")
        for dx in (-.32,.32):
            machines.rod("Trolley tube",(x+dx,.27,z),(x+dx,1.04,z+.29),.035,"metal",7)
            machines.rod("Small trolley wheel",(x+dx-.08,.14,z+.19),(x+dx+.08,.14,z+.19),.11,"black",8)
        machines.rod("Trolley handle",(x-.32,1.04,z+.29),(x+.32,1.04,z+.29),.06,"teal",8)
machines.box("Split-flap flight board",(13.1,3.68,11.34),(6.75,1.38,.14),"black")
for i in range(21):
    for row in range(4):
        machines.box("Flip-board cells",(10.01+i*.30,3.21+row*.31,11.43),(.267,.244,.04),
                     "yellow" if (i*7+row*3)%13<4 else "navy")

for x,z in [(-11,-8),(11,-5),(-13,6),(1,-10),(12,8)]:
    machines.rod("Reflective cone",(x,.06,z),(x,.69,z),.235,"orange",8,.043)
    machines.rod("Reflective cone white band",(x,.37,z),(x,.45,z),.145,"white",8,.126)
    machines.box("Cone base",(x,.04,z),(.49,.08,.49),"orange")
for x,z in [(-18,7),(-18,8),(17,4),(11,-6)]:
    machines.box("Wheel chock",(x,.12,z),(.42,.24,.33),"yellow",.46)
    machines.box("Chock base",(x,.04,z),(.47,.075,.40),"black",.46)
for x,z in [(-1.0,-9),(1.0,-9),(-1.0,1.0),(1.0,1.0)]:
    machines.box("Yellow mesh cage guard",(x,.95,z),(.10,1.87,1.74),"yellow")
    for i in range(6):
        machines.box("Wire guard horizontal",(x,.17+i*.30,z),(.041,.047,1.68),"black")
    for i in range(7):
        machines.box("Wire guard vertical",(x,.96,z+(i-3)*.24),(.044,1.71,.045),"black")
for x,z in [(-1.2,-3.9),(1.2,3.8)]:
    machines.box("Roller transfer dolly",(x,.38,z),(1.08,.23,1.36),"yellow")
    for i in range(6):
        machines.rod("Transfer roller",(x-.42,.53,z+(i-2.5)*.20),(x+.42,.53,z+(i-2.5)*.20),.075,"metal",8)

apron.box("Concrete airport apron",(0,-.54,5),(134,.46,104),"pavement")
for x in range(-50,55,8):
    apron.box("Apron runway center dash",(x,-.285,34),(4.0,.038,.18),"yellow")
    apron.box("Apron runway edge lamp",(x,.01,37),(.21,.24,.21),"light")
for x in range(-56,57,14):
    apron.box("Coastal horizon block",(x,-.25,58),(13,1.75,12),"sea")
    apron.rod("Coastal hillside",(x,0,58),(x,3+(x%5),58),7,"hill",5,.4)
for z in (-37,39):
    x=17 if z<0 else -29
    for i in range(9):
        apron.rod("Airfield light tower",(x,i*.83,z),(x,(i+1)*.83,z),.27,"red" if i%2==0 else "white",8)
    apron.rod("Airport beacon",(x,7.47,z),(x,7.84,z),.40,"signal",9)
apron.rod("Aircraft fuselage",(31,1.93,34),(49,2.05,34),1.3,"white",10,.87)
apron.rod("Aircraft nose",(31,1.93,34),(27.6,1.9,34),1.3,"white",10,.30)
apron.box("Nose cockpit strip",(30.3,2.53,32.94),(2.4,.30,.09),"navy",-.1)
apron.facet("Aircraft tail fin",[(46,2.6,34),(48.7,5.9,34),(51,5.8,34),(49,2.6,34)],"blue")
for x,z in [(-12,-27),(7,32)]:
    apron.box("Apron utility vehicle",(x,.7,z),(2.7,1.4,1.23),"white")
    apron.box("Apron windshield",(x+.69,1.34,z+.11),(.71,.34,1.15),"navy")
    for dx in (-.83,.83):
        apron.rod("Apron vehicle tire",(x+dx,.24,z-.63),(x+dx,.24,z+.63),.25,"black",9)

for x,c in [(-12,"58dfff"),(0,"ffcf5e"),(12,"e264d9")]:
    a.spot((x,7.2,-7),(x,0,-4),c,7.1,15,48,(0,0,2.7))
def points(xs):
    return [(x,.06,z) for x,z in xs]
a.layout.update(
 start=(3.3,.06,14.0),heading=0,
 opening=points([(0,8),(-8.8,7),(9,7),(-10,-5),(8.0,-11),(-8.7,-13),(0,-5),(19,8)]),
 spawns=points([(-11,19),(9.7,18),(0,21),(0,13),(-9,7),(8.1,8),(-10,0),(7.4,-1),(-10,-10),
                (8.0,-11),(-8.4,-18),(8.4,-18),(19,-14)])+[(0,3.18,-15),(-16,3.18,-8)],
 respawns=points([(3.3,14),(-10,15),(8,8),(-9,-4),(7.3,-12),(-8,-19)])+[(4,3.18,-15)],
 route=points([(0,13),(0,2),(-16,3.5),(16,3.5),(-10,-17),(10,-18),(-11,16),(10,16)])+[(0,3.18,-15),(-16,3.18,-8),(16,3.18,-9)],
 barrels=points([(-9.4,2),(8.5,-6),(17.5,9)]), comedy=(8.8,0,14.6,math.pi),
 cameras={
  "arrivals":[[9.8,1.73,21.2],[.1,1.8,10],66],
  "catwalk":[[-12,4.74,-15.6],[2.1,1.27,2],68],
  "sorting-frenzy":[[-.4,1.69,8.8],[-1.2,2.2,-10],69],
 })
a.write()
