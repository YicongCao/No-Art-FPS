"""Build the Hogwarts arena and its editable Blender collections."""
import math
from pathlib import Path
import random
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P = {
    "moss":"456038", "grass":"566b36", "turf":"65873f", "turf_dark":"456932", "chalk":"e5dfb0",
    "flagstone":"be9381", "stone":"c9a17b", "trim":"e2bb8f", "grout":"9b746d", "shade":"6e5357",
    "slate":"3b4268", "slate_light":"566082", "slate_dark":"2e354f", "ink":"222941",
    "oak":"674438", "timber":"8d6044", "wood_light":"bd8c5b", "plaster":"e0b895",
    "gold":"dfae56", "bronze":"a86b44", "rock":"5c526f", "rock_light":"766881", "lake":"263956",
    "pine_dark":"263f38", "pine":"365546", "pine_tip":"52704d",
    "amber":("ffbe63",.56,.84), "window":("ed924c",.6,.57), "window_dark":("bb7742",.64,.25),
    "red":"95394d", "red_bright":"b7454f", "yellow":"dcb051", "blue":"385e9d", "green":"326655",
    "pumpkin":"d6773d", "pumpkin_light":"ef9a45", "leaf":"697c40",
}
a = ArenaKit("hogwarts",P,{"sky":"493e70","ambient":"d7c7f4","energy":.56,
                         "sun":"ffbf91","sun_energy":.43,"sun_rotation":[-35,-43,0]})
rng = random.Random(114)
terrain = a.kit("terrain",True)
pitch = a.kit("pitch",True)
stand = a.kit("pavilion",True)
castle = a.kit("castle",True)
village = a.kit("village",True)
hut = a.kit("hut",True)
landscape = a.kit("landscape",True)
lake = a.kit("lake",True)
path_kit = a.kit("paving",True)


def cap(kit,label,x,z,y,r0,r1,height,color,sides=10):
    kit.rod(label,(x,y,z),(x,y+height,z),r0,color,sides,r1)


def slab(kit,label,center,size,color):
    a.solid(kit,label,center,size,color)


def road(points,width, color="flagstone", tiles=True):
    for p,q in zip(points,points[1:]):
        x,y,z=p
        X,Y,Z=q
        distance=math.hypot(X-x,Z-z)
        sx,sz=(Z-z)/distance,-(X-x)/distance
        vertices=[(x-sx*width/2,y,z-sz*width/2),(X-sx*width/2,Y,Z-sz*width/2),
                  (X+sx*width/2,Y,Z+sz*width/2),(x+sx*width/2,y,z+sz*width/2)]
        path_kit.slab("Paved lane",[(u,v+.015,w) for u,v,w in vertices],.13,"grout")
        if not tiles:
            path_kit.slab("Path surface",[(u,v+.015,w) for u,v,w in vertices],.035,color)
            continue
        n=max(1,round(distance/.69))
        across=max(2,round(width/.73))
        yaw=math.atan2(X-x,Z-z)
        for i in range(n):
            t=(i+.5)/n
            for j in range(across):
                cross=(j-(across-1)/2)*width/across
                at=(x+(X-x)*t+sx*cross,y+(Y-y)*t+.034,z+(Z-z)*t+sz*cross)
                path_kit.box("Individual worn paving block",at,(width/across-.045,.044,distance/n-.048),
                             rng.choice((color,color,color,"stone","flagstone")),yaw)


def lamp(kit,x,y,z,scale=1.0):
    kit.plinth("Lantern stone plinth",(x,y+.08*scale,z),.56*scale,.16*scale,.56*scale,"trim",flare=.04*scale)
    kit.box("Lantern stone base",(x,y+.24*scale,z),(.48*scale,.24*scale,.48*scale),"stone",taper=(.08,.08))
    kit.rod("Lantern iron post",(x,y+.34*scale,z),(x,y+1.24*scale,z),.064*scale,"ink",8,.050*scale)
    kit.box("Amber lantern glass",(x,y+1.35*scale,z),(.28*scale,.35*scale,.28*scale),"amber")
    for dx in (-.15,.15):
        for dz in (-.15,.15):
            kit.beam("Lantern cage",(x+dx*scale,y+1.16*scale,z+dz*scale),
                     (x+dx*scale,y+1.53*scale,z+dz*scale),.038*scale,.038*scale,"ink")
    cap(kit,"Lantern cap",x,z,y+1.52*scale,.25*scale,.03*scale,.20*scale,"ink",6)


def rail(kit,p,q,color="stone",blocking=True,height=.88):
    x,y,z=p
    X,Y,Z=q
    length=math.hypot(X-x,Z-z)
    yaw=math.atan2(X-x,Z-z)
    if blocking:
        a.layout["boxes"].append([[(x+X)/2,(y+Y)/2+height*.5,(z+Z)/2],[.36,height,length],yaw])
    kit.beam("Parapet lower course",(x,y+.24,z),(X,Y+.24,Z),.40,.47,color)
    kit.beam("Parapet cap",(x,y+.53,z),(X,Y+.53,Z),.50,.16,"trim" if color=="stone" else "wood_light")
    for i in range(1,max(2,round(length/1.9))):
        t=i/max(2,round(length/1.9))
        px,py,pz = x+(X-x)*t, y+(Y-y)*t, z+(Z-z)*t
        kit.plinth("Parapet pier foot",(px,py+.09,pz),.58,.18,.58,"trim" if color=="stone" else "oak",angle=yaw,flare=.035)
        if color=="stone" and i%2==1:
            kit.chipped("Parapet pier",(px,py+.46,pz),(.52,.78,.53),color,angle=yaw,taper=(.08,.08),core_color="trim")
            kit.chipped("Parapet pier cap",(px,py+.88,pz),(.59,.13,.60),"trim",angle=yaw,taper=(.04,.04))
        else:
            kit.box("Parapet pier",(px,py+.46,pz),(.52,.78,.53),color,angle=yaw,taper=(.08,.08))
            kit.box("Parapet pier cap",(px,py+.88,pz),(.59,.13,.60),"trim" if color=="stone" else "wood_light",angle=yaw)


