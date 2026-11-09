"""Build the arrivals hall, sorter and maintenance routes from the airport concepts."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit
from airport_board import write_board

P={
 "navy":"22314d","blue":"244d9c","cobalt":"325bbb","steel":"667687","black":"252a38",
 "metal":("a6b7c9",.31,0),"rubber":"343c4d","slat":"3e4758","concrete":"b7afb6",
 "white":"e7ebef","sand":"d9cab6","teal":"329eaa","turquoise":"4abdc5","glass":"8ccee2",
 "skyglass":("81c5e8",.52,.32),"orange":"f08b3b","amber":"e3a337","yellow":"f6c84d",
 "red":"b84153","green":"4e8a70","mint":"84bfb4","case_blue":"416cca","case_red":"b94851",
 "case_green":"40957c","light":("fff2ce",.45,.73),"signal":("fb6077",.5,.5),"cyan":("6feafc",.45,.55),
 "sea":("6ebadf",.65,.16),"hill":"587b8a","pavement":"a8a4a3",
}
a=ArenaKit("baggage_below",P,{"sky":"8cc5f2","ambient":"e6f0ff","energy":.83,"sun":"fff1cf","sun_energy":.31,"sun_rotation":[-44,30,0]})
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
roof=a.kit("ceiling_and_beams",True)
a.solid(roof,"Sorting hall ceiling",(0,8.22,-5),(44,.35,34),"navy")
a.solid(roof,"Arrivals ceiling",(0,5.5,17),(44,.3,12.1),"navy")
for x in (-22,22):
    # Keep the collision boundary while opening the view across the ramp.
    a.layout["boxes"].append([(x,4.05,-5),(.36,8.1,34),0])
    hall.box("Apron glazing concrete plinth",(x,.39,-5),(.36,.78,34),"white")
    hall.box("Terminal upper spandrel",(x,6.96,-5),(.36,2.28,34),"white")
    for y in (.82,2.64,5.78):
        hall.box("Long glass framing rail",(x,y,-5),(.32,.14,34),"blue")
    for z in range(-21,13,3):
        hall.box("Apron glazing mullion",(x,3.29,z),(.24,4.98,.15),"blue")
    for z in (-18,-12,-6,0,6,10):
        hall.box("Blue structural column",(x-math.copysign(.42,x),4.05,z),(.61,8.1,.56),"blue")
        hall.box("Impact bollard",(x-math.copysign(.73,x),.52,z),(.25,1.02,.21),"yellow")
for z in (-18,-12,-6,0,6,10,15,21):
    y=7.92 if z<12 else 5.24
    roof.box("Transverse ceiling girder",(0,y,z),(44,.45,.44),"blue")
    for x in (-13,-6,2,10,17):
        roof.box("Industrial LED strip",(x,y-.32,z),(2.65,.15,.3),"light")
for x in (-15.5,-8,8,15.5):
    roof.box("Longitudinal overhead girder",(x,7.75,-4.7),(.42,.45,33.2),"blue")

# The outer windows retain the runway view while providing a solid boundary.
for x in (-22,22):
    a.layout["boxes"].append([(x,2.65,17),(.18,5.3,12),0])
    hall.box("Glazing foot rail",(x,.34,17),(.19,.68,12),"steel")
    hall.box("Glazing top rail",(x,5.15,17),(.19,.34,12),"blue")
    for z in (11.4,12.9,20.8,22.6):
        hall.box("Blue glazing mullion",(x,2.7,z),(.19,5.25,.17),"blue")
    hall.box("High apron window transom",(x,3.72,17),(.19,.16,12),"blue")
a.layout["boxes"].append([(0,2.65,22.9),(44,5.3,.15),0])
for x in range(-22,23,3):
    hall.box("Apron-facing mullion",(x,2.66,22.91),(.14,5.15,.21),"blue")
for y in (.28,2.2,5.05):
    hall.box("Front glazing transom",(0,y,22.91),(44,.18,.23),"blue")
a.layout["glass"]=[[(x,2.7,17),(11.7,4.7),math.pi/2] for x in (-22,22)]
a.layout["glass"].append([(0,2.7,22.9),(43.8,4.7),0])
a.layout["glass"].extend([[(x,3.30,-5),(33.85,4.95),math.pi/2] for x in (-22,22)])
for left,right in [(-22,-17.15),(-13.65,-4.10),(4.10,22)]:
    x=(left+right)*.5
    width=right-left
    a.solid(hall,"Secure area lower wall",(x,.86,11),(width,1.72,.46),"white")
    a.layout["boxes"].append([(x,2.89,11),(width,2.34,.15),0])
    a.layout["glass"].append([(x,2.89,11),(width,2.34),0])
    for y in (1.70,4.06):
        hall.box("Divider glazing frame",(x,y,11),(width,.11,.53),"blue")
    for i in range(1,math.ceil(width/2.7)):
        rail_x=left+i*2.7
        hall.box("Window mullion",(rail_x,2.9,11.33),(.095,2.29,.08),"blue")
    hall.box("Sorting-side impact rail",(x,1.1,10.72),(width-.18,.12,.15),"yellow")
for x in (-13.05,13.05):
    a.solid(hall,"Secure area upper wall",(x,4.73,11),(17.9,1.25,.46),"white")
for x in (-17.15,-13.65):
    hall.box("West service opening jamb",(x,1.83,11),(.19,3.65,.57),"teal")
hall.box("West service opening lintel",(-15.4,3.70,11),(3.61,.21,.55),"teal")
hall.box("West service opening lamp",(-15.4,3.55,11),(1.41,.075,.39),"light")
for z in (9.75,10.72,11.53,12.34):
    for x in (-16.95,-13.86):
        floor.box("West service route stripe",(x,.02,z),(.10,.026,.60),"yellow")
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
        a.solid(machines,"Low belt-side safety guide",(x+edge*1.77,.44,-1.3),(.16,.88,17.5),color)
        for z0,z1 in ((-12.3,-10.05),(7.45,9.7)):
            a.solid(machines,"Belt run-off safety guide",(x+edge*1.77,.44,(z0+z1)*.5),(.16,.88,z1-z0),color)
    for z in (-9,-6,-3,0,3,6):
        for dx in (-1.25,1.25):
            machines.box("Belt pedestal",(x+dx,.35,z),(.17,.71,.22),"steel")
    a.layout["belts"].append([[x,.73,-1.3],[3.19,.18,17.5],-1 if i==0 else 1])
    a.slope(machines,"Belt step-on ramp",x-1.59,x+1.59,7.45,9.7,.82,0,.19,"rubber")
    a.slope(machines,"Rear belt run-off",x-1.59,x+1.59,-12.3,-10.05,0,.82,.19,"rubber")
    direction=-1 if i==0 else 1
    for z in (-10.05,7.45):
        machines.rod("Exposed conveyor end drum",(x-1.60,.66,z),(x+1.60,.66,z),.198,"metal",12)
        for side in (-1,1):
            xx=x+side*1.66
            machines.box("Bolted tension bracket",(xx,.59,z),(.22,.37,.58),"steel")
            machines.rod("Drum bearing cap",(xx,.66,z),(xx+side*.16,.66,z),.14,color,10)
            machines.rod("Tension screw",(xx,.55,z-.33),(xx,.55,z+.33),.038,"metal",8)
    outlet=-10.05 if direction<0 else 7.45
    drive_x=x+direction*1.43
    machines.rod("Sorter drive motor",(drive_x-direction*.22,.42,outlet),
                 (drive_x+direction*.21,.42,outlet),.24,"cobalt",12)
    for dx in (-.14,-.04,.06,.16):
        machines.rod("Motor cooling rib",(drive_x+dx,.42,outlet),
                     (drive_x+dx+.032,.42,outlet),.263,"steel",12)
    ramp_end=outlet+direction*2.25
    # Parallel guide strips frame the transfer slope without narrowing the walkable lane.
    for side in (-1,1):
        xx=x+side*1.53
        machines.beam("Sloping transfer chute lip",(xx,.87,outlet),(xx,.10,ramp_end),.09,.075,"metal")
    for step in range(4):
        t=.20+step*.16
        z=outlet+direction*t*2.25
        machines.box("Transfer chute roller strip",(x,.83*(1-t),z),(2.90,.035,.105),"slat")
for z in (-9,-5,-1,3,7):
    for x in (-6.37,-2.83,2.83,6.37):
        machines.box("Belt warning lens housing",(x,.925,z),(.23,.095,.68),"black")
    for x,color in [(-6.37,"ff3553"),(6.37,"3d91ff")]:
        direction=math.copysign(1,x)
        a.spot((x,1.13,z),(x+direction*1.5,0,z+.1),color,3.4,4.0,54,(0,0,.7))

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
a.prop("suitcase",(-3.95,.82,5.45),(1.11,.6,.71),name="BurstCase",effect="luggage")
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
a.layout["slabs"].append([[(cx+8*math.cos(i*math.tau/16),.67,cz+2.28*math.sin(i*math.tau/16))
                            for i in range(16)],.70])
a.layout["boxes"].append([(0,.46,17.6),(11.65,.92,2.16),0])
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
for x in (-10.3,10.3):
    a.solid(machines,"Terminal bench base",(x,.34,21.7),(3.48,.68,.74),"blue")
    for i in range(4):
        dx=(i-1.5)*.84
        machines.box("Terminal bench seat",(x+dx,.72,21.7),(.75,.11,.67),"teal")
        machines.box("Terminal bench back",(x+dx,1.00,22.0),(.75,.46,.15),"teal",.04)
scale=a.kit("cargo_scale")
scale.box("Low cargo scale platform",(0,.17,0),(1.83,.34,1.42),"steel")
scale.box("Rubber weighing pad",(0,.35,0),(1.69,.045,1.30),"rubber")
scale.rod("Scale display mount",(-.65,.34,-.50),(-.65,1.18,-.50),.059,"metal",8)
scale.box("Scale display housing",(-.65,1.18,-.47),(.37,.23,.15),"navy")
scale.box("Scale display window",(-.65,1.19,-.38),(.28,.13,.035),"cyan")
a.prop("cargo_scale",(-19.6,0,8.7),(1.83,1.30,1.42),effect="metal")
a.layout["flight_boards"]=[]
for z,angle in [(11.58,0),(10.40,math.pi)]:
    direction=math.cos(angle)
    machines.box("Split-flap board cabinet",(12.7,3.72,z),(12.1,3.04,.27),"black")
    for y in (2.2,5.24):
        machines.box("Brushed flight-board trim",(12.7,y,z), (12.18,.092,.33),"metal")
    for x in (6.68,18.72):
        machines.box("Board end frame",(x,3.72,z),(.09,3.02,.31),"steel")
    a.layout["flight_boards"].append([[12.7,3.72,z+direction*.145],11.77,2.88,angle])

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
terminal=a.kit("gate_terminal",True)
terminal.box("Remote passenger terminal podium",(0,.50,-38),(103,1.70,12),"concrete")
terminal.box("Passenger terminal glazed facade",(0,3.90,-37.05),(103,5.18,10),"navy")
terminal.box("Floating terminal roof",(0,6.86,-36.6),(105,.55,13.4),"white")
terminal.box("Blue roof fascia",(0,6.51,-29.95),(104,.30,.24),"blue")
for i in range(34):
    x=-49.5+i*3
    terminal.box("Warm terminal curtain wall",(x,3.87,-31.97),(2.82,4.65,.18),
                 ("skyglass","glass","light","glass")[i%4])
    for y in (2.05,4.12,5.81):
        terminal.box("Terminal facade transom",(x,y,-31.85),(2.88,.14,.11),"blue")
    terminal.box("Curtain wall mullion",(x-1.45,3.86,-31.85),(.15,4.83,.18),"white")

a.layout["cargo_belts"]=[]
for side in (-1,1):
    x=side*36
    offset=3.8 if side==1 else -2.5
    livery="teal" if side==1 else "orange"
    gear_x=x+side*.99
    nose=18.5+offset
    tail=-13+offset
    terminal.box("Passenger concourse pier",(side*48,4.25,-11+offset),(7.7,3.91,41),"white")
    terminal.box("Pier roof cap",(side*48,6.30,-11+offset),(8.2,.23,41),"blue")
    for j in range(10):
        z=-27+j*3.75+offset
        terminal.box("Pier gate window",(side*44.09,4.75,z),(.12,1.84,3.49),"glass")
        terminal.box("Pier window top rail",(side*44.0,5.70,z),(.16,.08,3.58),"blue")
    # The near-side pier and bridge keep the connection visible from the hall.
    gate_z=-7.65+offset
    pier_z=(-32+gate_z-4.1)*.5
    pier_length=gate_z-4.1+32
    terminal.box("Remote terminal boarding pier",(side*26.45,4.48,pier_z),(3.65,3.19,pier_length),"white")
    terminal.box("Boarding pier blue roof",(side*26.45,6.12,pier_z),(3.82,.25,pier_length),"blue")
    for i in range(round(pier_length/2.8)):
        z=-30.5+i*2.8
        terminal.box("Boarding pier tinted window",(side*24.59,4.71,z),(.10,1.41,2.58),"skyglass")
        terminal.box("Pier window lower trim",(side*24.54,3.96,z),(.14,.12,2.68),"blue")
    terminal.beam("Jet bridge articulated shell",(side*27.0,4.36,gate_z-5.26),
                  (side*33.92,3.93,gate_z),2.40,2.55,"white")
    terminal.beam("Jet bridge glass ribbon",(side*26.28,4.64,gate_z-4.27),
                  (side*33.17,4.21,gate_z+.97),.12,.99,"skyglass")
    for i in range(5):
        t=(i+.5)/5
        terminal.box("Jet bridge ribbon mullion",(side*(26.28+6.89*t),4.64-.43*t,gate_z-4.27+5.24*t),
                     (.09,1.01,.14),"blue")
    terminal.box("Accordion gate collar",(side*34.02,3.80,gate_z),(.64,2.29,2.29),"rubber")
    for i in range(4):
        terminal.box("Jet bridge bellows rib",(side*(33.78+i*.16),3.81,gate_z),(.065,2.34,2.36),"steel")
    terminal.rod("Bridge support column",(side*30.2,-.28,gate_z-2.79),
                 (side*30.2,3.03,gate_z-2.79),.25,"steel",10)
    terminal.box("Bridge ground bogie",(side*30.2,.17,gate_z-2.79),(1.65,.45,1.0),"blue")
    for dz in (-.59,.59):
        terminal.rod("Bridge support tire",(side*29.66,.15,gate_z-2.79+dz),
                     (side*30.71,.15,gate_z-2.79+dz),.29,"black",10)

    # Low-poly short-haul jets, with cargo hatches facing the playable windows.
    aircraft=apron
    aircraft.rod("Airliner fuselage",(x,2.80,tail+2.3),(x,2.80,nose-3.8),1.79,"white",14)
    aircraft.rod("Airliner radome",(x,2.80,nose-3.8),(x,2.45,nose),1.79,"white",14,.34)
    aircraft.rod("Airliner rear taper",(x,2.80,tail+2.3),(x,3.16,tail),1.79,"white",14,.27)
    for dx in (-1,1):
        cabin_x=x+dx*1.668
        aircraft.box("Airline painted cheatline",(cabin_x,2.63,offset+.9),(.16,.27,25.7),livery)
        for j in range(17):
            z=offset-8.5+j*1.29
            aircraft.box("Airline cabin window",(cabin_x,3.23,z),(.165,.38,.53),"navy")
            aircraft.box("Cabin window highlight",(cabin_x+dx*.088,3.34,z),(.018,.10,.42),"glass")
        for dz in (-7.65,12.0):
            z=offset+dz
            aircraft.box("Passenger door edge",(x+dx*1.73,3.01,z),(.11,1.39,.95),"steel")
            aircraft.box("Passenger door paint",(x+dx*1.80,3.02,z),(.041,1.23,.78),"white")
            aircraft.box("Passenger door handle",(x+dx*1.83,2.88,z+.23),(.035,.06,.20),"navy")
        aircraft.facet("Cockpit windscreens",[(x+dx*.67,3.22,nose-1.53),(x+dx*.19,3.28,nose-1.49),
                       (x+dx*.27,3.73,nose-2.43),(x+dx*.97,3.57,nose-2.60)],"navy")
        wing=[(x+dx*.88,1.97,offset+4.2),(x+dx*9.55,2.48,offset-4.6),
              (x+dx*10.23,2.56,offset-6.1),(x+dx*2.1,1.94,offset-2.0)]
        aircraft.slab("Swept aluminium wing",wing if dx==1 else wing[::-1],.17,"white")
        aircraft.facet("Painted winglet",[(x+dx*9.46,2.43,offset-4.62),(x+dx*10.23,2.53,offset-6.1),
                       (x+dx*10.67,3.39,offset-6.27),(x+dx*10.14,3.22,offset-5.23)],livery)
        engine_x=x+dx*4.14
        aircraft.rod("Low bypass nacelle",(engine_x,1.50,offset-.55),(engine_x,1.50,offset+3.65),.93,"white",14,1.02)
        aircraft.rod("Dark turbine intake",(engine_x,1.50,offset+3.66),(engine_x,1.50,offset+3.71),.80,"black",14)
        aircraft.rod("Turbine spinner",(engine_x,1.50,offset+3.72),(engine_x,1.50,offset+3.9),.23,"steel",10,.08)
        tailplane=[(x,3.25,tail+2.7),(x+dx*4.45,3.52,tail+.1),(x+dx*4.49,3.52,tail-1.2),(x,3.28,tail+.6)]
        aircraft.slab("Horizontal tail stabilizer",tailplane if dx==1 else tailplane[::-1],.12,"white")
    aircraft.facet("Airline vertical tail fin",[(x,3.8,tail+4.6),(x,7.22,tail+.38),
                   (x,7.20,tail-1.26),(x,3.38,tail-.92)],livery)
    aircraft.facet("Tail flash",[(x-side*.016,4.45,tail+2.88),(x-side*.016,5.37,tail+.57),
                   (x-side*.016,5.29,tail-.56),(x-side*.016,4.26,tail+1.50)],"white")
    for axle_x,z in [(x,nose-4.7),(gear_x,offset-.55),(x-side*.99,offset-.55)]:
        aircraft.rod("Landing gear strut",(axle_x,.36,z),(axle_x,1.69,z),.10,"steel",8)
        for dx in (-.20,.20):
            aircraft.rod("Landing gear tire",(axle_x+dx-.13,.15,z),(axle_x+dx+.13,.15,z),.38,"black",12)

    # A powered belt loader runs down from the open cargo hold into a dolly.
    z=offset+7.2
    hx=x-side*1.74
    lx=x-side*8.64
    aircraft.box("Open cargo hatch",(hx,2.31,z),(.11,1.0,1.98),"black")
    aircraft.box("Raised cargo hatch lid",(hx-side*.23,2.97,z),(.62,.14,2.03),"white")
    aircraft.box("Cargo hold threshold",(hx-side*.12,1.84,z),(.34,.12,1.88),"metal")
    aircraft.beam("Belt loader rubber deck",(hx,1.92,z),(lx,.56,z),1.38,.18,"rubber")
    for dz in (-.73,.73):
        aircraft.beam("Safety yellow loader railing",(hx,2.05,z+dz),(lx,.69,z+dz),.13,.16,"yellow")
    for j in range(19):
        t=(j+.5)/19
        tx=hx+(lx-hx)*t
        ty=1.95+(0.59-1.95)*t
        aircraft.box("Loader belt slat",(tx,ty,z),(.075,.041,1.33),"slat")
    aircraft.box("Belt loader motor housing",(lx+side*1.85,.30,z),(2.6,.62,1.53),"blue")
    aircraft.beam("Loader hydraulic lift",(lx+side*2.18,.43,z),(hx-side*1.6,1.58,z),.19,.20,"metal")
    for dx in (.82,2.86):
        for dz in (-.76,.76):
            wheel_x=lx+side*dx
            aircraft.rod("Loader wheel",(wheel_x,.18,z+dz-.10),(wheel_x,.18,z+dz+.10),.29,"black",10)
    aircraft.box("Cargo dolly bed",(lx-side*1.24,.35,z),(2.56,.29,1.75),"steel")
    for dz in (-.91,.91):
        aircraft.box("Dolly side rail",(lx-side*1.24,.65,z+dz),(2.58,.22,.10),"blue")
    for dx in (-.73,.73):
        for dz in (-.84,.84):
            xx=lx-side*1.24+dx
            aircraft.rod("Dolly rubber wheel",(xx,.02,z+dz-.10),(xx,.02,z+dz+.10),.23,"black",10)
    a.layout["cargo_belts"].append([[hx,2.02,z],[lx,.66,z],[lx-side*1.95,.51,z]])
    for zz in (offset-10,offset+9):
        apron.box("Apron stand guide stripe",(x,-.283,zz),(.14,.035,12.6),"yellow")
    for j in range(13):
        apron.box("Apron safety boundary dash",(side*24.3,-.282,-23+j*3.6),(.16,.039,1.98),"white")
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
 route=points([(0,13),(-15.4,13),(-15.4,9),(0,2),(-16,3.5),(16,3.5),(-10,-17),(10,-18),(-11,16),(10,16)])+[(0,3.18,-15),(-16,3.18,-8),(16,3.18,-9)],
 barrels=points([(-9.4,2),(8.5,-6),(17.5,9)]), comedy=(8.8,0,14.6,math.pi),
 cameras={
  "arrivals":[[9.8,1.73,21.2],[.1,1.8,10],66],
  "flight-board":[[11.95,2.34,18.1],[12.7,3.72,11.5],68],
  "flight-board-flip":[[11.95,2.34,18.1],[12.7,3.72,11.5],68,6.42],
  "east-gate":[[19.55,1.72,15.8],[34.0,2.55,6.3],72],
  "west-gate":[[-17.25,4.73,-5.55],[-34.0,3.04,-8.8],73],
  "catwalk":[[-5.7,4.78,-13.73],[.2,.21,3.2],70],
  "sorting-frenzy":[[-1.45,1.87,8.05],[-1.2,1.63,-8],72,45.32],
  "sorting-blue-frenzy":[[-1.45,1.87,8.05],[-1.2,1.63,-8],72,45.89],
 })
a.write()
write_board()
