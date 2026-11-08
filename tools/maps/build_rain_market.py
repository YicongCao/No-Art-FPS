"""Build the Hong Kong hillside wet market from its overview and street views."""
import math
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from arena_kit import ArenaKit

P = {
    "road": ("4f526b",.31,0), "asphalt": ("666d86",.38,0), "concrete":"a09ab0",
    "tile":"d7bb9c", "grout":"626a76", "teal":"247b83", "mint":"6db1a6", "green":"256052",
    "navy":"233753", "steel":"526887", "white":"f3e6df", "metal":("8fa5b7",.30,0),
    "ink":"192638", "pink":"c88096", "lilac":"a59abd", "warm":"daa386",
    "turq":"259d9f", "blue":"4161bb", "canvas":"5367cb", "gold":"f3c452",
    "bamboo":"dca062", "rope":"f0cc93", "red":"d44d58", "orange":"e98334",
    "yellow":"ffdc70", "leaf":"8ab658", "fruit":"ecad43", "fish":"a6bfcc",
    "salmon":"dd7558", "ice":("bedbfa",.4,.12), "light":("ffd798",.55,.85),
    "pink_light":("fc668f",.55,.65), "window":("e6be83",.55,.24), "sign":("ffe9bb",.55,.55),
}
a=ArenaKit("rain_market",P,{"sky":"263a67","ambient":"c0ceff","energy":.71,"sun":"aebff3","sun_energy":.44,"sun_rotation":[-38,-34,0]})
street=a.kit("street",True)
district=a.kit("district",True)
canopy=a.kit("canopy",True)
decor=a.kit("street_detail",True)


def height(z):
    return max(0,min(3.7,(18-z)*3.7/36))


def ground(x,z):
    return (x,round(height(z)+.06,3),z)


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
    a.solid(street,"End landing",(0,base-.33,z),(36,.66,7),"asphalt")
for i in range(40):
    z=18-(i+.5)*.9
    y=height(z)+.045
    street.box("Ceramic stair tread",(-15,y-.08,z),(5.55,.16,.895),"tile")
    street.box("Stair nosing",(-15,y+.004,z+.42),(5.55,.034,.045),"grout")
for x in (-17.65,-12.28):
    for z in (-17,-13,-8,-3,3,8,13):
        rail(decor,x,z,z+3.1,height)
    # Rail runs leave an opening at each market crossing.
    if x == -17.65:
        for z in (-13.9,-8.9,-3.9,2.1,7.1,12.1):
            rail(decor,x,z,z+1.1,height)
for z in (-15,-10,0,10,15):
    a.solid(street,"Service guard",(17.5,height(z)+.55,z),(.13,1.1,1.3),"gold")
for x in (-10.2,10.2,16.65):
    for z in range(-17,18):
        street.box("Drainage grate",(x,height(z)+.022,z),(.30,.035,.94),"ink")
        for j in range(5):
            street.box("Drainage grate bar",(x,height(z)+.047,z+(j-2)*.16),(.31,.025,.024),"metal")
for z in (-12,-3,6,14):
    street.beam("Transverse drain",(-10,height(z)+.025,z),(10,height(z)+.025,z),.29,.032,"ink")
    for x in range(-9,10):
        street.box("Cross drain teeth",(x,height(z)+.048,z),(.062,.024,.29),"metal")
for x in (-13,13):
    a.solid(street,"Lower stair railing",(x,.53,23),(8,1.05,.12),"green")
    for i in range(12):
        street.box("Vertical picket",(x-3.8+i*.69,.53,23),(.075,1.05,.14),"mint")
# End facades and rails prevent jumps outside the route.
a.solid(street,"Foot boundary",(0,1.1,24.85),(36,2.2,.3),"navy")
a.solid(street,"Upper landing edge",(0,4.15,-24.8),(36,.90,.35),"green")

for row,z in enumerate((-21,-15,-9,-3,3,9,15,21)):
    y=height(z)
    for x,side in [(-18.35,1),(18.35,-1)]:
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
        district.box("Shopfront frame",(front+side*.07,y+1.46,z),(.16,2.95,3.48),"green")
        if side == -1:
            for j in range(18):
                district.box("Roller shutter slat",(front+side*.18,y+.24+j*.148,z),(.085,.133,3.12),("steel","metal")[j%2])
        else:
            district.box("Recessed green door",(front+side*.15,y+1.40,z),(.075,2.76,1.22),"green")
            district.box("Frosted shop pane",(front+side*.15,y+1.67,z+1.09),(.075,1.60,.81),"window")
        district.box("Shop rain hood",(front+side*.57,y+3.12,z),(.99,.16,3.7),"teal" if row%2 else "blue")
        district.box("Warm wall fixture",(front+side*.21,y+2.68,z-2),(.31,.17,.65),"light")
        district.rod("Vertical rain pipe",(front+side*.20,y,z+2.62),(front+side*.20,y+9.3,z+2.62),.052,"steel",6)
