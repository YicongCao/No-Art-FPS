"""Original coarse Dust-inspired mid, B courtyard, tunnel and village dressing.
Executed by the Blender asset builder with its existing palette and helpers.
"""
import math

def box(name, x0,x1,y0,y1,z0,z1,color):
    return g.add_box(name,x0,x1,y0,y1,z0,z1,mats[color])

def arch_x(name,x,y0,y1,z0,width,height,color='sand'):
    wall=box(name,x-.35,x+.35,y0,y1,z0,z0+height+1.2,color)
    mid=(y0+y1)/2
    g.arch_cut_y(wall,x,mid-width/2,mid+width/2,width,height,z0)
    return wall

# Mid connects the lower CT yard to B. A winding western tunnel links back to long.
# B and mid are original extensions; the source A-site proportions remain intact.
box('floor_mid',-48,-4,-38,-30,-4,-3.5,'sand')
box('floor_mid_approach',-52,-25,-30,-22,-4,-3.5,'sand')
# Partition the courtyard around the cream connector: no coincident top faces.
box('floor_b_site',-84,-52,-64,-44,-4,-3.5,'sand')
box('floor_b_site_west',-84,-68,-44,-38,-4,-3.5,'sand')
box('floor_b_to_mid',-68,-48,-44,-30,-4,-3.5,'cream')
box('floor_tunnel',-84,-76,-38,6,-4,-3.5,'sand')
g.add_wedge('tunnel_ascent',-84,-76,-22,-3.5,6,0,-4,mats['cream'])
box('floor_tunnel_long_link',-84,-66,6,14,-3.5,0,'sand')
# Open a lower arch in the former CT west boundary and a catwalk return through mid.
g.arch_cut_y(g.B_CTW,-7,-36.7,-31.3,5.4,3.5,-3.5)
g.cut(g.B_SW,g.cutter_box(-42,-34,-20.5,-10.8,-5.5,8))
for obj in list(bpy.data.objects):
    if obj.name.startswith('B_southwest_base'):g.cut(obj,g.cutter_box(-42,-34,-20.6,-10.6,-5.5,8))
    if obj.name.startswith('B_ctwest_base'):g.cut(obj,g.cutter_box(-11,-3,-36.7,-31.3,-5,1))
g.add_wedge('mid_short_ascent',-42,-34,-30,-3.5,-11,2.5,-4,mats['cream'])
box('mid_ramp_guard_w',-42.35,-42,-30,-11,-3.5,3.4,'sand')
box('mid_ramp_guard_e',-34,-33.65,-30,-11,-3.5,3.4,'sand')
# Long doors no longer define the western limit: passage winds to upper/lower tunnel.
g.cut(g.B_TW,g.cutter_box(-71,-65,7,13,-5,4.5))
for obj in list(bpy.data.objects):
    if obj.name.startswith('B_tspawn_w_base'):g.cut(obj,g.cutter_box(-71,-65,7,13,-5,4.5))
box('mid_wall_n',-52,-10,-30,-29.6,-3.5,1,'sand')
# Remove ramp overlap from mid boundary.
g.cut(g.ALL[-1],g.cutter_box(-42.5,-33.5,-31,-29,-4,4))
box('mid_wall_s',-48,-10,-38.5,-38,-3.5,1.5,'cream')
mid_gate=arch_x('mid_double_doors',-49,-38,-30,-3.5,4.4,3.2)
# Angled door leaves leave a readable central gap.
box('mid_door_left',-48.65,-46.8,-37,-36.7,-3.5,-.6,'timber')
box('mid_door_right',-50.9,-49.35,-31.35,-31.05,-3.5,-.6,'timber')
for y in [-36.8,-31.2]:
    for z in [-3,-1.7,-.8]:box('mid_door_strap',-50.9 if y>-34 else -48.6,-49.4 if y>-34 else -46.9,y-.07,y+.07,z,z+.12,'ink')
