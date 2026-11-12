"""Shared painted-toy architectural primitives and selective bevel exporter for map builders.

All geometric helpers operate in Godot coordinates (Y up, forward -Z) and pass
`(label, vertices, faces, color)` to the caller's mesh emitter so each map builder
keeps its existing collection and collider pipeline intact.
"""
import math
import bpy
import bmesh
from mathutils import Vector

BEVEL_ANGLE = math.radians(52.0)


def _rot_pt(center, u, v, w, cos_a, sin_a):
    return (
        center[0] + u * cos_a + w * sin_a,
        center[1] + v,
        center[2] - u * sin_a + w * cos_a,
    )


def tapered_box(emit, label, center, size, color, angle=0.0, taper=(0.06, 0.06)):
    """8-vertex box whose top face narrows by `taper`=(tx, tz) for a sturdy toy silhouette."""
    w, h, d = size
    tx, tz = taper if isinstance(taper, tuple) else (taper, taper)
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    pts = []
    for sy, sx_scale, sz_scale in ((-0.5, 1.0, 1.0), (0.5, 1.0 - tx, 1.0 - tz)):
        for sx, sz in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
            pts.append(_rot_pt(center, sx * w * sx_scale, sy * h, sz * d * sz_scale, cos_a, sin_a))
    faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    emit(label, pts, faces, color)


def stepped_plinth(emit, label, center, width, height, depth, color, angle=0.0, flare=0.045):
    """Grounding baseboard/footing that flares slightly toward the floor."""
    w_bot, d_bot = width + flare * 2.0, depth + flare * 2.0
    tx = min(0.28, (flare * 2.0) / max(w_bot, 0.05))
    tz = min(0.28, (flare * 2.0) / max(d_bot, 0.05))
    tapered_box(emit, label, center, (w_bot, height, d_bot), color, angle=angle, taper=(tx, tz))


def segmented_coping(emit, label, center, width, height, depth, color, angle=0.0,
                     seg_len=1.75, gap=0.028, taper=0.05):
    """Splits a monolithic wall cap into bevel-ready molded coping stones along its longer axis."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    along_x = width >= depth
    span = width if along_x else depth
    count = max(1, round(span / seg_len))
    if count == 1 or span < 1.1:
        tapered_box(emit, label, center, (width, height, depth), color, angle=angle, taper=(taper, taper))
        return
    step = span / count
    piece_span = max(0.18, step - gap)
    for i in range(count):
        offset = -span * 0.5 + (i + 0.5) * step
        u, w = (offset, 0.0) if along_x else (0.0, offset)
        sub_center = _rot_pt(center, u, 0.0, w, cos_a, sin_a)
        sub_size = (piece_span, height, depth) if along_x else (width, height, piece_span)
        tapered_box(emit, label, sub_center, sub_size, color, angle=angle, taper=(taper, taper))


def recessed_window(emit, center, width, height, angle, frame_color, sill_color,
                    back_color, shutter_color=None, louver_color=None, depth=0.15):
    """Three-level toy window: projecting molded casing, recessed dark pocket, corbelled sill.
    Offsets stay >= 0 along local +w so surface-mounted calls never z-fight with the host wall."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def at(u, v, w):
        return _rot_pt(center, u, v, w, cos_a, sin_a)

    # 1. Shadow back plate sits cleanly in front of host wall while recessed behind outer casing
    tapered_box(emit, "Window shadow pocket", at(0.0, 0.0, 0.022),
                (width - 0.08, height - 0.08, 0.032), back_color, angle=angle, taper=(0.0, 0.0))
    # 2. Projecting surrounding molded frame jambs and lintel head (15 cm deep reveal)
    jamb_w = 0.115
    for side in (-1.0, 1.0):
        tapered_box(emit, "Window molded jamb", at(side * (width * 0.5 + jamb_w * 0.36), 0.0, depth * 0.5),
                    (jamb_w, height + 0.08, depth), frame_color, angle=angle, taper=(0.04, 0.04))
    tapered_box(emit, "Window molded head", at(0.0, height * 0.5 + 0.075, depth * 0.56),
                (width + jamb_w * 2.2, 0.15, depth + 0.04), sill_color, angle=angle, taper=(0.04, 0.06))
    # 3. Chunky overhanging bottom sill + pair of corbel brackets
    sill_y = -height * 0.5 - 0.075
    tapered_box(emit, "Window chunky sill", at(0.0, sill_y, depth * 0.68),
                (width + jamb_w * 2.5, 0.15, depth + 0.09), sill_color, angle=angle, taper=(0.02, 0.04))
    for side in (-1.0, 1.0):
        tapered_box(emit, "Window sill corbel", at(side * width * 0.34, sill_y - 0.11, depth * 0.52),
                    (0.13, 0.13, depth + 0.02), sill_color, angle=angle, taper=(-0.12, -0.18))
    # 4. Optional chunky slatted shutters set inside the frame reveal
    if shutter_color:
        leaf_w = (width - 0.10) * 0.5
        for side in (-1.0, 1.0):
            u = side * (leaf_w * 0.5 + 0.014)
            tapered_box(emit, "Shutter leaf", at(u, 0.0, 0.058),
                        (leaf_w, height - 0.09, 0.052), shutter_color, angle=angle, taper=(0.02, 0.02))
            if louver_color:
                for row in (-1, 0, 1):
                    tapered_box(emit, "Shutter louver", at(u, row * height * 0.24, 0.094),
                                (leaf_w - 0.08, 0.088, 0.042), louver_color, angle=angle, taper=(0.05, 0.12))


