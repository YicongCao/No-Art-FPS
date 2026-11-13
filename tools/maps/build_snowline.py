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
shutter_left=a.kit("shutter_left")
shutter_right=a.kit("shutter_right")
dome_glow=a.kit("shutter_lights")
CZ=-2.7
R=11.55
a.solid(terrain,"Compact snowy mountain pad",(0,-.44,0),(46,.87,48),"snow")

def snowbank(x,z,w,d,height):
    ring=[]
    for i in range(7):
        angle=i*math.tau/7
        spread=(.84,1.0,.95,.78,1.06,.92,1.05)[i]
        ring.append((x+math.cos(angle)*w*.5*spread,.008,z+math.sin(angle)*d*.5*spread))
    peak=(x+w*.12,height,z-d*.13)
    for i,p in enumerate(ring):
        terrain.facet("Wind sculpted snow drift",[peak,p,ring[(i+1)%7]],("frost","snow_lit","snow")[i%3])

for x,z,w,d in [(-16,-17,5,3),(13,-17,5,4),(-17,-6,5,3),(14,9,5,3),(-16,14,7,4),(16,19,8,4),(-9,21,5,3)]:
    snowbank(x,z,w,d,.26)
for x,z,w,d,h in [(-3.34,9.9,2.1,2.7,.30),(3.38,10.0,2.2,2.3,.33),
                  (-4.48,10.9,2.0,3.0,.22),(4.34,10.75,1.7,2.9,.24)]:
    snowbank(x,z,w,d,h)

for i in range(22):
    z=15.8+i*.27
    x=8.45+math.sin(i*.071)*.95
    for dx in (-.92,.92):
        track=x+dx
        terrain.box("Compacted snowcat rut",(track,.006,z),(.44,.017,.285),"frost",.10)
        terrain.box("Snowcat tread imprint",(track,.021,z),(.33,.018,.088),"ice",.18)
        for side in (-1,1):
            if (i+side)%3!=0:
                terrain.box("Snow pushed up by track",(track+side*.22,.047,z),
                            (.10,.090,.27),"snow_lit",.10)
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
    if i in (3, 8):
        terrain.chipped("Avalanche fence post",(x,.72,-22.5),(.18,1.44,.18),"wood",chips=[((1.0,1.0,1.0),.09)])
    else:
        terrain.box("Avalanche fence post",(x,.78,-22.5),(.18,1.56,.18),"wood")
    for y in (.38,.85,1.32):
        if i == 4 and y > 1.2:
            terrain.chipped("Broken snow fence plank",(x+1.05,y-.03,-22.5),(2.10,.25,.15),"wood",angle=.06)
        else:
            terrain.box("Anti-drift timber snow fence",(x+1.6,y,-22.5),(3.28,.27,.15),"wood")

