# Geometry helpers adapted from StarKnightt/counter-strike-in-browser.
# Copyright (c) 2026 StarKnightt. MIT; see LICENSE-dust2.txt.
import bpy, bmesh, math
from mathutils import Vector, Matrix
import time as _time
ALL = []
M_WALL = None
M_TRIM = None
M_STONE = None
M_WOOD = None

def assign(o, m):
    o.data.materials.clear()
    o.data.materials.append(m)
def apply_all(o):
    """Bake rotation + scale into the mesh, keep the location (data-API equivalent of transform_apply)."""
    M = o.rotation_euler.to_matrix().to_4x4() @ Matrix.Diagonal(o.scale).to_4x4()
    if M != Matrix.Identity(4):
        o.data.transform(M); o.data.update()
    o.matrix_world = Matrix.Translation(o.location)

def _new_obj(name, bm, loc, m=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); me.update()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.matrix_world = Matrix.Translation(loc)
    if m is not None: assign(o, m); ALL.append(o)
    return o

def _bm_box(sx, sy, sz, bevel=0.0, seg=1):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(sx, sy, sz), verts=bm.verts)
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges), offset=bevel, offset_type='OFFSET', segments=seg,
                        profile=0.5, affect='EDGES', clamp_overlap=True)
    return bm

def _bm_cyl(r, depth, verts, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=r, radius2=r, depth=depth,
                          matrix=Matrix.Rotation(rot[2], 4, 'Z') @ Matrix.Rotation(rot[1], 4, 'Y') @ Matrix.Rotation(rot[0], 4, 'X'))
    return bm

def add_box(name, x0, x1, y0, y1, z0, z1, m, bevel=0.0, seg=2):
    return _new_obj(name, _bm_box(abs(x1-x0), abs(y1-y0), abs(z1-z0), bevel, seg), ((x0+x1)/2, (y0+y1)/2, (z0+z1)/2), m)

def add_mesh(name, verts, faces, m):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    assign(o, m); ALL.append(o)
    return o

def add_wedge(name, x0, x1, y_lo, z_lo, y_hi, z_hi, base, m):
    """Ramp along Y: at y_lo top is z_lo, at y_hi top is z_hi. base = bottom z."""
    v = [(x0,y_lo,base),(x1,y_lo,base),(x1,y_hi,base),(x0,y_hi,base),
         (x0,y_lo,z_lo),(x1,y_lo,z_lo),(x1,y_hi,z_hi),(x0,y_hi,z_hi)]
    f = [(0,1,2,3),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    return add_mesh(name, v, f, m)

def add_cyl_axis(name, c, r, depth, m, axis='y', verts=20):
    rot = (math.pi/2, 0, 0) if axis == 'y' else ((0, math.pi/2, 0) if axis == 'x' else (0, 0, 0))
    return _new_obj(name, _bm_cyl(r, depth, verts, rot), c, m)

def cut(target, cutter):
    md = target.modifiers.new('cut', 'BOOLEAN'); md.object = cutter; md.operation = 'DIFFERENCE'; md.solver = 'EXACT'
    bpy.ops.object.select_all(action='DESELECT'); target.select_set(True); bpy.context.view_layer.objects.active = target
    _t = _time.time()
    bpy.ops.object.modifier_apply(modifier=md.name)
    if len(target.data.polygons) == 0:
        print('CUT EMPTIED TARGET:', target.name, 'cutter at', tuple(round(v, 2) for v in cutter.location))
    if cutter in ALL: ALL.remove(cutter)
    bpy.data.objects.remove(cutter, do_unlink=True)

def cutter_box(x0, x1, y0, y1, z0, z1):
    return _new_obj('cutter', _bm_box(abs(x1-x0), abs(y1-y0), abs(z1-z0)), ((x0+x1)/2, (y0+y1)/2, (z0+z1)/2))

def cutter_cyl_x(cx, cy, cz, r, length):
    return _new_obj('cutter', _bm_cyl(r, length, 8, (0, math.pi/2, 0)), (cx, cy, cz))

def _mesh_bounds(ob):
    """World-space AABB from the mesh vertices (Object.bound_box / dimensions are stale until a depsgraph update)."""
    mw = ob.matrix_world; xs, ys, zs = [], [], []
    for v in ob.data.vertices:
        p = mw @ v.co; xs.append(p.x); ys.append(p.y); zs.append(p.z)
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))

