"""Build the Hong Kong hillside wet market from its overview and street views."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit
from rain_market_neon import build_fish, build_storefront, sign
from rain_market_waterfront import build_harbour, build_restaurant_row

P = {
    "road": ("3b415d",.31,0), "asphalt": ("515973",.38,0), "concrete":"a09ab0",
    "tile":"d7bb9c", "grout":"626a76", "teal":"247b83", "mint":"6db1a6", "green":"256052",
    "navy":"233753", "steel":"526887", "white":"f3e6df", "metal":("8fa5b7",.30,0),
    "ink":"192638", "pink":"c88096", "lilac":"a59abd", "warm":"daa386",
    "turq":"279eb2", "blue":"3159bb", "canvas":"4778cc", "gold":"f3c452",
    "bamboo":"dca062", "rope":"f0cc93", "red":"d44d58", "orange":"e98334",
    "yellow":"ffdc70", "leaf":"8ab658", "fruit":"ecad43", "fish":"a6bfcc",
    "salmon":"dd7558", "ice":("bedbfa",.4,.12), "light":("ffd798",.55,.85),
    "pink_light":("fc668f",.55,.65), "window":("e6be83",.55,.24), "sign":("ffe9bb",.55,.55),
    "neon_case":"242d45", "neon_red":("ff5b5a",.40,.78), "neon_cream":("ffe3aa",.45,.55),
    "neon_mint":("79f3c9",.42,.75), "neon_amber":("f8bf63",.45,.62),
    "neon_blue":("9bd7ff",.43,.52), "restaurant_red":"b33d46", "restaurant_gold":("ffd464",.48,.65),
    "sea":"1b3357", "ship_hull":"223d55", "ship_deck":"c1d8d8",
    "ship_window":("ffce91",.54,.80), "strip_green":"2b9971", "strip_orange":"ed9955",
}
a=ArenaKit("rain_market",P,{"sky":"263a67","ambient":"c0ceff","energy":.76,"sun":"aebff3","sun_energy":.36,"sun_rotation":[-38,-34,0]})
street=a.kit("street",True)
district=a.kit("district",True)
canopy=a.kit("canopy",True)
decor=a.kit("street_detail",True)


def height(z):
    return max(0,min(3.7,(18-z)*3.7/36))


def terrace_height(z):
    rise = min(1, max(0, (18-z)/8), max(0, (z+18)/10))
    return height(z)+2.05*rise


def ground(x,z):
    y = terrace_height(z) if abs(x)>=18 else height(z)
    return (x,round(y+.06,3),z)


def rail(kit,x,z0,z1,base, color="green"):
    for z in (z0,z1):
        kit.box("Railing post",(x,base(z)+.57,z),(.13,1.14,.13),color)
    for y in (.27,1.09):
        kit.beam("Railing runner",(x,base(z0)+y,z0),(x,base(z1)+y,z1),.10,.10,color)
    for i in range(1,5):
        z=z0+(z1-z0)*i/5
        kit.box("Railing picket",(x,base(z)+.65,z),(.065,.87,.07),color)


# North is uphill. The staircase has visible treads over a smooth collision ramp.
for left,right,color in [(-18,-12,"grout"),(-12,11,"road"),(11,18,"asphalt")]:
    a.slope(street,"Hill",left,right,-18,18,3.7,0,.7,color)
for z,base in [(21.5,0),(-21.5,3.7)]:
    a.solid(street,"End landing",(0,base-.33,z),(46,.66,7),"asphalt")
# Raised frontage on both sides. The cross stairs reach the two galleries at
# staggered points so the player can flank without returning to the entrances.
crossings = {-1: (-5.7,-2.1), 1: (3.0,6.6)}
for side in (-1,1):
    low,high=sorted((side*18,side*23))
    for z0,z1 in [(-18,-8),(-8,10),(10,18)]:
        a.slope(street,"Raised shopfront walkway",low,high,z0,z1,
                terrace_height(z0),terrace_height(z1),.68,"grout")
    for z0,z1 in [(-18,-8),(10,18)]:
        count=round((z1-z0)/.43)
        step=(z1-z0)/count
        for i in range(count):
            z=z0+(i+.5)*step
            y=terrace_height(z)+.05
            street.box("Concrete stair tread",(side*20.5,y-.11,z),(4.93,.22,step-.015),"concrete")
            street.box("Yellow stair nosing",(side*20.5,y+.012,z+step*(.43 if z>0 else -.43)),(4.91,.021,.037),"gold")
    z0,z1=crossings[side]
    rail_breaks=sorted((-18,-14,-8,-2,4,10,14,18,z0,z1))
    for rear,front in zip(rail_breaks,rail_breaks[1:]):
        if z0 < (rear+front)*.5 < z1:
            continue
        x=side*18
        a.slab(street,"Tiled gallery retaining wall",
               [(x-.105,terrace_height(front),front),(x+.105,terrace_height(front),front),
                (x+.105,terrace_height(rear),rear),(x-.105,terrace_height(rear),rear)],2.17,"teal")
        rail(decor,x,rear,front,terrace_height)
        a.layout["slabs"].append([[(x-.07,terrace_height(front)+1.1,front),
                                   (x+.07,terrace_height(front)+1.1,front),
                                   (x+.07,terrace_height(rear)+1.1,rear),
                                   (x-.07,terrace_height(rear)+1.1,rear)],1.11])
    x0,x1=sorted((side*13.05,side*18.02))
    def stair_height(x,z):
        return height(z)+2.05*(abs(x)-13.05)/4.97
    a.slab(street,"Cross-stair collision",
           [(x0,stair_height(x0,z1),z1),(x1,stair_height(x1,z1),z1),
            (x1,stair_height(x1,z0),z0),(x0,stair_height(x0,z0),z0)],.42,"grout")
    for i in range(12):
        x=side*(13.05+(i+.5)*4.97/12)
        street.beam("Cross-stair concrete tread",(x,stair_height(x,z0)-.035,z0),
                    (x,stair_height(x,z1)-.035,z1),.41,.17,"tile")
        x-=side*.16
        street.beam("Cross-stair yellow nosing",(x,stair_height(x,z0)+.103,z0),
                    (x,stair_height(x,z1)+.103,z1),.046,.026,"gold")
    for z in (z0,z1):
        a.layout["slabs"].append([[(x0,stair_height(x0,z)+1.05,z+.056),(x1,stair_height(x1,z)+1.05,z+.056),
                                   (x1,stair_height(x1,z)+1.05,z-.056),(x0,stair_height(x0,z)+1.05,z-.056)],1.07])
        for offset in (.28,1.04):
            decor.beam("Cross-stair handrail",(x0,stair_height(x0,z)+offset,z),
                       (x1,stair_height(x1,z)+offset,z),.102,.108,"green")
        for x in (side*13.25,side*15.65,side*17.89):
            decor.box("Cross-stair rail post",(x,stair_height(x,z)+.54,z),(.12,1.08,.12),"green")
for z in (-15,-10,0,10,15):
    a.solid(street,"Service guard",(17.5,height(z)+.55,z),(.13,1.1,1.3),"gold")
for x in (-10.2,10.2,16.65):
    for z in range(-17,18):
        street.box("Drainage grate",(x,height(z)+.022,z),(.30,.035,.94),"ink")
        for j in range(5):
            street.box("Drainage grate bar",(x,height(z)+.047,z+(j-2)*.16),(.31,.025,.024),"metal")
for i in range(-19,20):
    x=i*.43
    street.box("Entrance yellow tactile tile",(x,.016,18.3),(.416,.028,.59),"gold")
    for dx in (-.105,.105):
        for dz in (-.16,.16):
            street.box("Raised tactile stud",(x+dx,.037,18.3+dz),(.087,.018,.087),"yellow")
for z in (-12,-3,6,14):
    street.beam("Transverse drain",(-10,height(z)+.025,z),(10,height(z)+.025,z),.29,.032,"ink")
    for x in range(-9,10):
        street.box("Cross drain teeth",(x,height(z)+.048,z),(.062,.024,.29),"metal")
for x in (-13,13):
    a.solid(street,"Lower stair railing",(x,.53,23),(8,1.05,.12),"green")
    for i in range(12):
        street.box("Vertical picket",(x-3.8+i*.69,.53,23),(.075,1.05,.14),"mint")
# The seafront rail leaves a clear view of the water while keeping the old edge.
a.layout["boxes"].append([(0,1.25,24.85),(46,2.5,.3),0])
build_harbour(a)
# The upper landing now connects to the minibus stop.
for x in (-15,15):
    street.box("Upper curb", (x,3.74,-24.85),(16,.08,.31),"green")
a.solid(street,"Bus lane at the market crest",(0,3.49,-27.20),(46,.42,4.60),"asphalt")
a.layout["boxes"].append([(0,5.15,-29.48),(46,2.91,.24),0])
for side in (-1,1):
    a.layout["boxes"].append([(side*23.1,5.15,-26.92),(.25,2.91,5.10),0])
for x in range(-19,20,4):
    street.box("Bus lane road marking",(x,3.714,-28.9),(2.35,.022,.12),"gold")

for row,z in enumerate((-21,-15,-9,-3,3,9,15,21)):
    y=terrace_height(z)
    for x,side in [(-23.35,1),(23.35,-1)]:
        tone=("pink","lilac","warm")[row%3] if side==1 else ("lilac","steel","concrete")[row%3]
        a.solid(district,"Tong lau wall" if side==1 else "Service façade",(x,y+4.9,z),(.70,10.6,6.02),tone)
        front=x+side*.38
        district.box("Mosaic skirting",(front,y+.65,z),(.065,1.32,5.96),"tile")
        for i in range(13):
            for j in range(3):
                if (i*7+j+row)%4!=0:
                    district.box("Individual ceramic tile",(front+side*.045,y+.27+j*.39,z+(i-6)*.445),(.035,.27,.36),("mint","teal","white")[(i+j)%3])
        for floor in (1,2):
            yy=y+2.1+floor*2.45
            for dz in (-1.58,1.54):
                district.box("Window recess",(front+side*.06,yy,z+dz),(.14,1.46,1.46),"navy")
                district.box("Warm glazing",(front+side*.15,yy,z+dz),(.035,1.29,1.29),"window" if (row+floor)%3 else "steel")
                for t in (-.32,0,.32):
                    district.box("Window mullion",(front+side*.183,yy,z+dz+t),(.04,1.3,.047),"green")
                district.box("Window rail",(front+side*.185,yy,z+dz),(.042,.055,1.32),"green")
            district.box("Window air conditioner",(front+side*.27,yy-.74,z+.20),(.61,.51,.83),"metal")
            for t in range(5):
                district.box("Air conditioner grille",(front+side*.60,yy-.91+t*.075,z+.20),(.025,.027,.64),"steel")
        for dz in (-1.70,1.53):
            yy=y+2.67
            district.box("Window AC metal cage",(front+side*.27,yy,z+dz),(.56,.56,.79),"steel")
            district.box("Window AC ivory housing",(front+side*.41,yy,z+dz),(.34,.48,.71),"white")
            district.box("Window AC dark intake",(front+side*.593,yy,z+dz),(.038,.34,.56),"ink")
            for j in range(6):
                district.box("Window AC intake louvre",(front+side*.625,yy+(j-2.5)*.054,z+dz),(.036,.017,.58),"metal")
            for dz_bracket in (-.26,.26):
                district.beam("Triangular AC mounting bracket",(front,yy-.63,z+dz+dz_bracket),
                              (front+side*.51,yy-.29,z+dz+dz_bracket),.064,.062,"steel")
        district.box("Shopfront frame",(front+side*.07,y+1.46,z),(.16,2.95,3.48),"green")
        if side == -1 or row%3==0:
            for j in range(18):
                district.box("Roller shutter slat",(front+side*.18,y+.24+j*.148,z),(.085,.133,3.12),("steel","metal")[j%2])
            district.box("Shutter barrel housing",(front+side*.29,y+2.91,z),(.31,.28,3.42),"navy")
            district.box("Shutter bottom rail",(front+side*.24,y+.17,z),(.15,.092,3.18),"navy")
            district.box("Shutter latch",(front+side*.35,y+.60,z-.75),(.12,.11,.21),"gold")
        else:
            district.box("Recessed green door",(front+side*.15,y+1.40,z),(.075,2.76,1.22),"green")
            district.box("Frosted shop pane",(front+side*.15,y+1.67,z+1.09),(.075,1.60,.81),"window")
        district.box("Shop rain hood",(front+side*.57,y+3.12,z),(.99,.16,3.7),"teal" if row%2 else "blue")
        district.box("Warm wall fixture",(front+side*.21,y+2.68,z-2),(.31,.17,.65),"light")
        district.rod("Vertical rain pipe",(front+side*.20,y,z+2.62),(front+side*.20,y+9.3,z+2.62),.052,"steel",6)
        if side==1 and row in (3,4,5):
            # Deep shopfront reveals sit behind the existing stair-side wall line.
            for dz in (-1.58,1.54):
                yy=y+4.55
                for offset in (-.78,.78):
                    district.box("Masonry window cheek",(front+side*.19,yy,z+dz+offset),(.36,1.72,.13),"tile")
                district.box("Projecting stone sill",(front+side*.23,yy-.77,z+dz),(.48,.16,1.76),"white")
                district.box("Deep window lintel",(front+side*.17,yy+.76,z+dz),(.33,.15,1.73),"tile")
            projection=.41 if row==4 else .26
            district.box("Projecting shop fascia",(front+side*projection,y+3.47,z),
                         (.22,.54,3.2),"red" if row==4 else "blue")
            district.box("Cream fascia lower rim",(front+side*(projection+.09),y+3.21,z),(.09,.065,3.22),"white")
for i in range(16):
    x=-32+i*4.3
    y=7+((i*13)%8)*.65
    rear_z=-44.5-(i%3)*1.1 if -27<x<10 else -31-(i%3)*2
    district.box("Distant tenement",(x,y*.5,rear_z),(4.25,y,4.4),("navy","steel","blue")[i%3])
    for j in range(int(y//1.3)):
        for dx in (-1.12,.19,1.33):
            if (j+i+int(dx))%4==0:
                district.box("Lit apartment window",(x+dx,1+j*1.3,rear_z+2.25),(.42,.43,.05),"window")

neon=a.kit("street_neon",True)
left_z=11.2
left_y=terrace_height(left_z)+4.82
sign(neon,"深記海鮮",(-21.75,left_y,left_z),0,(1.56,4.45),"neon_red","neon_cream",vertical=True)
for y in (left_y+1.70,left_y-1.66):
    neon.beam("Seafood sign wall arm",(-22.98,y,left_z),(-21.15,y,left_z),.11,.13,"steel")
    neon.beam("Triangular wall brace",(-22.98,y-.48,left_z),(-21.93,y,left_z),.076,.085,"steel")
    neon.box("Seafood sign anchor plate",(-22.97,y,left_z),(.10,.27,.27),"navy")
sign(neon,"潮記茶餐廳",(-22.58,terrace_height(1.4)+4.02,1.4),math.pi/2,
     (4.4,.99),"neon_amber","restaurant_red")

ice_angle=-.95
ice_y=terrace_height(8.0)+5.81
ice_center=(20.42,ice_y,8.0)
fish_at=sign(neon,"海旁冰廠",ice_center,ice_angle,(7.35,1.76),"neon_mint","neon_cream",fish=True)
for u in (-2.56,0,2.56):
    x=ice_center[0]+math.cos(ice_angle)*u
    z=ice_center[2]-math.sin(ice_angle)*u
    neon.beam("Iceworks sign tie-back",(x,ice_y+.53,z),(22.99,ice_y+.53,z),.11,.12,"steel")
    neon.beam("Iceworks sign bracket",(x,ice_y-.56,z),(22.99,ice_y-.91,z),.11,.12,"steel")
fish_neon=a.kit("neon_fish")
build_fish(fish_neon)
a.moving("neon_fish",fish_at,ice_angle)
sign(neon,"鮮魚批發",(22.55,terrace_height(-3)+3.53,-3),-math.pi/2,
     (3.86,.87),"neon_cream","neon_blue")
sign(neon,"通宵供冰",(21.82,terrace_height(-20)+4.22,-20),0,
     (1.25,3.28),"neon_blue","neon_cream",vertical=True)
for y in (terrace_height(-20)+3.06,terrace_height(-20)+5.38):
    neon.beam("Supply sign wall bracket",(21.82,y,-20),(22.99,y,-20),.094,.105,"steel")
build_storefront(a.kit("minibus_storefront",True),-3.65,-30.75)
build_restaurant_row(a)
a.layout["neon_lamps"] = [
    [(-21.0,left_y-.35,left_z),"ff6663",0.0],
    [(19.98,ice_y-.48,8.0),"82f3cd",2.1],
]

# Blue roof on peaked steel rafters with woven raincloth hung from the bamboo.
a.layout["awnings"]=[]
roof_spans=[(6.7,16.95),(-4.4,5.4),(-17.4,-5.5)]
for i,(z0,z1) in enumerate(roof_spans):
    count=round((z1-z0)/3)
    for j in range(count+1):
        z=z0+(z1-z0)*j/count
        y=height(z)
        for side in (-1,1):
            x=side*8.95
            canopy.beam("Peaked blue roof steel rafter",(x,y+3.41,z),(0,y+4.82,z),.135,.17,"navy")
            if j%2==0:
                canopy.rod("Roof support upright",(x,y,z),(x,y+3.48,z),.075,"bamboo")
                for dy in (-.09,0,.09):
                    canopy.rod("Rope binding",(x,y+3.32+dy,z-.106),(x,y+3.32+dy,z+.106),.083,"rope",8)
    for side in (-1,1):
        for j in range(5):
            x0,x1=(side*8.95*n/5 for n in (j,j+1))
            y0,y1=(4.86-1.42*abs(x)/8.95 for x in (x0,x1))
            canopy.facet("Blue rain roof panel",[(x0,height(z0)+y0,z0),(x1,height(z0)+y1,z0),
                         (x1,height(z1)+y1,z1),(x0,height(z1)+y0,z1)],
                         ("blue","canvas","blue","turq","canvas")[(i+j)%5])
            canopy.beam("Longitudinal roof seam",(x0,height(z0)+y0-.08,z0),
                        (x0,height(z1)+y0-.08,z1),.074,.083,"navy")
        for z in (z1-.12,z0+.25):
            y=height(z)
            x=side*7.34
            canopy.rod("Tarpaulin bamboo header",(x-1.56,y+3.32,z),(x+1.56,y+3.32,z),.056,"bamboo")
            a.layout["awnings"].append([[x,y+3.32,z],3.0,.83,0])
        z=z1-1.48
        x=side*8.92
        y=height(z)
        canopy.beam("Side tarpaulin bamboo header",(x,y+3.33,z-1.18),
                    (x,y+3.33,z+1.18),.075,.075,"bamboo")
        a.layout["awnings"].append([[x,y+3.33,z],2.28,.75,side*math.pi/2])
for z in (-15,-10,-5,0,5,10,15):
    y=height(z)
    canopy.rod("Central lamp suspension",(0,y+3.81,z),(0,y+4.8,z),.031,"ink",8)
    canopy.box("Warm fluorescent housing",(0,y+3.82,z),(1.42,.19,.49),"gold")
    canopy.box("Yellow fluorescent diffuser",(0,y+3.71,z),(1.31,.09,.40),"light")
    if z in (-15,-5,5,15):
        a.spot((0,y+3.64,z),(0,y,z),"ffd075",3.05,8.3,48)
for x in (-6.2,6.2):
    for z in (-12,-8,-1,3,9,13,16):
        y=height(z)
        canopy.rod("Pendant cord",(x,y+2.68,z),(x,y+3.7,z),.035,"ink",5)
        canopy.rod("Red market lamp",(x,y+2.60,z),(x,y+2.86,z),.41,"red",10,.15)
        canopy.rod("Glowing lamp underside",(x,y+2.57,z),(x,y+2.61,z),.34,"light",10)

fish=a.kit("fish_counter")
fish.box("Tiled seafood counter",(0,.53,0),(2.24,1.06,3.35),"teal")
for i in range(8):
    for j in range(3):
        fish.box("Turquoise ceramic tile",(1.126,.21+j*.31,-1.43+i*.41),(.055,.275,.365),("turq","mint","teal")[(i+j)%3])
        fish.box("Turquoise ceramic tile",(-1.126,.21+j*.31,-1.43+i*.41),(.055,.275,.365),("turq","mint","teal")[(i+j)%3])
for i in range(3):
    z=(i-1)*1.06
    fish.box("Stainless seafood tray",(0,1.095,z),(2.18,.11,.94),"metal")
    fish.box("Crushed ice bed",(0,1.16,z),(1.97,.075,.78),"ice")
    for j in range(5):
        x=(j-2)*.34
        tint="fish" if (i+j)%3 else "salmon"
        fish.rod("Faceted whole fish",(x-.09,1.26,z-.19),(x+.10,1.28,z+.22),.098,tint,5,.041)
        fish.facet("Fish tail",[(x+.10,1.28,z+.21),(x+.22,1.25,z+.31),(x+.04,1.25,z+.32)],tint)
        fish.box("Fish eye",(x-.075,1.334,z-.13),(.038,.019,.04),"ink")
    fish.box("Blank price card",(.67,1.30,z-.34),(.20,.18,.055),"yellow")
fish.box("Red scale base",(-.68,1.21,1.42),(.56,.16,.35),"red")
fish.rod("Scale dial",(-.67,1.42,1.52),(-.67,1.42,1.58),.163,"white",12)
fish.rod("Stainless scale pan",(-.67,1.54,1.42),(-.67,1.64,1.42),.16,"metal",12,.28)
fish.box("Scale needle",(-.66,1.43,1.588),(.028,.15,.026),"red",.30)

tank=a.kit("live_fish_tank")
tank.box("Tiled tank plinth",(0,.39,0),(2.12,.78,3.28),"teal")
tank.box("Tank recessed water",(0,1.13,0),(1.96,.07,3.07),"turq")
for side in (-1,1):
    tank.box("Tall blue tank wall",(side*1.01,1.04,0),(.16,.53,3.32),"teal")
    tank.box("White overflow lip",(side*1.01,1.32,0),(.20,.10,3.34),"white")
    tank.box("Tank end wall",(0,1.04,side*1.59),(2.04,.53,.16),"teal")
    tank.box("Tank end lip",(0,1.32,side*1.59),(2.18,.10,.19),"white")
for z in (-1.0,0,1.0):
    tank.box("Green pump return channel",(.71,1.19,z),(.46,.06,.13),"mint")
    for x in (-.54,.13):
        tank.rod("Live fish",(x-.14,1.17,z-.16),(x+.06,1.22,z+.18),.092,"fish",5,.035)
        tank.facet("Live fish tail",[(x+.06,1.22,z+.18),(x+.03,1.18,z+.30),(x+.23,1.18,z+.25)],"fish")
tank.rod("Overflow return riser",(.79,.79,-1.21),(.79,1.29,-1.21),.074,"metal",8)
tank.rod("Overflow return spout",(.79,1.29,-1.21),(.50,1.29,-1.21),.073,"metal",8)

prep=a.kit("fish_prep_station")
prep.box("Butcher block worktop",(0,.96,0),(2.12,.13,3.24),"bamboo")
for x in (-.91,.91):
    for z in (-1.47,1.47):
        prep.box("Stainless prep table leg",(x,.46,z),(.12,.91,.12),"steel")
prep.box("Under-table shelf",(0,.36,0),(1.95,.10,2.86),"steel")
prep.box("Rinsing tub",(.58,.59,.86),(.62,.42,.69),"blue")
prep.box("End grain chopping block",(-.36,1.065,-.38),(.93,.11,.85),"warm")
prep.box("Cleaver blade",(-.34,1.14,-.22),(.42,.048,.22),"metal",.26)
prep.box("Cleaver wooden handle",(-.66,1.14,-.31),(.23,.069,.087),"bamboo",.26)
prep.rod("Hanging scale upright",(.75,1.0,1.38),(.75,2.11,1.38),.061,"steel",8)
prep.rod("Hanging scale boom",(.75,2.11,1.38),(-.35,2.11,1.38),.053,"steel",8)
prep.rod("Hanging scale hook",(-.35,2.11,1.38),(-.35,1.71,1.38),.024,"metal",7)
prep.rod("Hanging scale dial",(-.35,1.71,1.44),(-.35,1.71,1.57),.23,"red",12)
prep.rod("Hanging scale face",(-.35,1.71,1.57),(-.35,1.71,1.59),.17,"white",12)
prep.box("Hanging scale pointer",(-.35,1.74,1.61),(.022,.19,.024),"ink",.28)
prep.rod("Hanging scale pan",(-.35,1.35,1.38),(-.35,1.43,1.38),.28,"metal",10,.36)
for x in (-.23,.23):
    prep.rod("Scale pan wire",(-.35,1.52,1.38),(-.35+x,1.43,1.38),.018,"steel",6)

produce=a.kit("produce_counter")
produce.box("Wooden produce table",(0,.47,0),(2.18,.92,3.38),"bamboo")
for i,z in enumerate((-1,0,1)):
    produce.box("Vegetable crate rim",(0,1.02,z),(2.05,.23,.88),"orange")
    for j in range(8):
        for k in range(2):
            x=(j-3.5)*.235
            produce.rod("Fruit or vegetables",(x,1.16,z+(k-.5)*.36),(x,1.32,z+(k-.5)*.36),.14,
                        ("leaf","fruit","salmon")[(i+j//4)%3],5,.089)
for x,z,asset in [(-6.1,14,"fish_counter"),(-6.1,9.9,"live_fish_tank"),(-6.1,2,"fish_prep_station"),
                  (6.1,13.8,"fish_prep_station"),(6.1,9.7,"live_fish_tank"),(6.1,2,"produce_counter"),
                  (-6.1,-3.5,"produce_counter"),(6.1,-3.5,"produce_counter"),
                  (-6.1,-12,"produce_counter"),(6.1,-12,"produce_counter"),(-6.1,-16,"produce_counter")]:
    a.prop(asset,(x,height(z),z),(2.22,1.38,3.42),effect="produce" if asset=="produce_counter" else "ice")

screen=a.kit("stall_screen")
screen.box("Striped destructible market partition",(0,1,0),(.18,1.9,3.4),"white")
for j in range(9):
    screen.box("Panel stripe",(0,1.02,(j-4)*.36),(.198,1.79,.22),("red","blue","white")[j%3])
for z in (-1.67,1.67):
    screen.box("Screen end post",(0,.99,z),(.15,1.98,.10),"green")
a.prop("stall_screen",(10.1,height(8.2),8.2),(.20,2.05,3.4),name="ServiceShortcut",effect="ice",structural=True)
for z0,z1 in [(2.35,6.50),(9.90,14.72)]:
    quad=[(10.0,height(z1)+1.6,z1),(10.2,height(z1)+1.6,z1),
          (10.2,height(z0)+1.6,z0),(10.0,height(z0)+1.6,z0)]
    a.slab(decor,"Continuous service-lane divider",quad,1.65,"green")
    decor.beam("Divider metal edging",(10.1,height(z0)+1.62,z0),(10.1,height(z1)+1.62,z1),.28,.09,"bamboo")
    for i in range(round((z1-z0)/.29)):
        z=z0+.14+i*.29
        decor.box("Painted divider stripe",(10.224,height(z)+1.31,z),(.048,.35,.17),("red","white","blue")[i%3])

# Drain hardware and a water feed identify the wet-side shortcut.
z=6.22
y=height(z)
decor.rod("Wash supply riser",(10.35,y+.09,z),(10.35,y+1.35,z),.071,"metal",8)
decor.rod("Wash pipe elbow",(10.35,y+1.35,z),(10.54,y+1.35,z),.074,"metal",8)
decor.rod("Red isolation valve",(10.35,y+1.05,z),(10.60,y+1.05,z),.18,"red",8,.14)
for z in (2.55,13.45):
    for x in (-11.9,-11.48,-11.06):
        street.box("Crossing anti-slip tile",(x,height(z)+.025,z),(.34,.043,1.31),"yellow")

crates=a.kit("crates")
crates.box("Foam box",(0,.24,0),(.91,.48,.71),"white")
crates.box("Foam lid",(0,.48,0),(.97,.085,.77),"white")
crates.box("Red foam-box tape",(0,.30,0),(.923,.084,.724),"red")
crates.box("Orange fish crate",(.72,.24,.11),(.56,.47,.64),"orange")
for j in range(6):
    crates.box("Crate recess",(.515+j*.079,.28,.438),(.045,.25,.026),"red")
crates.box("Crate rim",(.72,.48,.11),(.6,.08,.68),"gold")
for x,z in [(-8.5,16),(-8.5,12),(-8.5,-6),(8.4,15),(8.5,-5),(14,5),(-2,-17),(2,8),(-19.15,6.1),(-21.8,-10.8),(19.1,-.9),(21.6,12.4)]:
    a.prop("crates",(x,ground(x,z)[1]-.06,z),(1.5,.53,.86),effect="ice")

streetprops=a.kit("small_props",True)
for x,z in [(9.3,16),(9.5,12),(-8.9,-13),(15.8,-11),(14.6,14.8),(-8.9,7.0)]:
    y=height(z)
    streetprops.box("Red-white-blue market bag",(x,y+.28,z),(.65,.55,.41),"white")
    for i in range(5):
        streetprops.box("Nylon woven stripe",(x+(i-2)*.115,y+.28,z),(.073,.54,.427),("red","blue")[i%2])
    streetprops.rod("Bag handle",(x-.22,y+.54,z),(x+.22,y+.54,z),.041,"blue",6)
stool=a.kit("market_stool")
for dx in (-1,1):
    for dz in (-1,1):
        stool.beam("Flared stool leg",(dx*.255,.02,dz*.255),(dx*.199,.435,dz*.196),.101,.093,"red")
    stool.box("Molded stool apron",(dx*.226,.389,0),(.065,.119,.42),"red")
    stool.box("Seat surround",(dx*.158,.465,0),(.16,.086,.45),"red")
    stool.box("Seat surround",(0,.465,dx*.154),(.16,.086,.142),"red")
for x,z in [(7.88,16.2),(8.61,16.0),(7.9,8.2),(-8.25,15.3),(7.8,-17.3),(21.72,-1.8)]:
    a.prop("market_stool",(x,ground(x,z)[1]-.06,z),(.54,.51,.54),angle=.19,effect="produce")
cart=a.kit("shutter_trolley")
cart.box("Blue trolley deck",(0,.20,0),(.83,.10,1.06),"blue")
for x in (-.29,.29):
    for z in (-.36,.36):
        cart.rod("Rubber caster",(x-.071,.103,z),(x+.071,.103,z),.102,"ink",10)
    cart.rod("Pusher tube",(x,.22,-.42),(x,1.13,-.50),.036,"blue")
cart.rod("Pusher handle",(-.30,1.12,-.50),(.30,1.12,-.50),.042,"blue")
for i in range(3):
    y=.35+i*.28
    cart.box("Stacked foam cooler",(0,y,0),(.72,.268,.66),"white")
    cart.box("Foam cooler tape",(0,y-.051,0),(.725,.053,.667),"red")
    cart.box("Foam cooler lid",(0,y+.127,0),(.745,.038,.68),"white")
for x,z in [(22.0,9.35),(21.9,-5.94),(-22.0,2.6)]:
    a.prop("shutter_trolley",(x,terrace_height(z),z),(.89,1.18,1.11),angle=.24,effect="ice")

wash=a.kit("fish_wash")
wash.box("Fish wash porcelain basin",(0,.94,0),(1.52,.23,.77),"white")
wash.box("Basin recessed drain",(0,1.06,0),(1.19,.025,.51),"steel")
for x in (-.65,.65):
    wash.box("Fish wash tiled plinth",(x,.47,0),(.21,.93,.71),"teal")
wash.rod("Tap neck",(-.34,1.05,-.24),(-.34,1.35,-.24),.046,"metal",8)
wash.rod("Tap spout",(-.34,1.35,-.24),(-.34,1.31,.08),.045,"metal",8)
for i in range(12):
    angle=i*math.tau/12
    next_angle=(i+1)*math.tau/12
    wash.rod("Coiled hose",(.34+math.cos(angle)*.23,1.27+math.sin(angle)*.23,-.28),
             (.34+math.cos(next_angle)*.23,1.27+math.sin(next_angle)*.23,-.28),.034,"yellow",6)
a.prop("fish_wash",(-9.75,height(12.25),12.25),(1.55,1.54,.83),effect="ice")

kiosk=a.kit("tea_hatch")
kiosk.box("Cha chaan teng wall",(0,1.53,0),(3.25,3.06,.15),"warm")
kiosk.box("Serving opening",(0,1.58,.11),(2.53,1.34,.09),"window")
kiosk.box("Formica tea counter",(0,.94,.38),(2.89,.16,.65),"bamboo")
for x in (-.83,-.35,.19,.71):
    kiosk.rod("Milk tea urn",(x,1.02,.38),(x,1.48,.38),.17,"metal",9)
    kiosk.rod("Urn lid",(x,1.48,.38),(x,1.53,.38),.175,"ink",9)
kiosk.box("Shop sign casing",(0,2.59,.14),(3.18,.66,.17),"red")
a.prop("tea_hatch",(6.2,height(-16.8),-16.8),(3.28,3.06,.66),effect="produce")
a.sign("TeaShop","tea-shop",(6.2,height(-16.8)+2.59,-16.54),(2.97,.54))
a.sign("FishShop","fish-shop",(-6.05,height(15.8)+2.91,15.9),(2.34,.68))
canopy.box("Fish sign housing",(-6.05,height(15.8)+2.91,15.82),(2.5,.78,.12),"red")

bus=a.kit("minibus",True)
bx,by,bz=2.25,3.7,-27.04
def bus_box(label,at,size,color):
    bus.box(label,(bx+at[0],by+at[1],bz+at[2]),size,color)

def bus_solid(label,at,size,color):
    a.solid(bus,label,(bx+at[0],by+at[1],bz+at[2]),size,color)

door_x=1.13
door_z=bz+1.10
# Divide the shell around a 2 m opening on the market-facing side.
for lo,hi in [(-3.21,.10),(2.16,3.30)]:
    bus_solid("Solid body beside boarding door",((lo+hi)*.5,1.32,0),(hi-lo,1.94,2.09),"white")
bus_solid("Cabin back wall",(door_x,1.29,-.83),(2.06,2.02,.40),"navy")
bus_solid("Cabin floor",(door_x,.13,.05),(2.06,.32,1.56),"ink")
bus_box("Dark cabin step edge",(door_x,.26,.82),(2.01,.083,.18),"ink")
a.slope(bus,"Boarding step collision",bx+.10,bx+2.16,bz+.80,bz+1.85,by+.29,by,.18,"steel")
for depth in (1.0,1.53):
    y=.29*(1-(depth-.80)/1.05)
    bus_box("Yellow step nosing",(door_x,y+.015,depth),(1.99,.033,.054),"gold")
for x in (.13,2.13):
    bus_box("Boarding door jamb",(x,1.26,1.075),(.072,1.93,.09),"ink")
bus_box("Boarding door lintel",(door_x,2.24,1.07),(2.08,.12,.13),"navy")
bus_box("Boarding cabin lamp",(door_x,2.16,.72),(.64,.08,.24),"light")
bus_box("Red public light bus roof",(-.16,2.34,0),(6.02,.24,2.11),"red")
bus_box("Red rounded roof cap",(-.16,2.48,0),(5.75,.095,1.89),"red")
bus_box("Cab forward fascia",(3.30,1.12,0),(.23,.62,2.01),"white")
bus_box("Dark windscreen",(2.72,1.94,0),(.091,.66,1.82),"navy")
bus_box("Route display housing",(2.774,2.22,0),(.071,.15,1.18),"ink")
bus_box("Amber route display",(2.82,2.22,0),(.025,.096,.94),"light")
for s in (-1,1):
    if s<0:
        bus_box("Window belt stripe",(0,1.48,s*1.058),(6.41,.16,.071),"red")
    else:
        for lo,hi in [(-3.21,.10),(2.16,3.30)]:
            bus_box("Window belt stripe",((lo+hi)*.5,1.48,s*1.058),(hi-lo,.16,.071),"red")
    for i in range(6):
        x=-2.68+i*.96
        if s>0 and x+.45>.10 and x-.45<2.16:
            continue
        bus_box("Passenger window gasket",(x,1.92,s*1.035),(.865,.69,.052),"ink")
        bus_box("Blue passenger glazing",(x,1.94,s*1.068),(.80,.57,.023),"steel")
        bus_box("Window reflection",(x,2.17,s*1.086),(.70,.048,.017),"fish")
    bus_box("Side mirror arm",(2.56,1.94,s*1.14),(.16,.061,.25),"steel")
    bus_box("Side mirror",(2.61,1.97,s*1.28),(.13,.245,.107),"ink")
    bus_box("Bus headlamp",(3.43,1.09,s*.71),(.039,.22,.39),"light")
    bus_box("Bus red tail lamp",(-3.24,1.05,s*.78),(.041,.24,.26),"red")
    for x in (-2.09,2.52):
        bus.rod("Recessed wheel arch",(bx+x,by+.46,bz+s*1.05),(bx+x,by+.46,bz+s*1.08),.465,"ink",12)
        bus.rod("Rubber tire",(bx+x,by+.43,bz+s*.79),(bx+x,by+.43,bz+s*1.115),.405,"ink",14)
        bus.rod("Steel wheel cap",(bx+x,by+.43,bz+s*1.12),(bx+x,by+.43,bz+s*1.145),.234,"metal",12)
bus_box("Front bumper",(3.42,.71,0),(.22,.22,2.10),"ink")
bus_box("Front grille",(3.45,1.08,0),(.066,.23,.83),"ink")
for y in (1.015,1.081,1.147):
    bus_box("Front grille chrome slat",(3.49,y,0),(.025,.017,.78),"metal")

door=a.kit("minibus_door")
door.box("Painted sliding passenger door",(0,-.39,0),(2.01,1.14,.105),"white")
door.box("Dark window seal",(0,.56,0),(2.01,.81,.114),"ink")
door.box("Sliding door tinted pane",(0,.56,.064),(1.78,.65,.018),"steel")
door.box("Door kick stripe",(0,.14,.063),(2.0,.15,.025),"red")
door.box("Passenger door handle",(.71,.04,.079),(.21,.054,.044),"ink")
a.moving("minibus_door",(bx+door_x,by+1.28,door_z))
a.layout["minibus_entry"]=[(bx+door_x,by+.35,bz+.43)]
a.layout["minibus_rallies"]=[ground(x,z) for x,z in [(0,10),(-13,10),(13,8)]]

x,z=-2.47,-24.04
a.solid(decor,"Minibus stop post",(x,4.98,z),(.09,2.54,.09),"red")
decor.rod("Circular minibus stop sign",(x,6.07,z),(x,6.07,z+.08),.39,"red",24)
a.sign("MinibusStop","minibus-stop",(x,6.07,z+.085),(.75,.75))
decor.box("Timetable mount",(x,5.18,z+.075),(.45,.57,.095),"navy")
for j in range(6):
    decor.box("Minibus timetable rule",(x,5.02+j*.064,z+.133),(.34,.018,.013),"white")
for x,z in [(-4.48,-22.55),(4.17,-22.72),(-14.45,-20.8),(14.85,-20.7)]:
    a.layout["boxes"].append([(x,4.145,z),(1.52,.89,.15),0])
    for side in (-1,1):
        xx=x+side*.68
        decor.rod("Yellow bicycle barrier leg",(xx,3.7,z),(xx,4.42,z),.064,"gold",8)
        decor.rod("Yellow bicycle barrier elbow",(xx,4.42,z),(x+side*.55,4.55,z),.064,"gold",8)
    decor.rod("Yellow bicycle barrier top",(x-.55,4.55,z),(x+.55,4.55,z),.064,"gold",8)

for x,z,color in [(-6.2,12,"ffb974"),(6.2,12,"f286a0"),(-6.2,2,"ffc280"),(6.2,-5,"ffb974"),(-6.2,-12,"ffa56f")]:
    y=height(z)
    a.spot((x,y+2.57,z),(x,y,z),color,3.2,7.2,62)
for x,z,color in [(-9.2,10,"40c3ff"),(9.6,11,"fe51be"),(8.2,-8,"fd6fbe"),(-9.4,-6,"4b8ffb")]:
    y=height(z)
    a.spot((x,y+3.1,z),(x,y,z-1),color,5.4,12.0,41,(1.9,0,1.5))
a.layout.update(
    start=ground(0,19), heading=0,
    opening=[ground(x,z) for x,z in [(-1,12),(13,14),(-15,14),(2,3),(-20.25,-8),(20.35,-8),(2,-10),(-2,10)]],
    spawns=[ground(x,z) for x,z in [(-20.4,19),(-20.1,8),(-20.35,-4),(-20.6,-14),(20.15,18),(20.15,7),(20.5,-5),(20.25,-15),
                                                  (0,-20),(-3,17),(1,1),(-2,-10),(3,11),(9,-9)]],
    respawns=[ground(x,z) for x,z in [(0,19),(-20.45,12),(20.2,17),(2,7),(-20.2,-6),(20.4,-12),(0,-18)]],
    route=[ground(x,z) for x,z in [(-20.5,18.9),(-20.5,10),(-20.5,-3.9),(-12.0,-3.9),(-20.5,-3.9),(-20.5,-18.9),
                                    (0,-19.5),(20.5,-18.9),(20.5,-8),(20.5,4.8),(12.3,4.8),(20.5,4.8),
                                    (20.5,18.9),(0,19),(0,2),(0,-9),(-10,2.55),(-15,2.55),(-10,13.45),(-15,13.45)]],
    barrels=[ground(x,z) for x,z in [(-3.9,8.0),(9.5,-9.6),(-8.1,-10.1)]],
    comedy=[8.7,height(20.4),20.4,0.0],
    cameras={
        "slope-entry":[[.1,2.29,22.15],[.22,2.56,-2],78],
        "fish-crossing":[[-19.2,2.67,19.68],[-13.25,2.87,10.45],80],
        "upper-crossing":[[-20.55,6.05,-3.88],[-9.6,2.7,-3.74],72],
        "shutter-lane":[[19.25,2.69,17.64],[22.02,4.06,9.50],69],
        "minibus-stop":[[-5.3,5.65,-20.15],[1.18,5.07,-26.9],70],
        "drive-through":[[-11.3,5.50,-25.40],[-9.2,5.35,-33.1],72],
        "late-night-shops":[[-13.8,5.55,-24.60],[-17.0,5.83,-32.4],71],
        "harbour":[[.25,1.74,21.65],[.25,.86,52.0],70],
        "wet-aisle":[[.40,1.45,16.12],[.38,1.47,1.9],73],
        "service-frenzy":[[12.1,2.63,13.5],[8.0,2.82,4.1],72],
    })
a.write()