# Faceted nearby rock masses and more distant layered mountain peaks.
for i in range(31):
    th=i*math.tau/31
    x,z=math.cos(th)*27.5,math.sin(th)*30
    h=2.2+(i*7%9)*.70
    ridge.rod("Alpine outcrop",(x,-5,z),(x+math.cos(th)*1.75,h,z+math.sin(th)*1.3),
              4.6+(i%4),("rock","dark_rock","light_rock")[i%3],5,1.9)
    lower=[]
    upper=[]
    for j in range(5):
        angle=j*math.tau/5+th
        lower.append((x+math.cos(th)*1.7+math.cos(angle)*2.43,h-.42-((i+2*j)%4)*.24,
                      z+math.sin(th)*1.27+math.sin(angle)*2.43))
        upper.append((x+math.cos(th)*1.75+math.cos(angle)*1.95,h+.11+(j%2)*.12,
                      z+math.sin(th)*1.3+math.sin(angle)*1.95))
    for j in range(5):
        k=(j+1)%5
        ridge.facet("Irregular snow overhang",[lower[j],lower[k],upper[k],upper[j]],"frost" if j%2 else "snow_lit")
    ridge.facet("Snow cap crown",upper,"snow_lit")
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
        a.layout["boxes"].append([(x,y,z),(1.827,4.56,.29),angle])
        px,_,pz=pos(th,11.46,0)
        building.plinth("Drum base plinth",(px,.17,pz),1.85,.34,.42,"cobalt",angle=angle,flare=.035)
        building.box("Segmented drum wall",(x,y+.12,z),(1.79,4.32,.29),"orange" if i%3 else "orange_light",angle,taper=(.01,.03))
        building.box("Drum vertical rib",(pos(th-.5*math.tau/n,11.48,2.30)),(.09,4.28,.36),"navy",angle)
        building.box("Drum wall seam",(x,2.31,z),(1.82,.065,.40),"orange_dark",angle)
        xo_face,_,zo_face=pos(th,11.58,0)
        if i in (3, 14, 28, 35):
            building.seam((xo_face,1.42,zo_face),1.28,1.10,angle,"orange_dark","cream",tie_color="steel")
        elif i in (6, 17, 31):
            building.patch_plate((xo_face,1.36,zo_face),.96,.68,angle,"steel","navy")
        if i%2==0:
            xo,_,zo=pos(th,11.61,0)
            building.box("Dark ribbon window",(xo,3.27,zo),(1.62,.84,.16),"cobalt",angle)
            building.box("Ribbon window sill",(xo,2.83,zo),(1.68,.11,.24),"steel",angle)
            building.box("Cool ribbon glazing",(xo,3.30,zo),(1.38,.60,.19),"glass",angle)
    else:
        bottom=3.05 if i in (9,10,19,20,24,25) else 4.26
        a.solid(building,"Doorway head over route",(x,(bottom+4.56)/2,z),(1.84,4.56-bottom,.31),"orange",angle)
    t0,t1=i*math.tau/n,(i+1)*math.tau/n
    circle_slab(building,"Drum trim ring",t0,t1,11.18,11.84,4.64,4.64,"blue",False,.26)
    circle_slab(building,"Purple telescope floor",t0,t1,.10,11.54,.02,.02,"purple",False,.12)
building.rod("Telescope floor center",(0,-.04,CZ),(0,.024,CZ),.41,"plum",12)
a.solid(building,"Insulated door header",(0,3.45,9.08),(3.7,.55,1.02),"cobalt")
for x in (-1.77,1.77):
    a.layout["boxes"].append([(x,1.46,9.18),(.29,2.93,1.06),0])
    building.plinth("Entry jamb plinth",(x,.14,9.18),.38,.28,1.14,"navy",flare=.035)
    building.chipped("Insulated south entry jamb",(x,1.52,9.18),(.31,2.80,1.08),"cobalt",taper=(.05,.03),
                     chips=[((-math.copysign(1,x),1.0,1.0),.12)],core_color="steel")
    building.box("Storm door sidelight",(x,1.78,9.68),(.21,1.40,.17),"glass")
building.coping("Blue snow entry awning",(0,3.18,9.56),4.16,.30,2.02,"blue",seg_len=1.38,slant=.18,wear=.72)
terrain.rubble((13.45,0,.45),.38,0.4,("rock","light_rock","cream"),count=3)
for sx in (-1.55, 1.55):
    building.beam("Awning tie rod",(sx,3.88,9.05),(sx,3.26,10.35),.055,.055,"steel")
building.box("Snow on entry awning",(0,3.38,9.58),(3.96,.15,1.88),"snow",taper=(.04,.06))
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
    catwalk.plinth("Weather leg footing",(x,.14,z),.44,.28,.44,"cream",flare=.04)
    catwalk.box("Weather deck steel leg",(x,1.18,z),(.27,2.16,.27),"cobalt",taper=(.06,.06))
    catwalk.beam("Braced weather-deck leg",(x,.28,z),(x+1.3,2.16,z),.14,.13,"navy")
for z in (-4.64,-.68):
    catwalk.box("Blue east access jamb",(11.71,3.40,z),(.66,2.04,.21),"cobalt",taper=(.03,.04))