# B has courtyard crates, raised rear platform, tunnel mouth and a window landmark.
box('b_wall_n',-84,-52,-64.6,-64,-3.5,3,'cream')
box('b_wall_e',-52,-51.4,-64,-44,-3.5,3,'sand')
box('b_wall_w',-84.6,-84,-64,-38,-3.5,3,'cream')
box('b_wall_tunnel_divider',-76,-75.4,-38,-23,-3.5,3,'sand')
box('tunnel_wall_w',-84.6,-84,-38,6,-3.5,5,'sand')
box('tunnel_wall_e',-76,-75.4,-23,6,-3.5,5,'cream')
for y in [-35,-26,-17,-8,1]:
    # Polygonal arch ribs and broad roof segments make an actual covered passage.
    arch_x('tunnel_rib',-80,y-2.7,y+2.7,-3.5 if y<-22 else (-3.5+(y+22)*3.5/28),4.5,3.1)
# Ribs must cross the tunnel (along y), rather than run parallel and block it.
for obj in list(bpy.data.objects):
    if obj.name.startswith('tunnel_rib'):
        center=obj.location.copy()
        obj.rotation_euler.z=math.pi/2
        g.apply_all(obj)
# Fixed roofs sit safely above player height even on the ascending segment.
for y in [-32,-23,-14,-5]:box('tunnel_roof',-84,-76,y-4.6,y+4.6,4.5,4.8,'sand')
box('b_platform',-83,-76,-63,-55,-3.5,-2.6,'cream')
g.add_wedge('b_platform_ramp',-79,-76,-52,-3.5,-55,-2.6,-4,mats['cream'])
# Distinctive B back-wall window opening (visual; no jump required for routes).
window=box('b_window_wall',-68,-67.5,-64,-53,-3.5,2.5,'sand')
g.cut(window,g.cutter_box(-69,-66,-60,-56,-1.5,.6))
box('b_window_sill',-68.3,-67.1,-60.1,-55.9,-1.7,-1.5,'cream')
# Tower skyline uses low-sided cylinders and faceted dome sections.
def tower(name,x,y,base,color):
    g.add_cyl_axis(name+'_tower',(x,y,base+3),2.2,6,mats[color],axis='z',verts=8)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=2.3,location=(x,y,base+6))
    o=bpy.context.object;o.name=name+'_dome';o.scale.z=.8;g.apply_all(o);g.assign(o,mats['cream']);g.ALL.append(o)
    g.add_cyl_axis(name+'_spire',(x,y,base+8.5),.08,1.7,mats['timber'],axis='z',verts=6)
for name,x,y,z,c in [('b',-82,-62,-3.5,'sand'),('mid',-20,-39,-3.5,'green'),('a',18,14,0,'sand')]:tower(name,x,y,z,c)
# Raised ground foundation and perimeter walls keep every exposed edge bounded.
box('SafetyFoundation',-90,29,-70,26,-5,-4,'sand')
for name,vals in [('WestBoundary',(-89,-88,-69,25,-4,7)),('EastBoundary',(27,28,-69,25,-4,9)),('NorthBoundary',(-89,28,24,25,-4,8)),('SouthBoundary',(-89,28,-69,-68,-4,6))]:box(name,*vals,'sand')
# Original village dressing kept as separate, low-detail pieces.
def crate(name,x,y,z,size=1.6):
    box(name,x-size/2,x+size/2,y-size/2,y+size/2,z,z+size,'yellow')
    for h in [.12,size-.12]:box(name+'_strap',x-size/2-.025,x+size/2+.025,y-size/2-.03,y+size/2+.03,z+h,z+h+.12,'cream')
for i,p in enumerate([(-79,-59,-2.6),(-79,-59,-1),(-72,-48,-3.5),(-61,-59,-3.5),(-61,-59,-1.9),(-56,-42,-3.5),(-24,-34,-3.5),(-15,-32,-3.5),(-81,-18,-3),(-58,12,0),(2,8,0),(8,7,0)]):crate('cargo_'+str(i),*p)
# Blue shutters and stone trim repeat across façades, without surface noise.
for x in [-62,-51,-42,-30,-15,-3,8]:
    for level in [3.1,5.3]:box('facade_shutter',x-.6,x+.6,13.8,14.02,level,level+1.15,'blue')
    box('facade_sill',x-.72,x+.72,13.7,14.12,3.0,3.12,'cream')