def slope_x(x0,x1,z0,z1,y0,y1, label):
    a.slab(terrain,label,[(x0,y0,z1),(x1,y1,z1),(x1,y1,z0),(x0,y0,z0)],.32,"stone")


def steps(x,z0,z1,width,y0,y1,label):
    a.slope(terrain,label,x-width*.5,x+width*.5,z0,z1,y0,y1,.27,"grout")
    n=max(5,round(abs(y1-y0)/.20))
    run=(z1-z0)/n
    for i in range(n):
        h=y0+(y1-y0)*i/n
        path_kit.box("Stair tread",(x,h-.105,z0+(i+.5)*run),(width,.21,run+.012),"stone")
        path_kit.box("Stair nosing",(x,h+.008,z0+i*run),(width,.045,.085),"trim")


def arch(kit,x,y,z,r,legs,depth,color="stone", collision=False):
    for side in (-1,1):
        at=(x+side*(r+.23),y+legs*.5,z)
        if collision:
            a.layout["boxes"].append([at,(.46,legs,depth),0])
        kit.chipped("Stone arch jamb",at,(.48,legs,depth),color,taper=(.05,.04),
                    chips=[((-side,1.0,1.0),.14)],core_color="trim")
        kit.plinth("Stone arch foot",(x+side*(r+.23),y+.13,z),.56,.26,depth+.10,"trim",flare=.04)
        kit.chipped("Arch impost",(x+side*(r+.22),y+legs-.08,z),(.56,.15,depth+.12),"trim",
                    taper=(-.05,-.05),chips=[((-side,1.0,1.0),.06)])
    for i in range(11):
        t0,t1=math.pi*i/11,math.pi*(i+1)/11-.022
        keystone = (i == 5)
        jag = .05 if i in (2, 8) else (-.03 if i == 6 else 0.0)
        d_ext = depth * ((1.24 if keystone else 1.0) + jag)
        r_out = r + (.47 if keystone else (.41 if i in (2, 7) else .38))
        points=[(x+math.cos(t)*rr,y+legs+math.sin(t)*rr,z+d)
                for d in (-d_ext/2,d_ext/2) for t,rr in
                [(t0,r),(t1,r),(t1,r_out),(t0,r_out)]]
        kit.mesh("Cut-stone arch voussoir",points,
                 [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],
                 "trim" if keystone else color)


def lancet(kit,x,y,z,w,h):
    for depth,tint,scale in [(0,"shade",1.14),(.042,"window",1.0)]:
        points=[(x+dx*w*scale,y+dy*h*scale,z+depth) for dx,dy in
                [(-.5,0),(.5,0),(.5,.64),(0,1),(-.5,.64)]]
        kit.facet("Glazed pointed arch",points,tint)
    for side in (-1, 1):
        kit.box("Lancet outer jamb",(x+side*w*.56,y+h*.32,z+.09),(.14,h*.66,.18),"trim",taper=(.04,.04))
        kit.beam("Lancet hood arch",(x+side*w*.56,y+h*.64,z+.09),(x,y+h*1.05,z+.09),.14,.16,"trim")
    kit.box("Lancet central mullion",(x,y+h*.46,z+.075),(.085,h*.91,.06),"oak")
    kit.box("Lancet stone sill",(x,y-.10,z+.15),(w*1.32,.16,.38),"trim",taper=(.02,.04))
    for side in (-1, 1):
        kit.box("Lancet sill corbel",(x+side*w*.42,y-.21,z+.12),(.15,.14,.28),"stone")
    for offset in (.28,.54):
        kit.box("Lancet transom",(x,y+h*offset,z+.072),(w,.075,.055),"oak")


def gable(kit,x,y,z,width,depth,rise,roof="slate"):
    x0,x1=x-width/2,x+width/2
    z0,z1=z-depth/2,z+depth/2
    kit.facet("Front gable",[(x0,y,z1),(x1,y,z1),(x,y+rise,z1)],"plaster")
    kit.facet("Back gable",[(x1,y,z0),(x0,y,z0),(x,y+rise,z0)],"stone")
    for edge in (x0,x1):
        quad = [(edge,y-.10,z0-.26),(x,y+rise,z0-.26),(x,y+rise,z1+.26),(edge,y-.10,z1+.26)]
        kit.slab("Slate roof face", quad if edge < x else quad[::-1], .14, roof)
        kit.beam("Front bargeboard",(edge,y-.08,z1+.29),(x,y+rise+.04,z1+.29),.16,.16,"oak")
        kit.beam("Back bargeboard",(edge,y-.08,z0-.29),(x,y+rise+.04,z0-.29),.16,.16,"oak")
        for i in range(1,5):
            t=i/5
            X=edge+(x-edge)*t
            Y=y+rise*t+.03
            kit.beam("Slate seam",(X,Y,z0-.24),(X,Y,z1+.24),.05,.04,"slate_dark")
    kit.beam("Roof ridge",(x,y+rise+.05,z0-.28),(x,y+rise+.05,z1+.28),.16,.16,"slate_light")


# Lower land, raised courtyard and two separate links uphill.
slab(terrain,"Lower walkable ground",(0,-.42,1),(94,.84,83),"grass")
for x in (-47,47):
    a.layout["boxes"].append([(x,1.95,1),[.40,4.4,83],0])
for z in (-40.4,42.4):
    a.layout["boxes"].append([(0,1.95,z),[94,4.4,.40],0])