catwalk.coping("Weather deck entrance canopy",(12.75,4.54,-2.64),3.08,.30,4.20,"blue",seg_len=1.4)
catwalk.box("Canopy snow",(12.76,4.74,-2.65),(2.92,.14,4.04),"snow",taper=(.04,.04))
catwalk.box("Weather door top light",(12.83,4.36,-2.62),(.17,.12,1.48),"light")

# Fixed shell with a south-facing slot. Two curved leaves slide under it along
# concentric tracks. All three meshes share the same rotation center.
slot_center=math.pi*.5
slot_half=.41
theta_start=slot_center+slot_half
theta_span=math.tau-2*slot_half
def dome_pt(theta,elevation,inset=0):
    radius=(R-inset)*math.cos(elevation)
    return (radius*math.cos(theta),4.65+(R*.74-inset)*math.sin(elevation),radius*math.sin(theta))

for band in range(7):
    e0=(band)*1.51/7
    e1=(band+1)*1.51/7
    for i in range(32):
        t0=theta_start+theta_span*i/32
        t1=theta_start+theta_span*(i+1)/32
        v0,v1,v2,v3=dome_pt(t0,e0),dome_pt(t1,e0),dome_pt(t1,e1),dome_pt(t0,e1)
        dome.facet("Orange dome panel",[v0,v1,v2,v3],("orange","orange_light","orange_dark")[(i+band)%3 if (i+band)%7==0 else 0])
        if i%4==0:
            dome.rod("Dome radial panel rib",v0,v3,.045,"navy",6)
        dome.rod("Dome horizontal joint",v0,v1,.026,"orange_dark",5)
        if i in (0,31):
            p0,p1=(v0,v3) if i==0 else (v1,v2)
            edge=t0 if i==0 else t1
            dome.rod("Blue shutter edge",p0,p1,.115,"blue",8)
            inner0,inner1=dome_pt(edge,e0,.20),dome_pt(edge,e1,.20)
            dome.facet("Deep observing slot jamb",[p0,p1,inner1,inner0],"cobalt")
            dome.rod("Inside edge of shutter channel",inner0,inner1,.075,"steel",8)
            dome_glow.rod("Frenzy red shutter edge",p0,p1,.142,"red_light",8)
    for shutter,start,end in [(shutter_left,slot_center-slot_half-.025,slot_center+.001),
                              (shutter_right,slot_center-.001,slot_center+slot_half+.025)]:
        for panel in range(3):
            t0=start+(end-start)*panel/3
            t1=start+(end-start)*(panel+1)/3
            outer=[dome_pt(t,e,.30) for t,e in ((t0,e0),(t1,e0),(t1,e1),(t0,e1))]
            inner=[dome_pt(t,e,.43) for t,e in ((t0,e0),(t1,e0),(t1,e1),(t0,e1))]
            shutter.facet("Sliding shutter outer panel",outer,"orange_light" if panel%2==0 else "orange")
            shutter.facet("Sliding shutter interior liner",inner,"orange_dark")
            edge_indices=(1,2) if shutter is shutter_left else (0,3)
            if panel==(2 if shutter is shutter_left else 0):
                j,k=edge_indices
                shutter.facet("Thick leading shutter edge",[outer[j],outer[k],inner[k],inner[j]],"navy")
                shutter.rod("Shutter leading seam",inner[j],inner[k],.068,"blue",8)
        if band in (0,3,5):
            at=dome_pt((start+end)*.5,e0,.53)
            shutter.rod("Shutter guide roller",(at[0],at[1]-.08,at[2]),(at[0],at[1]+.08,at[2]),.14,"steel",8)

for elevation in (.025,.65,1.08):
    for rail in (.47,.59):
        for i in range(12):
            t0=slot_center-.96+i*.16
            dome.rod("Curved shutter guide rail",dome_pt(t0,elevation,rail),
                     dome_pt(t0+.16,elevation,rail),.047,"steel",7)