for y in [-58,-51,-42,-35]:box('b_green_shutter',-84.02,-83.8,y-.6,y+.6,-.6,.7,'green')
# Flat awnings, sturdy visible supports, clay pots and market cargo.
for i,(x,y,z,c) in enumerate([(-34,13.5,0,'green'),(-61,-63.5,-3.5,'red'),(-12,-38,-3.5,'purple')]):
    box('market_awning_'+str(i),x-3,x+3,y-2,y+.2,z+3,z+3.18,c)
    for dx in [-2.7,2.7]:box('awning_post',x+dx-.05,x+dx+.05,y-1.8,y-1.7,z,z+3.1,'timber')
    box('market_table',x-1.5,x+1.5,y-1.4,y-.5,z+.8,z+.95,'timber')
    for dx in [-1.3,1.3]:box('table_leg',x+dx-.06,x+dx+.06,y-1.2,y-.65,z,z+.8,'timber')
    for dx in [-1,0,1]:
        g.add_cyl_axis('clay_pot',(x+dx,y-1,z+1.18),.22,.45,mats['red'],axis='z',verts=8)
# Original cacti replace every tropical silhouette. Beds sit against boundaries.
def cactus(name,x,y,z,height=3.4,paddle=False):
    box(name+'_bed',x-1.05,x+1.05,y-.75,y+.75,z,z+.2,'cream')
    box(name+'_soil',x-.96,x+.96,y-.66,y+.66,z+.2,z+.24,'sand')
    base=z+.24
    if paddle:
        for i,(dx,dz,scale) in enumerate([(0,.55,.65),(-.45,1.2,.45),(.48,1.4,.5),(0,1.85,.4)]):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x+dx,y,base+dz))
            obj=bpy.context.object;obj.name=name+'_pad_'+str(i)
            obj.scale=(scale,.2,scale*1.25);g.apply_all(obj);g.assign(obj,mats['green']);g.ALL.append(obj)
    else:
        g.add_cyl_axis(name+'_trunk',(x,y,base+height*.5),.26,height,mats['green'],axis='z',verts=7)
        for i,(side,h) in enumerate([(-1,height*.4),(1,height*.62)]):
            g.add_cyl_axis(name+'_arm_'+str(i),(x+side*.45,y,base+h),.20,.9,mats['green'],axis='x',verts=7)
            g.add_cyl_axis(name+'_upright_'+str(i),(x+side*.9,y,base+h+.45),.20,.95,mats['green'],axis='z',verts=7)
        # Short sparse ribs are geometry, no high-frequency spine texture.
        for dx in [-.11,.11]:box(name+'_rib',x+dx-.018,x+dx+.018,y-.26,y-.245,base+.15,base+height-.15,'yellow')
    g.add_cyl_axis(name+'_pot',(x+.65,y+.28,base+.3),.2,.6,mats['red'],axis='z',verts=7)
for i,(x,y,z,paddle) in enumerate([(-85,9,0,False),(-72,-62,-3.5,True),(-12,-33,-3.5,False),(13,12,0,True),(-63,20,0,True),(-53.5,-61,-3.5,False)]):
    cactus('cactus_'+str(i),x,y,z,3.1 if i%2==0 else 3.7,paddle)
# Faceted cream cloud models are instanced by Godot outside navigation geometry.
# Match the concept's broad teal-and-cream canopy without changing its footprint.
for i,(x,y,z) in enumerate([(-34,13.5,0),(-61,-63.5,-3.5),(-12,-38,-3.5)]):
    for stripe in range(6):
        box('canopy_stripe_'+str(i)+'_'+str(stripe),x-3+stripe,x-2+stripe,y-2,y+.2,z+3.19,z+3.22,'cream' if stripe%2==0 else 'green')
