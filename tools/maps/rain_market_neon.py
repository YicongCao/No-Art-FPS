"""Hand-drawn tube strokes for the rain market's street signs."""

import math

# Centerlines on a 10 by 10 grid. Separate paths represent separate tubes.
GLYPHS = {
    "深": "08 17|06 15|03 11 22|36 38 98 96|57 46 35|77 76 95|34 94|65 61|64 42 30|64 82 91",
    "記": "28 39|16 46|25 45|24 44|13 43 41 11 13|58 98 95 65|65 61 91 92",
    "海": "08 17|06 15|03 11 22|47 59|48 98|46 87 83 71|56 52 95|34 94|64 73",
    "鮮": "18 28 35|28 48 36|16 46 43 13 16|15 45|26 23|11 00|21 20|31 30|41 50|68 77|98 87|57 97|66 96|55 95|74 70|54 94",
    "旁": "59 68|18 98|37 46|77 66|17 16 96 95|35 85|53 43 21|44 83 72 61",
    "冰": "09 28|05 26 13 02|58 51 31|57 47 44 32|96 76 66|66 74 92",
    "廠": "59 68|19 98|18 14 02|27 37|47 46|37 35|26 55 52|25 22|33 43 44 34 33|79 65|76 96|85 83 71 60|66 74 92",
    "潮": "09 18|07 16|04 12 21|39 32|28 68|27 67 64 24 27|26 66|23 63|32 30|74 78 98 91 81|75 95|74 94|74 72 61",
    "茶": "18 98|38 36|78 76|55 36 14|55 75 96|25 85|54 51 41|43 32 11|63 72 91",
    "餐": "29 28 48|28 16|27 46 34 14|26 35|58 98 76 55|67 75 95|54 36 13|54 76 95|33 73 72 32|33 30 51|53 61 90|83 72",
    "廳": "59 68|19 98|18 14 02|27 57|37 32|57 52|36 56|35 55|22 62|73 97|86 96|76 74 94 96|75 95|63 93|73 62|82 81|90 91|72 71 81",
    "魚": "28 39|28 18|28 68 56|16 86 82 12 16|14 84|56 52|11 00|31 30|61 60|81 90",
    "批": "18 18 11 01|06 36|13 36|48 41 63|44 64|77 71 91 92|75 96",
    "發": "18 38 27 05|47 69 76 95|68 87|76 96|34 64 62 31 30 40|63 83 72 60|63 73 91",
    "通": "29 69 48|28 67|28 26|37 87 82|37 32|35 85|54 84|56 52|08 17|05 24 13 12|12 31 91",
    "宵": "49 68|18 98 96|18 16|47 56|36 26|76 66|25 85 81 71|25 21|24 84|23 83",
    "供": "29 17 05|16 11|37 97|58 54|78 74|34 94|53 41 31|73 81 91",
}

STOREFRONT_LETTERS = {
    "M": "00 09 45 89 80", "c": "85 35 13 12 30 80", "D": "09 59 86 83 50 00 09",
    "o": "25 65 83 82 60 20 02 03 25", "n": "00 05|04 35 65 83 80",
    "a": "15 65 84 80|83 23 02 01 20 60 81", "l": "29 20 50",
    "d": "89 80|85 35 13 12 30 60 81", "'": "38 29", "s": "85 35 14 33 73 82 61 10",
}


def tube(kit, label, points, radius, color):
    for start, end in zip(points, points[1:]):
        if start != end:
            kit.rod(label, start, end, radius, color, 6)


