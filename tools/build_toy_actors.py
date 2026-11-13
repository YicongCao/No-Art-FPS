"""Painted-plastic toy actors. Run: blender --background --python tools/build_toy_actors.py

Node names, iron-sight points, head hit centre (y = 1.70) and shot origin (.22, 1.12, -.58)
match the gameplay contracts in scripts/player.gd and scripts/enemy.gd.
Combines sculpted curved superellipse armor shells (`sculpt_loft`) with crisp mechanical
articulation, vents, and physical 3D battle-damaged armor swaps (`BrokenVest`, `BrokenLeftFin`).
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from toy_blocks import *

reset(ROOT / 'assets/models/toy')

# ---------------------------------------------------------------------------
# 1. Player Rifle: rear aperture (0,.269,-.17), front post tip (0,.205,-.65), muzzle near z -1.0.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 2. Rifleman — 'Obsidian Enforcer'
#    Curved V-taper armor shells + exposed mechanical joints + 3D shattered BrokenVest!
# ---------------------------------------------------------------------------
begin('enemy')
torso = sculpt_loft('Torso', (0, 1.32, 0), [
    (-.18, 0, 0, .42, .27),
    (-.08, 0, -.01, .54, .34),
    (.08, 0, -.01, .66, .39),
    (.17, 0, 0, .58, .34),
    (.21, 0, .01, .40, .26),
], 'toy_body', exponent=.62)

# High tactical blast-collar + rib pistons + utility belt + pelvis tassets
attach(box('CollarRear', (0, 1.545, .11), (.38, .11, .085), 'toy_body_dark', .016), torso)
for s in (-1, 1):
    attach(wedge('CollarSide', (.205 * s, 1.53, -.01), (.085, .24), (.07, .19), .10,
                 'toy_vest', .012, rotation=(0, 0, -.18 * s)), torso)
    attach(box('CollarTab', (.215 * s, 1.575, -.05), (.055, .03, .08), 'toy_cream', .006), torso)
    attach(cyl('RibPiston', (.185 * s, 1.11, -.03), .032, .15, 'toy_cream', 'y', 12, .004), torso)
    attach(cyl('PistonCollar', (.185 * s, 1.16, -.03), .042, .04, 'toy_body_dark', 'y', 12, .005), torso)
    attach(box('BeltPouch', (.26 * s, 1.03, -.01), (.078, .115, .165), 'toy_body_dark', .014), torso)
    attach(box('HipSkirt', (.23 * s, .93, 0), (.068, .155, .25), 'toy_body', .014, (0, 0, -.14 * s)), torso)

attach(sculpt_loft('AbCore', (0, 1.10, .01), [
    (-.07, 0, 0, .34, .23), (.07, 0, 0, .41, .27),
], 'toy_body_dark', exponent=.65), torso)
attach(box('Belt', (0, 1.03, 0), (.49, .088, .33), 'toy_vest', .016), torso)
attach(box('BeltBuckle', (0, 1.03, -.172), (.13, .105, .045), 'toy_body_dark', .010), torso)
attach(box('BuckleLatch', (0, 1.03, -.192), (.07, .045, .022), 'toy_cream', .005), torso)
attach(sculpt_loft('Pelvis', (0, .94, 0), [
    (-.07, 0, 0, .29, .22), (.02, 0, 0, .41, .28), (.07, 0, 0, .43, .29),
], 'toy_body_dark', exponent=.65), torso)
attach(wedge('FrontTasset', (0, .92, -.148), (.14, .05), (.19, .065), .16, 'toy_vest', .012), torso)
attach(cyl('Neck', (0, 1.53, 0), .085, .10, 'toy_body_dark', 'y', 14, .008), torso)

# Twin-cell heavy power backpack with angled louvers & stubby antenna
attach(sculpt_loft('Backpack', (0, 1.32, .24), [
    (-.18, 0, 0, .39, .15), (0.0, 0, .01, .44, .19), (.18, 0, 0, .40, .16),
], 'toy_body_dark', exponent=.60), torso)
for s in (-1, 1):
    attach(sculpt_loft('PackCell', (.135 * s, 1.32, .29), [
        (-.16, 0, 0, .13, .10), (0.0, 0, .01, .15, .12), (.16, 0, 0, .135, .105),
    ], 'toy_body', exponent=.68), torso)
    attach(box('PackCellCap', (.135 * s, 1.495, .29), (.105, .035, .09), 'toy_cream', .008), torso)
attach(box('PackPlate', (0, 1.33, .34), (.135, .26, .035), 'toy_vest', .010), torso)
for row in (-1, 0, 1):
    attach(box('PackVent', (0, 1.35 + row * .058, .358), (.10, .026, .02), 'toy_body_dark', .004, (.25, 0, 0)), torso)
attach(box('PackCoreGlow', (0, 1.21, .358), (.085, .032, .018), 'toy_visor', .004), torso)
attach(cyl('AntennaMount', (-.15, 1.52, .27), .028, .05, 'toy_vest', 'y', 10, .005), torso)
attach(cyl('AntennaRod', (-.15, 1.615, .27), .012, .15, 'toy_cream', 'y', 8, .003), torso)
merge_rigid(torso)

# Intact sculpted chest cuirass + downward crimson triangle reactor core (`Vest`)
vest = sculpt_loft('Vest', (0, 1.34, -.185), [
    (-.13, 0, .01, .38, .09),
    (-.03, 0, -.01, .55, .12),
    (.09, 0, -.01, .57, .12),
    (.14, 0, .01, .42, .085),
], 'toy_vest', exponent=.56)
for s in (-1, 1):
    attach(box('CollarLatch', (.165 * s, 1.465, -.205), (.085, .042, .05), 'toy_cream', .008), vest)
attach(plate_profile('CoreBezel', (0, 1.345, -.245),
                     [(-.105, .074), (.105, .074), (0, -.095)], .036, 'toy_body_dark', .008, 'xy'), vest)
attach(plate_profile('ChestMark', (0, 1.345, -.258),
                     [(-.076, .054), (.076, .054), (0, -.070)], .024, 'toy_visor', .005, 'xy'), vest)
merge_rigid(vest)

# 3D Shattered Battle-Damaged Chest Cuirass (`BrokenVest`, revealed when Vest is blasted!)
broken_vest = wedge('BrokenVest', (.12, 1.33, -.188), (.22, .09), (.28, .11), .25,
                    'toy_vest', .018, rotation=(0, -.10, -.08))
attach(box('BrokenShardLow', (-.09, 1.23, -.192), (.15, .08, .09), 'toy_cream', .010, (0, .14, .26)), broken_vest)
attach(box('ExposedCavity', (-.11, 1.36, -.175), (.24, .21, .065), 'toy_body_dark', .010), broken_vest)
for rib_i in range(3):
    attach(box('ExposedRib', (-.12, 1.29 + rib_i * .060, -.208), (.18, .030, .038),
               'toy_cream', .005, (0, .16, -.16)), broken_vest)
attach(cyl('SnappedConduit', (-.16, 1.39, -.228), .026, .13, 'toy_team', 'z', 10, .004), broken_vest)
attach(cyl('SeveredCable', (-.09, 1.34, -.235), .020, .09, 'toy_glow', 'z', 10, .003), broken_vest)
attach(plate_profile('CrackedCore', (.02, 1.34, -.245),
                     [(-.07, .05), (.06, .04), (-.01, -.07)], .028, 'toy_visor', .004, 'xy'), broken_vest)
merge_rigid(broken_vest)

# Curved tactical dome helmet + fierce Talon V-brow + mechanical jaw respirator (hit sphere @ y=1.70)
head = sculpt_loft('Head', (0, 1.68, .01), [
    (-.11, 0, 0, .29, .28),
    (-.03, 0, -.01, .39, .36),
    (.06, 0, 0, .41, .37),
    (.12, 0, .01, .37, .34),
], 'toy_body', exponent=.68)
attach(box('VisorRecess', (0, 1.705, -.168), (.35, .105, .065), 'toy_body_dark', .012), head)
attach(box('NasalBridge', (0, 1.702, -.202), (.036, .085, .034), 'toy_body_dark', .006), head)
attach(wedge('JawGuard', (0, 1.595, -.138), (.22, .12), (.32, .14), .105, 'toy_vest', .014), head)
attach(box('ChinGrille', (0, 1.59, -.202), (.13, .055, .03), 'toy_body_dark', .006), head)
for side, s in [('Left', -1), ('Right', 1)]:
    joint_drum(side + 'Ear', (.212 * s, 1.685, .01), .070, .065, head, 'toy_vest', 'toy_cream', 'x')
    attach(box(side + 'CheekBolt', (.135 * s, 1.60, -.188), (.038, .038, .03), 'toy_cream', .005), head)
merge_rigid(head)

helmet = sculpt_loft('Helmet', (0, 1.81, .01), [
    (-.06, 0, -.01, .45, .42),
    (.01, 0, 0, .44, .41),
    (.07, 0, .01, .36, .35),
    (.11, 0, .02, .21, .22),
], 'toy_body_dark', exponent=.70)
for s in (-1, 1):
    attach(box('AngryBrow', (.090 * s, 1.745, -.198), (.18, .048, .068),
               'toy_body_dark', .008, (0, -.12 * s, .24 * s)), helmet)
attach(plate_profile('Crest', (0, 1.915, .01),
                     [(-.21, -.045), (-.14, .085), (.08, .095), (.21, .032), (.18, -.05)],
                     .088, 'toy_team', .014, 'zy'), helmet)
attach(box('CrestFrontSensor', (0, 1.905, -.152), (.055, .042, .05), 'toy_cream', .006), helmet)
merge_rigid(helmet)

visor = box('Visor', (0, 1.696, -.194), (.04, .034, .028), 'toy_visor', .005)
for s in (-1, 1):
    attach(box('VisorWing', (.096 * s, 1.708, -.192), (.142, .056, .034),
               'toy_visor', .008, (0, -.16 * s, .20 * s)), visor)
merge_rigid(visor)

# Sculpted curved thighs, flared bell-bottom shins & rounded clunky combat boots
for side, s in [('Left', -1), ('Right', 1)]:
    x = .185 * s
    leg = pivot(sculpt_loft(side + 'Leg', (x, .79, 0), [
        (-.15, 0, 0, .21, .23), (-.04, 0, 0, .27, .28), (.10, 0, 0, .26, .27), (.16, 0, 0, .20, .21),
    ], 'toy_body', exponent=.68), (x, .98, 0))
    attach(cyl(side + 'HipJoint', (x, .97, 0), .078, .16, 'toy_body_dark', 'x', 14, .008), leg)
    attach(box(side + 'ThighTrim', (x + .126 * s, .80, 0), (.032, .17, .12), 'toy_cream', .006), leg)
    joint_drum(side + 'KneeJoint', (x, .595, 0), .082, .22, leg, 'toy_body_dark', 'toy_cream', 'x')
    attach(wedge(side + 'Knee', (x, .595, -.142), (.17, .075), (.22, .095), .18, 'toy_vest', .016), leg)
    attach(box(side + 'KneeCapTrim', (x, .65, -.172), (.13, .042, .04), 'toy_cream', .006), leg)
    # Curved flared bell-bottom Gundam/Talon heavy shin guard with two-tone slate greave & crimson cuff
    attach(sculpt_loft(side + 'Shin', (x, .36, .01), [
        (-.17, 0, -.01, .31, .34), (-.05, 0, 0, .32, .34), (.10, 0, 0, .26, .28), (.18, 0, 0, .22, .24),
    ], 'toy_body', exponent=.66), leg)
    attach(wedge(side + 'ShinGreave', (x, .37, -.145), (.21, .07), (.17, .06), .24, 'toy_vest', .014), leg)
    attach(box(side + 'GreaveAccent', (x + .135 * s, .35, -.02), (.045, .18, .15), 'toy_team', .008), leg)
    attach(wedge(side + 'CalfPod', (x, .36, .18), (.17, .07), (.20, .09), .20, 'toy_body_dark', .012), leg)
    attach(sculpt_loft(side + 'AnkleCollar', (x, .185, -.005), [
        (-.024, 0, 0, .32, .355), (.024, 0, 0, .31, .345),
    ], 'toy_cream', exponent=.66), leg)
    # Sculpted curved heavy combat boot + split armored toe
    attach(sculpt_loft(side + 'Sole', (x, .035, -.055), [
        (-.035, 0, 0, .32, .43), (.035, 0, 0, .31, .42),
    ], 'toy_body_dark', exponent=.64), leg)
    attach(sculpt_loft(side + 'BootHeel', (x, .115, -.045), [
        (-.055, 0, 0, .30, .40), (.02, 0, .02, .27, .32), (.065, 0, .04, .23, .25),
    ], 'toy_body_dark', exponent=.68), leg)
    attach(wedge(side + 'BootInstep', (x, .145, -.13), (.17, .16), (.13, .11), .085, 'toy_vest', .012), leg)
    merge_rigid(leg)

# Curved Zaku/Talon dome-skirt crimson pauldrons + detachable LeftPad for physical battle damage!
hands = {'Left': (.17, 1.06, -.41), 'Right': (.22, 1.01, -.16)}
elbows = {'Left': (-.37, 1.14, -.18), 'Right': (.43, 1.15, -.02)}
for side, s in [('Left', -1), ('Right', 1)]:
    shoulder = (.39 * s, 1.43, 0)
    arm = pivot(taper_limb(side + 'Arm', shoulder, elbows[side], (.19, .20), (.16, .17), 'toy_body', .022), shoulder)
    attach(cyl(side + 'ShoulderJoint', shoulder, .095, .17, 'toy_body_dark', 'x', 16, .008), arm)
    attach(box(side + 'ShoulderSocket', (.41 * s, 1.45, 0), (.15, .13, .19), 'toy_vest', .012), arm)
    pad = sculpt_loft(side + 'Pad', (.44 * s, 1.465, 0), [
        (-.115, 0, 0, .31, .39),
        (-.02, -.01 * s, 0, .32, .40),
        (.07, -.03 * s, 0, .26, .33),
        (.12, -.05 * s, 0, .15, .21),
    ], 'toy_team', exponent=.72, rotation=(0, 0, -.18 * s))
    attach(pad, arm)
    pad_trim = sculpt_loft(side + 'PadTrim', (.46 * s, 1.348, 0), [
        (-.024, 0, 0, .325, .405), (.024, 0, 0, .315, .395),
    ], 'toy_cream', exponent=.72, rotation=(0, 0, -.18 * s))
    attach(pad_trim, arm)
    joint_drum(side + 'Elbow', elbows[side], .082, .20, arm, 'toy_body_dark', 'toy_cream', 'x')
    attach(taper_limb(side + 'Forearm', elbows[side], hands[side], (.19, .20), (.16, .17), 'toy_body', .022), arm)
    mid_fa = tuple((elbows[side][i] + hands[side][i]) * .5 for i in range(3))
    attach(box(side + 'GauntletPlate', (mid_fa[0] + .03 * s, mid_fa[1] + .02, mid_fa[2]),
               (.14, .09, .18), 'toy_vest', .012), arm)
    attach(box(side + 'WristCuff', hands[side], (.175, .175, .055), 'toy_cream', .008), arm)
    attach(box(side + 'Hand', hands[side], (.15, .15, .16), 'toy_body_dark', .028), arm)
    keep_parts = ('LeftPad', 'LeftPadTrim') if side == 'Left' else ('RightPad',)
    merge_rigid(arm, keep_parts)

# Heavy square-barrel pulse rifle — front bore at (.22, 1.12, -.58)
G = (.22, 1.12, -.28)
def gp(x, y, z):
    return (G[0] + x, G[1] + y, G[2] + z)

gun = box('EnemyGun', G, (.135, .165, .44), 'toy_gun', .020)
for part in [
    wedge('GunShroud', gp(0, .005, -.245), (.12, .09), (.105, .09), .14, 'toy_body_dark', .014),
    box('GunMuzzle', gp(0, .0, -.28), (.105, .115, .065), 'toy_gun_light', .012),
    box('GunBore', gp(0, .0, -.305), (.052, .052, .016), 'toy_body_dark', .004),
    box('GunStock', gp(0, -.01, .255), (.12, .155, .11), 'toy_gun_light', .018),
    box('GunStockPad', gp(0, -.01, .318), (.125, .16, .03), 'toy_body_dark', .008),
    box('GunRail', gp(0, .098, -.03), (.075, .036, .34), 'toy_body_dark', .008),
    box('GunOptic', gp(0, .132, .02), (.082, .048, .12), 'toy_vest', .010),
    box('GunClip', gp(0, -.15, -.05), (.072, .19, .11), 'toy_gun_light', .014, (.18, 0, 0)),
    box('GunClipBase', gp(0, -.245, -.068), (.082, .035, .12), 'toy_team', .008, (.18, 0, 0)),
    box('GunGrip', gp(0, -.12, .12), (.06, .14, .075), 'toy_body_dark', .012, (-.26, 0, 0)),
    box('GunStripeL', gp(-.071, .015, -.04), (.010, .032, .38), 'toy_visor', .004),
    box('GunStripeR', gp(.071, .015, -.04), (.010, .032, .38), 'toy_visor', .004),
]:
    attach(part, gun)
merge_rigid(gun)
export('enemy', False)

# ---------------------------------------------------------------------------
# 3. Rusher — 'Razor-Stalker'
#    Curved aerodynamic shark-helmet + sculpted torso/limbs + detachable ChestPlate & LeftFin!
# ---------------------------------------------------------------------------
begin('rusher')
torso = sculpt_loft('Torso', (0, 1.35, .01), [
    (-.15, 0, 0, .25, .18),
    (-.05, 0, -.01, .36, .24),
    (.06, 0, -.01, .49, .29),
    (.14, 0, 0, .42, .25),
    (.18, 0, .01, .25, .19),
], 'toy_rush', exponent=.66)

# Exposed inner mechanical ribcage & overloaded cyan/amber reactor behind ChestPlate!
attach(box('InnerSternum', (0, 1.33, -.125), (.28, .22, .048), 'toy_joint', .010), torso)
for rib_y in (1.255, 1.325, 1.395):
    for s in (-1, 1):
        attach(box('InnerRib', (.10 * s, rib_y, -.150), (.125, .032, .038),
                   'toy_cream' if rib_y == 1.325 else 'toy_joint', .005, (0, .22 * s, -.14 * s)), torso)
attach(cyl('InnerReactor', (0, 1.34, -.158), .062, .038, 'toy_thrust', 'z', 14, .004), torso)
attach(cyl('SeveredTube', (.085, 1.38, -.168), .020, .095, 'toy_blade', 'z', 10, .003), torso)

for side, s in [('Left', -1), ('Right', 1)]:
    attach(wedge('SpeedCollar', (.145 * s, 1.515, .01), (.065, .20), (.05, .16), .09,
                 'toy_rush', .010, rotation=(0, 0, -.24 * s)), torso)
    attach(taper_limb('WaistPiston', (.105 * s, 1.03, -.02), (.13 * s, 1.21, -.025),
                      (.038, .038), (.030, .030), 'toy_cream', .005), torso)
    fin = plate_profile(side + 'Fin', (.15 * s, 1.48, .17),
                        [(-.07, -.08), (.06, -.06), (.28, .19), (.18, .23)],
                        .038, 'toy_rush', .010, 'zy', rotation=(0, -.22 * s, -.30 * s))
    attach(fin, torso)
    if side == 'Right':
        attach(plate_profile('FinTrim', (.165 * s, 1.50, .155),
                             [(-.05, -.05), (.02, -.04), (.20, .18), (.14, .20)],
                             .042, 'toy_cream', .006, 'zy', rotation=(0, -.22 * s, -.30 * s)), torso)
    attach(cyl('Thruster', (.205 * s, 1.00, .03), .088, .11, 'toy_rush', 'x', 18, .016), torso)
    attach(cyl('ThrusterNozzle', (.252 * s, 1.00, .03), .072, .042, 'toy_joint', 'x', 18, .006), torso)
    attach(cyl('ThrusterGlow', (.274 * s, 1.00, .03), .054, .016, 'toy_thrust', 'x', 16, .003), torso)

# Detachable outer ivory-cream diamond ChestPlate
chest_plate = plate_profile('ChestPlate', (0, 1.35, -.164),
                            [(-.195, .085), (-.085, .118), (.085, .118), (.195, .085),
                             (.145, -.095), (0, -.172), (-.145, -.095)],
                            .050, 'toy_cream', .014, 'xy')
attach(chest_plate, torso)
attach(plate_profile('ChestCoreGlow', (0, 1.355, -.193),
                     [(-.044, .035), (.044, .035), (0, -.052)], .018, 'toy_visor', .004, 'xy'), chest_plate)

attach(cyl('Waist', (0, 1.11, .01), .076, .19, 'toy_joint', 'y', 14, .008), torso)
attach(box('WaistRing', (0, 1.155, .005), (.23, .045, .18), 'toy_joint', .010), torso)
attach(sculpt_loft('Hips', (0, .99, 0), [
    (-.065, 0, 0, .27, .19), (.02, 0, 0, .35, .24), (.065, 0, 0, .33, .22),
], 'toy_rush', exponent=.66), torso)
attach(wedge('GroinPod', (0, .965, -.118), (.10, .05), (.14, .06), .13, 'toy_cream', .010), torso)
attach(cyl('Neck', (0, 1.54, 0), .060, .10, 'toy_joint', 'y', 12, .006), torso)
attach(wedge('BackPlate', (0, 1.36, .155), (.18, .07), (.26, .09), .22, 'toy_cream', .014), torso)
attach(cyl('DorsalThruster', (0, 1.32, .198), .055, .035, 'toy_joint', 'z', 14, .006), torso)
attach(cyl('DorsalGlow', (0, 1.32, .216), .038, .014, 'toy_thrust', 'z', 14, .003), torso)
merge_rigid(torso, ('ChestPlate', 'LeftFin'))

# Sleek curved aerodynamic shark-wedge assassin helmet (axis='z' loft for true swept curve!)
head = sculpt_loft('Head', (0, 1.665, -.01), [
    (-.09, 0, 0, .18, .19),
    (0.0, 0, -.01, .27, .27),
    (.09, 0, .01, .25, .25),
], 'toy_joint', exponent=.70)
attach(wedge('ChinGuard', (0, 1.585, -.095), (.12, .09), (.19, .13), .068, 'toy_cream', .010), head)
for side, s in [('Left', -1), ('Right', 1)]:
    joint_drum(side + 'Ear', (.165 * s, 1.69, .02), .056, .050, head, 'toy_joint', 'toy_cream', 'x')
merge_rigid(head)

helmet = sculpt_loft('Helmet', (0, 1.80, .04), [
    (-.22, 0, -.045, .24, .055),
    (-.14, 0, -.015, .35, .13),
    (0.0, 0, .025, .36, .19),
    (.16, 0, .075, .26, .18),
    (.30, 0, .125, .12, .10),
], 'toy_rush', axis='z', exponent=.72)
for side, s in [('Left', -1), ('Right', 1)]:
    attach(wedge('HelmetCheek', (.138 * s, 1.655, -.035), (.065, .20), (.075, .24), .13,
                 'toy_rush', .012, rotation=(0, -.12 * s, .10 * s)), helmet)
    horn = plate_profile(side + 'Horn', (.118 * s, 1.845, .21),
                         [(-.13, -.035), (.04, -.045), (.30, .085), (.19, .115)],
                         .038, 'toy_rush', .010, 'zy', rotation=(0, -.20 * s, -.26 * s))
    attach(horn, helmet)
attach(plate_profile('HelmetStripe', (0, 1.875, .05),
                     [(-.18, -.02), (-.03, .032), (.22, .055), (.16, -.02)],
                     .046, 'toy_cream', .008, 'zy'), helmet)
merge_rigid(helmet, ('LeftHorn',))

visor = box('Visor', (0, 1.688, -.156), (.075, .040, .028), 'toy_visor', .006)
for s in (-1, 1):
    attach(box('VisorSlit', (.076 * s, 1.698, -.146), (.118, .046, .030),
               'toy_visor', .006, (0, -.22 * s, .22 * s)), visor)
merge_rigid(visor)

# Curved muscular thighs, blade-canted white shins & three-toed mechanical talon feet
for side, s in [('Left', -1), ('Right', 1)]:
    x = .135 * s
    leg = pivot(sculpt_loft(side + 'Leg', (x, .79, -.01), [
        (-.15, 0, -.01, .15, .17), (-.03, 0, 0, .20, .22), (.11, 0, 0, .20, .22), (.16, 0, 0, .15, .17),
    ], 'toy_rush', exponent=.70), (x, .98, 0))
    attach(cyl(side + 'HipBall', (x, .97, 0), .068, .13, 'toy_joint', 'x', 14, .008), leg)
    joint_drum(side + 'Knee', (x, .585, -.02), .068, .16, leg, 'toy_joint', 'toy_cream', 'x')
    attach(plate_profile(side + 'KneeCap', (x, .56, -.118),
                         [(-.02, -.08), (.03, -.06), (.05, .09), (-.02, .06)],
                         .12, 'toy_rush', .012, 'zy'), leg)
    attach(sculpt_loft(side + 'Shin', (x, .34, -.01), [
        (-.17, 0, .01, .15, .18), (-.04, 0, -.01, .21, .24), (.11, 0, -.02, .22, .24), (.18, 0, -.02, .17, .19),
    ], 'toy_cream', exponent=.68), leg)
    attach(box(side + 'ShinAnkleBand', (x, .18, -.01), (.18, .045, .20), 'toy_rush', .008), leg)
    attach(box(side + 'ShinSidePiston', (x + .102 * s, .36, -.01), (.032, .18, .055), 'toy_joint', .006), leg)
    attach(plate_profile(side + 'CalfFin', (x, .36, .118),
                         [(-.03, -.10), (.05, -.04), (.07, .10), (-.02, .08)],
                         .042, 'toy_rush', .008, 'zy'), leg)
    attach(wedge(side + 'AnkleBlock', (x, .105, -.01), (.16, .18), (.14, .15), .10, 'toy_joint', .014), leg)
    for claw_i, (cx, yaw) in enumerate([(-.052, .18), (0.0, 0.0), (.052, -.18)]):
        attach(wedge(side + f'Talon{claw_i}', (x + cx, .042, -.145), (.046, .15), (.034, .11), .075,
                     'toy_joint', .008, rotation=(.12, yaw, 0)), leg)
    attach(wedge(side + 'HeelSpur', (x, .045, .105), (.065, .11), (.048, .08), .075, 'toy_joint', .008), leg)
    merge_rigid(leg)

# Curved swallowtail shoulders, Left-Arm Cyan Energy Buckler & Right Hydraulic Slash Arm
wrists = {'Left': (-.32, 1.01, -.17), 'Right': (.30, .99, -.15)}
elbows = {'Left': (-.34, 1.22, -.04), 'Right': (.32, 1.22, -.02)}
for side, s in [('Left', -1), ('Right', 1)]:
    shoulder = (.285 * s, 1.445, 0)
    arm = pivot(sculpt_loft(side + 'Arm', (.305 * s, 1.455, .01), [
        (-.09, 0, 0, .20, .24), (.02, .01 * s, .01, .21, .25), (.09, .02 * s, .03, .14, .17),
    ], 'toy_rush', exponent=.72, rotation=(0, 0, -.20 * s)), shoulder)
    attach(plate_profile(side + 'ShoulderWing', (.365 * s, 1.515, .05),
                         [(-.08, -.05), (.02, -.04), (.15, .09), (.05, .11)],
                         .038, 'toy_cream', .008, 'zy', rotation=(0, -.18 * s, -.28 * s)), arm)
    attach(taper_limb(side + 'UpperLink', shoulder, elbows[side], (.12, .13), (.105, .115), 'toy_joint', .014), arm)
    joint_drum(side + 'Elbow', elbows[side], .062, .14, arm, 'toy_joint', 'toy_cream', 'x')
    attach(taper_limb(side + 'Forearm', elbows[side], wrists[side], (.175, .19), (.145, .16), 'toy_cream', .020), arm)
    if side == 'Left':
        attach(cyl('BucklerMount', (-.395, 1.09, -.135), .080, .048, 'toy_joint', 'x', 16, .008), arm)
        attach(cyl('BucklerPlate', (-.422, 1.09, -.135), .140, .026, 'toy_cream', 'x', 20, .008), arm)
        attach(cyl('BucklerCap', (-.438, 1.09, -.135), .055, .022, 'toy_rush', 'x', 16, .006), arm)
        attach(ring('BucklerRim', (-.428, 1.09, -.135), .162, .025, 'toy_blade', axis='x'), arm)
        attach(box('LeftHand', (-.32, .96, -.18), (.11, .115, .12), 'toy_joint', .022), arm)
    else:
        attach(box('SlashCuff', (.335, 1.10, -.09), (.065, .14, .12), 'toy_rush', .012), arm)
    merge_rigid(arm, ('LeftHand',))

box('RightHand', (.30, .94, -.175), (.115, .12, .125), 'toy_joint', .024)
export('rusher', False)

# ---------------------------------------------------------------------------
# 4. Rusher Blade — Curved Glowing Cyan Plasma Cleaver with Mechanical Spine
# ---------------------------------------------------------------------------
begin('rusher_blade')
box('Handle', (0, 0, 0), (.046, .15, .056), 'toy_joint', .012)
box('Guard', (0, .088, .008), (.092, .044, .115), 'toy_rush', .012)
cyl('PowerCell', (0, .088, .055), .026, .060, 'toy_blade', 'x', 12, .005)
box('Pommel', (0, -.088, 0), (.056, .040, .068), 'toy_cream', .010)
plate_profile('BladeSpine', (0, .27, -.026),
              [(-.030, -.16), (.014, -.16), (.026, .09), (-.008, .18), (-.036, .12)],
              .044, 'toy_joint', .008, 'zy')
plate_profile('Blade', (0, .295, .018),
              [(-.024, -.185), (.052, -.172), (.078, .025), (.060, .168), (-.018, .232), (-.030, .095)],
              .030, 'toy_blade', .008, 'zy')
export('rusher_blade')

bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/toy_actors.blend'), compress=True)