slab(terrain,"Castle courtyard core",(0,1.86,-25),(49,3.72,23),"stone")
road([(-22,3.72,-14.5),(22,3.72,-14.5)],3.5)
road([(-23,3.72,-19.5),(23,3.72,-19.5)],6)
road([(-23,3.72,-25.0),(23,3.72,-25.0)],4.8)
steps(0,-13.5,-1.8,8.4,3.72,0,"Main castle stair ramp")
for x in (-4.42,4.42):
    rail(castle,(x,3.72,-13.5),(x,0,-1.8))
for x0,x1 in [(-24,-4.48),(4.48,18.0)]:
    rail(castle,(x0,3.72,-13.38),(x1,3.72,-13.38))
    for x in range(math.ceil(x0+2),math.floor(x1-1),4):
        arch(castle,x,0,-13.29,1.03,1.55,.22,"shade")
rail(castle,(-24.45,3.72,-36),(-24.45,3.72,-13.8))
# East traverse goes down alongside the castle then turns toward the hut.
a.slope(terrain,"Hut approach ramp",18.6,24.4,-13.54,-2.0,3.72,1.15,.29,"stone")
rail(castle,(24.40,3.72,-13.5),(24.40,1.15,-2.0),"stone")
rail(castle,(18.59,3.72,-13.5),(18.59,1.15,-2.0),"stone")
slab(terrain,"Hut clearing terrace",(30.3,.575,.6),(23.4,1.15,11.0),"moss")
a.slope(terrain,"Hut lower lane ramp",26.0,34.2,6.1,12.1,1.15,0,.25,"stone")
road([(27,1.15,-2),(30,1.15,2),(30,1.15,6.1)],3.3)
road([(0,0,-1.8),(0,0,12),(1.5,0,23),(1.5,0,35.5)],4.9)
road([(-13.5,0,35.4),(1.5,0,35.4),(15.5,0,35.4),(27.6,0,35.4)],4.5)
road([(-14.0,0,25.1),(-12.6,0,27.6),(-6.0,0,27.6),(1.0,0,23)],3.9)
road([(30,0,12.1),(31.2,0,18.3),(28.5,0,24),(29.5,0,30),(27.6,0,39)],5.2)
road([(1,0,22),(10.5,0,23),(20,0,27),(28.9,0,28.8)],3.5)
for x,z,y in [(4,1,0),(-2.8,12,0),(4.2,29,0),(-9.5,37,0),(9,37,0),(23,36,0),
              (28.3,8,.7),(34.7,5,1.15),(17.2,-14,3.72),(-6,-14,3.72),(-18,-16,3.72),
              (16,-22,3.72),(-19,-25,3.72),(1,-27,3.72),(34,20,0),(25.5,28,0)]:
    lamp(path_kit,x,y,z)


# Pitch with true oval turf, segmented bleachers and entry tunnels.
cx,cz,rx,rz=-25.3,16.5,15.0,19.0
for i in range(10):
    x0=-rx+2*rx*i/10
    x1=-rx+2*rx*(i+1)/10
    pts=[]
    for n in range(9):
        x=x0+(x1-x0)*n/8
        pts.append((cx+x,.023,cz+rz*math.sqrt(max(0,1-(x/rx)**2))))
    for n in range(8,-1,-1):
        x=x0+(x1-x0)*n/8
        pts.append((cx+x,.023,cz-rz*math.sqrt(max(0,1-(x/rx)**2))))
    pitch.facet("Alternating mown turf stripe",pts,"turf" if i%2 else "turf_dark")


def ring_point(angle,offset=0,y=.046):
    return (cx+(rx+offset)*math.cos(angle),y,cz+(rz+offset)*math.sin(angle))


def ring_line(kit,x,y,z,r,w,color,vertical=False):
    for i in range(32):
        t0,t1=i*math.tau/32,(i+1)*math.tau/32
        points=[(x+math.cos(t)*rr,y+math.sin(t)*rr,z) if vertical
                else (x+math.cos(t)*rr,y,z+math.sin(t)*rr)
                for t,rr in [(t0,r-w/2),(t1,r-w/2),(t1,r+w/2),(t0,r+w/2)]]
        kit.facet("Continuous line ring",points,color)


pitch.box("Center field stripe",(cx,.047,cz),(29.90,.021,.11),"chalk")
ring_line(pitch,cx,.058,cz,3.6,.14,"chalk")
for i in range(64):
    t0,t1=i*math.tau/64,(i+1)*math.tau/64
    pitch.beam("Oval pitch chalk",ring_point(t0),ring_point(t1),.12,.022,"chalk")
for side in (-1,1):
    goal_z=cz+side*15.1
    for dx,h in [(-3.25,4.7),(0,6.1),(3.25,4.7)]:
        x=cx+dx
        a.solid(pitch,"Goal stone footing",(x,.16,goal_z),(.76,.32,.76),"trim")
        pitch.rod("Brass goal staff",(x,.3,goal_z),(x,h-1.08,goal_z),.09,"gold",8)
        ring_line(pitch,x,h,goal_z,1.10,.15,"gold",True)
for i in range(32):
    t0,t1=i*math.tau/32,(i+1)*math.tau/32
    mid=(t0+t1)*.5
    if i in (0,1,2,3,5,6,22,23,29,30,31):continue
    p,q=ring_point(t0,.56),ring_point(t1,.56)
    rail(pitch,p,q,"stone",True,.82)
    for row in range(5):
        offset=.9+row*.69
        y=.32+row*.46
        pitch.beam("Tiered timber bleacher bench",ring_point(t0,offset,y),ring_point(t1,offset,y),.65,.30,"timber" if row%2 else "wood_light")
    for offset in (.92,3.65):
        x,y,z=ring_point(mid,offset,0)
        pitch.box("Grandstand timber frame",(x,1.32,z),(.19,2.64,.19),"oak")
    x,y,z=ring_point(mid,3.86,0)
    if i%3==0:lamp(pitch,x,y,z,.75)
    a.layout["boxes"].append([list(ring_point(mid,2.7,1.06)),[3.05,2.12,3.6],-mid])
    if i%3!=0:
        p0,p1=ring_point(t0,2.60,2.83),ring_point(t1,2.60,2.83)
        q0,q1=ring_point(t0,4.1,3.46),ring_point(t1,4.1,3.46)
        pitch.facet("Covered bleacher slate panel",[p0,p1,q1,q0],"slate")
        pitch.beam("Bleacher roof gold trim",p0,p1,.10,.105,"gold")

