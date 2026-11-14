"""Concept-facing FPS carbine. Blender +Y bore; precision sockets remain unchanged."""
import bpy,sys,math
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(HERE))
from geometry import *
bpy.ops.wm.read_factory_settings(use_empty=True);m=palette();root=group('IonRifle')
# Deliberately keep paint below diffuse white; lighting creates the final highlights.
m['white'].node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.24,.25,.24,1)
m['metal'].node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.10,.13,.15,1)
m['metal'].node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.48
m['cyan'].node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value=1.3
# Wedge receiver, lower structural chassis, and separate rear ceramic plates.
box('Receiver spine',(0,-.12,.015),(.19,.53,.15),m['dark'],.028,root)
panel('Lower chassis',0,.18,[(-.40,-.09),(.04,-.09),(.13,-.045),(.04,.05),(-.38,.05)],m['dark'],root)
for side in [-1,1]:
 panel('Rear ceramic',side*.108,.025,[(-.39,-.055),(-.06,-.055),(.025,-.005),(-.015,.095),(-.31,.125),(-.43,.06)],m['white'],root)
 panel('Rear inlay',side*.124,.008,[(-.37,.045),(-.17,.045),(-.14,.065),(-.34,.085)],m['dark'],root)
 box('Selector housing',(side*.131,-.07,-.018),(.024,.092,.055),m['orange'],.008,root)
 beam('Selector',(side*.145,-.07,-.015),(side*.157,-.07,-.015),.016,m['metal'],root,12)
 for y,z in [(-.35,.03),(-.12,.07),(.48,.04),(.77,-.005)]:
  beam('Recessed fastener',(side*.12,y,z),(side*.132,y,z),.008,m['metal'],root,10)
# Main chamber is visible from the player's left, between independent armor sections.
beam('Pressure core',(-.065,.055,.005),(-.065,.43,.005),.063,m['dark'],root,32)
for y in [.10,.21,.32]:
 beam('Machined collar',(-.065,y-.022,.005),(-.065,y+.025,.005),.071,m['metal'],root,32)
 beam('Ion coil',(-.065,y+.025,.005),(-.065,y+.047,.005),.073,m['cyan'],root,32)
for y in [.05,.405]:beam('Chamber end',(-.065,y,.005),(-.065,y+.026,.005),.077,m['dark'],root,24)
# One top and one bottom guard; leave a true side opening, not an emissive sticker.
box('Chamber upper bridge',(0,.24,.105),(.16,.43,.035),m['dark'],.009,root)
box('Chamber lower guard',(0,.24,-.082),(.14,.38,.025),m['metal'],.008,root)
# Layered short handguard and barrel with recessed side ventilation.
box('Fore-end core',(0,.64,.012),(.18,.37,.14),m['dark'],.018,root)
for side in [-1,1]:
 panel('Fore-end armor',side*.105,.025,[(.45,-.045),(.79,-.045),(.84,.005),(.79,.09),(.49,.09),(.43,.04)],m['white'],root)
 for y in [.53,.62,.71]:
  panel('Vent recess',side*.12,.008,[(y-.022,-.02),(y+.016,-.02),(y+.033,.045),(y-.005,.045)],m['rubber'],root)
 box('Fore-end accent',(side*.123,.49,.055),(.008,.04,.045),m['orange'],.003,root)
beam('Barrel',(0,.79,.015),(0,.98,.015),.031,m['metal'],root,20)
for y in [.84,.89]:beam('Barrel collar',(0,y,.015),(0,y+.027,.015),.042,m['dark'],root,16)
for x,z,w,h in [(-.044,.015,.022,.10),(.044,.015,.022,.10),(0,-.03,.07,.02),(0,.06,.07,.02)]:box('Muzzle brake',(x,.985,z),(w,.11,h),m['dark'],.006,root)
beam('Bore darkness',(0,1.02,.015),(0,1.025,.015),.024,m['rubber'],root,20)
# Short sight mount; no full-length silver ladder across the receiver.
box('Sight mount',(0,.02,.135),(.10,.21,.028),m['dark'],.007,root)
for y in [-.045,.015,.075]:box('Mount notch',(0,y,.151),(.11,.018,.012),m['metal'],.003,root)
optic=group('Optic',(0,.015,.24),root)
for side in [-1,1]:
 panel('Sight hood',side*.075,.026,[(-.065,.16),(-.065,.30),(-.035,.325),(.10,.325),(.125,.29),(.125,.16)],m['dark'],optic)
 box('Sight side plate',(side*.091,.005,.25),(.008,.10,.065),m['metal'],.006,optic)
 box('Sight warning',(side*.098,.03,.25),(.005,.025,.035),m['orange'],.003,optic)
