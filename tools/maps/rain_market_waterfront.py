"""Night waterfront and the row of shops across the minibus road."""

import math


def build_restaurant_row(arena):
    kit = arena.kit("restaurant_row", True)

    def box(label, x, y, z, width, height, depth, color, angle=0):
        kit.box(label, (x, y, z), (width, height, depth), color, angle)

    box("Forecourt asphalt", (-23.0+10.5)/2, 3.57, -35.9, 33.5, .25, 13.4, "road")
    box("Rear return lane", -4.0, 3.707, -39.4, 28, .025, 3.9, "asphalt")
    box("Pickup lane asphalt", -10.35, 3.707, -34.25, 3.73, .025, 10.9, "asphalt")
    box("Pavement below ramen and convenience stores", -18.8, 3.77, -31.5, 13.0, .14, 2.65, "concrete")
    box("End-of-row retaining wall", -25.25, 3.09, -34.0, .68, 1.29, 10.40, "steel")
    box("Retaining wall coping", -25.25, 3.78, -34.0, .78, .15, 10.40, "concrete")
    for z in (-29.1,-31.7,-34.3,-36.9,-39.0):
        box("Retaining wall post", -25.25, 4.23, z, .15, .90, .15, "navy")
    box("End-of-row railing", -25.25, 4.61, -34.0, .09, .09, 10.27, "metal")
    box("Painted curb beside pickup lane", -12.34, 3.76, -35.3, .15, .13, 8.28, "white")
    for z in (-31.2,-34.15,-37.17):
        box("Yellow pickup lane divider", -8.68, 3.733, z, .092, .026, 1.54, "yellow")
    for x in (-8,-4,0,4,8):
        box("Rear lane dash", x, 3.733, -39.38, 2.48, .025, .105, "yellow")
    for z in (-30.55,-36.9):
        kit.box("Directional arrow stem", (-10.47,3.735,z+.32), (.20,.019,.96), "white")
        kit.facet("Directional arrowhead", [(-10.47,3.747,z-.64),(-10.95,3.747,z),(-9.99,3.747,z)],"white")
    for z in (-32.30,-33.83,-34.40):
        kit.rod("Protective pickup bollard",(-8.64,3.70,z),(-8.64,4.41,z),.088,"restaurant_gold")

    # A sheltered side window faces the queue with its menu and pickup shelf.
    box("Pickup window surround", -8.37, 5.23, -33.02, .20, 1.60, 1.55, "restaurant_red")
    box("Lit pickup hatch", -8.491, 5.21, -33.02, .05, 1.14, 1.20, "window")
    box("Sliding pickup hatch rail", -8.53, 5.21, -33.02, .08, 1.12, .075, "ink")
    box("Takeout shelf", -8.58, 4.64, -33.02, .47, .10, 1.54, "metal")
    box("Pickup awning", -8.59, 6.22, -33.02, .87, .14, 1.93, "restaurant_red")
    box("Pickup awning warm lamp", -8.83, 6.128, -33.02, .14, .047, 1.32, "light")
    box("Drive-through sign mast", -11.93, 5.17, -30.53, .13, 2.95, .13, "ink")
    box("Drive-through sign case", -11.69, 6.44, -30.53, 2.05, .90, .16, "restaurant_red")
    arena.sign("DriveThroughSign", "drive-through", (-11.69,6.44,-30.44), (1.97,.82))
    box("Order menu mast", -12.04, 4.58, -34.48, .12, 1.7, .12, "ink")
    box("Order menu illuminated case", -12.02, 5.23, -34.47, 1.30, 1.12, .20, "ink")
    for x, color in [(-12.41,"restaurant_red"),(-12.02,"restaurant_gold"),(-11.63,"window")]:
        box("Menu poster", x, 5.23, -34.358, .32, .91, .024, color)
    box("Order speaker", -11.86, 4.43, -33.56, .29, .47, .23, "steel")
    box("Order speaker foot", -11.86, 3.96, -33.56, .10, .54, .10, "ink")

    # Parked at the window with room for the car behind it.
    x, z = -10.44, -33.55
    box("Pickup hatchback body", x, 4.25, z, 1.62, .65, 3.04, "turq")
    box("Pickup hatchback cabin", x, 4.73, z-.25, 1.43, .57, 1.65, "navy")
    box("Pickup hatchback roof", x, 5.03, z-.26, 1.44, .11, 1.70, "turq")
    box("Pickup hatchback windshield", x, 4.76, z-1.08, 1.24, .36, .045, "steel")
    for side in (-1,1):
        box("Front light", x+side*.55, 4.37, z-1.524, .30, .15, .035, "light")
        box("Tail light", x+side*.55, 4.37, z+1.524, .30, .15, .035, "restaurant_red")
        for dz in (-.94,.96):
            kit.rod("Hatchback tyre", (x+side*.65,4.01,z+dz), (x+side*.89,4.01,z+dz), .265, "ink", 10)
            kit.rod("Hatchback wheel hub", (x+side*.89,4.01,z+dz), (x+side*.90,4.01,z+dz), .125, "metal", 8)

    for x, ramen in [(-15.55,True),(-21.45,False)]:
        width = 5.53 if ramen else 5.82
        box("Shop masonry", x, 5.91, -34.51, width, 4.4, 3.96, "steel")
        box("Shop base", x, 4.06, -32.43, width, .53, .33, "ink")
        box("Shop fascia", x, 7.11, -32.40, width, .94, .31, "green" if ramen else "white")
        box("Roof edge", x, 7.73, -32.42, width+.12, .16, .43, "navy")
        for offset in (-1.73,0,1.73):
            box("Deep shop window", x+offset, 5.47, -32.46, 1.61, 2.49, .24, "navy")
            box("Glowing shop interior", x+offset, 5.46, -32.321, 1.44, 2.30, .035, "window" if ramen else "mint")
            box("Shop window mullion", x+offset-.73, 5.46, -32.29, .09, 2.39, .10, "ink")
            if not ramen:
                for y in (4.65,5.08,5.52):
                    box("Convenience-store shelf", x+offset, y, -32.279, 1.36, .065, .042, "navy")
                    for i in range(6):
                        color = ("strip_orange","red","yellow","white")[(i+int(y*10))%4]
                        box("Drink or snack pack", x+offset+(i-2.5)*.20, y+.13, -32.267, .12, .19, .04, color)
        if ramen:
            for i in range(7):
                box("Red split noren curtain", x+(i-3)*.43, 6.14, -32.07, .39, .74, .075, "restaurant_red")
            for side in (-1,1):
                xx = x+side*2.10
                kit.rod("Ramen lantern", (xx,5.66,-31.98), (xx,6.31,-31.98), .205, "pink_light", 8)
                box("Lantern cap", xx, 6.35, -31.98, .30, .08, .30, "ink")
        else:
            for index, color in enumerate(("strip_orange","white","strip_green","red")):
                box("Convenience-store color band", x, 6.535-index*.105, -32.21, width+.06, .095, .09, color)
        arena.sign("IchiranSign" if ramen else "ConvenienceSign",
                   "ichiran-market" if ramen else "seven-eleven-market",
                   (x,7.11,-32.232), (4.05,.83))