# Raised, playable ceremonial pavilion with a field-side view.
slab(stand,"Pavilion podium",(-8.7,.82,14.5),(4.0,1.64,12.2),"stone")
stand.plinth("Pavilion base plinth",(-8.7,.16,14.5),4.18,.32,12.38,"trim",flare=.05)
stand.coping("Pavilion deck coping",(-8.7,1.62,14.5),4.24,.16,12.42,"trim",seg_len=1.8)
steps(-8.7,20.6,25.1,3.0,1.64,0,"Pavilion steps")
for z in (9.1,12.8,16.6,19.95):
    for x in (-10.48,-6.93):
        stand.plinth("Pavilion pillar foot",(x,1.74,z),.30,.20,.30,"trim",flare=.025)
        stand.box("Pavilion oak pillar",(x,3.02,z),(.22,2.72,.22),"timber",taper=(.08,.08))
    stand.beam("Pavilion roof tie",(-10.6,4.17,z),(-6.8,4.17,z),.18,.18,"oak")
gable(stand,-8.7,4.18,14.5,4.56,12.65,1.29)
rail(stand,(-10.63,1.64,8.55),(-10.63,1.64,20.56),"oak")
rail(stand,(-6.73,1.64,8.55),(-6.73,1.64,20.56),"oak")
rail(stand,(-10.65,1.64,8.55),(-6.73,1.64,8.55),"oak")
for z in (9.6,13.0,16.4,19.7):
    stand.box("Red ceremonial drape",(-10.74,1.56,z),(.065,.62,2.45),"red")
    stand.box("Gold drape border",(-10.78,1.27,z),(.056,.11,2.45),"gold")
for i,house in enumerate(("gryffindor","hufflepuff","ravenclaw","slytherin")):
    x,z=-11.12,8.5+i*3.45
    stand.box("Flagpole carved stone base",(x,.22,z),(.70,.44,.70),"trim")
    stand.rod("Tall brass flagpole",(x,.42,z),(x,8.05,z),.071,"gold",8)
    stand.rod("Spherical finial",(x,8.00,z),(x,8.27,z),.16,"gold",10,.075)
    flag=a.kit("flag_"+house)
    for row in range(10):
        for column in range(8):
            def vertex(i,j):
                u,v=i/8,j/10
                return (u*1.86,-v*(2.42-.27*abs(2*u-1)),.018*math.sin(u*7))
            flag.facet("Subdivided banner cloth",[vertex(column,row),vertex(column+1,row),
                      vertex(column+1,row+1),vertex(column,row+1)],("red","yellow","blue","green")[i])
    a.moving("flag_"+house,(x,7.89,z),math.pi*.5)


def tower(x,z,r,h,spire,hero=False):
    base=3.72
    cap(castle,"Faceted castle tower",x,z,base,r,r*.96,h,"stone",12)
    cap(castle,"Corbelled tower crown",x,z,base+h-.42,r*1.08,r*1.08,.51,"trim",12)
    cap(castle,"Pointed slate spire",x,z,base+h+.04,r*1.14,.06,spire,"slate",12)
    cap(castle,"Gilt spire finial",x,z,base+h+spire,.115,.022,.54,"gold",6)
    for y in (base+.58,base+h*.29,base+h*.68):
        cap(castle,"Tower masonry belt",x,z,y,r*1.01,r*1.009,.105,"grout",12)
    for dy in range(3,int(h)-2,3):
        for az in (math.pi*.24,math.pi*.5,math.pi*.78):
            X,Z=x+math.cos(az)*r*.99,z+math.sin(az)*r*.99
            castle.box("Slit window stone reveal",(X,base+dy,Z),(.52,1.0,.13),"shade",az-math.pi*.5)
            castle.box("Lit tower slit window",(X,base+dy,Z+.074),(.24,.68,.086),"amber",az-math.pi*.5)
    if -24<x<24 and -36<z<-13:
        a.layout["boxes"].append([(x,base+h*.5,z),[r*1.45,h,r*1.45],0])
    if hero:
        front=z+r+.07
        castle.box("Gryffindor pennant backing",(x,base+h*.60,front),(2.52,4.86,.135),"red")
        castle.beam("Golden pennant bar",(x-1.54,base+h*.84,front+.07),(x+1.54,base+h*.84,front+.07),.13,.13,"gold")
        a.sign("GryffindorTowerBanner","hogwarts-gryffindor",(x,base+h*.60,front+.097),(2.43,4.75))
        for side in (-1,1):
            X=x+side*r*.77
            cap(castle,"Corner turret",X,z+.76,base+h*.62,.83,.78,h*.40,"trim",8)
            cap(castle,"Turret cone roof",X,z+.76,base+h*1.02,.92,.025,2.82,"slate_dark",8)