def cambered_canopy(emit, origin, width, depth, drop, angle, stripe_a, stripe_b, wood_color, post_h=2.06):
    """Three-segment curved striped awning with thick scalloped valance and diagonal knee braces."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def pt(u, v, w):
        return _rot_pt(origin, u, v, w, cos_a, sin_a)

    # Curved profile along w in 3 segments so the awning reads as a thick molded shell, not a flat card
    curve = [(0.0, 0.0), (0.36, -drop * 0.24), (0.72, -drop * 0.58), (1.0, -drop)]
    thick = 0.085
    stripes = 7
    for i in range(stripes):
        u0 = -width * 0.5 + width * i / stripes
        u1 = -width * 0.5 + width * (i + 1) / stripes
        tone = stripe_a if i % 2 == 0 else stripe_b
        for seg in range(len(curve) - 1):
            t0, y0 = curve[seg]
            t1, y1 = curve[seg + 1]
            w0, w1 = depth * t0, depth * t1
            top_quad = [pt(u0, y0, w0), pt(u1, y0, w0), pt(u1, y1, w1), pt(u0, y1, w1)]
            bot_quad = [pt(u0, y0 - thick, w0), pt(u1, y0 - thick, w0),
                        pt(u1, y1 - thick, w1), pt(u0, y1 - thick, w1)]
            faces = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
            emit("Canopy curved rib", top_quad + bot_quad, faces, tone)
        # Chunky front valance tab with slight gap between tabs
        um = (u0 + u1) * 0.5
        tab_w = (u1 - u0) - 0.016
        tapered_box(emit, "Canopy valance", pt(um, -drop - 0.14, depth - 0.03),
                    (tab_w, 0.24, 0.078), tone, angle=angle, taper=(-0.06, 0.06))

    # Wall ledger beam + front crossbeam + sturdy posts + diagonal knee braces
    tapered_box(emit, "Canopy wall ledger", pt(0.0, -0.06, 0.05),
                (width + 0.10, 0.12, 0.11), wood_color, angle=angle, taper=(0.02, 0.02))
    tapered_box(emit, "Canopy front rail", pt(0.0, -drop - 0.07, depth - 0.12),
                (width - 0.08, 0.11, 0.11), wood_color, angle=angle, taper=(0.02, 0.02))
    for side in (-1.0, 1.0):
        pu = side * (width * 0.5 - 0.16)
        pw = depth - 0.12
        tapered_box(emit, "Canopy post", pt(pu, -post_h * 0.5 - drop * 0.85, pw),
                    (0.145, post_h, 0.145), wood_color, angle=angle, taper=(0.12, 0.12))
        stepped_plinth(emit, "Canopy post foot", pt(pu, -post_h - drop * 0.85 + 0.07, pw),
                       0.19, 0.14, 0.19, stripe_b, angle=angle, flare=0.025)
        # Diagonal knee brace from wall/rear toward front rail
        b0 = Vector(pt(pu, -drop - 0.52, pw))
        b1 = Vector(pt(pu, -0.14, max(0.10, pw - 0.58)))
        _strut(emit, "Canopy knee brace", b0, b1, 0.095, wood_color)


def _strut(emit, label, start, end, thickness, color):
    axis = (end - start).normalized()
    ref = Vector((0.0, 1.0, 0.0)) if abs(axis.y) < 0.9 else Vector((1.0, 0.0, 0.0))
    side = axis.cross(ref).normalized() * (thickness * 0.5)
    up = side.cross(axis).normalized() * (thickness * 0.5)
    pts = [tuple(p + sx * side + sy * up) for p in (start, end)
           for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    faces = [(0, 1, 2, 3), (7, 6, 5, 4), (4, 5, 1, 0), (5, 6, 2, 1), (6, 7, 3, 2), (7, 4, 0, 3)]
    emit(label, pts, faces, color)


def chunky_monitor(emit, center, width, height, angle, casing_color, bezel_color, glass_color):
    """Toy-proportioned thick-bezel monitor with stepped rear housing instead of a paper-thin slab."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def at(u, v, w):
        return _rot_pt(center, u, v, w, cos_a, sin_a)

    # Thick molded outer bezel shell
    tapered_box(emit, "Monitor chunky bezel", at(0.0, 0.0, -0.015),
                (width + 0.085, height + 0.085, 0.105), bezel_color, angle=angle, taper=(0.03, 0.03))
    # Stepped rear CRT/terminal hump for crisp side/back silhouette
    tapered_box(emit, "Monitor rear housing", at(0.0, -0.01, -0.095),
                (width * 0.76, height * 0.74, 0.095), casing_color, angle=angle, taper=(0.10, 0.10))
    # Recessed screen glass
    tapered_box(emit, "Lit display", at(0.0, 0.0, 0.032),
                (width, height, 0.026), glass_color, angle=angle, taper=(0.0, 0.0))


