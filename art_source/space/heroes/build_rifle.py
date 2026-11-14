import bpy,sys,math,json
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(HERE))
from geometry import *
bpy.ops.wm.read_factory_settings(use_empty=True);m=palette();root=group('IonRifle')
# The bore is exactly +Y at Z .015. Real apertures and separated armor plates.
box('Receiver',(0,-.055,.015),(.15,.42,.17),m['dark'],.025,root)
for side in [-1,1]:
 panel('Receiver armor',side*.085,.028,[(-.27,-.065),(.12,-.065),(.19,.0),(.14,.11),(-.24,.11),(-.30,.06)],m['white'],root)
 panel('Forward shroud',side*.094,.025,[(.39,-.055),(.85,-.055),(.92,.02),(.87,.095),(.43,.095)],m['white'],root)
 for y in [.53,.64,.75]:
  slot=box('Vent',(side*.11,y,.0),(.008,.063,.045),m['rubber'],.009,root);slot.rotation_euler.x=-.22
 box('Warning stripe',(side*.103,-.11,.07),(.007,.15,.025),m['orange'],.003,root)
 for y,z in [(-.22,.07),(.10,-.03),(.46,.05),(.83,.04)]:beam('Panel fastener',(side*.107,y,z),(side*.112,y,z),.009,m['metal'],root,8)
beam('Ion chamber',(0,.18,.015),(0,.45,.015),.072,m['metal'],root,24)
for y in [.23,.31,.39]:beam('Ion coil',(0,y,.015),(0,y+.023,.015),.076,m['cyan'],root,24)
for x in [-.065,.065]:
 for z in [-.045,.075]:box('Chamber cage',(x,.32,z),(.018,.29,.018),m['dark'],.006,root)
beam('Inner barrel',(0,.43,.015),(0,.97,.015),.034,m['metal'],root)
# Muzzle uses four rails around the bore instead of an opaque cylinder end cap.
for x,z,w,h in [(-.055,.015,.025,.14),(.055,.015,.025,.14),(0,-.045,.09,.025),(0,.075,.09,.025)]:box('Muzzle brake',(x,.98,z),(w,.15,h),m['dark'],.009,root)
beam('Bore darkness',(0,1.02,.015),(0,1.025,.015),.025,m['rubber'],root)
# Receiver rail, stock struts and polymer butt pad.
box('Top rail',(0,.03,.14),(.095,.74,.035),m['dark'],.005,root)
for y in [-.28,-.20,-.12,-.04,.04,.12,.20,.28,.36]:box('Rail teeth',(0,y,.16),(.11,.027,.018),m['metal'],.003,root)
for x in [-.058,.058]:beam('Stock strut',(x,-.29,.05),(x,-.57,.0),.023,m['metal'],root)
box('Stock cheek',(0,-.44,.10),(.13,.30,.065),m['white'],.018,root)
box('Butt stock',(0,-.59,-.01),(.16,.07,.25),m['orange'],.021,root)
box('Butt rubber',(0,-.635,-.01),(.15,.035,.23),m['rubber'],.012,root)
# Holographic sight: genuinely open center, reticle placed on the bore-aligned sight axis.
optic=group('Optic',(0,.12,.32),root)
box('Optic base',(0,.12,.19),(.18,.20,.055),m['dark'],.009,optic)
for side in [-1,1]:
 panel('Sight ears',side*.082,.025,[(.035,.21),(.035,.38),(.065,.415),(.19,.415),(.205,.38),(.205,.21)],m['dark'],optic)
box('Sight top',(0,.12,.408),(.15,.18,.027),m['white'],.008,optic)
for side in [-1,1]:box('Sight marking',(side*.098,.10,.34),(.008,.07,.033),m['orange'],.003,optic)
beam('Reticle',(0,.18,.32),(0,.183,.32),.0028,m['cyan'],optic,12)
optic.scale=(.78,.82,.68);optic.location.z=.24
# Detachable magazine and grips have independent pivots, for the reload animation.
mag=group('Magazine',(0,.02,-.07),root)
magshape=panel('Cell magazine',0,.12,[(-.06,-.08),(.12,-.08),(.17,-.36),(-.02,-.40),(-.08,-.29)],m['orange'],mag)
for side in [-1,1]:
 box('Mag inset',(side*.063,.045,-.24),(.006,.085,.18),m['dark'],.005,mag)
 for z in [-.15,-.24,-.33]:box('Mag ribs',(side*.067,.045,z),(.008,.13,.012),m['metal'],.003,mag)
panel('Pistol grip',0,.105,[(-.25,-.04),(-.14,-.04),(-.19,-.31),(-.31,-.30)],m['rubber'],root)
for z in [-.12,-.18,-.24]:box('Grip ribs',(0,-.245,z),(.114,.09,.009),m['dark'],.002,root)
# The support hand wraps the fore-end. Both forearms enter from outside the screen.
for name,side,y in [('RightHand',1,-.22),('SupportHand',-1,.57)]:
 hand=group(name,(side*.095,y,-.08),root)
 box('Glove palm',(side*.09,y,-.10),(.11,.14,.10),m['rubber'],.027,hand)
 for k in range(4):
  box('Finger',(side*.055,y-.045+k*.028,-.15),(.12,.022,.035),m['rubber'],.009,hand)
  box('Knuckle',(side*.14,y-.045+k*.028,-.10),(.025,.025,.035),m['white'],.007,hand)
 wrist=(side*.16,y-.10,-.16);elbow=(side*.35,y-.47,-.37)
 beam('Suit forearm',wrist,elbow,.073,m['rubber'],hand)
 mid=(Vector(wrist)+Vector(elbow))*.5
 armor=box('Forearm armor',mid,(.13,.33,.105),m['white'],.025,hand);armor.rotation_euler.x=.45
 box('Gauntlet stripe',(mid.x,mid.y,mid.z+.058),(.11,.12,.016),m['orange'],.004,hand)
# Export source before per-material merging so all detail remains editable.
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'ion-rifle.blend'))
batch_children(root)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/space/ion-rifle.glb'),export_format='GLB')
# Third-person version removes player arms and scales around the same precise bore axis.
for name in ['RightHand','SupportHand']:
 obj=bpy.data.objects.get(name)
 if obj:
  for child in list(obj.children_recursive):bpy.data.objects.remove(child,do_unlink=True)
  bpy.data.objects.remove(obj,do_unlink=True)
root.scale=(.6,.6,.6)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/space/mech-rifle.glb'),export_format='GLB')
print('RIFLE_READY: muzzle (0,.015,-1.025), sight axis y=.32')