# Castle silhouette, Great Hall, north cloister and a bridge over the lake.
tower(-16.0,-27.4,3.55,14.8,6.1,True)
for x,z,r,h,spire in [(-24,-31,1.65,8.4,3.45),(-21,-34,1.26,10.6,4.2),(-8,-34,1.72,11.6,4.1),
                      (-1,-31,1.58,8.8,4.3),(4,-35,1.32,11.8,4.5),(19,-35,1.32,13.4,5.0),
                      (24,-29,2.23,9.5,4.65),(28,-34,1.77,8.3,3.45),(12,-37,1.60,11.1,4.6)]:
    tower(x,z,r,h,spire)
hall_x,hall_z=12.0,-29.5
slab(castle,"Great Hall masonry shell",(hall_x,7.73,hall_z),(17.8,8.02,8.9),"stone")
castle.plinth("Great Hall stone plinth",(hall_x,3.92,hall_z),18.1,.42,9.2,"trim",flare=.06)
for z in (hall_z-4.70,hall_z+4.70):
    quad = [(2.80,11.72,z),(21.2,11.72,z),(21.2,15.82,hall_z),(2.80,15.82,hall_z)]
    castle.slab("Long hall slate roof", quad if z > hall_z else quad[::-1], .18, "slate")
    for x in range(3,22):
        castle.beam("Ribbed slate roof seam",(x,11.77,z),(x,15.88,hall_z),.065,.055,"slate_dark")
for x in (3.07,20.93):
    castle.facet("Great Hall end gable",[(x,11.7,-34.20),(x,15.82,hall_z),(x,11.7,-24.8)],"plaster")
castle.beam("Great Hall roof crest",(2.8,15.86,hall_z),(21.2,15.86,hall_z),.26,.24,"slate_light")
for i_b, x in enumerate((5.05,8.53,12.0,15.47,18.95)):
    lancet(castle,x,5.22,-25.007,2.12,5.86)
    castle.plinth("Hall buttress foot",(x+1.58,3.95,-24.78),.56,.46,.92,"stone",flare=.05)
    if i_b % 2 == 1:
        castle.chipped("Hall buttress",(x+1.58,6.64,-24.85),(.44,5.85,.78),"trim",taper=(.10,.12),
                       chips=[((1.0,1.0,1.0),.18)],core_color="stone")
    else:
        castle.box("Hall buttress",(x+1.58,6.64,-24.85),(.44,5.85,.78),"trim",taper=(.10,.12))
    castle.box("Buttress set-off",(x+1.58,6.80,-24.76),(.50,.18,.88),"stone",taper=(.08,.12))
    cap(castle,"Buttress pinnacle",x+1.58,-24.87,9.60,.40,.02,1.88,"slate_dark",4)
castle.seam((6.8,5.6,-25.04),1.45,1.30,0.0,"grout","trim",tie_color="ink")
castle.seam((17.2,5.8,-25.04),1.45,1.30,0.0,"grout","trim",flip=True)
castle.rubble((4.85,3.72,-13.85),.44,0.4,("stone","trim","flagstone"),count=3)
castle.rubble((-4.85,3.72,-13.85),.44,-0.6,("stone","trim"),count=3)
for y in (4.08,4.74,10.92,11.43):
    castle.box("Continuous hall stone belt",(12,y,-24.93),(17.83,.13,.22),"trim" if y>10 else "grout")
for x in (6.76,10.25,13.73,17.17):
    for y in (5.35,6.10,6.85,7.6,8.35,9.1,9.85):
        castle.box("Alternating ashlar face",(x+(int(y*4)%2-.5)*.20,y,-24.995),(.46,.20,.105),"trim")
for x in range(-22,29,2):
    if x>1 and x<22:continue
    castle.box("Castle curtain wall",(x,7.38,-35.1),(2.0,7.3,1.42),"stone")
    c_h = .58 if x % 6 == 0 else .76
    castle.chipped("Castle wall crenel",(x,10.90+c_h*.5,-35.1),(1.12,c_h,1.48),"trim",seed=abs(x))
for x in (-11.5,-8.0,-4.5):
    arch(castle,x,3.72,-29.25,1.20,2.12,.59)
    castle.box("Recessed cloister back",(x,6.1,-30.23),(3.30,4.74,.24),"shade")
    castle.box("Covered cloister lintel",(x,7.73,-29.60),(3.55,.63,1.28),"stone")
    lamp(castle,x+.93,3.72,-30.06,.72)
# Real door between two Gothic turrets and a separate walkable cloister opening.
arch(castle,0.8,3.72,-25.3,1.72,2.20,.84,"stone",True)
castle.box("Dark oak Great Hall doors",(.8,5.12,-25.75),(3.52,2.77,.20),"oak")
castle.box("Central door mullion",(.8,5.13,-25.61),(.075,2.73,.1),"gold")
for side in (-1,1):
    x=.8+side*1.6
    castle.box("Pointed doorway pier",(x,6.15,-25.6),(.31,4.65,.65),"trim")
    lamp(castle,.8+side*2.50,3.72,-24.46,.86)
gable(castle,.8,8.16,-25.44,4.2,2.15,2.17)

# Stone bridge silhouette and parapets above the Black Lake.
castle.box("Lake bridge deck",(-42.3,3.15,-28.6),(36.6,1.08,4.9),"stone")
for x in (-56.6,-49.3,-42.0,-34.7,-27.4):
    for z in (-31.0,-26.2):
        arch(castle,x,-4.7,z,2.65,4.12,.74)
    castle.box("Viaduct stone pier",(x-3.65,-.80,-28.6),(1.03,7.18,4.5),"stone")
for z in (-30.95,-26.25):
    rail(castle,(-60.55,3.72,z),(-24.05,3.72,z),blocking=False)
for x in (-56,-48,-40,-32):
    lamp(castle,x,3.72,-26.43,.81)

