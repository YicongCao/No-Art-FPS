"""Build an editable portable toilet and its column charges."""
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/comedy"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

colors = {
    "teal": "47A99D", "mint": "82CFBC", "dark": "294554", "cream": "FFF0CB",
    "gold": "FFCA60", "orange": "F06A37", "red": "B7433A", "ruby": "FF4541",
    "porcelain": "EAE6DC",
}
paints = {}
for name, hex_color in colors.items():
    rgb = [int(hex_color[i:i+2],16)/255 for i in (0,2,4)]
    rgba = (*[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb],1)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    surface = mat.node_tree.nodes["Principled BSDF"]
    surface.inputs["Base Color"].default_value = rgba
    surface.inputs["Roughness"].default_value = .86
    if name=="ruby":
        surface.inputs["Emission Color"].default_value = rgba
        surface.inputs["Emission Strength"].default_value = .6
    paints[name] = mat


def xyz(v):
    return v[0],-v[2],v[1]


def group(name, at=(0,0,0), parent=None):
    node = bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.location = xyz(at)
    return node


def finish(parent, name, paint):
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.data.materials.append(paints[paint])
    return obj


def box(parent, name, at, size, paint, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(at))
    obj = bpy.context.object
    obj.dimensions = (size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod = obj.modifiers.new("Faceted edges","BEVEL")
        mod.width = bevel
        mod.segments = 1
    return finish(parent,name,paint)


def column(parent, name, at, radius, height, paint):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=radius,depth=height,location=xyz(at))
    return finish(parent,name,paint)


def export(parent):
    bpy.ops.object.select_all(action="DESELECT")
    parent.select_set(True)
    for obj in parent.children_recursive:obj.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.export_scene.gltf(filepath=str(OUT/f"{parent.name}.glb"),use_selection=True,
                             export_format="GLB",export_yup=True)


booth = group("portable_toilet")
shell = group("Shell",parent=booth)
box(shell,"Skid base",(0,.09,0),(1.78,.18,1.58),"dark",.04)
box(shell,"Back panel",(0,1.17,-.70),(1.57,2.18,.14),"teal",.035)
for side in (-1,1):
    box(shell,"Molded side",(side*.75,1.17,0),(.13,2.18,1.43),"teal",.034)
    box(shell,"Front jamb",(side*.64,1.18,.688),(.25,2.18,.13),"mint",.022)
    for z in (-.47,-.14,.20,.49):
        box(shell,"Panel reinforcement",(side*.829,1.05,z),(.036,1.55,.08),"mint",.008)
    for y in (1.88,1.99,2.10):
        box(shell,"Vent louver",(side*.827,y,-.33),(.043,.044,.37),"dark",.006)
box(shell,"Front header",(0,2.21,.691),(1.5,.16,.14),"mint",.025)
box(shell,"Pedestal",(0,.32,-.32),(.46,.42,.54),"porcelain",.055)
box(shell,"Toilet bowl",(0,.54,-.25),(.58,.20,.61),"porcelain",.06)
box(shell,"Seat",(0,.653,-.25),(.47,.047,.49),"dark",.025)
box(shell,"Tank",(0,.84,-.555),(.48,.38,.23),"porcelain",.037)

door = group("Door",(0,1.15,.763),booth)
box(door,"Door leaf",(0,0,0),(1.08,2.02,.08),"mint",.028)
box(door,"Inset panel",(0,-.17,.047),(.82,1.01,.033),"teal",.014)
for x in (-.36,.36):
    box(door,"Door rib",(x,-.18,.072),(.042,.94,.025),"mint",.004)
box(door,"Handle",(.34,-.03,.081),(.088,.23,.074),"dark",.014)
box(door,"Occupied indicator",(.34,.18,.086),(.102,.071,.018),"red",.005)
box(door,"WC placard",(0,.60,.061),(.57,.31,.049),"dark",.013)
for i, letter in enumerate((("10101","10101","10101","11111","01010"),("1111","1000","1000","1000","1111"))):
    for y,row in enumerate(letter):
        for x,value in enumerate(row):
            if value=="1":
                box(door,"Sign tile",(-.225+(x+i*6)*.046,.691-y*.046,.089),(.046,.046,.012),"cream")

roof = group("Roof",(0,2.33,0),booth)
box(roof,"Ivory canopy",(0,0,0),(1.80,.22,1.64),"cream",.071)
box(roof,"Raised cap",(0,.11,-.08),(1.43,.13,1.32),"cream",.057)
for z in (-.46,0,.46):
    box(roof,"Canopy fold",(0,.18,z),(1.28,.03,.047),"gold",.006)
export(booth)

charge = group("column_charge")
column(charge,"Orange charge core",(0,.47,0),.32,.94,"orange")
for y in (.10,.83):
    column(charge,"Dark retention ring",(0,y,0),.344,.11,"dark")
column(charge,"Safety cap",(0,.96,0),.225,.12,"gold")
column(charge,"Fuse plug",(0,1.058,0),.097,.10,"dark")
column(charge,"Red armed lamp",(0,1.124,0),.064,.051,"ruby")
for i in range(8):
    angle = i*math.tau/8
    at = (.318*math.sin(angle),.47,.318*math.cos(angle))
    stripe = box(charge,"Hazard tab",at,(.135,.245,.019),"gold",.004)
    stripe.rotation_euler.z = angle
export(charge)
charge.location.x = 2.5
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/comedy_toilet.blend"),compress=True)