for i in range(16):
    x=-32+i*4.3
    y=7+((i*13)%8)*.65
    district.box("Distant tenement",(x,y*.5,-31-(i%3)*2),(4.25,y,4.4),("navy","steel","blue")[i%3])
    for j in range(int(y//1.3)):
        for dx in (-1.12,.19,1.33):
            if (j+i+int(dx))%4==0:
                district.box("Lit apartment window",(x+dx,1+j*1.3,-28.75-(i%3)*2),(.42,.43,.05),"window")

# Alternating tarps leave gaps over the cross lanes and let the rainy sky through.
for i,(z0,z1) in enumerate([(7.2,17.9),(-3.3,4.9),(-15.7,-5.6)]):
    for side in (-1,1):
        x=side*8.8
        inner=side*1.8
        for z in (z0,z1):
            y=height(z)
            canopy.rod("Tied bamboo upright",(x,y,z),(x,y+3.3,z),.083,"bamboo")
            canopy.rod("High canopy spine",(inner,y+1.9,z),(inner,y+4.22,z),.078,"green")
            canopy.rod("Roof rafter",(x,y+3.25,z),(inner,y+4.23,z),.082,"bamboo")
            for dy in (-.08,0,.08):
                canopy.rod("Rope binding",(x,y+3.25+dy,z-.102),(x,y+3.25+dy,z+.102),.085,"rope",6)
        for j in range(4):
            f0,f1=j/4,(j+1)/4
            left=x+(inner-x)*f0
            right=x+(inner-x)*f1
            y0=3.29+f0*.92
            y1=3.29+f1*.92
            canopy.facet("Tarpaulin color panel",[(left,height(z0)+y0,z0),(right,height(z0)+y1,z0),
                         (right,height(z1)+y1,z1),(left,height(z1)+y0,z1)],
                         ("turq","teal","canvas","blue")[(i+j+(side+1))%4])
        canopy.rod("Awning edge",(x,height(z0)+3.29,z0),(x,height(z1)+3.29,z1),.083,"bamboo")
        for j in range(7):
            zs=z1-j*.32
            canopy.facet("Striped canopy valance",[(x,height(zs)+3.29,zs),(x,height(zs-.32)+3.29,zs-.32),
                         (x+side*.18,height(zs-.32)+2.62,zs-.32),(x+side*.18,height(zs)+2.62,zs)],
                         ("red","white","blue")[j%3])
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

produce=a.kit("produce_counter")
produce.box("Wooden produce table",(0,.47,0),(2.18,.92,3.38),"bamboo")
for i,z in enumerate((-1,0,1)):
    produce.box("Vegetable crate rim",(0,1.02,z),(2.05,.23,.88),"orange")
    for j in range(8):
        for k in range(2):
            x=(j-3.5)*.235
            produce.rod("Fruit or vegetables",(x,1.16,z+(k-.5)*.36),(x,1.32,z+(k-.5)*.36),.14,
                        ("leaf","fruit","salmon")[(i+j//4)%3],5,.089)
for x,z,asset in [(-6.1,14,"fish_counter"),(-6.1,9.9,"fish_counter"),(-6.1,2,"fish_counter"),
                  (6.1,13.8,"produce_counter"),(6.1,9.7,"fish_counter"),(6.1,2,"produce_counter"),
                  (-6.1,-3.5,"produce_counter"),(6.1,-3.5,"produce_counter"),
                  (-6.1,-12,"produce_counter"),(6.1,-12,"produce_counter"),(-6.1,-16,"produce_counter")]:
    a.prop(asset,(x,height(z),z),(2.22,1.38,3.42),effect="ice" if asset=="fish_counter" else "produce")

screen=a.kit("stall_screen")
screen.box("Striped destructible market partition",(0,1,0),(.18,1.9,3.4),"white")
for j in range(9):
    screen.box("Panel stripe",(0,1.02,(j-4)*.36),(.198,1.79,.22),("red","blue","white")[j%3])
for z in (-1.67,1.67):
    screen.box("Screen end post",(0,.99,z),(.15,1.98,.10),"green")
a.prop("stall_screen",(10.1,height(8.2),8.2),(.20,2.05,3.4),name="ServiceShortcut",effect="ice",structural=True)

crates=a.kit("crates")
crates.box("Foam box",(0,.24,0),(.91,.48,.71),"white")
crates.box("Foam lid",(0,.48,0),(.97,.085,.77),"white")
crates.box("Red foam-box tape",(0,.30,0),(.923,.084,.724),"red")
crates.box("Orange fish crate",(.72,.24,.11),(.56,.47,.64),"orange")
for j in range(6):
    crates.box("Crate recess",(.515+j*.079,.28,.438),(.045,.25,.026),"red")
crates.box("Crate rim",(.72,.48,.11),(.6,.08,.68),"gold")
for x,z in [(-8.5,16),(-8.5,12),(-8.5,-6),(8.4,15),(8.5,-5),(14,5),(-2,-17),(2,8)]:
    a.prop("crates",(x,height(z),z),(1.5,.53,.86),effect="ice")

streetprops=a.kit("small_props",True)
for x,z in [(9.3,16),(9.5,12),(-8.9,-13),(15.8,-11),(14.6,14.8),(-8.9,7.0)]:
    y=height(z)
    streetprops.box("Red-white-blue market bag",(x,y+.28,z),(.65,.55,.41),"white")
    for i in range(5):
        streetprops.box("Nylon woven stripe",(x+(i-2)*.115,y+.28,z),(.073,.54,.427),("red","blue")[i%2])
    streetprops.rod("Bag handle",(x-.22,y+.54,z),(x+.22,y+.54,z),.041,"blue",6)
    for dx in (-.18,.18):
        for dz in (-.20,.20):
            streetprops.box("Stacked plastic stool leg",(x+dx,y+.24,z+.76+dz),(.09,.48,.10),"red")
    streetprops.box("Stacked plastic stool seat",(x,y+.48,z+.76),(.49,.10,.51),"red")
for x,z in [(15.2,11.7),(15.8,-15)]:
    y=height(z)
    for dz in (-.24,.24):
        streetprops.rod("Handcart wheel",(x-.15,y+.18,z+dz),(x+.12,y+.18,z+dz),.151,"ink")
        streetprops.rod("Handcart handle side",(x,y+.18,z+dz),(x+.19,y+1.1,z+dz),.035,"blue")
    streetprops.rod("Handcart top handle",(x+.19,y+1.1,z-.24),(x+.19,y+1.1,z+.24),.036,"blue")
    streetprops.box("Folded toe plate",(x+.25,y+.22,z),(.39,.09,.58),"metal")

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
bus.box("Red-roof public light bus",(0,4.93,-23.7),(6.5,2.06,2.06),"white")
bus.box("Red minibus roof",(0,5.97,-23.7),(6.57,.28,2.10),"red")
bus.box("Red body stripe",(0,4.35,-22.66),(6.43,.22,.07),"red")
for i in range(5):
    bus.box("Bus passenger windows",(-2.54+i*1.18,5.33,-22.65),(1.04,.73,.055),"navy")
for x in (-2.13,2.14):
    bus.rod("Bus tire",(x,4.11,-22.86),(x,4.11,-22.49),.41,"ink",12)
    bus.rod("Bus wheel hub",(x,4.11,-22.48),(x,4.11,-22.45),.22,"metal",10)

for x,z,color in [(-6.2,12,"ffb974"),(6.2,12,"f286a0"),(-6.2,2,"ffc280"),(6.2,-5,"ffb974"),(-6.2,-12,"ffa56f")]:
    y=height(z)
    a.spot((x,y+2.57,z),(x,y,z),color,3.2,7.2,62)
for x,z,color in [(-9.2,10,"40c3ff"),(9.6,11,"fe51be"),(8.2,-8,"fd6fbe"),(-9.4,-6,"4b8ffb")]:
    y=height(z)
    a.spot((x,y+3.1,z),(x,y,z-1),color,5.4,12.0,41,(1.9,0,1.5))
a.layout.update(
    start=ground(0,19), heading=0,
    opening=[ground(x,z) for x,z in [(-1,12),(13,14),(-15,14),(2,3),(-15,-9),(13,-9),(2,-10),(-2,10)]],
    spawns=[ground(x,z) for x,z in [(-15,19),(-15,8),(-15,-4),(-15,-14),(15,18),(15,7),(15,-5),(15,-15),
                                                  (0,-20),(-3,17),(1,1),(-2,-10),(3,11),(9,-9)]],
    respawns=[ground(x,z) for x,z in [(0,19),(-15,12),(14,17),(2,7),(-15,-6),(14,-12),(0,-18)]],
    route=[ground(x,z) for x,z in [(-15,2),(-15,-17),(0,-19),(15,-13),(15,6),(15,19),(0,2),(0,-9)]],
    barrels=[ground(x,z) for x,z in [(-3.9,8.0),(9.5,-9.6),(-8.1,-10.1)]],
    comedy=[8.7,height(20.4),20.4,0.0],
    cameras={
        "slope-entry":[[0,2.15,22],[0,3.2,-2],64],
        "fish-crossing":[[-3.5,2.43,17.6],[-9.6,3.15,8],62],
        "service-frenzy":[[14.0,2.55,13.8],[8.6,3.08,3.0],66],
    })
a.write()