def export_toy_parts(name, parts, materials_lookup, filepath, *,
                     bevel=True, max_bevel=0.030, min_thick=0.022, skip_labels=()):
    """Batch `(label, blender_verts, faces, mat_key_or_mat)` parts into one GLB with selective
    1-segment bevels and weighted normals so broad faces stay flat while edges catch light.
    """
    combined = bmesh.new()
    mat_keys = []
    mat_index_map = {}

    for label, verts_bl, faces, mat_ref in parts:
        mat = materials_lookup[mat_ref] if isinstance(mat_ref, str) else mat_ref
        if mat.name not in mat_index_map:
            mat_index_map[mat.name] = len(mat_keys)
            mat_keys.append(mat)
        m_idx = mat_index_map[mat.name]

        bm = bmesh.new()
        v_objs = [bm.verts.new(v) for v in verts_bl]
        for f in faces:
            try:
                bm.faces.new([v_objs[i] for i in f])
            except ValueError:
                pass

        skip = (not bevel) or any(label.startswith(prefix) for prefix in skip_labels)
        closed = len(bm.faces) >= 4 and all(e.is_manifold for e in bm.edges)
        if closed:
            bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        did_bevel = False
        if not skip and closed:
            max_area = max((f.calc_area() for f in bm.faces), default=0.0)
            vol = abs(bm.calc_volume())
            slab_thick = vol / max(max_area, 1e-6) if max_area > 1e-6 else 0.0
            min_edge = min((e.calc_length() for e in bm.edges), default=0.0)
            if slab_thick >= min_thick and min_edge >= 0.012:
                sharp_edges = [e for e in bm.edges if e.calc_face_angle(0.0) > BEVEL_ANGLE]
                if sharp_edges:
                    width = min(max_bevel, max(0.006, min(slab_thick, min_edge * 1.4) * 0.17))
                    bmesh.ops.bevel(
                        bm,
                        geom=sharp_edges,
                        offset=width,
                        offset_type='OFFSET',
                        segments=1,
                        profile=0.5,
                        affect='EDGES',
                        clamp_overlap=True,
                    )
                    did_bevel = True

        for f in bm.faces:
            f.smooth = True
            f.material_index = m_idx
        if not did_bevel:
            for e in bm.edges:
                if not e.is_manifold or e.calc_face_angle(0.0) > BEVEL_ANGLE:
                    e.smooth = False

        tmp = bpy.data.meshes.new("_part")
        bm.to_mesh(tmp)
        bm.free()
        combined.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)

    out_mesh = bpy.data.meshes.new(name)
    combined.to_mesh(out_mesh)
    combined.free()
    for mat in mat_keys:
        out_mesh.materials.append(mat)

    obj = bpy.data.objects.new(name, out_mesh)
    bpy.context.scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if len(out_mesh.polygons) > 0:
        wn = obj.modifiers.new("ToyWeightedNormal", "WEIGHTED_NORMAL")
        wn.keep_sharp = True
        wn.weight = 100
        bpy.ops.object.modifier_apply(modifier=wn.name)
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
        use_selection=True,
        export_normals=True,
    )
    tris = sum(len(p.vertices) - 2 for p in out_mesh.polygons)
    bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.meshes.remove(out_mesh)
    return tris
