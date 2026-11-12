"""Painted-plastic comedy viewmodels and the shared slipper projectile.
Run: blender --background --python tools/build_comedy_weapons.py

Shapes follow docs/art/toy/concepts/tripo/water-blaster and mop-launcher. Muzzles stay where
player.gd expects them: water (0, .072, -.665), mop (0, .15, -.82). The mode sticker sits on the
left receiver face near (-.146, .028, .09).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from toy_blocks import *

reset(ROOT / 'assets/models/comedy')


def hands(grip, support, support_turn=(.45, 0, .35), reach=(-.09, -.13, .11), sleeve=(-.14, -.20, .19)):
    gx, gy, gz = grip
    sx, sy, sz = support
    box('right_glove', grip, (.13, .17, .17), 'toy_glove', .04)
    box('right_cuff', (gx + .055, gy - .10, gz + .09), (.18, .06, .2), 'toy_cuff', .022, (.35, 0, -.25))
    box('right_sleeve', (gx + .085, gy - .19, gz + .15), (.2, .34, .23), 'toy_sleeve', .05)
    box('left_glove', support, (.15, .14, .18), 'toy_glove', .04)
    box('left_cuff', (sx + reach[0], sy + reach[1], sz + reach[2]), (.19, .07, .21), 'toy_cuff', .025, support_turn)
    box('left_sleeve', (sx + sleeve[0], sy + sleeve[1], sz + sleeve[2]), (.21, .35, .23), 'toy_sleeve', .05)


def slipper(at=(0, 0, 0), scale=1.0, tag=''):
    x, y, z = at
    k = scale
    box('outsole' + tag, (x, y, z), (.25 * k, .05 * k, .52 * k), 'toy_sole', .022 * k)
    box('footbed' + tag, (x, y + .035 * k, z + .005 * k), (.225 * k, .025 * k, .48 * k), 'toy_cream', .01 * k)
    box('strap' + tag, (x, y + .085 * k, z - .10 * k), (.245 * k, .075 * k, .17 * k), 'toy_sole', .03 * k)


begin('water_blaster')
box('body', (0, .025, -.10), (.28, .20, .56), 'toy_water', .05)
cyl('tank', (0, .215, -.13), .1, .40, 'toy_tank', 'z', 20, .05)
cyl('tank_cap', (0, .215, .085), .075, .045, 'toy_nozzle', 'z', 16, .015)
for z in (-.28, .0):
    box('tank_tab', (0, .13, z), (.13, .07, .07), 'toy_water', .02)
for x in (-.104, .104):
    cyl('tank_window', (x, .235, -.10), .042, .014, 'toy_aqua', 'x', 16, .004)
box('pump', (0, -.105, -.30), (.22, .10, .17), 'toy_pump', .035)
ring('collar', (0, .06, -.39), .082, .022, 'toy_gold')
cyl('nozzle', (0, .065, -.52), .072, .25, 'toy_nozzle', 'z', 16, .02)
cyl('nozzle_mouth', (0, .065, -.648), .032, .012, 'toy_joint', 'z', 12, 0)
box('grip', (0, -.20, .12), (.13, .30, .17), 'toy_navy', .04, (-.25, 0, 0))
ring('trigger_loop', (0, -.11, -.01), .045, .011, 'toy_gold', 'x')
hands((.015, -.23, .17), (-.08, -.15, -.30))
export('water_blaster')

begin('mop_launcher')
box('receiver', (0, .02, .06), (.28, .24, .34), 'toy_violet', .055)
cyl('receiver_nose', (0, .03, -.13), .09, .07, 'toy_violet', 'z', 16, .02)
box('latch', (0, .155, .10), (.09, .04, .07), 'toy_gold', .015)
box('grip', (0, -.20, .15), (.14, .30, .17), 'toy_plum', .04, (-.2, 0, 0))
cyl('pole', (0, .04, -.43), .035, .60, 'toy_lilac', 'z', 16, .01)
cyl('pole_clip', (0, .04, -.40), .046, .045, 'toy_nozzle', 'z', 16, .01)
cyl('collar', (0, .04, -.725), .062, .055, 'toy_nozzle', 'z', 16, .015)
box('mop_core', (0, .05, -.86), (.32, .30, .22), 'toy_mop', .09)
for x, y in [(-.11, .11), (.11, .11), (-.14, -.03), (.14, -.03), (0, -.11), (0, .16)]:
    box('mop_lobe', (x, .05 + y, -.90), (.13, .14, .26), 'toy_mop', .06, (0, 0, x * 1.5))
slipper((0, .095, -.42), .62)
hands((.015, -.22, .18), (-.05, -.045, -.60), (.55, 0, .35), (-.08, -.15, .10), (-.15, -.29, .17))
export('mop_launcher')

begin('slipper')
slipper(scale=.78)
export('slipper')

for i, obj in enumerate(roots):
    obj.location.x = i * 1.65
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/comedy_weapons.blend'), compress=True)