box('Sight crown',(0,.025,.316),(.145,.18,.025),m['dark'],.008,optic)
box('Sight lower rim',(0,.015,.169),(.15,.16,.019),m['dark'],.006,optic)
# A small physical reticle on the same axis as the gameplay sight markers.
beam('Reticle',(0,.11,.24),(0,.113,.24),.0028,m['cyan'],optic,12)
optic.scale=(.70,.80,.65)
# Slim telescoping butt rather than a solid near-camera block.
for x in [-.052,.052]:beam('Stock rail',(x,-.38,.03),(x,-.60,-.005),.018,m['dark'],root,12)
box('Cheek saddle',(0,-.48,.065),(.13,.22,.045),m['dark'],.012,root)
box('Butt frame',(0,-.63,-.015),(.13,.055,.18),m['white'],.016,root)
box('Butt pad',(0,-.665,-.015),(.125,.028,.17),m['rubber'],.01,root)
# Detachable magazine and grip retain their gameplay pivots.
mag=group('Magazine',(0,-.02,-.075),root)
panel('Magazine body',0,.115,[(-.10,-.07),(.075,-.07),(.11,-.29),(.045,-.36),(-.11,-.32)],m['dark'],mag)
for side in [-1,1]:
 panel('Magazine armor',side*.062,.012,[(-.085,-.12),(.06,-.12),(.075,-.28),(.025,-.31),(-.085,-.29)],m['white'],mag)
 box('Cell stripe',(side*.071,-.015,-.21),(.008,.04,.16),m['orange'],.003,mag)
box('Magazine shoe',(0,-.015,-.34),(.14,.16,.035),m['rubber'],.007,mag)
panel('Pistol grip',0,.105,[(-.35,-.035),(-.23,-.035),(-.27,-.27),(-.39,-.25)],m['rubber'],root)
for z in [-.10,-.15,-.20]:box('Grip rib',(0,-.30,z),(.11,.07,.012),m['dark'],.003,root)
beam('Trigger bow',(-.055,-.21,-.08),(-.055,-.17,-.17),.009,m['metal'],root,12)
beam('Trigger return',(-.055,-.17,-.17),(-.055,-.29,-.17),.009,m['metal'],root,12)
# Articulated armored gloves, with fingers wrapping rather than flat box palms.
for name,side,y in [('RightHand',1,-.31),('SupportHand',-1,.61)]:
 hand=group(name,(side*.09,y,-.10),root)
 box('Glove palm',(side*.10,y,-.10),(.09,.13,.095),m['rubber'],.025,hand)
 for k in range(4):
  yy=y-.042+k*.028
  box('Finger',(side*.055,yy,-.145),(.11,.022,.032),m['rubber'],.010,hand)
  box('Curled finger',(side*-.004,yy,-.12),(.025,.022,.06),m['rubber'],.009,hand)
  box('Knuckle',(side*.15,yy,-.08),(.022,.023,.03),m['dark'],.007,hand)
 box('Thumb',(side*.095,y-.07,-.055),(.045,.065,.035),m['rubber'],.015,hand)
 wrist=Vector((side*.16,y-.07,-.16));elbow=Vector((-.70 if side<0 else .40,y-(.68 if side<0 else .43),-.50 if side<0 else -.35))
 beam('Suit sleeve',wrist,elbow,.067,m['rubber'],hand,16)
 mid=(wrist+elbow)*.5
 orientation=Vector((0,1,0)).rotation_difference((wrist-elbow).normalized())
 normal=orientation@Vector((0,0,1))
 armor=box('Gauntlet plate',mid+normal*.067,(.17,.50 if side<0 else .29,.055),m['white'],.018,hand)
 armor.rotation_mode='QUATERNION';armor.rotation_quaternion=orientation
 stripe=box('Gauntlet stripe',mid+normal*.098,(.155,.055,.012),m['orange'],.004,hand)
 stripe.rotation_mode='QUATERNION';stripe.rotation_quaternion=orientation

bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'ion-rifle.blend'))
batch_children(root)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/space/ion-rifle.glb'),export_format='GLB')
# Only update the first-person asset in this pass; accepted enemies keep their rifle.
print('RIFLE_READY: muzzle (0,.015,-1.025), sight axis y=.24')
