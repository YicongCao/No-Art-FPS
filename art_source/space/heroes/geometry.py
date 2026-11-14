"""Z-up, +Y forward. Explicit rigid parts and pivots for Godot GLB exports."""
import bpy,math
from mathutils import Vector

def material(name,color,metal=0,rough=.5,emission=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m

def palette():
 return {'white':material('Lunar ceramic',(.47,.45,.40),.05,.5),'dark':material('Graphite frame',(.035,.048,.065),.5,.43),'orange':material('Orange armor',(.65,.13,.035),.05,.46),'metal':material('Machined alloy',(.24,.28,.31),.85,.3),'rubber':material('Grip polymer',(.012,.018,.025),0,.83),'cyan':material('Ion cyan',(.025,.6,.72),.1,.35,2),'red':material('Enemy optics',(.8,.055,.01),0,.4,2)}

def group(name,pos=(0,0,0),parent=None):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=pos;bpy.context.view_layer.update()
 if parent:attach(o,parent)
 return o

def attach(o,parent):
 bpy.context.view_layer.update();world=o.matrix_world.copy();o.parent=parent;o.matrix_world=world
 return o

def bevel(o,width):
 if width:
  bpy.context.view_layer.objects.active=o;b=o.modifiers.new('Machined edge','BEVEL');b.width=width;b.segments=2;bpy.ops.object.modifier_apply(modifier=b.name)
 return o

def box(name,p,size,mat,b=.012,parent=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);bevel(o,b)
 if parent:attach(o,parent)
 return o

def beam(name,a,b,r,mat,parent=None,vertices=16):
 a,b=Vector(a),Vector(b);v=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=v.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=v.to_track_quat('Z','Y');o.data.materials.append(mat);bevel(o,min(r*.18,.018))
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 if parent:attach(o,parent)
 return o

def panel(name,x,depth,yz,mat,parent=None):
 verts=[(x+d,y,z) for d in [-depth/2,depth/2] for y,z in yz];n=len(yz)
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.materials.append(mat);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);bevel(o,.008)
 if parent:attach(o,parent)
 return o

def batch_children(root):
 # Never cross an articulation pivot. Preserve animation/hit-test aliases.
 for parent in [root]+[o for o in root.children_recursive if o.type=='EMPTY']:
  mats={o.data.materials[0] for o in parent.children if o.type=='MESH' and len(o.data.materials)==1}
  for mat in mats:
   obs=[o for o in parent.children if o.type=='MESH' and len(o.data.materials)==1 and o.data.materials[0]==mat]
   if len(obs)<2:continue
   bpy.ops.object.select_all(action='DESELECT')
   for o in obs:o.select_set(True)
   bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=parent.name+'_'+mat.name.replace(' ','_')