def arch_cut_y(target, x, y0, y1, w, h, z0=0.0):
    """Arched opening through a wall that runs along Y (opening axis = X)."""
    cut(target, cutter_box(x-4, x+4, y0, y1, z0-0.2, z0 + h - w/2))
    cut(target, cutter_cyl_x(x, (y0+y1)/2, z0 + h - w/2, w/2, 8))

def building(name, x0, x1, y0, y1, z0, z1, m=M_WALL, faces='', parapet=True, base=True, beams=False, base_z=None):
    """Solid building block with parapet/cornice, stone base and beam ends on the listed faces (N/S/E/W)."""
    b = add_box(name, x0, x1, y0, y1, z0, z1, m)
    if parapet:
        p = 0.2
        add_box(name+'_cap', x0-p, x1+p, y0-p, y1+p, z1-0.35, z1+0.55, m, bevel=0.04)
        add_box(name+'_capstone', x0-p-0.04, x1+p+0.04, y0-p-0.04, y1+p+0.04, z1+0.5, z1+0.62, M_TRIM, bevel=0.02)
    if isinstance(base, dict):
        # per-face stone skirt at that face's ground level (buildings spanning two floor heights)
        for f, bz in base.items():
            if f == 'N': add_box(name+'_base', x0-0.08, x1+0.08, y1-0.3, y1+0.08, bz-0.6, bz+0.9, M_STONE, bevel=0.02)
            if f == 'S': add_box(name+'_base', x0-0.08, x1+0.08, y0-0.08, y0+0.3, bz-0.6, bz+0.9, M_STONE, bevel=0.02)
            if f == 'W': add_box(name+'_base', x0-0.08, x0+0.3, y0-0.08, y1+0.08, bz-0.6, bz+0.9, M_STONE, bevel=0.02)
            if f == 'E': add_box(name+'_base', x1-0.3, x1+0.08, y0-0.08, y1+0.08, bz-0.6, bz+0.9, M_STONE, bevel=0.02)
    elif base:
        bz = base_z if base_z is not None else z0
        add_box(name+'_base', x0-0.08, x1+0.08, y0-0.08, y1+0.08, bz-0.6, bz+0.9, M_STONE, bevel=0.02)
    if beams:
        zb = z1 - 1.15
        step = 1.35
        if 'S' in faces:
            x = x0 + 0.7
            while x < x1 - 0.4:
                add_box(name+'_bm', x-0.11, x+0.11, y0-0.32, y0+0.2, zb-0.11, zb+0.11, M_WOOD, bevel=0.015); x += step
        if 'N' in faces:
            x = x0 + 0.7
            while x < x1 - 0.4:
                add_box(name+'_bm', x-0.11, x+0.11, y1-0.2, y1+0.32, zb-0.11, zb+0.11, M_WOOD, bevel=0.015); x += step
        if 'W' in faces:
            y = y0 + 0.7
            while y < y1 - 0.4:
                add_box(name+'_bm', x0-0.32, x0+0.2, y-0.11, y+0.11, zb-0.11, zb+0.11, M_WOOD, bevel=0.015); y += step
        if 'E' in faces:
            y = y0 + 0.7
            while y < y1 - 0.4:
                add_box(name+'_bm', x1-0.2, x1+0.32, y-0.11, y+0.11, zb-0.11, zb+0.11, M_WOOD, bevel=0.015); y += step
    return b