dome.rod("Zenith track cap",(0,13.03,0),(0,13.24,0),.77,"cobalt",14,.56)
a.moving("dome",(0,0,CZ))
a.moving("shutter_left",(0,0,CZ))
a.moving("shutter_right",(0,0,CZ))
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
snowcat.box("Snowcat orange hull",(0,.81,0),(2.48,1.18,4.06),"orange",taper=(.04,.03))
snowcat.box("Snowcat cabin",(0,1.76,.81),(2.34,1.32,2.16),"orange",taper=(.08,.06))
snowcat.box("Snowcat broad windscreen",(0,1.98,1.92),(2.02,.74,.09),"glass")
snowcat.coping("Snowcat screen surround",(0,2.44,.83),2.44,.15,2.24,"navy",seg_len=1.2)
for sx in (-1, 1):
    snowcat.box("Engine side louver",(sx*1.25,.92,-.85),(.08,.48,1.42),"navy")
for x in (-1.31,1.31):
    snowcat.box("Tracked drive unit",(x,.36,0),(.58,.72,4.14),"ink",taper=(.04,.02))
    for i in range(6):
        z=-1.64+i*.64
        snowcat.rod("Track road wheel",(x-.30,.38,z),(x+.30,.38,z),.275,"steel",10)
        snowcat.rod("Hub face",(x,.38,z),(x+math.copysign(.33,x),.38,z),.145,"metal",8)
    for i in range(18):
        snowcat.box("Heavy track grouser",(x,.72,-1.92+i*.22),(.60,.042,.085),"metal")
snowcat.box("Snow pusher blade",(0,.47,2.54),(3.54,.88,.30),"steel",taper=(.02,.08))
snowcat.box("Snow blade wear strip",(0,.094,2.57),(3.56,.17,.34),"ink")
for x in (-.81,.81):
    snowcat.box("White snowcat headlamp",(x,1.05,2.00),(.44,.20,.11),"light")
    snowcat.box("Roof floodlamp",(x,2.54,1.60),(.34,.15,.17),"light")
for x in (-.52,.52):
    snowcat.box("Tie-down equipment case",(x,1.60,-1.25),(.80,.44,1.04),"yellow" if x<0 else "olive",taper=(.04,.04))
a.prop("snowcat",(7.8,0,13.7),(3.53,2.53,5.53),-.32,effect="instrument")

a.layout["boxes"].append([(-13.55,1.27,15.1),(5.36,2.55,3.9),0])
yard.plinth("Maintenance hut plinth",(-13.55,.15,15.1),5.52,.30,4.06,"cream",flare=.045)
yard.box("Blue maintenance hut",(-13.55,1.34,15.1),(5.32,2.40,3.86),"blue",taper=(.03,.03))
for sx in (-1, 1):
    for sz in (-1, 1):
        yard.box("Hut corner post",(-13.55+sx*2.58,1.34,15.1+sz*1.85),(.22,2.42,.22),"cobalt",taper=(.05,.05))
yard.coping("Maintenance hut eave",(-13.55,2.54,15.1),5.62,.16,4.16,"navy",seg_len=1.4)
yard.box("Heavy snow blanket on hut",(-13.55,2.70,15.1),(5.56,.26,4.08),"snow",taper=(.04,.04))
yard.box("Maintenance shed recess",(-13.55,1.38,17.09),(3.34,2.24,.14),"navy")
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
console.plinth("Console base foot",(0,.09,0),2.68,.18,.98,"cobalt",flare=.03)
console.box("Telescope console base",(0,.48,0),(2.58,.78,.91),"navy",taper=(.03,.03))
console.coping("Instrument desk counter",(0,.94,.06),2.80,.17,1.08,"cream",seg_len=1.4)
for x in (-.61,.61):
    console.box("Telemetry terminal",(x,1.35,-.22),(1.04,.63,.26),"blue",taper=(.04,.04))
    console.box("Telemetry rear hood",(x,1.34,-.40),(.76,.46,.16),"cobalt",taper=(.14,.14))
    console.box("Telemetry LCD",(x,1.37,-.08),(.85,.43,.04),"lcd")
    for j in range(5):
        console.box("LCD signal plot",(x-.32+j*.16,1.30+j*.036,-.055),(.07,.026,.024),"cobalt")
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
