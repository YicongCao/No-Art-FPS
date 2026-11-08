"""Build the two toy viewmodels and the shared slipper projectile."""
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/comedy"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

PALETTE = {
    "ink": "263548", "mint": "62CFB4", "blue": "3583CF", "aqua": "86E3F4",
    "gold": "FFD366", "orange": "F2974E", "violet": "8459BA", "lilac": "C39BEF",
    "cream": "FFF1D1", "plum": "4A355D", "rubber": "34867C", "coral": "E46B55",
}
paints = {}
for name, code in PALETTE.items():
    rgb = [int(code[i:i+2], 16)/255 for i in (0,2,4)]
    rgba = (*[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb],1)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = rgba
    shader.inputs["Roughness"].default_value = .82
    paints[name] = mat


def xyz(p):
    return p[0], -p[2], p[1]


def group(name):
    obj = bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    return obj


def finish(parent, name, paint):
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.data.materials.append(paints[paint])
    return obj


def box(parent, name, at, size, paint, bevel=.018, tilt=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(at))
    obj = bpy.context.object
    obj.dimensions = (size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod = obj.modifiers.new("Faceted edges","BEVEL")
        mod.width = bevel
        mod.segments = 1
    obj.rotation_euler.x = tilt
    return finish(parent,name,paint)


def barrel(parent, name, at, radius, depth, paint):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=radius,depth=depth,
                                      location=xyz(at),rotation=(math.pi/2,0,0))
    return finish(parent,name,paint)


def hands(parent):
    box(parent,"Trigger hand",(.025,-.255,.20),(.148,.16,.185),"ink")
    box(parent,"Right sleeve",(.14,-.40,.365),(.205,.34,.23),"rubber")
    box(parent,"Support glove",(-.11,-.185,-.23),(.18,.15,.17),"ink")
    box(parent,"Support sleeve",(-.21,-.345,-.085),(.20,.32,.21),"rubber")


def slipper(parent, at=(0,0,0), scale=1):
    x,y,z = at
    box(parent,"Orange outsole",(x,y,z),(.255*scale,.047*scale,.53*scale),"orange",.026*scale)
    box(parent,"Cream sole stripe",(x,y+.026*scale,z),(.244*scale,.025*scale,.51*scale),"cream",.018*scale)
    box(parent,"Mint footbed",(x,y+.042*scale,z),(.232*scale,.025*scale,.49*scale),"mint",.018*scale)
    box(parent,"Wide curved strap",(x,y+.102*scale,z-.064*scale),(.240*scale,.087*scale,.166*scale),"rubber",.024*scale)
    box(parent,"Strap accent",(x,y+.148*scale,z-.061*scale),(.187*scale,.012*scale,.034*scale),"gold",.007*scale)
    for i in range(3):
        box(parent,"Outsole tread",(x,y-.027*scale,z+(.13-i*.105)*scale),
            (.18*scale,.012*scale,.022*scale),"coral",.003*scale)


def export(parent):
    bpy.ops.object.select_all(action="DESELECT")
    parent.select_set(True)
    for obj in parent.children:obj.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.export_scene.gltf(filepath=str(OUT/f"{parent.name}.glb"),
                             use_selection=True,export_format="GLB",export_yup=True)


water = group("water_blaster")
box(water,"Aqua pump body",(0,.025,-.08),(.264,.226,.61),"blue",.032)
box(water,"Mint pump slider",(0,-.023,-.355),(.284,.154,.26),"mint",.028)
box(water,"Pistol grip",(0,-.213,.159),(.142,.33,.20),"ink",.017,-.17)
box(water,"Trigger guard",(0,-.115,.035),(.129,.13,.19),"gold",.023)
barrel(water,"Yellow reservoir",(0,.237,.009),.113,.39,"gold")
barrel(water,"Reservoir screw cap",(0,.237,.227),.123,.062,"orange")
barrel(water,"Clear water window",(0,.238,-.19),.089,.058,"aqua")
barrel(water,"Orange nozzle",(0,.072,-.485),.102,.24,"orange")
barrel(water,"Nozzle collar",(0,.072,-.618),.089,.046,"gold")
barrel(water,"Dark nozzle opening",(0,.072,-.647),.042,.02,"ink")
box(water,"Left badge plate",(-.134,.02,-.02),(.017,.13,.22),"aqua",.007)
hands(water)
export(water)

launcher = group("slipper_launcher")
box(launcher,"Purple receiver",(0,.006,.04),(.285,.27,.50),"violet",.031)
box(launcher,"Ergonomic grip",(0,-.218,.14),(.154,.32,.193),"plum",.020,-.15)
box(launcher,"Open launch tray",(0,.045,-.38),(.37,.095,.66),"lilac")
for x in (-.18,.18):
    box(launcher,"Orange side rail",(x,.127,-.381),(.045,.145,.65),"orange")
    box(launcher,"Rail tip",(x,.13,-.725),(.07,.15,.089),"gold")
    for z in (-.39,-.23,-.07):
        box(launcher,"Rail vent",(x*1.125,.145,z),(.012,.031,.059),"plum",.005)
box(launcher,"Front bumper",(0,.035,-.752),(.332,.105,.074),"orange")
box(launcher,"Rear loading latch",(0,.183,.19),(.24,.09,.069),"gold")
slipper(launcher,(0,.116,-.335),.93)
hands(launcher)
export(launcher)

shoe = group("slipper")
slipper(shoe,scale=.78)
export(shoe)
for i,obj in enumerate((water,launcher,shoe)):
    obj.location.x = i*1.65
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/comedy_weapons.blend"),compress=True)
