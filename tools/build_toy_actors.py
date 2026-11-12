"""Painted-plastic toy actors. Run: blender --background --python tools/build_toy_actors.py

Node names, iron-sight points and muzzle position match the original actors so gameplay
code is unchanged. Shapes follow docs/art/toy/concepts/tripo/.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from toy_blocks import *

reset(ROOT / 'assets/models/toy')

# Rifle: rear aperture centre (0,.269,-.17), front post tip (0,.205,-.65), muzzle near z -1.0.
# Layout follows docs/art/toy/concepts/tripo/player-rifle: blue receiver, cream handguard and
# stock, one smooth top rail, ring aperture on a short stem.
begin('rifle')
box('receiver', (0, 0, 0), (.19, .24, .60), 'toy_primary', .035)
for x in (-.097, .097):
    box('side_panel', (x, -.005, -.02), (.014, .12, .36), 'toy_shell', .006)
    box('glow_strip', (x * 1.07, -.02, -.02), (.008, .026, .24), 'toy_glow', .003)
    box('guard_slot', (x * .87, .01, -.50), (.008, .035, .17), 'toy_rubber', .004)
box('badge', (.098, .075, .14), (.012, .045, .075), 'toy_accent', .006)
box('handguard', (0, .01, -.50), (.165, .19, .42), 'toy_shell', .04)
cyl('barrel', (0, .01, -.80), .038, .2, 'toy_metal', 'z', 16, .006)
cyl('muzzle_ring', (0, .01, -.905), .05, .025, 'toy_glow', 'z', 16, .004)
cyl('muzzle', (0, .01, -.955), .058, .09, 'toy_primary', 'z', 16, .016)
box('stock', (0, 0, .45), (.17, .22, .30), 'toy_shell', .045)
box('stock_pad', (0, 0, .615), (.18, .235, .05), 'toy_rubber', .015)
box('rail', (0, .145, -.06), (.125, .05, .50), 'toy_metal', .014)
box('sight_base', (0, .19, -.17), (.05, .045, .05), 'toy_shell', .01)
ring('sight_ring', (0, .269, -.17), .058, .013, 'toy_metal')
box('post_base', (0, .12, -.65), (.05, .03, .05), 'toy_metal', .008)
box('front_sight', (0, .165, -.65), (.022, .08, .022), 'toy_accent', .005)
box('magazine', (0, -.25, .02), (.12, .34, .18), 'toy_metal', .025)
box('mag_window', (0, -.22, .02), (.126, .13, .045), 'toy_glow', .006)
box('mag_base', (0, -.42, .02), (.13, .04, .19), 'toy_primary', .014)
box('grip', (0, -.24, .27), (.1, .27, .13), 'toy_rubber', .03, (-.18, 0, 0))
box('trigger_guard', (0, -.14, .17), (.055, .1, .13), 'toy_metal', .012)
box('left_glove', (-.08, -.16, -.38), (.15, .14, .18), 'toy_glove', .04)
box('left_cuff', (-.17, -.29, -.27), (.19, .07, .21), 'toy_cuff', .025, (.45, 0, .35))
box('left_sleeve', (-.22, -.36, -.19), (.21, .35, .23), 'toy_sleeve', .05)
box('right_glove', (.015, -.23, .3), (.13, .17, .17), 'toy_glove', .04)
box('right_cuff', (.07, -.33, .39), (.18, .06, .2), 'toy_cuff', .022, (.35, 0, -.25))
box('right_sleeve', (.1, -.42, .45), (.2, .34, .23), 'toy_sleeve', .05)
export('rifle')

# Profile extrusions give armor an authored silhouette instead of stacked boxes.
def armor_profile(name, points, depth, at, material, width=.02, side=False, taper=None):
    import bmesh
    vertices = []
    for layer in (-depth/2, depth/2):
        for j, (a, b) in enumerate(points):
            thickness = layer*(taper[j] if taper else 1.0)
            local = (thickness, a, b) if side else (a, b, thickness)
            vertices.append(xyz(tuple(at[i]+local[i] for i in range(3))))
    n = len(points)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    bm = bmesh.new(); bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    return finish(obj, name, material, width)

# Curved armor is lofted through authored sections, rather than bevelled cubes.
# Each section is (axis position, transverse centre, width, depth).
def armor_loft(name, sections, material, axis='y', exponent=.75):
    import bmesh
    vertices=[]; count=20
    for at, centre, width, depth in sections:
        for i in range(count):
            angle=2*math.pi*i/count
            c, q=math.cos(angle), math.sin(angle)
            x=math.copysign(abs(c)**exponent,c)*width/2
            other=math.copysign(abs(q)**exponent,q)*depth/2+centre
            vertices.append(xyz((x,at,other) if axis=='y' else (x,other,at)))
    faces=[tuple(reversed(range(count)))]
    for j in range(len(sections)-1):
        for i in range(count):
            k=j*count+i; following=j*count+(i+1)%count
            faces.append((k,following,following+count,k+count))
    faces.append(tuple(range((len(sections)-1)*count,len(sections)*count)))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    return finish(obj,name,material,0)

def rounded(name, p, size, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=xyz(p))
    obj=bpy.context.object
    obj.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,name,material,0)

def shift_mesh(obj, x):
    # Move mesh coordinates, keeping the existing world-space attachment convention.
    for vertex in obj.data.vertices:vertex.co.x+=x
    return obj

begin('enemy')
torso=armor_loft('Torso',[(1.05,0,.36,.27),(1.13,0,.48,.35),(1.38,0,.72,.43),(1.48,0,.66,.37),(1.53,0,.43,.28)],'toy_body')
attach(box('Backpack',(0,1.30,.25),(.42,.42,.20),'toy_body_dark',.075),torso)
attach(box('PackPlate',(0,1.30,.36),(.20,.12,.025),'toy_vest',.025),torso)
attach(box('Pelvis',(0,1.00,0),(.42,.18,.30),'toy_body_dark',.07),torso)
attach(box('Belt',(0,1.10,0),(.49,.085,.36),'toy_vest',.025),torso)
attach(cyl('Neck',(0,1.54,0),.085,.10,'toy_body_dark'),torso)
merge_rigid(torso)
vest=armor_loft('Vest',[(1.13,-.18,.34,.10),(1.23,-.20,.57,.13),(1.43,-.19,.61,.13),(1.49,-.16,.40,.08)],'toy_vest',exponent=.48)
attach(box('ChestMark',(0,1.37,-.27),(.18,.075,.025),'toy_visor',.018),vest)
head=armor_loft('Head',[(1.55,0,.28,.28),(1.60,0,.44,.38),(1.72,0,.47,.40),(1.80,0,.43,.38)],'toy_body_dark')
for side,x in [('Left',-.245),('Right',.245)]:
    attach(cyl(side+'Ear',(x,1.72,.015),.09,.065,'toy_vest','x',20,.018),head)
merge_rigid(head)
helmet=armor_loft('Helmet',[(1.77,0,.49,.43),(1.84,.015,.49,.43),(1.93,.025,.39,.34),(1.97,.025,.22,.21),(1.98,.025,.05,.05)],'toy_body')
attach(armor_profile('Crest',[(0,-.17),(.11,-.13),(.14,.02),(.10,.17),(-.02,.19)],.095,(0,1.94,0),'toy_team',.03,side=True),helmet)
merge_rigid(helmet)
box('VisorRecess',(0,1.745,-.205),(.38,.12,.055),'toy_rubber',.035)
box('Visor',(0,1.745,-.239),(.33,.077,.025),'toy_visor',.019)
for side,x in [('Left',-.18),('Right',.18)]:
    leg=pivot(shift_mesh(armor_loft(side+'Leg',[(.64,0,.24,.25),(.73,0,.30,.31),(.92,0,.27,.28),(.98,0,.20,.21)],'toy_body'),x),(x,.98,0))
    attach(shift_mesh(armor_loft(side+'Shin',[(.16,-.005,.23,.26),(.25,0,.29,.31),(.49,0,.32,.32),(.58,0,.24,.25)],'toy_body'),x),leg)
    attach(cyl(side+'KneeJoint',(x,.61,0),.09,.23,'toy_body_dark','x',16,.012),leg)
    attach(box(side+'Knee',(x,.60,-.15),(.24,.18,.08),'toy_vest',.045),leg)
    attach(rounded(side+'Boot',(x,.115,-.07),(.32,.24,.44),'toy_body_dark'),leg)
    attach(box(side+'Sole',(x,.035,-.06),(.33,.07,.43),'toy_body_dark',.028),leg)
    merge_rigid(leg)
hands={'Left':(.19,1.06,-.43),'Right':(.25,1.06,-.08)}
elbows={'Left':(-.38,1.10,-.18),'Right':(.43,1.13,.02)}
for side,sign in [('Left',-1),('Right',1)]:
    shoulder=(.40*sign,1.44,0)
    arm=pivot(segment(side+'Arm',shoulder,elbows[side],(.23,.25),'toy_body',.095),shoulder)
    attach(segment(side+'Forearm',elbows[side],hands[side],(.22,.23),'toy_body',.105),arm)
    attach(rounded(side+'Pad',(.42*sign,1.46,0),(.37,.35,.43),'toy_team'),arm)
    attach(cyl(side+'Elbow',elbows[side],.10,.23,'toy_body_dark','x',16,.014),arm)
    merge_rigid(arm)
    glove=box(side+'Hand',hands[side],(.17,.17,.19),'toy_rubber',.055)
    for finger in range(3):attach(box('Finger',(hands[side][0]+(finger-1)*.044,hands[side][1],hands[side][2]-.09),(.038,.12,.035),'toy_body',.012),glove)
    merge_rigid(glove)
G=(.22,1.20,-.22)
def gp(x,y,z):return (G[0]+x,G[1]+y,G[2]+z)
gun=box('EnemyGun',G,(.14,.16,.60),'toy_gun',.025)
for part in [box('GunMuzzle',gp(0,-.08,-.34),(.10,.10,.08),'toy_body_dark',.018),
             box('GunBore',gp(0,-.08,-.382),(.052,.052,.012),'toy_rubber',.006),
             box('GunStock',gp(0,0,.34),(.13,.17,.10),'toy_gun_light',.025),
             box('GunClip',gp(0,-.12,-.04),(.07,.17,.11),'toy_gun_light',.018),
             box('GunTop',gp(0,.09,-.04),(.07,.035,.10),'toy_body_dark',.01),
             box('GunStripe',gp(-.073,.02,0),(.008,.035,.43),'toy_visor',.005),
             box('GunStripe',gp(.073,.02,0),(.008,.035,.43),'toy_visor',.005)]:attach(part,gun)
merge_rigid(gun);export('enemy',False)

begin('rusher')
torso=armor_loft('Torso',[(1.15,0,.22,.17),(1.22,-.015,.28,.22),(1.39,-.02,.46,.31),(1.48,0,.40,.27),(1.51,0,.23,.20)],'toy_rush')
attach(armor_profile('ChestPlate',[(-.18,.08),(-.09,.04),(.09,.04),(.18,.08),(.145,-.08),(0,-.17),(-.145,-.08)],.05,(0,1.34,-.17),'toy_cream',.025),torso)
attach(box('Waist',(0,1.11,0),(.19,.18,.17),'toy_joint',.045),torso)
attach(box('Hips',(0,.99,0),(.31,.14,.23),'toy_rush',.045),torso)
attach(cyl('Neck',(0,1.55,0),.055,.10,'toy_joint'),torso)
attach(box('BackPlate',(0,1.38,.16),(.22,.19,.05),'toy_cream',.028),torso)
for sign in [-1,1]:
    attach(armor_profile('Fin',[(-.08,-.05),(.08,-.04),(.24,.28),(.18,.33)],.045,(.16*sign,1.48,.14),'toy_rush',.015,side=True),torso)
    attach(cyl('Thruster',(.20*sign,1.0,.02),.09,.10,'toy_rush','x',20,.02),torso)
    attach(cyl('ThrusterGlow',(.255*sign,1.0,.02),.06,.012,'toy_thrust','x',20,.005),torso)
merge_rigid(torso)
head=armor_loft('Head',[(1.56,-.01,.14,.19),(1.61,-.02,.26,.28),(1.73,0,.32,.31),(1.80,.02,.26,.27)],'toy_cream')
for side,x in [('Left',-.17),('Right',.17)]:attach(cyl(side+'Ear',(x,1.73,.035),.075,.055,'toy_joint','x',20,.012),head)
merge_rigid(head)
helmet=armor_loft('Helmet',[(-.24,1.77,.25,.055),(-.18,1.80,.36,.13),(-.04,1.85,.37,.20),(.12,1.91,.28,.21),(.28,1.98,.15,.13),(.40,2.03,.012,.015)],'toy_rush',axis='z')
attach(armor_loft('HelmetStripe',[(-.18,1.86,.045,.012),(-.04,1.954,.05,.012),(.12,2.019,.045,.012),(.28,2.047,.025,.012),(.40,2.04,.006,.006)],'toy_cream',axis='z'),helmet)
merge_rigid(helmet)
box('VisorRecess',(0,1.72,-.15),(.26,.095,.045),'toy_joint',.025)
box('Visor',(0,1.727,-.179),(.225,.05,.025),'toy_visor',.012)
for side,x in [('Left',-.12),('Right',.12)]:
    leg=pivot(shift_mesh(armor_loft(side+'Leg',[(.62,-.03,.12,.14),(.71,-.01,.18,.21),(.89,0,.19,.22),(.98,0,.13,.16)],'toy_rush'),x),(x,.98,0))
    attach(shift_mesh(armor_loft(side+'Shin',[(.12,0,.11,.14),(.22,-.01,.15,.20),(.42,-.02,.21,.23),(.54,-.025,.18,.19)],'toy_cream'),x),leg)
    attach(cyl(side+'Knee',(x,.58,-.02),.071,.16,'toy_joint','x',16,.014),leg)
    attach(box(side+'KneeCap',(x,.52,-.115),(.14,.13,.04),'toy_rush',.025),leg)
    attach(rounded(side+'Boot',(x,.08,-.045),(.18,.15,.29),'toy_joint'),leg)
    attach(box(side+'Sole',(x,.025,-.04),(.19,.05,.29),'toy_joint',.018),leg)
    merge_rigid(leg)
wrists={'Left':(-.32,1.01,-.17),'Right':(.30,.99,-.15)}
elbows={'Left':(-.34,1.22,-.04),'Right':(.32,1.22,-.02)}
for side,sign in [('Left',-1),('Right',1)]:
    shoulder=(.28*sign,1.45,0)
    arm=pivot(rounded(side+'Arm',(.29*sign,1.45,0),(.22,.23,.27),'toy_rush'),shoulder)
    attach(segment(side+'UpperLink',shoulder,elbows[side],(.12,.14),'toy_joint',.045),arm)
    attach(cyl(side+'Elbow',elbows[side],.065,.14,'toy_joint','x',16,.012),arm)
    attach(segment(side+'Forearm',elbows[side],wrists[side],(.17,.19),'toy_cream',.06),arm)
    if side=='Left':
        attach(cyl('ShieldRim',(-.42,1.08,-.14),.145,.045,'toy_rush','x',24,.018),arm)
        attach(cyl('Shield',(-.446,1.08,-.14),.115,.015,'toy_cream','x',24,.008),arm)
        attach(box('LeftHand',(-.32,.96,-.18),(.11,.12,.12),'toy_joint',.04),arm)
    merge_rigid(arm,('LeftHand',))
box('RightHand',(.30,.94,-.17),(.11,.12,.12),'toy_joint',.04)
export('rusher',False)

# Rusher blade, after concepts/tripo/rusher-blade. Grip centred on the origin, blade along +Y;
# enemy.gd flips it so the blade hangs below the hand.
begin('rusher_blade')
box('Handle', (0, 0, 0), (.04, .14, .05), 'toy_joint', .012)
box('Guard', (0, .085, 0), (.075, .035, .08), 'toy_rush', .012)
box('Cap', (0, -.085, 0), (.05, .035, .06), 'toy_cream', .012)
box('Blade', (0, .25, 0), (.035, .30, .085), 'toy_blade', .015)
box('Tip', (0, .43, .012), (.035, .08, .06), 'toy_blade', .015, (-.45, 0, 0))
export('rusher_blade')

bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/toy_actors.blend'), compress=True)