# Winged statue and a cobbled landing. Its base doubles as cover.
for i,r in enumerate((4.0,2.9,1.58)):
    for j in range(48):
        t0,t1=j*math.tau/48,(j+1)*math.tau/48
        castle.beam("Circular forecourt inlay",(r*math.cos(t0),3.748+i*.001,-19.5+r*math.sin(t0)),
                    (r*math.cos(t1),3.748+i*.001,-19.5+r*math.sin(t1)),.13,.020,"trim")
slab(castle,"Statue solid base",(0,4.05,-19.5),(1.56,.66,1.44),"slate_light")
cap(castle,"Bronze gryphon torso",0,-19.5,4.38,.40,.26,1.05,"bronze",7)
castle.box("Griffin head",(0,5.48,-19.14),(.54,.52,.56),"gold")
for side in (-1,1):
    castle.facet("Gryphon open wing",[(side*.12,4.90,-19.51),(side*1.45,5.48,-19.51),
                    (side*1.63,6.27,-19.65),(side*.87,5.93,-19.67),(side*.40,5.66,-19.66)],"gold")
    castle.beam("Raised bronze wing rib",(side*.23,5.07,-19.46),(side*1.52,6.17,-19.55),.095,.09,"bronze")


# Crooked Hogsmeade shopfronts with warm bay windows facing the lane.
def shop(x,z,w,d,h,side,index):
    front=z+d*.5
    tint=("plaster","stone","flagstone")[index%3]
    a.layout["boxes"].append([(x,h*.5,z),[w,h,d],0])
    village.plinth("Shop stone plinth",(x,.18,z),w+.12,.36,d+.12,"stone",flare=.05)
    village.box("Timber and plaster shop",(x,h*.5+.06,z),(w,h-.12,d),tint,taper=(.03,.03))
    gable(village,x,h,z,w+.44,d+.40,2.0+index%3*.32,("slate","slate_dark","slate_light")[index%3])
    village.box("Stone chimney",(x+w*.27,h+1.88,z-d*.18),(.72,2.88,.68),"stone",taper=(.09,.09))
    village.coping("Chimney coping",(x+w*.27,h+3.32,z-d*.18),.90,.18,.86,"trim",seg_len=.9,wear=.78)
    village.seam((x+w*.24,1.52,front),min(1.1,w*.28),1.05,0.0,"grout","trim",tie_color="ink" if index%2==0 else None)
    village.masonry_patch((x+side*w*.5,1.02,z),0.90,0.58,math.pi*.5*side,"grout","stone",alt_color="flagstone",lip_color="trim")
    for dx in (-w*.46,0,w*.46):
        village.box("Exposed oak stud",(x+dx,h*.48,front+.06),(.16,h,.21),"oak")
    for y in (.36,h*.55,h-.10):
        village.box("Oak cross member",(x,y,front+.08),(w+.06,.18,.21),"oak")
    for dx in (-1,1):
        village.beam("Diagonal half timber brace",(x+dx*.13,h*.52,front+.17),
                     (x+dx*w*.44,h-.14,front+.17),.13,.125,"oak")
    for y in (1.12,h*.72):
        village.box("Front bay window casing",(x-.82,y,front+.16),(1.44,.96,.18),"oak")
        village.box("Front bay sill",(x-.82,y-.48,front+.22),(1.56,.13,.28),"trim")
        village.box("Front bay amber window",(x-.82,y,front+.24),(1.26,.78,.08),"window")
        for dd in (-.52,0,.52):
            village.box("Front window mullion",(x-.82+dd,y,front+.29),(.06,.80,.05),"oak")
    wall_x=x+side*(w*.5+.07)
    for zz in (z-d*.26,z+d*.23):
        village.box("Lane-facing shop window recess",(wall_x,1.43,zz),(.26,1.92,1.50),"oak")
        village.box("Lane-facing warm shop window",(wall_x+side*.135,1.47,zz),(.045,1.55,1.23),"window")
        for dz in (-.39,0,.39):
            village.box("Bay window oak mullion",(wall_x+side*.165,1.47,zz+dz),(.072,1.52,.062),"oak")
        village.box("Bay window transom",(wall_x+side*.165,1.44,zz),(.072,.068,1.26),"oak")
        village.box("Lane sill",(wall_x+side*.19,.58,zz),(.46,.18,1.58),"wood_light")
    village.box("Laneway half-timber crossbar",(wall_x,2.61,z),(.17,.20,d),"oak")
    if index%2==0:
        village.canopy((wall_x+side*.02,2.92,z),d*.88,.92,.30,math.pi*.5*side,"red","trim","oak",posts=False)
    village.box("Heavy timber front door",(x+.82,1.03,front+.12),(.82,2.02,.15),"oak")
    village.box("Door arch lintel",(x+.82,2.08,front+.14),(.96,.16,.22),"trim")
    lamp(village,wall_x+side*.52,0,z-d*.42,.69)


for index,params in enumerate([
    (21.7,17.2,5.4,6.1,3.9,1),(21.1,25.3,5.5,6.1,4.25,1),(20.1,34.5,5.9,6.3,3.9,1),
    (40.2,14.5,6.25,6.4,4.1,-1),(39.6,23.0,5.9,6.25,4.45,-1),(39.1,33.8,6.1,6.6,4.15,-1),
]):
    shop(*params,index)
road([(27.7,0,39.1),(33.5,0,38.2),(34.3,0,34.2),(32.8,0,30.5)],3.45)
arch(village,33.65,0,37.5,1.83,2.0,.85,"stone",True)
for x in (31.27,36.03):
    lamp(village,x,0,37.92,.84)
    village.box("Village entry hanging pennant",(x,1.99,37.97),(.60,1.13,.12),"red" if x<33 else "blue")

