"""Blender source for 27 small breakable prop families; metres, Z-up, +Y front."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models/interactive_props'
SRC=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True)
COLORS={'wood':'B87952','edge':'F1D29A','red':'E86759','gold':'F3C95E','blue':'58A9DD','teal':'3C9390','purple':'9B75C0','dark':'283E52','white':'F2EACF','green':'73AE69','leaf':'3C7855','glass':'AFE3EA','terra':'CA7758','soil':'685044','silver':'A7BBCB','pink':'ED87B3'}
paints={}
for key,c in COLORS.items():
 m=bpy.data.materials.new(key);m.diffuse_color=tuple((v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4) for v in [int(c[i:i+2],16)/255 for i in (0,2,4)])+(1,);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=m.diffuse_color;p.inputs['Roughness'].default_value=.68;paints[key]=m
# Every named part is joined into one vertex-coloured surface for economical draws.
common=bpy.data.materials.new('PropPaint');common.use_nodes=True
v=common.node_tree.nodes.new('ShaderNodeVertexColor');v.layer_name='Color';common.node_tree.links.new(v.outputs['Color'],common.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);common.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.72
parts={};active='Base'
def tag(obj,color):
 obj.data.materials.append(paints[color]);parts.setdefault(active,[]).append(obj);return obj
def box(at,size,c,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at,rotation=rot);o=tag(bpy.context.object,c);o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);mod=o.modifiers.new('Soft edges','BEVEL');mod.width=.012;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name);return o
def cyl(at,r,h,c,top=None):
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r,radius2=r if top is None else top,depth=h,location=at);return tag(bpy.context.object,c)
def ball(at,size,c):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=at);o=tag(bpy.context.object,c);o.scale=size;return o
def rod(a,b,r,c):
 mid=(Vector(a)+Vector(b))*.5;o=cyl(mid,r,(Vector(b)-Vector(a)).length,c);o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o
def table(w=1.25,d=.6,h=.82,c='wood'):
 box((0,0,h),(w,d,.08),c)
 for x in [-w*.4,w*.4]:
  for y in [-d*.36,d*.36]:box((x,y,h*.5),(.065,.065,h),c)
def part(i):
 global active;active='Target%d'%i
def base():
 global active;active='Base'
def jar(x=0,y=0,z=0,c='terra',scale=1):
 cyl((x,y,z+.16*scale),.18*scale,.28*scale,c,top=.25*scale);cyl((x,y,z+.38*scale),.25*scale,.2*scale,c,top=.13*scale);cyl((x,y,z+.50*scale),.14*scale,.05*scale,'edge');cyl((x,y,z+.528*scale),.09*scale,.006,'dark')
def remnant(i,at=(0,0,.04),c='terra'):
 global active;active='Remnant%d'%i;cyl(at,.17,.07,c);base()
def crate(z=.25):
 for y in [-.26,.26]:
  for zz in [z-.12,z+.12]:box((0,y,zz),(1,.055,.16),'wood')
 for x in [-.48,.48]:box((x,0,z),(.055,.52,.43),'wood')
 box((0,0,z-.2),(.95,.5,.05),'wood')
def leaf(x,y,z):
 ball((x,y,z),(.10,.045,.19),'leaf')
def paper(x,y,z,c='white'):box((x,y,z),(.32,.24,.035),c)
def model(kind):
 base()
 if kind in ['pots','fruit','slats']:
  if kind=='pots':
   for i,x in enumerate([-.4,0,.4]):part(i);jar(x,0,0,['terra','teal','blue'][i]);remnant(i,(x,0,.04))
  elif kind=='fruit':
   crate()
   for i,x in enumerate([-.29,0,.29]):
    part(i)
    for y in [-.12,.12]:ball((x,y,.55),(.13,.13,.13),'gold' if i%2 else 'red')
  else:
   box((0,0,.07),(1.5,.14,.14),'wood')
   for i,x in enumerate([-.58,-.29,0,.29,.58]):part(i);box((x,0,.73),(.22,.09,1.25),'teal');box((x,-.055,.9),(.19,.035,.05),'edge')
 elif kind=='balloons':
  box((0,0,.07),(1.4,.45,.14),'purple')
  for i,x in enumerate([-.48,0,.48]):
   base();rod((x,0,.12),(x,0,1.35+(.2 if i==1 else 0)),.012,'white');part(i);ball((x,0,1.6+(.2 if i==1 else 0)),(.23,.20,.30),['red','gold','blue'][i]);cyl((x,0,1.3+(.2 if i==1 else 0)),.045,.09,'white',top=0)
 elif kind=='cans':
  table()
  for i,(x,z) in enumerate([(-.25,1),(0,1),(.25,1),(-.12,1.29),(.12,1.29),(0,1.58)]):part(i);cyl((x,0,z),.115,.27,['red','white','teal'][i%3]);cyl((x,0,z+.14),.115,.025,'silver')
 elif kind=='popcorn':
  box((0,0,.50),(.75,.48,1),'red');box((0,0,1.65),(.83,.56,.12),'gold')
  for x in [-.35,.35]:box((x,0,1.3),(.045,.46,.7),'red')
  part(0);box((0,-.23,1.29),(.65,.025,.58),'glass');remnant(0,(0,0,1.01),'white')
  for i,x in enumerate([-.2,0,.2]):part(i+1);cyl((x,0,1.15),.09,.23,'white',top=.13);ball((x,0,1.3),(.15,.14,.06),'gold')
 elif kind=='vests':
  box((0,.19,.62),(1.15,.12,1.2),'teal');box((0,0,.12),(1.15,.5,.24),'white')
  part(0);box((0,-.24,.75),(1,.035,.93),'glass');remnant(0,(0,0,.25),'white')
  for i,x in enumerate([-.32,.32]):part(i+1);box((x,0,.7),(.27,.19,.73),'gold');box((x,-.11,.77),(.29,.025,.06),'white')
 elif kind=='chairs':
  for i,x in enumerate([-.32,.32]):
   part(i)
   for xx in [-.19,.19]:
    for y in [-.19,.19]:box((x+xx,y,.24),(.045,.045,.48),'white')
   box((x,0,.49),(.48,.48,.07),'teal');box((x,.21,.80),(.48,.07,.58),'teal');remnant(i,(x,0,.04),'white')
 elif kind=='bottles':
  crate(.22)
  for i,x in enumerate([-.30,0,.30]):
   part(i);cyl((x,0,.63),.10,.46,'green');cyl((x,0,.91),.04,.13,'green');box((x,-.10,.62),(.14,.015,.18),'white')
 elif kind=='foam':
  box((0,0,.09),(1.4,.65,.18),'wood')
  for i,(x,z) in enumerate([(-.32,.38),(.32,.38),(-.32,.9),(.32,.9),(0,1.42)]):part(i);box((x,0,z),(.60,.42,.49),'white');remnant(i,(x,0,.14),'gold')
 elif kind=='clapper':
  table()
  part(0);box((-.25,0,1.15),(.55,.07,.53),'dark')
  for x in [-.43,-.25,-.07]:box((x,-.05,1.36),(.12,.025,.1),'white',rot=(0,.3,0))
  for j in range(3):box((-.25,-.045,1.1-j*.09),(.4,.012,.015),'white')
  for i,x in enumerate([.21,.43]):part(i+1);cyl((x,0,1.02),.075,.3,'pink');cyl((x,0,1.22),.033,.12,'silver')
 elif kind=='paper_roll':
  for x in [-.52,.52]:rod((x,0,0),(x,0,1.95),.035,'silver')
  box((0,0,.04),(1.3,.5,.08),'dark');rod((-.6,0,1.9),(.6,0,1.9),.04,'silver')
  for i,x in enumerate([-.33,0,.33]):part(i);box((x,0,1.12),(.32,.025,1.5),'blue');box((x,-.02,.41),(.32,.06,.08),'white')
 elif kind=='screens':
  table(1.4,.65)
  cyl((0,0,.91),.14,.08,'dark');box((0,.05,1.08),(.06,.06,.3),'silver')
  part(0);box((0,0,1.36),(.82,.09,.50),'dark');box((0,-.05,1.36),(.74,.015,.41),'blue')
  for x in [-.23,0,.23]:box((x,-.062,1.35),(.14,.006,.02),'white')
  part(1);box((0,-.20,.91),(.61,.20,.045),'dark')
  for x in [-.22,-.11,0,.11,.22]:box((x,-.20,.94),(.07,.12,.02),'white')
 elif kind=='figures':
  table()
  for i,x in enumerate([-.33,.33]):
   part(i);cyl((x,0,.9),.17,.05,'gold');box((x,0,1.14),(.24,.16,.30),'teal' if i==0 else 'purple');ball((x,0,1.42),(.15,.14,.15),'white');box((x,-.13,1.43),(.21,.04,.07),'dark');rod((x-.12,0,1.19),(x-.24,-.02,1.04),.055,'gold');rod((x+.12,0,1.19),(x+.24,-.02,1.04),.055,'gold')
 elif kind=='takeout':
  table()
  for i,x in enumerate([-.35,0,.35]):
   part(i)
   if i==0:box((x,0,.97),(.27,.3,.21),'white');box((x,0,1.09),(.3,.32,.03),'red')
   elif i==1:cyl((x,0,1.04),.11,.3,'white',top=.14);cyl((x,0,1.20),.15,.025,'dark')
   else:
    for z in [.90,.94,.98]:paper(x,0,z)
 elif kind=='target':
  rod((0,0,.1),(0,0,1.3),.06,'wood');box((0,0,.07),(.85,.45,.14),'wood')
  part(0);o=cyl((0,0,1.46),.40,.10,'purple');o.rotation_euler.x=math.pi/2
  for radius,c,y in [(.30,'gold',-.06),(.17,'teal',-.075)]:o=cyl((0,y,1.46),radius,.02,c);o.rotation_euler.x=math.pi/2
 elif kind=='brooms':
  box((0,0,.25),(1.2,.5,.5),'wood');box((0,-.26,.25),(1,.025,.09),'gold')
  for i,x in enumerate([-.36,0,.36]):part(i);rod((x,0,.4),(x+.12,0,1.7),.025,'wood');cyl((x,0,.57),.12,.4,'edge',top=.025);box((x,-.04,.74),(.09,.08,.05),'gold')
 elif kind=='armor':
  cyl((0,0,.07),.34,.14,'wood');rod((0,0,.1),(0,0,1.6),.04,'wood')
  part(0);ball((0,0,1.12),(.30,.20,.36),'silver');box((0,-.19,1.18),(.18,.05,.23),'gold')
  part(1);ball((0,0,1.66),(.22,.20,.25),'silver');box((0,-.20,1.66),(.3,.05,.07),'dark')
  part(2);ball((.4,0,1.05),(.23,.08,.33),'teal');box((.4,-.08,1.05),(.04,.025,.42),'gold')
 elif kind=='icicles':
  for x in [-.55,.55]:rod((x,0,.05),(x,0,1.8),.035,'silver')
  box((0,0,1.8),(1.25,.2,.12),'blue')
  for i,x in enumerate([-.4,-.13,.13,.4]):part(i);cyl((x,0,1.42),.015,.68 if i%2 else .95,'glass',top=.12)
 elif kind=='frost':
  box((0,0,.17),(1.15,.6,.34),'blue')
  for i,x in enumerate([-.33,0,.33]):
   base();box((x,0,.55),(.22,.30,.39),'gold');part(i);box((x,-.19,.64),(.28,.1,.45),'glass');remnant(i,(x,0,.38),'white')
 elif kind=='snowman':
  part(0);ball((0,0,.38),(.43,.39,.39),'white');remnant(0)
  part(1);ball((0,0,.93),(.33,.31,.33),'white');box((0,-.30,1.03),(.57,.08,.13),'red')
  part(2);ball((0,0,1.4),(.24,.23,.24),'white');cyl((0,0,1.64),.29,.045,'dark');cyl((0,0,1.76),.18,.23,'dark')
  for x in [-.08,.08]:ball((x,-.21,1.46),(.025,.025,.025),'dark')
 elif kind=='seedlings':
  table()
  for i,x in enumerate([-.38,0,.38]):part(i);jar(x,0,.88,scale=.60);leaf(x,0,1.28);leaf(x+.08,0,1.4);remnant(i,(x,0,.91))
 elif kind=='nozzles':
  box((0,0,.06),(1.2,.4,.12),'teal');rod((-.5,0,.1),(-.5,0,1.2),.06,'teal');rod((-.5,0,1.2),(.5,0,1.2),.06,'teal')
  for i,x in enumerate([-.3,0,.3]):part(i);cyl((x,0,1.28),.09,.13,'gold');cyl((x,0,1.36),.12,.04,'silver')
 elif kind=='soilbags':
  box((0,0,.04),(1.15,.6,.08),'wood')
  for i,x in enumerate([-.34,0,.34]):part(i);ball((x,0,.38),(.17,.24,.36),'edge');box((x,-.23,.40),(.23,.025,.25),'green');box((x,0,.72),(.25,.06,.04),'wood');remnant(i,(x,0,.1),'soil')
 elif kind=='vending':
  box((0,0,.07),(1,.6,.14),'red');box((0,.26,.88),(1,.08,1.6),'red')
  for x in [-.46,.46]:box((x,0,.88),(.08,.6,1.6),'red')
  box((0,0,1.69),(1,.6,.08),'white')
  part(0);box((0,-.31,1.05),(.80,.025,1.1),'glass');remnant(0,(0,0,.23),'silver')
  for i,z in enumerate([.62,.99,1.36]):
   part(i+1)
   for x in [-.26,0,.26]:cyl((x,0,z),.08,.25,['gold','teal','blue'][i])
 elif kind=='newspapers':
  for x in [-.45,.45]:rod((x,0,.05),(x,0,1.45),.035,'silver')
  box((0,0,.06),(1.05,.48,.12),'dark')
  for i,z in enumerate([.50,.90,1.3]):
   base();box((0,0,z-.12),(.90,.25,.035),'silver');part(i);box((0,0,z),(.8,.06,.25),'white');box((-.2,-.04,z+.05),(.28,.02,.06),'red');box((.2,-.04,z),(.23,.02,.12),'dark')
 elif kind=='umbrellas':
  box((0,0,.22),(.85,.5,.44),'teal')
  for i,x in enumerate([-.27,0,.27]):part(i);rod((x,0,.25),(x,0,1.2),.018,'silver');cyl((x,0,.91),.09,.57,['blue','purple','white'][i],top=.015);box((x,0,1.25),(.11,.04,.05),'dark')
 else:raise ValueError(kind)

def finish(kind):
 global parts,active
 for name,objects in parts.items():
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:
   o.select_set(True);bpy.context.view_layer.objects.active=o
   if o.type=='MESH':
    attr=o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    c=o.data.materials[0].diffuse_color
    for v in attr.data:v.color=c
    o.data.materials.clear();o.data.materials.append(common)
  bpy.context.view_layer.objects.active=objects[0]
  if len(objects)>1:bpy.ops.object.join()
  o=bpy.context.object;o.name=name
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(kind+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',export_yup=True,export_apply=True,export_materials='EXPORT')
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
 parts={};active='Base'

KINDS=['pots','fruit','slats','balloons','cans','popcorn','vests','chairs','bottles','foam','clapper','paper_roll','screens','figures','takeout','target','brooms','armor','icicles','frost','snowman','seedlings','nozzles','soilbags','vending','newspapers','umbrellas']
for kind in KINDS:model(kind);finish(kind)
print('INTERACTIVE_MODELS',len(KINDS))