def sign(kit, title, center, angle, size, color, border, *, vertical=False, fish=False):
    x, y, z = center
    width, height = size
    c, s = math.cos(angle), math.sin(angle)

    def point(u, v, depth):
        return (x + c*u + s*depth, y + v, z - s*u + c*depth)

    kit.box(title + " enamel case", center, (width, height, .20), "neon_case", angle)
    kit.box(title + " folded casing edge", center, (width + .07, height + .07, .09), "ink", angle)
    for face in (-1, 1):
        def lit(u, v):
            return point(u*face, v, face*.133)

        w, h, clip = width/2 - .12, height/2 - .12, .11
        outline = [(-w+clip,-h),(w-clip,-h),(w,-h+clip),(w,h-clip),
                   (w-clip,h),(-w+clip,h),(-w,h-clip),(-w,-h+clip),(-w+clip,-h)]
        tube(kit, title + " rim tube", [lit(*p) for p in outline], .026, border)
        letters_width = width - (2.25 if fish else .48)
        letter_size = (min(width*.74, (height-.42)/len(title)) if vertical
                       else min(height*.77, letters_width/len(title)))
        for i, char in enumerate(title):
            u = 0 if vertical else (i - (len(title)-1)/2)*letters_width/len(title) - (1.04*face if fish else 0)
            v = ((len(title)-1)/2 - i)*(height-.40)/len(title) if vertical else 0
            for stroke in GLYPHS[char].split("|"):
                points = [lit(u+(int(p[0])/9-.5)*letter_size*.85,
                              v+(int(p[1])/9-.5)*letter_size*.91) for p in stroke.split()]
                tube(kit, char + " glass tube", points, max(.013, letter_size*.028), color)
    return point(width/2-1.22, 0, 0)


def build_fish(kit):
    outline = [(-.94,0),(-.76,.25),(-.41,.37),(.04,.38),(.40,.28),(.62,.11),
               (.99,.36),(.94,0),(.99,-.36),(.62,-.11),(.35,-.29),
               (-.04,-.36),(-.50,-.30),(-.80,-.15),(-.94,0)]
    for face in (-1, 1):
        for shape in (outline, [(-.35,.27),(-.22,.13),(-.20,-.03),(-.31,-.22)],
                      [(-.68,.06),(-.61,.09),(-.57,.02),(-.65,-.03),(-.68,.06)]):
            tube(kit, "Fish outline tube", [(x,y,face*.133) for x,y in shape], .036, "neon_mint")


def build_storefront(kit, x, z):
    # The entrance faces the playable side of the road, behind the map boundary.
    def box(label, at, size, color):
        kit.box(label, (x+at[0],3.7+at[1],z+at[2]), size, color)

    box("Restaurant masonry bay", (0,2.18,-1.22), (9.3,4.36,2.62), "steel")
    box("Red McDonald's fascia", (0,3.48,.20), (9.33,1.09,.32), "restaurant_red")
    box("Dark fascia shadow line", (0,2.88,.25), (9.29,.105,.35), "ink")
    box("Pavement below shopfront", (0,.035,.28), (10.0,.075,1.35), "concrete")
    for bay in (-3.16,-1.58,0,1.58,3.16):
        box("Deep shopfront glazing", (bay,1.63,.13), (1.43,2.28,.13), "navy")
        box("Warm interior behind glazing", (bay,1.73,.207), (1.30,1.99,.035), "window")
        box("Shopfront glass kickplate", (bay,.55,.26), (1.41,.42,.13), "steel")
        box("Glazing header", (bay,2.83,.25), (1.55,.12,.16), "ink")
        box("Window mullion", (bay-.71,1.63,.25), (.086,2.37,.14), "ink")
        if bay:
            box("Window counter silhouette", (bay,.98,.23), (1.20,.26,.047), "restaurant_red")
            box("Warm pendant reflected in window", (bay+.16,2.25,.239), (.31,.13,.018), "light")
        else:
            box("Entrance double-door stile", (0,1.59,.264), (.07,2.31,.14), "ink")
            for side in (-1,1):
                box("Entrance pull bar", (side*.11,1.38,.34), (.043,.40,.052), "metal")
    # Two tangent arches, flattened into a single shallow sign on the red fascia.
    for side in (-1,1):
        points = []
        for i in range(13):
            theta = math.pi*i/12
            points.append((x-3.17+side*.27+.27*math.cos(theta),
                           3.7+3.18+.64*math.sin(theta),z+.409))
        tube(kit, "Golden arch", points, .062, "restaurant_gold")
    for i, char in enumerate("McDonald's"):
        for stroke in STOREFRONT_LETTERS[char].split("|"):
            points=[(x-2.20+i*.41+int(p[0])*.041,3.7+3.28+int(p[1])*.051,z+.376)
                    for p in stroke.split()]
            tube(kit, "Restaurant fascia lettering", points, .025, "neon_cream")
