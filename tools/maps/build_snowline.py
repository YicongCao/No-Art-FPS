"""Build the alpine observatory, weather deck and inner telescope route."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P={
 "snow":"e7ecfa","frost":"c6d6f0","ice":"9cb9d9","snow_lit":"f2f2f7","navy":"253354",
 "ink":"212c45","rock":"5b6880","dark_rock":"4a5775","light_rock":"8294ae","blue":"365ea0",
 "cobalt":"254a83","steel":"688098","metal":("a3b3c7",.36,0),"glass":("83badd",.40,.09),
 "orange":"ed853b","orange_light":"f3a24a","orange_dark":"c95c30","yellow":"f0c052",
 "white":"edf0ed","cream":"e0d5c8","purple":"76619c","plum":"574870","wood":"92715d",
 "red":"c53e4c","olive":"5c775e","olive_light":"789478","light":("ffe0a7",.5,.75),
 "red_light":("fe3b39",.43,.72),"lcd":("a5d8e3",.45,.42),
}
a=ArenaKit("snowline",P,{"sky":"7797d9","ambient":"cddfff","energy":.81,"sun":"fff0d6","sun_energy":.79,"sun_rotation":[-29,-39,0]})
terrain=a.kit("snow_terrain",True)
building=a.kit("observatory_drum",True)
catwalk=a.kit("instrument_deck",True)
yard=a.kit("snow_yard",True)
ridge=a.kit("ridge",True)
dome=a.kit("dome")
dome_glow=a.kit("shutter_lights")
CZ=-2.7
R=11.55
a.solid(terrain,"Compact snowy mountain pad",(0,-.44,0),(46,.87,48),"snow")
for x,z,w,d in [(-16,-17,5,3),(13,-17,5,4),(-17,-6,5,3),(14,9,5,3),(-16,14,7,4),(16,19,8,4),(-9,21,5,3)]:
    for i in range(5):
        ang=i*math.tau/5
        nxt=(i+1)*math.tau/5
        terrain.facet("Wind sculpted snow drift",[(x,.26,z),(x+math.cos(ang)*w*.5,.008,z+math.sin(ang)*d*.5),
                       (x+math.cos(nxt)*w*.5,.008,z+math.sin(nxt)*d*.5)],("frost","snow_lit","snow")[i%3])
for i in range(37):
    z=10+i*.33
    x=6.4+math.sin(i*.084)*2.2
    for dx in (-.75,.75):
        terrain.box("Snowcat compacted tread",(x+dx,.007,z),(.39,.017,.13),"ice",.18)
for i in range(25):
    z=-21+i*.46
    x=-6.7+math.sin(i*.20)*4
    terrain.box("Service road tracks",(x,.009,z),(.43,.018,.24),"frost",.14)

def rail_line(kit,p0,p1,color="yellow",collision=True):
    x0,y0,z0=p0
    x1,y1,z1=p1
    length=math.hypot(x1-x0,z1-z0)
    for j in range(max(2,math.ceil(length/1.33)+1)):
        t=j/(max(2,math.ceil(length/1.33)+1)-1)
        x,y,z=(p0[i]+(p1[i]-p0[i])*t for i in range(3))
        kit.box("Guardrail post",(x,y+.55,z),(.10,1.10,.10),color)
    for dy in (.55,1.07):
        kit.beam("Guardrail runner",(x0,y0+dy,z0),(x1,y1+dy,z1),.092,.089,color)
    if not collision:
        return
    dx,dz=(z1-z0)*.06/length,(x0-x1)*.06/length
    a.layout["slabs"].append([[(x0-dx,y0+1.1,z0-dz),(x0+dx,y0+1.1,z0+dz),
                               (x1+dx,y1+1.1,z1+dz),(x1-dx,y1+1.1,z1-dz)],1.14])

for p0,p1 in [((-22,0,-22),(-22,0,22)),((22,0,-22),(22,0,22)),
              ((-22,0,22),(22,0,22)),((-22,0,-22),(22,0,-22))]:
    rail_line(terrain,p0,p1,"blue")
for x,z in [(-21,7),(-21,13),(-21,-4),(-21,-13),(-14,-21),(-7,-21),(3,-21),
            (11,-21),(20,-18),(21,12),(19,20),(10,21),(-11,21)]:
    terrain.rod("Striped snow gauge pole",(x,0,z),(x,1.65,z),.065,"red",8)
    for y in (.32,.91,1.40):
        terrain.rod("White snow gauge stripe",(x,y,z),(x,y+.18,z),.068,"white",8)
for i in range(12):
    x=-18+i*3.25
    terrain.box("Avalanche fence post",(x,.78,-22.5),(.18,1.56,.18),"wood")
    for y in (.38,.85,1.32):
        terrain.box("Anti-drift timber snow fence",(x+1.6,y,-22.5),(3.28,.27,.15),"wood")

# Faceted nearby rock masses and more distant layered mountain peaks.
for i in range(31):
    th=i*math.tau/31
    x,z=math.cos(th)*27.5,math.sin(th)*30
    h=2.2+(i*7%9)*.70
    ridge.rod("Alpine outcrop",(x,-5,z),(x+math.cos(th)*1.75,h,z+math.sin(th)*1.3),
              4.6+(i%4),("rock","dark_rock","light_rock")[i%3],5,1.9)
    ridge.rod("Snow cap",(x+math.cos(th)*1.68,h-.7,z+math.sin(th)*1.24),
              (x+math.cos(th)*1.75,h+.04,z+math.sin(th)*1.3),2.22,"frost" if i%3 else "snow_lit",5,1.88)
for i in range(20):
    th=i*math.tau/20
    x,z=75*math.cos(th),85*math.sin(th)
    y=10+(i*13%7)*2.6
    ridge.rod("Distant blue mountain",(x,-11,z),(x+4,y,z-3),21,"light_rock" if i%2 else "rock",5,1.2)
    ridge.rod("Distant bright snow line",(x+3,y-5,z-2),(x+4,y+.06,z-3),4.85,"snow" if i%2 else "frost",5,1.12)

def pos(theta,radius,y):
    return (math.cos(theta)*radius,y,CZ+math.sin(theta)*radius)


def circle_slab(kit,label,t0,t1,inner,outer,y0,y1,color,physical=True,thick=.21):
    quad=[pos(t0,inner,y0),pos(t1,inner,y1),pos(t1,outer,y1),pos(t0,outer,y0)]
    if physical:
        a.slab(kit,label,quad,thick,color)
    else:
        kit.slab(label,quad,thick,color)

n=40
for i in range(n):
    th=(i+.5)*math.tau/n
    x,y,z=pos(th,11.43,2.28)
    angle=-th+math.pi/2
    gap=i in (0,39,9,10,19,20,24,25)
    if not gap:
        a.solid(building,"Segmented drum wall",(x,y,z),(1.827,4.56,.29),"orange" if i%3 else "orange_light",angle)
        building.box("Drum wall seam",(x,2.31,z),(1.79,.048,.38),"orange_dark",angle)
        if i%2==0:
            xo,_,zo=pos(th,11.60,0)
            building.box("Dark ribbon window",(xo,3.27,zo),(1.58,.76,.096),"cobalt",angle)
            building.box("Cool ribbon glazing",(xo,3.30,zo),(1.38,.60,.122),"glass",angle)
    else:
        bottom=3.05 if i in (9,10,19,20,24,25) else 4.26
        a.solid(building,"Doorway head over route",(x,(bottom+4.56)/2,z),(1.84,4.56-bottom,.31),"orange",angle)
    t0,t1=i*math.tau/n,(i+1)*math.tau/n
    circle_slab(building,"Drum trim ring",t0,t1,11.22,11.73,4.6,4.6,"blue",False,.22)
    circle_slab(building,"Purple telescope floor",t0,t1,.10,11.54,.02,.02,"purple",False,.12)
building.rod("Telescope floor center",(0,-.04,CZ),(0,.024,CZ),.41,"plum",12)
a.solid(building,"Insulated door header",(0,3.45,9.08),(3.7,.55,1.02),"cobalt")
for x in (-1.77,1.77):
    a.solid(building,"Insulated south entry jamb",(x,1.46,9.18),(.29,2.93,1.06),"cobalt")
    building.box("Storm door sidelight",(x,1.78,9.66),(.19,1.40,.15),"glass")
building.box("Blue snow entry awning",(0,3.18,9.52),(4.0,.29,1.92),"blue")
building.box("Snow on entry awning",(0,3.36,9.56),(3.91,.11,1.86),"snow")
building.box("Insulated airlock task light",(0,2.99,9.57),(1.35,.093,.16),"light")
building.box("Entry boot grate",(0,.034,10.09),(2.63,.063,1.24),"ink")
for i in range(11):
    building.box("Boot grate ribs",((i-5)*.22,.071,10.09),(.042,.029,1.15),"metal")

hatch=a.kit("storm_hatch")
hatch.box("Insulated snow shutter",(0,1.50,0),(3.54,3.0,.27),"blue")
for i in range(9):
    hatch.box("Horizontal shutter rib",(0,.19+i*.32,.16),(3.44,.073,.09),"cobalt")
for x in (-1.46,1.46):
    hatch.box("Yellow latch plate",(x,1.45,.18),(.25,.68,.08),"yellow")
    hatch.rod("Shutter grab handle",(x,1.27,.23),(x,1.61,.23),.067,"ink",8)
hatch_angle=-3*math.pi/4
hx,_,hz=pos(hatch_angle,11.39,0)
a.prop("storm_hatch",(hx,0,hz),(3.57,3.03,.31),hatch_angle,name="StormHatch",effect="ice",structural=True)
for dx in (-1.87,1.87):
    building.box("Storm hatch frame",(hx+dx*math.cos(hatch_angle),1.55,hz-dx*math.sin(hatch_angle)),
                 (.20,3.1,.39),"cobalt",hatch_angle)
building.box("Northwest hatch emergency lamp",(hx+.24,3.17,hz+.24),(1.15,.12,.15),"red_light",hatch_angle)
building.box("Snow shelf above hatch",(hx-.22,3.20,hz-.22),(3.89,.21,.63),"snow",hatch_angle)

# Walk from the northern room floor up the half-level curved ramp to the east deck.
ramp_start,ramp_end=-2.11,-.22
segments=16
for i in range(segments):
    t0=ramp_start+(ramp_end-ramp_start)*i/segments
    t1=ramp_start+(ramp_end-ramp_start)*(i+1)/segments
    y0,y1=2.38*i/segments,2.38*(i+1)/segments
    circle_slab(building,"Curving half-level ramp",t0,t1,7.5,10.96,y0,y1,"plum")
    if i>=2:
        rail_line(building,pos(t0,7.52,y0),pos(t1,7.52,y1))
for i in range(6):
    t0=-.22+i*.075
    t1=t0+.075
    circle_slab(building,"East ring landing",t0,t1,7.50,11.78,2.38,2.38,"purple")
    rail_line(building,pos(t0,7.52,2.38),pos(t1,7.52,2.38))
rail_line(building,pos(.23,7.53,2.38),pos(.23,11.44,2.38))

a.solid(catwalk,"East weather deck",(16.1,2.23,-3.05),(10.0,.30,7.4),"steel")
for x in range(12,22):
    for z in range(-6,1):
        catwalk.box("Instrument grating panel",(x,2.389,z),(.94,.026,.94),"navy")
        for i in range(6):
            catwalk.box("Cross grating bar",(x-.40+i*.16,2.413,z),(.034,.029,.92),"metal")
for p0,p1 in [((11.18,2.38,.64),(21.08,2.38,.64)),((21.08,2.38,.64),(21.08,2.38,-6.68)),
              ((11.18,2.38,-6.68),(17.32,2.38,-6.68)),((11.13,2.38,-6.68),(11.13,2.38,-4.55)),
              ((11.13,2.38,-.75),(11.13,2.38,.64))]:
    rail_line(catwalk,p0,p1)
a.slope(catwalk,"Outside ramp to north snow road",17.32,21.02,-14.6,-6.70,0,2.38,.27,"steel")
for x in (17.32,21.02):
    rail_line(catwalk,(x,0,-14.6),(x,2.38,-6.7))
for x,z in [(13,-5.5),(19,-5.5),(13,.0),(19,.0)]:
    catwalk.box("Weather deck steel leg",(x,1.13,z),(.24,2.27,.24),"cobalt")
    catwalk.beam("Braced weather-deck leg",(x,.28,z),(x+1.3,2.16,z),.13,.12,"navy")
for z in (-4.64,-.68):
    catwalk.box("Blue east access jamb",(11.71,3.40,z),(.63,2.04,.17),"cobalt")
catwalk.box("Weather deck entrance canopy",(12.75,4.54,-2.64),(3.0,.28,4.12),"blue")
catwalk.box("Canopy snow",(12.76,4.72,-2.65),(2.88,.10,4.00),"snow")
catwalk.box("Weather door top light",(12.83,4.36,-2.62),(.17,.12,1.48),"light")

# Rotatable segmented orange shell, open in the south-facing observing slot.
theta_start=math.pi*.5+.41
theta_span=math.tau-.82
for band in range(7):
    e0=(band)*1.51/7
    e1=(band+1)*1.51/7
    for i in range(32):
        t0=theta_start+theta_span*i/32
        t1=theta_start+theta_span*(i+1)/32
        def dome_pt(th,el):
            rr=R*math.cos(el)
            return (rr*math.cos(th),4.65+R*.74*math.sin(el),rr*math.sin(th))
        v0,v1,v2,v3=dome_pt(t0,e0),dome_pt(t1,e0),dome_pt(t1,e1),dome_pt(t0,e1)
        dome.facet("Orange dome panel",[v0,v1,v2,v3],("orange","orange_light","orange_dark")[(i+band)%3 if (i+band)%7==0 else 0])
        if i%4==0:
            dome.rod("Dome radial panel rib",v0,v3,.045,"navy",6)
        dome.rod("Dome horizontal joint",v0,v1,.026,"orange_dark",5)
        if i in (0,31):
            p0,p1=(v0,v3) if i==0 else (v1,v2)
            dome.rod("Blue shutter edge",p0,p1,.115,"blue",8)
            if band%2==0:
                dome.beam("Observing slot fixture",p0,p1,.16,.14,"cream")
            dome_glow.rod("Frenzy red shutter edge",p0,p1,.142,"red_light",8)
a.moving("dome",(0,0,CZ))
a.moving("shutter_lights",(0,0,CZ))

telescope=a.kit("telescope",True)
telescope.rod("Telescope concrete pedestal",(0,.03,CZ),(0,.80,CZ),1.76,"cream",12,1.52)
a.layout["boxes"].append([(0,.64,CZ),(2.65,1.28,2.65),0])
telescope.rod("Equatorial base",(0,.79,CZ),(0,1.28,CZ),1.13,"navy",12,.83)
telescope.rod("Equatorial pier",(0,1.27,CZ),(0,2.28,CZ),.72,"blue",9,.59)
telescope.beam("Equatorial fork",(0,1.85,CZ),(0,4.01,CZ+.52),.79,.74,"blue")
for x in (-.94,.94):
    telescope.beam("Telescope fork arm",(x,2.16,CZ),(x,4.08,CZ+.69),.46,.48,"cobalt")
    telescope.rod("Declination circle",(x-.12,3.94,CZ+.60),(x+.13,3.94,CZ+.60),.57,"navy",14)
    telescope.rod("Yellow declination bearing cap",(x-.12,3.94,CZ+.60),(x+.19,3.94,CZ+.60),.245,"yellow",12)
rear=(0,3.22,CZ-1.79)
front=(0,7.7,CZ+4.74)
telescope.rod("Optical telescope tube",rear,front,1.07,"white",16,1.05)
def along(t):
    return tuple(rear[i]+(front[i]-rear[i])*t for i in range(3))
for t in (.03,.30,.61,.93):
    telescope.rod("Dark tube band",along(t),along(t+.045),1.10,"navy",16)
telescope.rod("Primary objective lip",along(.967),along(1.035),1.13,"blue",16)
telescope.rod("Dark optical glass",along(1.036),along(1.039),.96,"ink",16)
telescope.rod("Optics lens highlight",along(1.039),along(1.041),.66,"cobalt",16)
telescope.rod("Finder scope",(1.01,4.9,CZ+.22),(1.01,6.26,CZ+2.17),.16,"white",9)
telescope.rod("Finder scope eyepiece",(1.01,4.83,CZ+.10),(1.01,4.94,CZ+.28),.20,"navy",9)
for i in range(28):
    t0,t1=i*math.tau/28,(i+1)*math.tau/28
    telescope.rod("Circular cable conduit",pos(t0,2.28,.082),pos(t1,2.28,.082),.048,"yellow",7)

snowcat=a.kit("snowcat")
snowcat.box("Snowcat orange hull",(0,.81,0),(2.46,1.18,4.04),"orange")
snowcat.box("Snowcat cabin",(0,1.74,.81),(2.33,1.30,2.15),"orange")
snowcat.box("Snowcat broad windscreen",(0,1.98,1.91),(2.02,.74,.08),"glass")
snowcat.box("Snowcat screen surround",(0,2.42,.83),(2.38,.12,2.17),"navy")
for x in (-1.31,1.31):
    snowcat.box("Tracked drive unit",(x,.36,0),(.56,.70,4.12),"ink")
    for i in range(6):
        z=-1.64+i*.64
        snowcat.rod("Track road wheel",(x-.30,.38,z),(x+.30,.38,z),.273,"steel",10)
        snowcat.rod("Hub face",(x,.38,z),(x+math.copysign(.325,x),.38,z),.14,"metal",8)
    for i in range(18):
        snowcat.box("Heavy track grouser",(x,.711,-1.92+i*.22),(.60,.038,.08),"metal")
snowcat.box("Snow pusher blade",(0,.47,2.54),(3.52,.86,.28),"steel")
snowcat.box("Snow blade wear strip",(0,.094,2.57),(3.54,.16,.32),"ink")
for x in (-.81,.81):
    snowcat.box("White snowcat headlamp",(x,1.05,1.99),(.43,.19,.09),"light")
    snowcat.box("Roof floodlamp",(x,2.52,1.60),(.32,.13,.15),"light")
for x in (-.52,.52):
    snowcat.box("Tie-down equipment case",(x,1.60,-1.25),(.78,.42,1.02),"yellow" if x<0 else "olive")
a.prop("snowcat",(7.8,0,13.7),(3.53,2.53,5.53),-.32,effect="instrument")

a.solid(yard,"Blue maintenance hut",(-13.55,1.27,15.1),(5.36,2.55,3.9),"blue")
yard.box("Heavy snow blanket on hut",(-13.55,2.61,15.1),(5.55,.25,4.05),"snow")
yard.box("Maintenance shed recess",(-13.55,1.38,17.09),(3.28,2.24,.10),"navy")
for y in (.48,1.10,1.81):
    yard.box("Open ski equipment rack",(-13.45,y,17.20),(2.88,.09,.23),"wood")
    for i in range(4):
        yard.box("Insulated mountain equipment case",(-14.42+i*.69,y+.18,17.25),(.56,.32,.34),
                 ("yellow","olive","red","cobalt")[(i+int(y*4))%4])
yard.box("Avalanche beacon box",(-15.43,1.20,17.15),(.63,.78,.21),"red")
yard.box("Avalanche beacon latch",(-15.43,1.20,17.27),(.12,.21,.055),"white")
a.sign("AvalancheBeacon","beacon",(-15.43,1.38,17.27),(.51,.34))
for i in range(3):
    x=-15.77+i*.32
    yard.beam("Snow shovel shaft",(x,.27,17.66),(x+.24,1.56,17.28),.055,.055,"metal")
    yard.box("Snow shovel blade",(x,.18,17.69),(.27,.36,.09),"red")
yard.box("Hut work light",(-13.57,2.29,17.18),(1.38,.13,.15),"light")
yard.box("Portable generator",(-10.27,.49,14.78),(1.35,.93,.98),"yellow")
yard.box("Generator service grille",(-10.27,.49,15.30),(1.13,.65,.07),"ink")
for i in range(8):
    yard.box("Generator cooling vane",(-10.73+i*.13,.49,15.35),(.045,.53,.035),"metal")
for i in range(3):
    x=-7.08+i*.27
    yard.rod("Ice-covered conduit",(x,.10,8.97),(x,2.50+i*.08,8.97),.085,"metal",8)
    yard.rod("Pipe ice accretion",(x+.025,1.95,9.03),(x+.02,2.44+i*.08,9.03),.097,"ice",6)
    yard.rod("Generator cable",(-9.63+i*.11,.07,14.92),(x,.08,8.97),.055,"yellow" if i<2 else "navy",6)
yard.rod("Cliff viewer stand",(-18.7,.05,-5.2),(-18.7,1.10,-5.2),.105,"blue",9)
yard.rod("Cliff observation binoculars",(-18.7,1.34,-5.54),(-18.7,1.34,-4.88),.19,"white",10)
yard.box("Cliff overlook bench",(-18.5,.57,-2.9),(2.85,.15,.61),"yellow")
for x in (-19.55,-17.47):
    yard.box("Cliff bench support",(x,.28,-2.90),(.11,.56,.52),"blue")

instrument=a.kit("weather_screen")
instrument.box("Louvered weather screen",(0,1.33,0),(1.17,.94,1.11),"white")
instrument.box("Weather screen cap",(0,1.85,0),(1.32,.17,1.26),"snow")
for x in (-.51,.51):
    for z in (-.51,.51):
        instrument.beam("Weather screen legs",(x*1.18,0,z*1.16),(x,1.07,z),.077,.08,"metal")
for j in range(7):
    y=.96+j*.108
    instrument.box("Louver shadow line",(0,y,.568),(1.07,.044,.037),"navy")
    instrument.box("Louver white face",(0,y+.040,.59),(1.08,.048,.07),"white")
a.prop("weather_screen",(18.7,2.38,-2.75),(1.33,1.94,1.31),name="WeatherScreen",effect="instrument")
for x,z in [(19.65,-4.62),(18.0,-5.6),(19.64,-.73)]:
    catwalk.rod("Weather mast",(x,2.38,z),(x,5.26,z),.050,"navy",8)
    catwalk.box("Mast electronics package",(x,3.6,z),(.24,.34,.22),"metal")
catwalk.rod("Cup anemometer arm",(19.1,5.25,-4.62),(20.18,5.25,-4.62),.038,"ink",8)
for x in (19.07,20.20):
    catwalk.rod("Cup anemometer shell",(x,5.11,-4.62),(x,5.39,-4.62),.15,"navy",9,.11)
catwalk.facet("Yellow wind vane",[(18.01,5.22,-5.57),(18.01,4.90,-4.69),(18.01,4.68,-5.57)],"yellow")
for t in range(3):
    phi=t*math.tau/3
    catwalk.rod("Calibration tripod leg",(16.92+.52*math.cos(phi),2.40,-2.08+.52*math.sin(phi)),
                (16.92,3.30,-2.08),.047,"yellow",7)
catwalk.box("Calibration head",(16.92,3.41,-2.08),(.29,.29,.23),"metal")

console=a.kit("console")
console.box("Telescope console base",(0,.46,0),(2.61,.92,.93),"navy")
console.box("Instrument desk counter",(0,.93,.06),(2.76,.16,1.05),"cream")
for x in (-.61,.61):
    console.box("Telemetry terminal",(x,1.34,-.22),(1.02,.61,.25),"blue")
    console.box("Telemetry LCD",(x,1.37,-.085),(.85,.43,.033),"lcd")
    for j in range(5):
        console.box("LCD signal plot",(x-.32+j*.16,1.30+j*.036,-.064),(.07,.026,.024),"cobalt")
for i in range(11):
    console.box("Console mechanical key",(-.59+i*.12,1.028,.30),(.089,.055,.12),"metal")
console.rod("Yellow instrument stool",(0,.02,.89),(0,.48,.89),.074,"steel",8)
console.rod("Yellow stool seat",(0,.49,.89),(0,.58,.89),.27,"yellow",10)
a.prop("console",(-4.05,0,.10),(2.77,1.65,1.41),effect="instrument")
bench=a.kit("star_table")
bench.box("Lens service table",(0,.81,0),(2.44,.16,1.22),"cream")
for x in (-1.02,1.02):
    for z in (-.46,.46):
        bench.box("Service table leg",(x,.39,z),(.093,.78,.10),"navy")
bench.box("Star chart paper",(-.53,.905,0),(1.08,.02,.92),"white")
bench.rod("Printed planisphere disk",(-.53,.923,0),(-.53,.936,0),.38,"blue",20)
for j in range(15):
    x=-.53+math.cos(j*2.41)*(.09+(j%5)*.062)
    z=math.sin(j*2.41)*(.09+(j%5)*.062)
    bench.box("Planisphere printed stars",(x,.942,z),(.033,.01,.033),"cream")
bench.box("Field lens case",(.68,1.04,.06),(.64,.27,.61),"olive")
bench.rod("Spare eyepiece",(.85,.96,-.36),(.85,1.15,-.36),.095,"navy",10)
a.prop("star_table",(3.8,0,4.3),(2.47,1.18,1.25),effect="instrument")
rack=a.kit("optical_rack")
for x in (-.68,.68):
    rack.box("Optical storage upright",(x,.91,0),(.105,1.82,.69),"navy")
for y in (.35,.89,1.43):
    rack.box("Optical storage shelf",(0,y,0),(1.39,.075,.68),"steel")
    for x in (-.38,.34):
        rack.box("Foam-lined lens case",(x,y+.18,0),(.51,.28,.49),"olive")
        rack.box("Lens case brass latch",(x,y+.22,.257),(.095,.095,.06),"yellow")
a.prop("optical_rack",(-7.6,0,-8.1),(1.47,1.83,.72),effect="instrument")
kit=a.kit("field_case")
kit.box("Rugged alpine case",(0,.29,0),(1.16,.57,.92),"olive")
kit.box("High visibility crate lid",(0,.55,0),(1.19,.105,.97),"olive_light")
for x in (-.36,.36):
    kit.box("Equipment case catch",(x,.49,.476),(.13,.20,.10),"yellow")
for x,y,z in [(-14,0,12),(-17,0,-3),(-7.4,0,5.8),(8.5,0,9.9),(8.9,2.38,-5.9),
               (17.5,2.38,-4.6),(15.1,0,-15),(4.8,0,-8)]:
    a.prop("field_case",(x,y,z),(1.20,.61,.98),effect="instrument")

# The warm task light stays in normal mode; red rays animate only in frenzy.
for x,z in [(-6,-5),(6,4),(0,6)]:
    a.spot((x,4.45,z),(x,0,z),"ffe1a7",2.3,7.8,52)
a.spot((6.0,8.2,.2),(18.6,2.38,-.4),"ff4039",8.2,23,12,(.55,.15,4.8),True)
a.spot((-.1,8.0,2),(1.7,0,13.9),"ff5749",7.2,21,13,(5.4,.05,1.5))
a.spot((-2,5,-3),(1,0,-1),"ff2f3d",4.7,13,55,(2,0,1.2))

def g(x,z):
    return (x,.06,z)
a.layout.update(
 start=g(-.15,14.2),heading=0,
 opening=[g(0,7.7),g(-6.1,13.2),g(13.2,11.7),g(-16.8,3.4),g(1,-9.9),g(15.2,-15.8),g(-7.4,-5.9),g(3.1,1.1)],
 spawns=[g(x,z) for x,z in [(-15,10),(-16,2),(-16,-13),(-9,-17),(2,-17),(12,-17),(16,-10),(16,5),
                         (14,13),(-6,18),(-5,-4),(3.5,-5),(0,7.4)]]+[(16.7,2.44,-3.2),(9,2.44,-2.3)],
 respawns=[g(x,z) for x,z in [(-.15,14.2),(-17.4,7.8),(-16,-12),(2,-17),(15,13),(-4.8,-7.5)]]+[(14.9,2.44,-3.8)],
 route=[g(x,z) for x,z in [(-16,-6),(-15,-16),(0,-18),(14,-15),(17,6),(0,12),(0,5.7),(-4,-8)]]
       +[(18.9,2.44,-4.25),(14.1,2.44,-3.1),(8.85,2.44,-3.2)],
 barrels=[g(-6.4,8.5),g(15.5,-14),g(-7.9,-5.8)],comedy=(13.7,0,15.8,0),
 cameras={
  "snowcat-court":[[-.75,1.76,20.1],[.45,4.1,1.0],78],
  "telescope-ring":[[5.5,1.78,5.2],[.2,3.48,-2.3],74],
  "telescope-frenzy":[[5.5,1.78,5.2],[.2,2.24,-2.3],74],
  "weather-deck-frenzy":[[20.65,4.02,-1.63],[9.4,4.37,-2.9],75],
 })
a.write()
