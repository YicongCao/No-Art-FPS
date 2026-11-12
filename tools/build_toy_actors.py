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

# Enemy rifleman, after docs/art/toy/concepts/tripo/rifleman: big helmet, coral pads, boots.
# Gameplay names stay; limbs pivot at shoulder and hip. Head hit sphere stays at y 1.70,
# the shot origin at (.22, 1.12, -.58) is the blaster's front opening.
begin('enemy')
torso = box('Torso', (0, 1.30, 0), (.56, .38, .32), 'toy_body', .08)
attach(box('Backpack', (0, 1.29, .22), (.38, .36, .14), 'toy_body_dark', .04), torso)
attach(box('PackPlate', (0, 1.30, .295), (.18, .08, .02), 'toy_vest', .01), torso)
attach(box('Belt', (0, 1.11, 0), (.48, .08, .33), 'toy_vest', .02), torso)
attach(box('Pelvis', (0, 1.0, 0), (.40, .17, .27), 'toy_body_dark', .04), torso)
attach(cyl('Neck', (0, 1.51, 0), .075, .10, 'toy_body_dark'), torso)
merge_rigid(torso)
vest = box('Vest', (0, 1.32, -.165), (.44, .30, .07), 'toy_vest', .03)
attach(box('ChestMark', (0, 1.36, -.203), (.15, .045, .02), 'toy_visor', .008), vest)
head = box('Head', (0, 1.68, 0), (.36, .29, .33), 'toy_body', .07)
for side, x in [('Left', -.195), ('Right', .195)]:
    attach(cyl(side + 'Ear', (x, 1.68, .01), .075, .05, 'toy_body_dark', 'x', 16, .012), head)
merge_rigid(head)
helmet = box('Helmet', (0, 1.835, .01), (.39, .11, .37), 'toy_body_dark', .045)
attach(box('Crest', (0, 1.915, 0), (.08, .075, .38), 'toy_team', .025), helmet)
box('Visor', (0, 1.70, -.167), (.28, .08, .04), 'toy_visor', .015)
for side, x in [('Left', -.16), ('Right', .16)]:
    leg = pivot(box(side + 'Leg', (x, .81, 0), (.20, .32, .22), 'toy_body', .05), (x, .98, 0))
    attach(box(side + 'Shin', (x, .38, .01), (.22, .40, .24), 'toy_body', .055), leg)
    attach(cyl(side + 'KneeJoint', (x, .62, 0), .08, .17, 'toy_body_dark', 'x', 12, .01), leg)
    attach(box(side + 'Knee', (x, .60, -.13), (.19, .15, .06), 'toy_vest', .025), leg)
    attach(box(side + 'Foot', (x, .095, -.05), (.26, .19, .37), 'toy_body_dark', .05), leg)
    merge_rigid(leg)
hands = {'Left': (.20, 1.07, -.50), 'Right': (.25, 1.03, -.24)}
elbows = {'Left': (-.30, 1.17, -.27), 'Right': (.40, 1.20, -.04)}
for side, s in [('Left', -1), ('Right', 1)]:
    shoulder = (.37 * s, 1.43, 0)
    arm = pivot(segment(side + 'Arm', shoulder, elbows[side], (.18, .19), 'toy_body', .05), shoulder)
    attach(segment(side + 'Forearm', elbows[side], hands[side], (.16, .17), 'toy_body', .05), arm)
    attach(cyl(side + 'Elbow', elbows[side], .088, .17, 'toy_body_dark', 'x', 12, .01), arm)
    attach(box(side + 'Pad', (.39 * s, 1.47, 0), (.25, .16, .27), 'toy_team', .06), arm)
    merge_rigid(arm)
    box(side + 'Hand', hands[side], (.14, .14, .15), 'toy_rubber', .045)
G = (.22, 1.12, -.36)
def gp(x, y, z):
    return (G[0] + x, G[1] + y, G[2] + z)
gun = box('EnemyGun', G, (.10, .11, .34), 'toy_gun', .022)
for part in [
    box('GunMuzzle', gp(0, .005, -.205), (.078, .078, .08), 'toy_body_dark', .016),
    box('GunBore', gp(0, .005, -.246), (.038, .038, .012), 'toy_rubber', 0),
    box('GunStock', gp(0, 0, .215), (.112, .125, .09), 'toy_gun_light', .022),
    box('GunTop', gp(0, .073, -.03), (.05, .04, .08), 'toy_body_dark', .01),
    box('GunRear', gp(0, .066, .12), (.04, .025, .04), 'toy_body_dark', .006),
    box('GunClip', gp(0, -.11, -.06), (.05, .13, .08), 'toy_gun_light', .012),
    box('GunGrip', gp(0, -.10, .09), (.045, .12, .06), 'toy_body_dark', .012, (-.3, 0, 0)),
    box('GunStripe', gp(-.052, .012, -.02), (.006, .022, .22), 'toy_visor', .003),
    box('GunStripe', gp(.052, .012, -.02), (.006, .022, .22), 'toy_visor', .003),
]:
    attach(part, gun)
