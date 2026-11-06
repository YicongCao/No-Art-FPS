"""blender --background --python tools/build_dust_flavor_assets.py
Localizes the audited MIT A-site geometry without external textures or scenery.
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/vendor'))
import dust_geometry as g
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
colors={'sand':'d5b471','cream':'e5e0d2','timber':'a97c4b','ink':'243440','green':'4d7d70','blue':'304f9d','red':'b65745','purple':'754c87','yellow':'e9ba50'}
mats={}
for name,code in colors.items():
    def linear(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
    rgba=tuple(linear(int(code[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m=bpy.data.materials.new(name);m.diffuse_color=rgba;m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=rgba;b.inputs['Roughness'].default_value=.9
    mats[name]=m
# All upstream texture dependencies become named palette slots.
for name,color in {'M_WALL':'cream','M_WALL2':'sand','M_STONE':'sand','M_TRIM':'cream','M_WOOD':'timber','M_GROUND':'sand','M_GROUND2':'sand','M_ROAD':'sand','M_COBBLE':'cream','M_PAVE':'cream','M_DOOR':'blue','M_PLANK':'timber'}.items():
    setattr(g,name,mats[color])
# Rebind the sole default material after assigning the local palette.
g.building.__defaults__=(g.M_WALL,'',True,True,False,None)
exec(compile((ROOT/'tools/vendor/dust_layout.py').read_text(),'dust_layout.py','exec'),g.__dict__)
g.add_wedge('mission_west_ramp',-55,-50,-6,2.5,6,0,-3,g.M_PAVE)
g.add_box('mission_short_link',-55,-46,-11,-6,-3,2.5,g.M_COBBLE)
g.add_box('west_guardrail',-55.3,-55,-11,6,2.5,3.5,g.M_WOOD)
g.add_box('pit_slope_rail_e',-14.1,-13.9,2,6,-3.5,1.0,mats['cream'])
g.add_box('pit_slope_rail_w',-22.2,-22,2,6,-3.5,1.0,mats['cream'])
# Original low-poly mission props, separate and movable in Godot.
for name,x,y,z,s in [('site_crate',0,4,0,1.6),('site_crate_high',0,4,1.6,1.6),('site_cover',8,-5,0,1.3),('short_cover',-29,-8,2.5,1.2),('court_cover',2,-34,-3.5,1.5),('long_crate',-39,12,0,1.3)]:
    g.add_box(name,x-s/2,x+s/2,y-s/2,y+s/2,z,z+s,mats['timber'])
    for h in [.12,s-.12]:g.add_box(name+'_strap',x-s/2-.02,x+s/2+.02,y-s/2-.025,y+s/2+.025,z+h-.05,z+h+.05,mats['cream'])
for x,y,z in [(-23,13,0),(8,-38,-3.5),(-35,-10,2.5)]:
    g.add_cyl_axis('pot',(x,y,z+.45),.34,.9,mats['red'],axis='z',verts=8)
# Facade colour bands and restrained shutters.
g.add_box('site_teal_band',15.85,16,-12,14,.8,1.6,mats['green'])
g.add_box('short_purple_band',-46,-14,-6.05,-5.9,3.3,3.8,mats['purple'])
for x in [-43,-28,-5,8]:g.add_box('shutter',x-.55,x+.55,13.9,14.05,2.8,4,mats['blue'])
# Coarse car silhouette, no chrome, rust decals or fine bolts.
g.add_box('car_body',-20,-16,10.7,12.4,.35,1.1,mats['blue'])
g.add_box('car_cab',-18.8,-17,10.8,12.3,1.1,1.8,mats['cream'])
for x in [-19.3,-16.8]:
    for y in [10.65,12.45]:g.add_cyl_axis('wheel',(x,y,.45),.4,.18,mats['ink'],axis='y',verts=8)
# A small bomb model in its own GLB, with original geometry.
architecture=[o for o in bpy.data.objects if o.type=='MESH']
for o in architecture:
    o['solid']=not any(k in o.name for k in ['strap','band','shutter','pot','capstone'])
    o['region']='short' if o.location.x<-14 and o.location.y<0 else ('court' if o.location.y<-12 else 'site')
OUT=ROOT/'assets/models/dust_flavor';OUT.mkdir(exist_ok=True)
def export(objects,path):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),use_selection=True,export_format='GLB',export_extras=True,export_yup=True)
export(architecture,OUT/'architecture.glb')
first=set(bpy.data.objects)
g.add_box('c4_case',-.18,.18,-.08,.08,0,.25,mats['ink'])
for x in [-.11,0,.11]:g.add_box('c4_charge',x-.045,x+.045,-.10,-.08,.02,.23,mats['timber'])
g.add_box('c4_display',-.10,.10,-.105,-.09,.14,.22,mats['green'])
export([o for o in bpy.data.objects if o not in first],OUT/'c4.glb')
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene['source']='StarKnightt A-site geometry, commit 190a277; MIT. Local palette, west bypass and original coarse props.'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/dust_flavor.blend'))
triangles=0
for o in architecture:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
(ROOT/'artifacts/local/dust-localization.json').write_text(json.dumps({'meshes':len(architecture),'triangles':triangles,'images':len(bpy.data.images),'coordinates':'Blender X/Y/Z -> Godot X/Z/-Y'},indent=2))
print('DUST_LOCALIZED',len(architecture),triangles,'triangles; original scene grouping preserved')