def build_harbour(arena):
    quay = arena.kit("harbour_quay", True)
    quay.box("Stone quay wall", (0,-.72,24.97), (46,1.36,.45), "steel")
    quay.coping("Stone coping", (0,.085,24.89), 46.2, .19, .46, "concrete", seg_len=2.3)
    for y in (.42,1.04):
        quay.box("Harbour railing runner", (0,y,24.85), (46,.085,.092), "metal")
    for x in range(-22,23,2):
        quay.plinth("Railing base shoe", (x,.21,24.85), .18, .09, .18, "navy", flare=.02)
        quay.box("Harbour railing upright", (x,.59,24.85), (.115,1.12,.115), "steel", taper=(.05,.05))
    for x in (-18,-9,9,18):
        quay.plinth("Bollard plinth", (x,.18,24.52), .44, .09, .44, "concrete", flare=.03)
        quay.rod("Stone bollard", (x,.20,24.52), (x,.46,24.52), .18, "navy", 10, .15)
        quay.rod("Bollard cap", (x,.45,24.52), (x,.52,24.52), .21, "gold", 10, .17)
    water = arena.kit("harbour_water", True)
    water.facet("Night water surface", [(-115,-.86,25),(115,-.86,25),(115,-.86,190),(-115,-.86,190)], "sea")
    arena.layout["harbour_ferries"] = []
    for index, (x,z,direction,speed) in enumerate([(-16,51,1,1.85),(28,78,-1,1.45)]):
        key = f"harbour_ferry_{index+1}"
        ferry = arena.kit(key)
        length = 14.0 if index==0 else 19.3
        beam = 3.6 if index==0 else 4.5
        outline = [(-.47,-.31),(.31,-.5),(.48,-.23),(.54,0),(.48,.23),(.31,.5),(-.47,.31)]
        points = [(u*length*s,y,v*beam*s) for y,s in [(-.29,.83),(.67,1)] for u,v in outline]
        count = len(outline)
        faces = [tuple(range(count)),tuple(reversed(range(count,count*2)))]
        faces.extend((i,i+count,(i+1)%count+count,(i+1)%count) for i in range(count))
        ferry.mesh("Tapered passenger hull", points, faces, "ship_hull")
        ferry.box("Light-painted main deck",(-.13*length,.93,0),(length*.76,.50,beam*.87),"ship_deck")
        ferry.box("Enclosed passenger cabin",(-.12*length,1.65,0),(length*.62,1.22,beam*.69),"ship_deck")
        ferry.box("Second deck and deckhouse",(-.10*length,2.43,0),(length*.50,.37,beam*.73),"green")
        if index:
            ferry.box("Upper passenger lounge",(-.10*length,2.94,0),(length*.41,.71,beam*.57),"ship_deck")
        for side in (-1,1):
            for i in range(8):
                xx = (i-3.5)*length*.073-.12*length
                ferry.box("Warm passenger window",(xx,1.72,side*beam*.348),(length*.051,.37,.052),"ship_window")
                if index and 1<=i<=6:
                    ferry.box("Upper lounge window",(xx,2.97,side*beam*.29),(length*.048,.26,.049),"ship_window")
            ferry.box("Navigation light",(.20*length,2.43,side*beam*.383),(.13,.16,.12),"neon_mint" if side==1 else "neon_red")
        ferry.box("Bridge glazing",(.19*length,1.74,0),(.07,.51,beam*.62),"navy")
        ferry.rod("Ferry signal mast",(-.12*length,2.60,0),(-.12*length,4.05,0),.055,"steel",6)
        ferry.box("White mast light",(-.12*length,4.07,0),(.13,.16,.13),"light")
        ferry.slab("Pale V-shaped wake",
                   [(-length*.38,-.015,-.15),(-length*1.04,-.015,-beam*.61),
                    (-length*1.04,-.015,-beam*.81),(-length*.38,-.015,-.30)],.012,"steel")
        ferry.slab("Pale V-shaped wake",
                   [(-length*.38,-.015,.15),(-length*.38,-.015,.30),
                    (-length*1.04,-.015,beam*.81),(-length*1.04,-.015,beam*.61)],.012,"steel")
        arena.moving(key,(x,-.83,z),0 if direction>0 else math.pi)
        arena.layout["harbour_ferries"].append([key,x,speed*direction])