# Round hut, a stone chimney, garden fence and a pumpkin patch.
hx,hz,hy=34.7,-.80,1.15
cap(hut,"Hagrid's round stone hut",hx,hz,hy,3.35,3.35,2.89,"stone",12)
cap(hut,"Layered conical shingle roof",hx,hz,hy+2.80,3.78,.13,2.65,"slate_light",12)
for i in range(1,6):
    t=i/6
    cap(hut,"Shingle course lip",hx,hz,hy+2.80+t*2.65,3.80-(3.78-.13)*t,
        3.76-(3.78-.13)*t,.071,"slate_dark",12)
hut.box("Stone chimney shaft",(hx+2.54,hy+3.72,hz-.77),(.88,4.26,.94),"stone")
hut.box("Raised chimney top",(hx+2.54,hy+5.88,hz-.77),(1.06,.21,1.10),"trim")
for dx in (-1.51,1.51):
    lancet(hut,hx+dx,hy+.84,hz+2.99,.77,1.08)
arch(hut,hx,hy,hz+3.31,.61,1.26,.19)
hut.box("Hut arched oak door",(hx,hy+.76,hz+3.44),(1.12,1.47,.12),"oak")
a.layout["boxes"].append([(hx,hy+1.40,hz),[5.1,2.8,5.1],0])
for x,z in [(30,3.50),(39.7,3.8),(40.5,-3.4)]:
    lamp(hut,x,hy,z,.64)
for x,z,s in [(32.15,3.90,.70),(33.05,3.96,.40),(31.10,3.45,.46),(38.31,2.37,.39),(38.98,2.88,.52)]:
    for k in range(8):
        t=k*math.tau/8
        cap(hut,"Ribbed orange pumpkin",x+math.cos(t)*s*.37,z+math.sin(t)*s*.37,hy+.07,s*.68,s*.52,s*.88,
            "pumpkin_light" if k%2==0 else "pumpkin",8)
    hut.rod("Pumpkin stem",(x,hy+s*.93,z),(x+.11,hy+s*1.15,z),.073,"leaf",5)
for p,q in [((24.5,1.15,-4.8),(27,1.15,-4.8)),((38,1.15,5.9),(42,1.15,5.9)),
            ((42,1.15,5.9),(42,1.15,-4.9))]:
    rail(hut,p,q,"oak",False)

# Pine silhouettes and basalt cliffs define the play area against the Black Lake.
def pine(x,y,z,h):
    cap(landscape,"Pine trunk",x,z,y,h*.064,h*.038,h*.73,"oak",6)
    for level,(up,rad,length) in enumerate(((.24,.27,.53),(.40,.22,.48),(.57,.16,.45))):
        cap(landscape,"Faceted Scots pine crown",x,z,y+h*up,h*rad,.035,h*length,
            ("pine_dark","pine","pine_tip")[level],7)


for i in range(67):
    if i<20:
        x,z=rng.uniform(-48,-43),rng.uniform(-34,42)
    elif i<39:
        x,z=rng.uniform(43,51),rng.uniform(-33,43)
    elif i<52:
        x,z=rng.uniform(-23,40),rng.uniform(-43,-39)
    else:
        x,z=rng.uniform(-14,28),rng.uniform(42,50)
    pine(x,0,z,rng.uniform(3.8,8.3))
for x,z,h in [(12,-8,6.9),(14,-4,6.6),(14,3,5.2),(11,9,5.5),(26,-9,6.0),
              (36,-8,8.2),(40,-6,6.6),(42,6,7.8),(-14,-6,6.1),(-11,-10,5.8),(-7,4,4.2),
              (8.4,4.3,5.0),(12.1,6.8,6.1),(13.5,13.5,5.8),(15.2,16.2,4.4),(18.4,19.3,5.5),
              (5.1,31.2,4.6),(7.9,29.1,5.0),(11,31.7,4.0),(40.8,-12,6.4),(34,-17,5.1)]:
    pine(x,0,z,h)
for i in range(64):
    if i<28:
        x,z=rng.uniform(48,73),rng.uniform(-50,49)
    elif i<46:
        x,z=rng.uniform(0,55),rng.uniform(-64,-43)
    else:
        x,z=rng.uniform(-29,50),rng.uniform(47,61)
    landscape.rod("Forest hillside mass",(x,-4,z),(x,-.38,z),rng.uniform(5.4,7.8),"moss",7,5.4)
    pine(x,-.30,z,rng.uniform(4.7,8.7))
landscape.box("Continuous east forest floor",(59,-1.9,2),(25.4,3.76,99),"moss")
landscape.box("Continuous southern forest floor",(18,-1.9,51),(105,3.76,18),"moss")
landscape.box("Pine ridge behind castle",(27,-1.8,-50),(71,3.5,20),"moss")
for x,z in [(-10,-8),(-9,-4),(-7,2),(6,-8),(9,-5),(12,-11),(13,1),(17,7),(15,18),(10,29),
            (-40,0),(-43,8),(-46,14),(40,8),(40,4),(23,8),(17,-10),(-20,-10),(-23,-7)]:
    for j in range(3):
        X,Z=x+rng.uniform(-.9,.9),z+rng.uniform(-.9,.9)
        h=rng.uniform(.48,1.30)
        landscape.rod("Faceted lichen boulder",(X,-.18,Z),(X+.32,h,Z-.18),h*.92,
                      ("rock","rock_light","moss")[j],6,h*.55)
for z in range(-43,39,4):
    x=-48-rng.uniform(0,2.0)
    landscape.rod("Low poly lakeside cliff",(x,-4.45,z),(x+rng.uniform(-1,2),-.05,z),rng.uniform(2.1,3.2),
                  rng.choice(("rock","rock_light")),6,1.40)
for i in range(24):
    x,z=rng.uniform(-105,-60),rng.uniform(-80,-49)
    if i<7:
        landscape.rod("Pine islet",(x,-3.8,z),(x,-1.5,z),6.1,"rock",6,4.0)
    pine(x,-1.5,z,rng.uniform(3.3,5.8))
