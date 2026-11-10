"""Build the tropical Palm House: glass octagon, canopy deck, lily channel and garden ring."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P={
 "lawn":"7fc25a","lawn_dark":"5fa448","gravel":"dcbd85","gravel_dark":"c9a66f","paving":"d4c3a2",
 "paving_dark":"bba98a","stone":"cdbd9e","stone_dark":"a8977a","brick":"c4573f","brick_dark":"9b3f30",
 "white":"f4f3ec","frame":"e9ebe3","mint":"8fcfae","mint_dark":"5aa585","green":"2f7d55",
 "iron":"2b5a48","water":"3fc7d2","water_deep":"27a4bd","pad":"5bb04c","pink":"f28fb6",
 "palm":"4fae3c","palm_light":"86cf45","palm_dark":"2f8a36","trunk":"b07a45","trunk_dark":"8a5a33",
 "monstera":"2e9a4e","banana":"9ad04a","hedge":"3f9a45","hedge_light":"5bb553",
 "terracotta":"d4744a","terracotta_dark":"a95536","soil":"6b4a35","wood":"b98a5a","wood_dark":"8c6440",
 "coral":"f06a5a","sun":"f6c63e","slate":"4c5872","slate_dark":"3a4459","cream":"efe2c4",
 "brass":"d9a93d","glass":("a7e3ea",.25,0),"mesh":"6e8f86","navy":"2c3a55",
 "grow":("ff4fd8",.4,.9),"lamp":("ffe7b0",.5,.6),
 "bone":"eadfc4","bone_dark":"c4ae86","bone_shadow":"9e8763",
}
a=ArenaKit("palm_house",P,{"sky":"6fb3f2","ambient":"e9f4ff","energy":.6,"sun":"fff3d8",
                           "sun_energy":.64,"sun_rotation":[-48,-28,0]})
ground=a.kit("garden_ground",True)
frame=a.kit("glasshouse_frame",True)
glass=a.kit("glasshouse_glass",True)
deck=a.kit("canopy_deck",True)
interior=a.kit("interior_garden",True)
annex=a.kit("garden_annexes",True)
border=a.kit("garden_border",True)
grow=a.kit("grow_lights")
a.layout["glass_models"]=["glasshouse_glass"]

A=10.0
HALF=A*math.tan(math.pi/8)
CORNER=A/math.cos(math.pi/8)
EAVE=4.6
DECK_Y=2.4

a.solid(ground,"Garden lawn base",(0,-.44,0),(48,.87,48),"lawn")

def flat(kit,label,points,color,y=.012):
    pts=[(x,y,z) for x,z in points]
    (x0,_,z0),(x1,_,z1),(x2,_,z2)=pts[:3]
    if (z1-z0)*(x2-x0)-(x1-x0)*(z2-z0)<0:
        pts.reverse()
    kit.mesh(label,pts,[tuple(range(len(pts)))],color)

def octagon(cx,cz,radius,turn=math.pi/8):
    return [(cx+radius*math.cos(turn+i*math.pi/4),cz+radius*math.sin(turn+i*math.pi/4)) for i in range(8)]

flat(ground,"Surrounding parkland",[(-150,-150),(150,-150),(150,150),(-150,150)],"lawn_dark",-.05)

# Gravel ring, forecourt and service paths drawn as thin flat plates over the lawn.
outer=octagon(0,0,CORNER+4.4)
inner=octagon(0,0,CORNER-.2)
for i in range(8):
    j=(i+1)%8
    flat(ground,"Sand gravel ring path",[outer[i],outer[j],inner[j],inner[i]],"gravel" if i%2 else "gravel_dark")
flat(ground,"Ticket forecourt paving",[(-6,13.6),(6,13.6),(6,21.2),(-6,21.2)],"paving",.016)
for i in range(6):
    flat(ground,"Forecourt joint",[(-6,14.6+i*1.2),(6,14.6+i*1.2),(6,14.66+i*1.2),(-6,14.66+i*1.2)],"paving_dark",.02)
flat(ground,"West tool yard gravel",[(-21.2,-9),(-13.6,-9),(-13.6,9),(-21.2,9)],"gravel",.014)
flat(ground,"North service gravel",[(-14,-21.2),(14,-21.2),(14,-14.4),(-14,-14.4)],"gravel",.014)
flat(ground,"East butterfly path",[(13.6,-7),(18.4,-7),(18.4,7),(13.6,7)],"gravel_dark",.014)
flat(ground,"Glasshouse stone floor",octagon(0,0,CORNER),"paving",.02)
for k in range(-4,5):
    flat(ground,"Floor paving joint",[(k*2.2-.03,-A),(k*2.2+.03,-A),(k*2.2+.03,A),(k*2.2-.03,A)],"paving_dark",.026)

def along(theta,s,radius=A):
    """Point on an octagon face: theta is the outward normal, s the tangent offset."""
    return (radius*math.cos(theta)-s*math.sin(theta),radius*math.sin(theta)+s*math.cos(theta))

def face_box(theta,s0,s1,y0,y1,color,kit=frame,depth=.32,physical=True,label="Glasshouse wall"):
    x,z=along(theta,(s0+s1)/2)
    angle=math.pi/2-theta
    size=(s1-s0,y1-y0,depth)
    if physical:
        a.solid(kit,label,(x,(y0+y1)/2,z),size,color,angle)
    else:
        kit.box(label,(x,(y0+y1)/2,z),size,color,angle)

def glazing(theta,s0,s1,y0,y1):
    p=[along(theta,s0),along(theta,s1)]
    glass.facet("Glasshouse glazing",[(p[0][0],y0,p[0][1]),(p[1][0],y0,p[1][1]),
                                      (p[1][0],y1,p[1][1]),(p[0][0],y1,p[0][1])],"glass")
    for s in [s0+(s1-s0)*t/3 for t in range(4)]:
        x,z=along(theta,s,A+.04)
        frame.box("White glazing mullion",(x,(y0+y1)/2,z),(.09,y1-y0,.12),"frame",math.pi/2-theta)
    for y in (y0,(y0+y1)/2,y1):
        face_box(theta,s0,s1,y-.045,y+.045,"frame",depth=.14,physical=False,label="White glazing transom")

def wall_section(theta,s0,s1,y0=0.0):
    if y0==0:
        face_box(theta,s0,s1,0,1.0,"brick",depth=.40,physical=False,label="Brick dado wall")
        face_box(theta,s0,s1,.98,1.08,"stone",depth=.46,physical=False,label="Stone sill")
        glazing(theta,s0,s1,1.08,EAVE)
    else:
        glazing(theta,s0,s1,y0,EAVE)
    x,z=along(theta,(s0+s1)/2)
    a.layout["boxes"].append([(x,(y0+EAVE)/2,z),(s1-s0,EAVE-y0,.32),math.pi/2-theta])

DOOR=1.55
BREACH=1.62
for k in range(8):
    theta=k*math.pi/4
    if k in (0,2,4,6):
        wall_section(theta,-HALF,-DOOR)
        wall_section(theta,DOOR,HALF)
        x,z=along(theta,0)
        a.layout["boxes"].append([(x,(3.25+EAVE)/2,z),(DOOR*2,EAVE-3.25,.32),math.pi/2-theta])
        face_box(theta,-DOOR,DOOR,3.25,3.4,"frame",depth=.36,physical=False,label="Door head")
        glazing(theta,-DOOR,DOOR,3.4,EAVE)
        for s in (-DOOR,DOOR):
            x,z=along(theta,s,A+.05)
            frame.box("Door jamb",(x,1.62,z),(.22,3.25,.44),"frame",math.pi/2-theta)
        for side in (-1,1):
            x,z=along(theta,side*(DOOR+.55),A+.75)
            leaf_angle=math.pi/2-theta+side*1.1
            frame.box("Open glazed door leaf",(x,1.5,z),(1.25,2.9,.08),"frame",leaf_angle)
            frame.box("Door leaf pane",(x,1.65,z),(1.0,2.2,.1),"mint",leaf_angle)
    elif k==3:
        wall_section(theta,-HALF,-BREACH)
        wall_section(theta,BREACH,HALF)
        x,z=along(theta,0)
        a.layout["boxes"].append([(x,(3.0+EAVE)/2,z),(BREACH*2,EAVE-3.0,.32),math.pi/2-theta])
        face_box(theta,-BREACH,BREACH,3.0,3.1,"frame",depth=.36,physical=False,label="Breach head")
        glazing(theta,-BREACH,BREACH,3.1,EAVE)
    else:
        wall_section(theta,-HALF,HALF)
for i in range(8):
    phi=math.pi/8+i*math.pi/4
    x,z=CORNER*math.cos(phi),CORNER*math.sin(phi)
    frame.rod("Cast iron corner column",(x,0,z),(x,EAVE+.15,z),.2,"frame",8)
    frame.rod("Column plinth",(x,0,z),(x,.55,z),.3,"stone",8)
for i in range(8):
    phi0,phi1=math.pi/8+i*math.pi/4,math.pi/8+(i+1)*math.pi/4
    p0=(CORNER*math.cos(phi0),EAVE+.1,CORNER*math.sin(phi0))
    p1=(CORNER*math.cos(phi1),EAVE+.1,CORNER*math.sin(phi1))
    frame.beam("Eave gutter",p0,p1,.38,.26,"frame")

breach=a.kit("glass_breach")
breach.box("Breach brick dado",(0,.5,0),(BREACH*2,1.0,.38),"brick")
breach.box("Breach stone sill",(0,1.03,0),(BREACH*2+.04,.1,.44),"stone")
breach.box("Low breach glazing",(0,2.04,0),(BREACH*2-.1,1.9,.06),"glass")
for s in (-BREACH/3,BREACH/3):
    breach.box("Breach mullion",(s,2.04,0),(.08,1.9,.12),"frame")
breach.box("Breach transom",(0,2.04,0),(BREACH*2,.08,.12),"frame")
bx,bz=along(3*math.pi/4,0)
a.prop("glass_breach",(bx,0,bz),(BREACH*2,3.0,.4),math.pi/2-3*math.pi/4,name="GlassBreach",effect="glass",structural=True)

# Faceted dome: eight ribs rising from the eave to a raised lantern.
bands=[0,.42,.8,1.12,1.32]
def dome_pt(phi,e):
    r=CORNER*math.cos(e)
    return (r*math.cos(phi),EAVE+.2+4.3*math.sin(e),r*math.sin(phi))
for b in range(len(bands)-1):
    for i in range(8):
        phi0,phi1=math.pi/8+i*math.pi/4,math.pi/8+(i+1)*math.pi/4
        quad=[dome_pt(phi0,bands[b]),dome_pt(phi1,bands[b]),dome_pt(phi1,bands[b+1]),dome_pt(phi0,bands[b+1])]
        glass.facet("Dome glazing",quad,"glass")
        frame.rod("Dome rib",quad[0],quad[3],.085,"frame",6)
        frame.rod("Dome ring",quad[2],quad[3],.06,"frame",6)
        mid0=dome_pt((phi0+phi1)/2,bands[b])
        mid1=dome_pt((phi0+phi1)/2,bands[b+1])
        frame.rod("Dome secondary rib",mid0,mid1,.04,"frame",5)
top=EAVE+.2+4.3*math.sin(bands[-1])
lantern_r=CORNER*math.cos(bands[-1])
for i in range(8):
    phi0,phi1=math.pi/8+i*math.pi/4,math.pi/8+(i+1)*math.pi/4
    for y in (top+.06,top+1.04):
        frame.beam("Lantern ring",(lantern_r*math.cos(phi0),y,lantern_r*math.sin(phi0)),
                   (lantern_r*math.cos(phi1),y,lantern_r*math.sin(phi1)),.16,.2,"frame")
for i in range(8):
    phi=math.pi/8+i*math.pi/4
    frame.rod("Lantern mullion",(lantern_r*math.cos(phi),top+.1,lantern_r*math.sin(phi)),
              (lantern_r*math.cos(phi),top+1.05,lantern_r*math.sin(phi)),.06,"frame",5)
glass.rod("Lantern glazing",(0,top+.15,0),(0,top+.95,0),lantern_r,"glass",8)
glass.rod("Lantern cap glazing",(0,top+1.1,0),(0,top+1.7,0),lantern_r+.25,"glass",8,.25)
frame.rod("Lantern cap rim",(0,top+1.08,0),(0,top+1.16,0),lantern_r+.3,"frame",8)
for i in range(8):
    phi=math.pi/8+i*math.pi/4
    frame.rod("Lantern cap rib",((lantern_r+.25)*math.cos(phi),top+1.12,(lantern_r+.25)*math.sin(phi)),(0,top+1.72,0),.05,"frame",5)
frame.rod("Lantern finial",(0,top+1.7,0),(0,top+2.5,0),.08,"frame",6)
frame.rod("Finial ball",(0,top+2.45,0),(0,top+2.6,0),.16,"brass",8)

# Misting pipe ring hung from the dome base with nozzles over the beds.
for i in range(16):
    phi0,phi1=i*math.tau/16,(i+1)*math.tau/16
    r=7.2
    frame.rod("Misting pipe",(r*math.cos(phi0),EAVE-.05,r*math.sin(phi0)),
              (r*math.cos(phi1),EAVE-.05,r*math.sin(phi1)),.04,"navy",5)
    frame.rod("Mist nozzle",(r*math.cos(phi0),EAVE-.3,r*math.sin(phi0)),(r*math.cos(phi0),EAVE-.05,r*math.sin(phi0)),.05,"brass",6)
for i in range(8):
    phi=math.pi/8+i*math.pi/4
    frame.rod("Pipe hanger",(7.2*math.cos(phi),EAVE-.05,7.2*math.sin(phi)),dome_pt(phi,.42),.025,"navy",4)

# Grow-light bars only appear in frenzy.
for i in range(8):
    phi=i*math.pi/4
    x,z=6.3*math.cos(phi),6.3*math.sin(phi)
    grow.box("Grow light bar",(x,EAVE-.42,z),(2.2,.12,.32),"grow",math.pi/2-phi)
a.moving("grow_lights",(0,0,0))

# Canopy deck across the dome with a west stair and an east ramp to the side doors.
DW=1.5
RAMP_FOOT=A-.15
FLAT=3.4
a.slab(deck,"Canopy walkway deck",[(-FLAT,DECK_Y,DW),(FLAT,DECK_Y,DW),(FLAT,DECK_Y,-DW),(-FLAT,DECK_Y,-DW)],.24,"mint")
for x in range(-3,4):
    deck.box("Deck plank seam",(x,DECK_Y+.004,0),(.05,.01,DW*2-.1),"mint_dark")
a.slab(deck,"East planter ramp",[(FLAT,DECK_Y,DW),(RAMP_FOOT,0,DW),(RAMP_FOOT,0,-DW),(FLAT,DECK_Y,-DW)],.24,"paving")
a.slab(deck,"West garden stair",[(-RAMP_FOOT,0,DW),(-FLAT,DECK_Y,DW),(-FLAT,DECK_Y,-DW),(-RAMP_FOOT,0,-DW)],.24,"stone")
steps=14
for i in range(steps):
    x0=-RAMP_FOOT+(RAMP_FOOT-FLAT)*i/steps
    x1=-RAMP_FOOT+(RAMP_FOOT-FLAT)*(i+1)/steps
    y=DECK_Y*(i+1)/steps
    deck.box("Stone stair tread",((x0+x1)/2,y-.08,0),(x1-x0+.02,.16,DW*2),"stone" if i%2 else "stone_dark")
def rail(p0,p1,collision=True):
    x0,y0,z0=p0
    x1,y1,z1=p1
    length=math.dist((x0,z0),(x1,z1))
    count=max(2,math.ceil(length/1.2)+1)
    for j in range(count):
        t=j/(count-1)
        x,y,z=(p0[i]+(p1[i]-p0[i])*t for i in range(3))
        deck.box("Mint rail post",(x,y+.55,z),(.08,1.1,.08),"mint_dark")
    for dy in (.5,1.06):
        deck.beam("Mint handrail",(x0,y0+dy,z0),(x1,y1+dy,z1),.08,.07,"mint")
    if collision:
        dx,dz=(z1-z0)*.05/length,(x0-x1)*.05/length
        a.layout["slabs"].append([[(x0-dx,y0+1.1,z0-dz),(x0+dx,y0+1.1,z0+dz),
                                   (x1+dx,y1+1.1,z1+dz),(x1-dx,y1+1.1,z1-dz)],1.14])
for z in (-DW,DW):
    rail((-FLAT,DECK_Y,z),(FLAT,DECK_Y,z))
    rail((FLAT,DECK_Y,z),(RAMP_FOOT-2.2,DECK_Y*2.2/(RAMP_FOOT-FLAT),z))
    rail((-FLAT,DECK_Y,z),(-RAMP_FOOT+2.2,DECK_Y*2.2/(RAMP_FOOT-FLAT),z))
for x in (-FLAT+.2,FLAT-.2,-1.4,1.4):
    for z in (-DW+.15,DW-.15):
        deck.rod("White deck column",(x,0,z),(x,DECK_Y-.24,z),.11,"white",8)
a.layout["boxes"].extend([[(x,(DECK_Y-.24)/2,z),(.24,DECK_Y-.24,.24),0] for x in (-FLAT+.2,FLAT-.2) for z in (-DW+.15,DW-.15)])
deck.box("Humidity gauge post plate",(-FLAT+.2,DECK_Y+1.45,-DW-.05),(.36,.5,.06),"white")
deck.rod("Humidity gauge dial",(-FLAT+.2,DECK_Y+1.48,-DW-.08),(-FLAT+.2,DECK_Y+1.48,-DW-.14),.2,"green",14)
deck.rod("Humidity gauge face",(-FLAT+.2,DECK_Y+1.48,-DW-.14),(-FLAT+.2,DECK_Y+1.48,-DW-.16),.16,"cream",14)

# Lily channel under the deck. Low stone curbs split the floor; two footbridges cross it.
CH=1.1
Z0,Z1=-7.0,6.4
flat(interior,"Lily channel water",[(-CH,Z0),(CH,Z0),(CH,Z1),(-CH,Z1)],"water",.09)
flat(interior,"Channel deep stripe",[(-.45,Z0),(.45,Z0),(.45,Z1),(-.45,Z1)],"water_deep",.095)
BRIDGES=(4.0,-4.8)
def curb(x,z0,z1):
    if z1-z0>.05:
        a.solid(interior,"Lily channel stone curb",(x,.31,(z0+z1)/2),(.36,.62,z1-z0),"stone")
for x in (-CH-.18,CH+.18):
    edges=[Z0]+[v for b in sorted(BRIDGES) for v in (b-1.0,b+1.0)]+[Z1]
    for j in range(0,len(edges),2):
        curb(x,edges[j],edges[j+1])
for z in (Z0-.18,Z1+.18):
    a.solid(interior,"Channel end curb",(0,.31,z),(CH*2+.72,.62,.36),"stone")
for zb in BRIDGES:
    a.slab(interior,"Stone footbridge",[(-CH-.4,.42,zb+1),(CH+.4,.42,zb+1),(CH+.4,.42,zb-1),(-CH-.4,.42,zb-1)],.42,"stone")
    for side in (-1,1):
        x0,x1=side*(CH+.4),side*(CH+1.85)
        quad=[(x0,.42,zb+1),(x1,0,zb+1),(x1,0,zb-1),(x0,.42,zb-1)]
        if side>0:
            quad=[(x1,0,zb+1),(x0,.42,zb+1),(x0,.42,zb-1),(x1,0,zb-1)]
        a.slab(interior,"Footbridge approach",quad,.3,"stone_dark")
    for z in (zb-1.07,zb+1.07):
        a.solid(interior,"Footbridge parapet",(0,.4,z),((CH+1.85)*2,.8,.14),"stone_dark")
for i,(x,z) in enumerate([(-.5,-6),(.4,-2.8),(-.3,1.2),(.5,2.6),(-.4,5.8),(.3,-.6),(-.5,-3.6)]):
    interior.rod("Lily pad",(x,.095,z),(x,.11,z),.32+.06*(i%3),"pad",10)
    if i%2==0:
        interior.rod("Lily flower",(x+.1,.11,z),(x+.1,.24,z),.12,"pink",6,.05)

def palm(kit,x,z,height,base=0.0,lean=(.0,.0),collide=True,crown=1.0):
    top=(x+lean[0],base+height,z+lean[1])
    kit.rod("Palm trunk",(x,base,z),top,.24,"trunk",7,.17)
    for t in (.25,.5,.75):
        p=(x+lean[0]*t,base+height*t,z+lean[1]*t)
        kit.rod("Trunk ring",p,(p[0],p[1]+.1,p[2]),.25,"trunk_dark",7)
    for i in range(9):
        phi=i*math.tau/9+x*.37
        length=(2.6+(i%3)*.35)*crown
        tip=(top[0]+math.cos(phi)*length,top[1]-.7-(i%2)*.3,top[2]+math.sin(phi)*length)
        side=(-math.sin(phi)*.5*crown,0,math.cos(phi)*.5*crown)
        mid=(top[0]+math.cos(phi)*length*.55,top[1]+.25,top[2]+math.sin(phi)*length*.55)
        color=("palm","palm_light","palm_dark")[i%3]
        kit.facet("Palm frond",[top,(mid[0]+side[0],mid[1],mid[2]+side[2]),tip],color)
        kit.facet("Palm frond",[top,tip,(mid[0]-side[0],mid[1]-.12,mid[2]-side[2])],"palm_dark" if i%2 else "palm")
    if collide:
        a.layout["boxes"].append([(x,base+height/2,z),(.42,height,.42),0])

def leafy(kit,x,y,z,count,size,color,lift=.9):
    for i in range(count):
        phi=i*math.tau/count+z*.5
        root=(x,y,z)
        tip=(x+math.cos(phi)*size,y+lift,z+math.sin(phi)*size)
        wide=(-math.sin(phi)*size*.4,0,math.cos(phi)*size*.4)
        mid=(x+math.cos(phi)*size*.55,y+lift*.95,z+math.sin(phi)*size*.55)
        kit.facet("Broad tropical leaf",[root,(mid[0]+wide[0],mid[1],mid[2]+wide[2]),tip,
                                         (mid[0]-wide[0],mid[1],mid[2]-wide[2])],color if i%2 else "palm_dark")

def flowers(kit,x,y,z,count=5,spread=.6):
    for i in range(count):
        phi=i*2.4
        r=spread*(.3+.7*((i*37)%10)/10)
        kit.rod("Hibiscus bloom",(x+math.cos(phi)*r,y,z+math.sin(phi)*r),
                (x+math.cos(phi)*r,y+.14,z+math.sin(phi)*r),.14,"coral" if i%3 else "sun",5,.06)

def planter(x,z,w,d,h=.9,color="stone"):
    a.solid(interior,"Stone palm planter",(x,h/2,z),(w,h,d),color)
    interior.box("Planter cap",(x,h+.04,z),(w+.12,.1,d+.12),"stone_dark" if color=="stone" else "brick_dark")
    interior.box("Planter soil",(x,h+.06,z),(w-.3,.06,d-.3),"soil")

for x,z,palm_h,size in [(-4.2,6.8,5.0,1.5),(5.6,5.6,5.2,2.6),(-5.6,-5.4,5.1,2.6),(5.6,-5.4,4.9,2.6)]:
    planter(x,z,size,size)
    palm(interior,x,z,palm_h,.9,(-x*.06,-z*.06),False,.8)
    a.layout["boxes"].append([(x,.9+palm_h/2,z),(.42,palm_h,.42),0])
    leafy(interior,x,.95,z,6,size*.5,"monstera")
    flowers(interior,x+.6,1.0,z+.6)
for x,z in [(-7.4,3.0),(7.4,3.0),(-7.4,-3.0),(7.4,-3.0)]:
    planter(x,z,2.3,1.1,.72,"brick")
    leafy(interior,x-.5,.75,z,4,.8,"banana",.7)
    leafy(interior,x+.55,.75,z,4,.7,"monstera",.6)
    flowers(interior,x,.78,z,4,.8)

# Exterior annexes.
# West tool yard: open lean-to shelter backed onto the hedge.
a.solid(annex,"Tool shelter back wall",(-20.6,1.5,0),(.5,3.0,12.0),"cream")
for z in (-6,-2,2,6):
    annex.box("Shelter post",(-17.8,1.4,z),(.18,2.8,.18),"white")
annex.beam("Shelter roof",(-21.0,3.2,0),(-17.1,2.55,0),12.6,.14,"slate")
annex.box("Shelter eave board",(-17.2,2.52,0),(.12,.2,12.4),"white")
for y in (.35,1.0,1.65):
    annex.box("Wall pot shelf",(-20.1,y,-2.2),(.5,.06,5.6),"wood")
    for i in range(6):
        annex.rod("Stacked clay pot",(-20.1,y+.04,-4.6+i*.95),(-20.1,y+.32,-4.6+i*.95),.17,"terracotta",8,.22)
for i in range(4):
    z=1.4+i*.55
    annex.rod("Brass garden tap",(-20.32,1.0,z),(-20.05,1.0,z),.04,"brass",6)
    annex.rod("Tap spout",(-20.05,1.0,z),(-20.05,.85,z),.035,"brass",6)
for i in range(3):
    annex.beam("Hanging rake",(-20.25,.3,4.2+i*.42),(-20.25,1.9,4.2+i*.42),.04,.04,"wood_dark")
    annex.box("Rake head",(-20.25,.25,4.2+i*.42),(.08,.12,.34),"navy")

# North: brick boiler house with chimney, potting shed with a glass lean-to.
a.solid(annex,"Brick boiler house",(9.5,2.2,-18.5),(8.0,4.4,5.4),"brick")
annex.beam("Boiler house roof ridge",(5.4,6.0,-18.5),(13.6,6.0,-18.5),.3,.2,"slate_dark")
for side in (-1,1):
    p=[(5.3,4.4,-18.5+side*2.95),(13.7,4.4,-18.5+side*2.95),(13.7,6.0,-18.5),(5.3,6.0,-18.5)]
    annex.facet("Boiler house slate roof",p,"slate")
    annex.facet("Boiler house slate roof",p[::-1],"slate_dark")
for x in (5.5,13.5):
    annex.facet("Brick gable",[(x,4.4,-21.2),(x,4.4,-15.8),(x,6.0,-18.5)],"brick_dark")
    annex.facet("Brick gable",[(x,6.0,-18.5),(x,4.4,-15.8),(x,4.4,-21.2)],"brick_dark")
for x in (7.2,11.8):
    annex.box("Arched boiler window",(x,2.4,-15.77),(1.3,1.8,.08),"slate_dark")
    annex.box("Window frame",(x,2.4,-15.74),(1.46,.1,.06),"white")
    annex.box("Window frame",(x,1.5,-15.74),(1.5,.14,.12),"stone")
annex.box("Boiler house door",(9.5,1.2,-15.76),(1.4,2.4,.08),"green")
annex.rod("Brick chimney",(12.3,4.0,-20.2),(12.3,11.5,-20.2),.75,"brick",4)
annex.rod("Chimney cap",(12.3,11.5,-20.2),(12.3,11.9,-20.2),.9,"stone_dark",4)
for i in range(3):
    annex.rod("Steam pipe",(6.0+i*.35,.1,-15.6),(6.0+i*.35,3.6,-15.6),.09,"navy",6)
annex.rod("Coal bunker",(14.6,0,-16.6),(14.6,1.2,-16.6),.6,"slate_dark",6)
a.solid(annex,"Potting shed",(-9.5,1.45,-19.3),(7.2,2.9,3.8),"cream")
annex.box("Potting shed roof",(-9.5,3.0,-19.3),(7.6,.18,4.2),"slate")
for x in (-11.5,-7.5):
    annex.box("Shed door",(x,1.1,-17.37),(1.1,2.2,.06),"green")
for i in range(6):
    x=-12.6+i*1.25
    annex.beam("Glass lean-to rafter",(x,2.85,-17.4),(x,1.6,-15.6),.07,.07,"white")
glass.facet("Glass lean-to roof",[(-12.7,2.85,-17.4),(-6.3,2.85,-17.4),(-6.3,1.6,-15.6),(-12.7,1.6,-15.6)],"glass")
a.solid(annex,"Lean-to potting bench",(-9.5,.45,-16.4),(6.2,.9,1.3),"wood")
for i in range(8):
    annex.box("Seedling tray",(-12.2+i*.78,.95,-16.4),(.66,.08,.9),"terracotta_dark")
    for j in range(3):
        annex.rod("Seedling",(-12.4+i*.78+j*.2,.98,-16.4),(-12.4+i*.78+j*.2,1.14,-16.4),.07,"palm_light",4,.02)

# East: octagonal butterfly house with screen walls and a north-south walk-through.
BX,BA=16.2,3.0
BH=BA*math.tan(math.pi/8)
def butterfly_face(k,s0,s1):
    theta=k*math.pi/4
    pa=(BX+BA*math.cos(theta)-s0*math.sin(theta),BA*math.sin(theta)+s0*math.cos(theta))
    pb=(BX+BA*math.cos(theta)-s1*math.sin(theta),BA*math.sin(theta)+s1*math.cos(theta))
    cx,cz=(pa[0]+pb[0])/2,(pa[1]+pb[1])/2
    angle=math.pi/2-theta
    a.solid(annex,"Butterfly house brick plinth",(cx,.3,cz),(s1-s0,.6,.3),"brick",angle)
    a.layout["boxes"].append([(cx,1.6,cz),(s1-s0,2.6,.24),angle])
    annex.box("Butterfly screen mesh",(cx,1.75,cz),(s1-s0,2.3,.06),"mesh",angle)
    annex.box("Screen top rail",(cx,2.92,cz),(s1-s0,.1,.14),"white",angle)
for k in range(8):
    if k in (2,6):
        butterfly_face(k,-BH,-.95)
        butterfly_face(k,.95,BH)
        theta=k*math.pi/4
        for s in (-.95,.95):
            x,z=BX+BA*math.cos(theta)-s*math.sin(theta),BA*math.sin(theta)+s*math.cos(theta)
            annex.box("Butterfly door post",(x,1.5,z),(.14,3.0,.2),"white")
        annex.box("Butterfly door header",(BX,2.95,BA*math.sin(theta)),(2.1,.14,.22),"white")
        annex.box("Open screen door",(BX+1.35,1.3,BA*math.sin(theta)*1.18),(.06,2.4,.9),"mesh")
    else:
        butterfly_face(k,-BH,BH)
for i in range(8):
    phi=math.pi/8+i*math.pi/4
    x,z=BX+BA/math.cos(math.pi/8)*math.cos(phi),BA/math.cos(math.pi/8)*math.sin(phi)
    annex.rod("Butterfly house post",(x,0,z),(x,3.0,z),.08,"white",6)
    annex.rod("Butterfly roof rib",(x,3.0,z),(BX,4.4,0),.05,"white",5)
for i in range(8):
    phi0,phi1=math.pi/8+i*math.pi/4,math.pi/8+(i+1)*math.pi/4
    r=BA/math.cos(math.pi/8)
    glass.facet("Butterfly house roof",[(BX+r*math.cos(phi0),3.0,r*math.sin(phi0)),
                                        (BX+r*math.cos(phi1),3.0,r*math.sin(phi1)),(BX,4.4,0)],"glass")
for x,z in [(BX-1.6,0),(BX+1.6,0)]:
    a.solid(annex,"Butterfly flower bed",(x,.3,z),(.9,.6,2.6),"brick")
    annex.box("Flower bed soil",(x,.62,z),(.7,.05,2.4),"soil")
    for j in range(5):
        flowers(annex,x,.62,z-1.0+j*.5,3,.25)
for i,(x,y,z) in enumerate([(BX-.5,2.1,-1.0),(BX+.4,1.7,.6),(BX+.9,2.4,-.4),(BX-.9,1.9,1.2)]):
    for side in (-1,1):
        annex.facet("Paper butterfly wing",[(x,y,z),(x+side*.22,y+.12,z-.08),(x+side*.18,y-.1,z+.1)],"sun" if i%2 else "coral")

# South forecourt: ticket kiosk, gate pillars, low iron fences.
a.solid(annex,"Ticket kiosk",(-8.2,1.25,17.4),(2.6,2.5,2.6),"cream")
annex.box("Kiosk window",(-8.2,1.45,16.08),(1.6,.8,.06),"glass")
annex.box("Kiosk counter",(-8.2,1.0,15.95),(1.9,.08,.3),"wood")
for i in range(4):
    phi=math.pi/4+i*math.pi/2
    annex.facet("Kiosk green roof",[(-8.2+1.95*math.cos(phi),2.5,17.4+1.95*math.sin(phi)),
                                     (-8.2+1.95*math.cos(phi+math.pi/2),2.5,17.4+1.95*math.sin(phi+math.pi/2)),
                                     (-8.2,3.5,17.4)],"green")
for i in range(10):
    phi=math.pi/4+i*math.pi/2.5
    annex.box("Scalloped kiosk valance",(-8.2+1.35*math.cos(i*math.tau/10),2.38,17.4+1.35*math.sin(i*math.tau/10)),(.5,.18,.06),"white",-i*math.tau/10+math.pi/2)
for x in (-2.6,2.6):
    a.solid(annex,"Gate pillar",(x,1.15,16.4),(.8,2.3,.8),"stone")
    annex.box("Pillar cap",(x,2.4,16.4),(1.0,.2,1.0),"stone_dark")
    annex.rod("Pillar lamp",(x,2.5,16.4),(x,2.95,16.4),.18,"lamp",6)
for side in (-1,1):
    x0,x1=side*3.0,side*8.4
    for j in range(16):
        x=x0+(x1-x0)*j/15
        annex.box("Iron fence spear",(x,.65,16.4),(.05,1.3,.05),"iron")
        annex.rod("Spear tip",(x,1.3,16.4),(x,1.45,16.4),.05,"iron",4,.005)
    for y in (.2,1.1):
        annex.box("Iron fence rail",((x0+x1)/2,y,16.4),(abs(x1-x0),.06,.06),"iron")
    a.layout["boxes"].append([((x0+x1)/2,.65,16.4),(abs(x1-x0),1.3,.12),0])
    for j in range(4):
        x=side*(3.4+j*.6)
        annex.beam("Open iron gate bar",(side*2.2,.1,16.6+j*.55),(side*2.2,1.7,16.6+j*.55),.05,.05,"iron")
for x in (-4.5,4.5):
    a.solid(annex,"Forecourt flower box",(x,.35,19.6),(2.0,.7,1.0),"terracotta")
    flowers(annex,x,.72,19.6,7,.8)

# Hedge and palm boundary.
for x0,z0,x1,z1 in [(-22,-22,22,-22),(-22,22,22,22),(-22,-22,-22,22),(22,-22,22,22)]:
    length=math.dist((x0,z0),(x1,z1))+1.6
    horizontal=z0==z1
    size=(length,2.8,1.6) if horizontal else (1.6,2.8,length)
    a.solid(border,"Clipped boundary hedge",((x0+x1)/2,1.4,(z0+z1)/2),size,"hedge")
    n=int(length/2.4)
    for j in range(n):
        t=(j+.5)/n
        x=x0+(x1-x0)*t
        z=z0+(z1-z0)*t
        border.box("Hedge bump",(x,2.85,z),(2.2 if horizontal else 1.3,.35,1.3 if horizontal else 2.2),"hedge_light" if j%2 else "hedge")
for i in range(28):
    t=i/28*4
    side,u=int(t),(t%1)*2-1
    r=24.4+(i%3)*.9
    x,z=[(u*r,-r),(r,u*r),(-u*r,r),(-r,-u*r)][side]
    palm(border,x,z,6.5+(i%4)*1.1,0,(x*.02,z*.02),False,1.2)
for i in range(28):
    phi=i*math.tau/28
    x,z=55*math.cos(phi),58*math.sin(phi)
    border.rod("Distant tropical canopy",(x,-4,z),(x,5+(i*7%5),z),8+(i%3)*2,("hedge","palm_dark","lawn_dark")[i%3],6,5)
for x,z,h in [(-17.5,-17.5,5.6),(17.5,17.5,6.0),(-17.5,13.5,6.3),(18.5,-12.5,5.8),(-12.5,11.5,5.2)]:
    a.solid(border,"Palm island planter",(x,.3,z),(1.6,.6,1.6),"stone")
    palm(border,x,z,h,.6,(.5,-.3),True,1.05)

# Destructible garden props.
seed=a.kit("seedling_rack")
for x in (-.85,.85):
    for z in (-.35,.35):
        seed.box("Rack leg",(x,.7,z),(.07,1.4,.07),"wood_dark")
for y in (.45,1.05):
    seed.box("Rack shelf",(0,y,0),(1.85,.06,.8),"wood")
    for i in range(3):
        seed.box("Seedling tray",(-.6+i*.6,y+.07,0),(.52,.08,.7),"terracotta_dark")
        for j in range(4):
            seed.rod("Seedling sprout",(-.75+i*.6+j*.1,y+.1,0),(-.75+i*.6+j*.1,y+.28,(j%2-.5)*.3),.05,"palm_light",4,.02)
potrack=a.kit("pot_rack")
for x in (-.7,.7):
    potrack.box("Pot rack upright",(x,.85,0),(.08,1.7,.55),"iron")
for y in (.3,.85,1.4):
    potrack.box("Pot rack slats",(0,y,0),(1.5,.05,.55),"wood")
    for i in range(3):
        potrack.rod("Terracotta pot",(-.45+i*.45,y+.03,0),(-.45+i*.45,y+.33,0),.13,"terracotta",8,.18)
        if y<1:
            leafy(potrack,-.45+i*.45,y+.3,0,4,.22,"monstera",.25)
reel=a.kit("hose_reel")
reel.rod("Hose reel drum",(-.32,.55,0),(.32,.55,0),.42,"green",12)
reel.rod("Coiled hose",(-.26,.55,0),(.26,.55,0),.36,"palm_dark",12)
for x in (-.36,.36):
    reel.rod("Reel frame",(x,0,-.3),(x,.6,0),.04,"navy",5)
    reel.rod("Reel frame",(x,0,.3),(x,.6,0),.04,"navy",5)
reel.rod("Reel handle",(.36,.55,0),(.5,.75,.2),.04,"brass",5)
barrow=a.kit("wheelbarrow")
barrow.slab("Barrow tub",[(-.45,.8,.6),(.45,.8,.6),(.38,.8,-.75),(-.38,.8,-.75)],.06,"green")
barrow.slab("Barrow tub floor",[(-.28,.4,.4),(.28,.4,.4),(.25,.45,-.5),(-.25,.45,-.5)],.06,"green")
for x in (-.42,.42):
    barrow.beam("Barrow tub side",(x,.6,.55),(x*.9,.6,-.7),.06,.4,"green")
barrow.beam("Barrow tub front",(-.38,.6,.6),(.38,.6,.6),.06,.4,"green")
barrow.beam("Barrow tub back",(-.34,.62,-.72),(.34,.62,-.72),.06,.4,"green")
barrow.rod("Barrow wheel",(-.06,.24,.8),(.06,.24,.8),.24,"navy",12)
barrow.rod("Barrow hub",(-.08,.24,.8),(.08,.24,.8),.09,"sun",8)
for x in (-.3,.3):
    barrow.beam("Barrow handle",(x,.45,.7),(x*1.1,.65,-1.15),.05,.05,"wood")
    barrow.beam("Barrow leg",(x,.45,-.4),(x,0,-.45),.05,.05,"navy")
table=a.kit("seedling_table")
table.box("Potting table top",(0,.85,0),(1.9,.08,.9),"wood")
for x in (-.85,.85):
    for z in (-.38,.38):
        table.box("Table leg",(x,.42,z),(.08,.84,.08),"wood_dark")
for i in range(3):
    table.box("Tray of seedlings",(-.6+i*.6,.93,0),(.52,.08,.75),"terracotta_dark")
    leafy(table,-.6+i*.6,.97,0,5,.2,"palm_light",.18)
table.rod("Watering can",(.5,.9,.3),(.5,1.15,.3),.13,"green",8)
table.beam("Watering can spout",(.6,1.05,.3),(.85,1.2,.3),.03,.03,"green")
label=a.kit("label_board")
label.beam("Label board leg",(-.35,0,0),(-.3,.75,-.05),.05,.05,"iron")
label.beam("Label board leg",(.35,0,0),(.3,.75,-.05),.05,.05,"iron")
label.box("Plant label board",(0,.85,0),(.9,.7,.05),"green")
label.box("Plant label panel",(0,.85,.03),(.78,.58,.02),"cream")
leafy(label,0,.82,.05,5,.18,"monstera",.16)
crate=a.kit("pot_crate")
crate.box("Slatted crate",(0,.3,0),(1.0,.6,.7),"wood")
for y in (.15,.45):
    crate.box("Crate slat",(0,y,.36),(1.02,.1,.02),"wood_dark")
for i in range(3):
    crate.rod("Crated pot",(-.3+i*.3,.6,0),(-.3+i*.3,.8,0),.12,"terracotta",8,.15)
cart=a.kit("tool_cart")
cart.box("Tool cart bed",(0,.6,0),(1.4,.12,.8),"navy")
cart.box("Fertiliser sacks",(-.3,.85,0),(.6,.38,.6),"cream")
cart.box("Sack band",(-.3,.86,.31),(.6,.12,.02),"green")
cart.rod("Compost bin",(.35,.66,0),(.35,1.1,0),.26,"palm_dark",8)
for x in (-.55,.55):
    for z in (-.32,.32):
        cart.rod("Cart wheel",(x,.15,z-.06),(x,.15,z+.06),.15,"slate_dark",8)

for asset,at,size,angle,name in [
    ("seedling_rack",(-9.9,0,6.0),(1.95,1.45,.85),math.pi/4,"SeedlingRack"),
    ("pot_rack",(-18.6,0,-6.6),(1.55,1.75,.6),math.pi/2,""),
    ("pot_rack",(-18.6,0,6.8),(1.55,1.75,.6),math.pi/2,""),
    ("hose_reel",(-16.4,0,-3.6),(.8,1.0,.8),.2,""),
    ("hose_reel",(-12.8,0,-13.2),(.8,1.0,.8),1.1,""),
    ("hose_reel",(13.0,0,-12.4),(.8,1.0,.8),-.4,""),
    ("wheelbarrow",(-15.5,0,2.6),(1.0,.9,2.1),2.4,""),
    ("wheelbarrow",(3.6,0,13.2),(1.0,.9,2.1),-.7,""),
    ("seedling_table",(-15.8,0,-1.0),(1.95,1.2,.95),math.pi/2,""),
    ("seedling_table",(-2.4,0,-15.0),(1.95,1.2,.95),0,""),
    ("seedling_table",(-12.0,0,-8.6),(1.95,1.2,.95),.6,""),
    ("label_board",(-4.2,0,15.5),(.95,1.0,.4),0,""),
    ("label_board",(4.2,0,15.5),(.95,1.0,.4),0,""),
    ("label_board",(13.6,0,4.4),(.95,1.0,.4),-math.pi/2,""),
    ("pot_crate",(-2.7,0,-8.5),(1.0,.82,.72),.3,""),
    ("pot_crate",(2.8,0,8.5),(1.0,.82,.72),-.2,""),
    ("pot_crate",(3.9,0,-2.7),(1.0,.82,.72),0,""),
    ("pot_crate",(-3.9,0,2.7),(1.0,.82,.72),0,""),
    ("pot_crate",(19.4,0,-8.2),(1.0,.82,.72),.5,""),
    ("tool_cart",(-6.0,0,-13.4),(1.5,1.15,.95),.3,""),
    ("tool_cart",(12.4,0,7.6),(1.5,1.15,.95),-.9,""),
    ("pot_crate",(-13.2,0,13.6),(1.0,.82,.72),.8,""),
]:
    effect="glass" if asset=="glass_breach" else "garden"
    a.prop(asset,at,size,angle,name=name,effect=effect)

# Magenta grow lights sweep the interior during frenzy. They stay off in daylight.
# A tall, thin T. rex fossil rears up from a plinth in the lily channel. Its skull
# hangs over the centre of the dome, above head height on the canopy deck.
fossil=a.kit("trex_fossil",True)
PZ0,PZ1=-3.3,-1.85
PLINTH=.62
BONE=1.65
def bone_rod(label,p,q,r,color,sides=6,r2=None):
    fossil.rod(label,p,q,r*BONE,color,sides,(r2 or r)*BONE)
a.solid(fossil,"Fossil plinth",(0,PLINTH/2,(PZ0+PZ1)/2),(1.8,PLINTH,PZ1-PZ0),"stone_dark")
fossil.box("Plinth cap",(0,PLINTH+.04,(PZ0+PZ1)/2),(1.92,.08,PZ1-PZ0+.12),"stone")
fossil.box("Brass plinth plaque",(0,.34,PZ1+.005),(.7,.26,.03),"brass")
a.layout["boxes"].append([(0,PLINTH+1.7,-2.55),(.62,3.4,.5),0])

def spine(points,radius,color="bone",sides=6,taper=1.0):
    for i in range(len(points)-1):
        r0=radius*(1-(1-taper)*i/(len(points)-1))
        r1=radius*(1-(1-taper)*(i+1)/(len(points)-1))
        bone_rod("Fossil bone",points[i],points[i+1],r0,color,sides,r1)

def lerp(p,q,t):
    return tuple(p[k]+(q[k]-p[k])*t for k in range(3))

HIP=(0,PLINTH+3.05,-2.55)
for side in (-1,1):
    x=side*.34
    knee=(x,PLINTH+1.75,-2.05)
    ankle=(x*1.05,PLINTH+.62,-2.62)
    foot=(x*1.08,PLINTH+.08,-2.22)
    bone_rod("Fossil femur",(x*.6,HIP[1]-.1,HIP[2]),knee,.12,"bone",7,.09)
    bone_rod("Fossil shin",knee,ankle,.085,"bone",7,.07)
    bone_rod("Fossil metatarsal",ankle,foot,.07,"bone_dark",6,.06)
    bone_rod("Fossil knee cap",(knee[0],knee[1]-.06,knee[2]),(knee[0],knee[1]+.08,knee[2]+.03),.13,"bone_dark",7)
    for toe in (-.16,0,.16):
        tip=(foot[0]+toe*side,PLINTH+.05,foot[2]+.42)
        bone_rod("Fossil toe",foot,tip,.045,"bone",5,.025)
    fossil.rod("Mount rod",(x*.5,PLINTH,-2.9),(x*.5,HIP[1]-.15,HIP[2]-.12),.025,"navy",5)
bone_rod("Fossil pelvis",(-.38,HIP[1],HIP[2]),(.38,HIP[1],HIP[2]),.15,"bone_dark",7)
bone_rod("Fossil pubic boot",(0,HIP[1]-.05,HIP[2]+.05),(0,HIP[1]-.85,HIP[2]+.45),.09,"bone",6,.13)

# Upright, almost vertical back: the thin old-fashioned museum pose.
back=[HIP,(0,HIP[1]+.8,-2.42),(0,HIP[1]+1.6,-2.2),(0,HIP[1]+2.25,-1.95)]
neck=[back[-1],(0,HIP[1]+2.75,-1.55),(0,HIP[1]+3.05,-1.0),(0,HIP[1]+3.12,-.45)]
tail=[HIP,(0,HIP[1]-.35,-2.95),(0,HIP[1]-1.2,-3.12),(0,HIP[1]-2.1,-3.1),(0,PLINTH+.35,-2.9),(.28,PLINTH+.08,-2.6),(.62,PLINTH+.06,-2.15)]
spine(back,.075)
spine(neck,.07,taper=.8)
spine(tail,.11,taper=.25)
for chain,size in ((back,.11),(neck,.09),(tail,.12)):
    for i in range(len(chain)-1):
        for t in (.2,.6):
            p=lerp(chain[i],chain[i+1],t)
            fossil.box("Fossil vertebra",p,(size*2.2,size*1.1,size*1.1),"bone_dark")
            bone_rod("Neural spine",p,(p[0],p[1]+.05,p[2]-size*1.7),.03,"bone",4,.015)
for i in range(7):
    t=.08+i*.13
    base=lerp(back[0],back[-1],t) if t<1 else back[-1]
    length=.35+.45*math.sin(math.pi*min(1,(i+1)/7))
    for side in (-1,1):
        mid=(side*(.18+length*.55),base[1]-.16,base[2]+length*.5)
        tip=(side*.06,base[1]-.4-length*.15,base[2]+length*.95)
        bone_rod("Fossil rib",base,mid,.028,"bone",5,.024)
        bone_rod("Fossil rib",mid,tip,.024,"bone",5,.016)
shoulder=back[-1]
for side in (-1,1):
    elbow=(side*.24,shoulder[1]-.22,shoulder[2]+.28)
    hand=(side*.2,shoulder[1]-.18,shoulder[2]+.55)
    bone_rod("Fossil scapula",(0,shoulder[1]+.05,shoulder[2]-.08),(side*.2,shoulder[1]-.08,shoulder[2]+.1),.05,"bone_dark",5)
    bone_rod("Tiny arm",(side*.2,shoulder[1]-.08,shoulder[2]+.1),elbow,.035,"bone",5,.03)
    bone_rod("Tiny forearm",elbow,hand,.03,"bone",5,.025)
    for claw in (-.04,.04):
        bone_rod("Two-finger claw",hand,(hand[0]+claw,hand[1]-.1,hand[2]+.12),.018,"bone_dark",4,.008)

# Skull points south, jaws slightly open, over the walkway.
SK=neck[-1]
S=1.45
top=[(-.2*S,SK[1]+.22*S,SK[2]),(.2*S,SK[1]+.22*S,SK[2]),(.12*S,SK[1]+.12*S,SK[2]+.95*S),(-.12*S,SK[1]+.12*S,SK[2]+.95*S)]
low=[(-.24*S,SK[1]-.18*S,SK[2]),(.24*S,SK[1]-.18*S,SK[2]),(.14*S,SK[1]-.08*S,SK[2]+.98*S),(-.14*S,SK[1]-.08*S,SK[2]+.98*S)]
for quad in (top,low[::-1],[top[0],top[1],low[1],low[0]],[top[2],top[3],low[3],low[2]],
             [top[1],top[2],low[2],low[1]],[top[3],top[0],low[0],low[3]]):
    fossil.facet("Fossil skull",quad,"bone")
for side in (-1,1):
    fossil.facet("Skull window",[(side*.205*S,SK[1]+.12*S,SK[2]+.12*S),(side*.18*S,SK[1]+.14*S,SK[2]+.42*S),
                                 (side*.17*S,SK[1]-.06*S,SK[2]+.4*S),(side*.2*S,SK[1]-.08*S,SK[2]+.16*S)],"bone_shadow")
    fossil.facet("Eye socket",[(side*.19*S,SK[1]+.2*S,SK[2]+.18*S),(side*.18*S,SK[1]+.2*S,SK[2]+.34*S),(side*.19*S,SK[1]+.06*S,SK[2]+.26*S)],"navy")
jaw=(0,SK[1]-.24*S,SK[2]+.06*S)
bone_rod("Fossil lower jaw",(-.2*S,jaw[1],jaw[2]),(-.11*S,jaw[1]-.22*S,SK[2]+.9*S),.05,"bone_dark",5,.035)
bone_rod("Fossil lower jaw",(.2*S,jaw[1],jaw[2]),(.11*S,jaw[1]-.22*S,SK[2]+.9*S),.05,"bone_dark",5,.035)
for i in range(6):
    t=.2+i*.13
    for side in (-1,1):
        x=side*(.2-.07*t)*S
        p=(x,SK[1]-.1*S+.03*t,SK[2]+(.05+.9*t)*S)
        bone_rod("Fossil tooth",p,(x,p[1]-.12*S,p[2]+.02),.025,"cream",4,.004)

for i,(x,z,tx,tz) in enumerate([(-4,-4,-5.5,5.6),(4,4,5.6,-5.4),(4,-4,-5.6,-5.4),(-4,4,5.6,5.6)]):
    a.spot((x,EAVE+2.6,z),(tx,0,tz),"ff4fd8" if i%2 else "b85cff",6.4,13,34,(2.4,0,2.4))
a.spot((0,EAVE+3.8,0),(0,DECK_Y,0),"ff6ae6",7.0,12,30,(3.0,0,.8),True)

def g(x,z,y=0.0):
    return (x,y+.06,z)
a.layout.update(
 start=g(0,19.4),heading=0,
 opening=[g(0,12.6),g(-7.6,12.2),g(9.4,11.4),g(-15.4,5.2),g(15.6,-4.6),g(4.6,8.8),g(-3.2,-7.4),g(-10.6,-11.8)],
 spawns=[g(x,z) for x,z in [(-18,-16),(-18,10),(-17,-6),(-11,-13),(1,-16),(16,-16),(19,-4),(19,8),
                           (13,16),(-14,17),(-5,-7.5),(5,-7.5),(-3.2,8.4),(3.6,2.6)]]+[g(-1.8,0,DECK_Y),g(1.8,0,DECK_Y)],
 respawns=[g(0,19.4),g(-17,12),g(-16,-16),(16.4,.06,0),g(16,16),g(0,-14),g(1.8,0,DECK_Y)],
 route=[g(x,z) for x,z in [(-11,15),(-17,0),(-16,-16),(0,-13),(16,-15),(16.2,-1),(16,14),(4,12),(2.2,6),(2.2,0),
                           (2.4,-6),(-8.8,-5.8),(-8.9,6.4)]]+[g(-8.4,0,DECK_Y*(RAMP_FOOT-8.4)/(RAMP_FOOT-FLAT)),g(0,0,DECK_Y),
                                          g(8.4,0,DECK_Y*(RAMP_FOOT-8.4)/(RAMP_FOOT-FLAT))],
 barrels=[g(-14.3,-11.0),g(14.6,-11.4),g(-11.6,13.2)],comedy=(13.4,0,15.8,0),
 cameras={
  "forecourt":[[0,1.72,20.6],[0,3.6,0],76],
  "canopy-walk":[[-3.0,DECK_Y+1.65,.2],[9.5,DECK_Y+.6,0],74],
  "trex-fossil":[[3.9,1.72,-7.4],[0,4.5,-1.6],72],
  "thumbnail":[[11.8,2.1,15.6],[-.6,3.9,-1.2],56],
  "tool-yard-frenzy":[[-14.6,1.75,9.2],[-6.4,2.2,5.6],78],
 })
a.write()