merge_rigid(gun)
export('enemy', False)

# Rusher, after docs/art/toy/concepts/tripo/rusher: slim orange shell, cream panels, wedge helmet,
# back fins and hip thrusters. Torso, Helmet and limb meshes take the flashing orange override, so
# they carry the orange shell; cream and dark parts are child meshes. The right hand sits where the
# knife arm holds the blade, (.3, .94, -.18); the head hit sphere stays at y 1.70.
begin('rusher')
torso = box('Torso', (0, 1.33, 0), (.40, .28, .24), 'toy_rush', .06)
attach(box('ChestPlate', (0, 1.33, -.125), (.24, .17, .04), 'toy_cream', .02), torso)
attach(box('BackPlate', (0, 1.35, .125), (.20, .18, .03), 'toy_cream', .015), torso)
attach(box('Waist', (0, 1.13, 0), (.20, .16, .16), 'toy_joint', .03), torso)
attach(box('Hips', (0, 1.0, 0), (.30, .13, .20), 'toy_rush', .04), torso)
attach(cyl('Neck', (0, 1.52, 0), .05, .09, 'toy_joint'), torso)
for s in (-1, 1):
    attach(box('Fin', (.12 * s, 1.52, .15), (.05, .22, .11), 'toy_rush', .02, (.55, 0, -.35 * s)), torso)
    attach(cyl('Thruster', (.19 * s, 1.0, .02), .075, .09, 'toy_rush', 'x', 16, .015), torso)
    attach(cyl('ThrusterGlow', (.24 * s, 1.0, .02), .05, .012, 'toy_thrust', 'x', 16, .003), torso)
merge_rigid(torso)
head = box('Head', (0, 1.66, -.01), (.24, .22, .25), 'toy_cream', .05)
for side, x in [('Left', -.13), ('Right', .13)]:
    attach(cyl(side + 'Ear', (x, 1.69, .02), .062, .05, 'toy_joint', 'x', 16, .012), head)
merge_rigid(head)
helmet = box('Helmet', (0, 1.79, .02), (.28, .13, .32), 'toy_rush', .05)
attach(box('HelmetSweep', (0, 1.84, .2), (.18, .09, .26), 'toy_rush', .035, (.32, 0, 0)), helmet)
attach(box('HelmetBrim', (0, 1.735, -.13), (.27, .05, .07), 'toy_rush', .02), helmet)
attach(box('HelmetStripe', (0, 1.858, .03), (.07, .012, .30), 'toy_cream', .005), helmet)
merge_rigid(helmet)
box('Visor', (0, 1.685, -.135), (.20, .05, .03), 'toy_visor', .012)
for side, x in [('Left', -.12), ('Right', .12)]:
    leg = pivot(segment(side + 'Leg', (x, .98, 0), (x, .58, -.01), (.13, .15), 'toy_rush', .04), (x, .98, 0))
    attach(segment(side + 'Shin', (x, .55, -.01), (x, .14, .01), (.15, .17), 'toy_cream', .045), leg)
    attach(box(side + 'KneeCap', (x, .52, -.085), (.135, .13, .05), 'toy_rush', .02), leg)
    attach(cyl(side + 'Knee', (x, .58, -.01), .062, .14, 'toy_joint', 'x', 12, .01), leg)
    attach(box(side + 'Foot', (x, .06, -.04), (.15, .12, .27), 'toy_joint', .035), leg)
    merge_rigid(leg)
wrists = {'Left': (-.29, 1.0, -.12), 'Right': (.30, .99, -.15)}
elbows = {'Left': (-.29, 1.20, -.02), 'Right': (.30, 1.20, -.03)}
for side, s in [('Left', -1), ('Right', 1)]:
    shoulder = (.27 * s, 1.43, 0)
    arm = pivot(segment(side + 'Arm', shoulder, elbows[side], (.11, .12), 'toy_rush', .035), shoulder)
    attach(box(side + 'Shoulder', (.29 * s, 1.45, 0), (.13, .12, .15), 'toy_rush', .035), arm)
    attach(cyl(side + 'Elbow', elbows[side], .058, .12, 'toy_joint', 'x', 12, .01), arm)
    attach(segment(side + 'Forearm', elbows[side], wrists[side], (.13, .14), 'toy_cream', .04), arm)
    if side == 'Left':
        attach(box('LeftHand', (-.29, .95, -.14), (.09, .10, .10), 'toy_joint', .03), arm)
    merge_rigid(arm, ('LeftHand',))
box('RightHand', (.30, .94, -.17), (.09, .10, .10), 'toy_joint', .03)
export('rusher', False)

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