for i in range(9):
    x=-112+i*24
    z=-102+(i%3)*5
    landscape.rod("Far ridge silhouette",(x,-5,z),(x+6,10+(i%3)*5,z),21,"rock",6,7.1)
lake.facet("Black Lake",( (-162,-3.34,-141),(91,-3.34,-141),(91,-3.34,117),(-162,-3.34,117) ),"lake")

# Frenzy cover breaks apart, while the stairs, walls carrying platforms and walkable floor stay intact.
crate=a.kit("festival_crate")
crate.plinth("Crate skid",(0,.06,0),1.36,.12,1.20,"oak",flare=.02)
crate.box("Wooden crate",(0,.60,0),(1.28,1.06,1.12),"timber",taper=(.02,.02))
for sx in (-1, 1):
    for sz in (-1, 1):
        crate.box("Crate oak stud",(sx*.60,.60,sz*.52),(.15,1.14,.15),"oak",taper=(.03,.03))
for y in (.15,1.08):
    crate.box("Crate reinforcing band",(0,y,0),(1.38,.15,1.22),"wood_light")
for sz in (-1, 1):
    crate.beam("Crate diagonal brace",(-.54,.16,sz*.57),(.54,1.04,sz*.57),.11,.10,"wood_light")
stall=a.kit("village_stall")
stall.plinth("Stall stone plinth",(0,.09,0),2.32,.18,1.12,"stone",flare=.035)
stall.box("Festival counter",(0,.58,0),(2.20,.96,1.00),"timber",taper=(.03,.03))
for sx in (-1, 1):
    stall.box("Counter oak post",(sx*1.04,.58,0),(.16,.98,1.06),"oak",taper=(.04,.04))
stall.coping("Festival counter top",(0,1.12,0),2.38,.14,1.18,"wood_light",seg_len=1.2)
stall.canopy((0,2.68,-.56),2.42,1.42,.38,0.0,"red","trim","oak",post_h=2.32,posts=True)
for x,y,z in [(-15,0,12),(-31,0,23),(-32,0,8),(-19,0,26),(-4,0,26),
              (9,0,14),(12,3.72,-18),(-10,3.72,-19),(17,3.72,-23),(25,1.15,1.7),
              (26.4,0,24.6),(32.7,0,32.0),(17.7,0,34.0),(35.5,0,14.6)]:
    a.prop("festival_crate",(x,y,z),(1.40,1.2,1.36),rng.uniform(-.35,.35),effect="wood")
for x,z in [(24.8,29.2),(33.9,19.2),(-3.7,11.0),(23.4,9.1)]:
    a.prop("village_stall",(x,0,z),(2.25,2.80,1.10),math.pi*.5,effect="wood")

# Stone and roof colors stay readable under the moving spell beams.
for origin,target,color,motion in [
    ((-23,8.3,10),(-25,0,17),"5bc9ff",(10,0,4)),
    ((-3.0,9.2,17),(-15,0,18),"ff63a5",(5,0,11)),
    ((-17.0,16,-24),(0,3.72,-16),"e58aff",(11,0,6)),
    ((18.6,13.8,-25),(3.5,3.72,-18),"78ffc8",(11,0,5)),
    ((35,7,24),(29,0,26),"ffc15e",(4,0,8)),
]:
    a.spot(origin,target,color,5.4,17.0,34,motion,True)
for x,y,z,color in [(-10,4.1,15,"ffb96b"),(-1,6.8,-16,"ffc679"),(28.0,4,26,"ffc17b"),(33.2,4,3.7,"ffa967")]:
    a.spot((x,y,z),(x,0,z+.8),color,1.58,9.4,51)

a.layout.update(
    start=(-24,.06,27.0),heading=-.32,
    opening=[(-21,0.06,15),(-33,.06,12),(-18,.06,5),(-14,.06,19),
             (-5,.06,14),(5,.06,8),(25,.06,15),(2,3.78,-16)],
    spawns=[(-33,.06,9),(-18,.06,6),(-30,.06,29),(-19,.06,23),(-6,.06,28),
            (4,.06,15),(12,.06,24),(24.5,.06,34),(29,.06,34),(32,.06,17),(26,.06,12),
            (28,1.21,1),(15,3.78,-19),(-16,3.78,-18),(7,3.78,-22),(-7,3.78,-24)],
    respawns=[(-24,.06,27),(-34,.06,14),(-7,.06,27),(13,.06,27),(29,.06,26),
              (31,1.21,3),(7,3.78,-19),(-15,3.78,-20)],
    route=[(-24,.06,27),(-18,.06,23),(-13,.06,26.8),(-11.8,.06,28.2),(-6,.06,28.2),(-4,.06,21),(0,.06,10),(0,.06,-1.5),
           (0,3.78,-14.8),(5,3.78,-17.6),(16,3.78,-16),(21.6,3.78,-13.7),
           (21.6,1.21,-2),(25.0,1.21,0),(30,1.21,4),(30,.06,12.4),
           (29,.06,25),(28,.06,37),(15,.06,35.4),(2,.06,35.4),(-8.7,.06,27.1),(-8.7,1.70,18.0)],
    barrels=[(-16,.06,15),(-31,.06,19),(8,.06,23),(26,.06,31),(32,.06,15),(-8,3.78,-17),(27,1.21,3)],
    comedy=(11.6,0,12.2,.30),
    cameras={
        "quidditch":[[-35.8,3.5,29.4],[-14.2,5.2,4.0],70],
        "castle":[[.05,5.1,-6.6],[-2.4,7.7,-27.0],77],
        "hogsmeade":[[27.0,1.80,41.25],[32.6,4.0,2.2],72],
        "frenzy":[[-16.1,2.25,22.7],[-5.5,7.1,-18.4],75,48.5],
    })
a.write()
