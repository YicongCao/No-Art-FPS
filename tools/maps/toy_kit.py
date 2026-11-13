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


def _det_hash(seed_val):
    """Deterministic float in [0, 1) from any tuple/number so procedural wear stays reproducible."""
    x = math.sin(seed_val * 127.1 + 311.7) * 43758.5453123
    return x - math.floor(x)


def _coord_seed(center, salt=0.0):
    return center[0] * 19.19 + center[1] * 7.31 + center[2] * 23.47 + salt


def chipped_box(emit, label, center, size, color, angle=0.0, taper=(0.05, 0.05),
                chips=None, core_color=None, seed=None):
    """Manifold tapered block with clean, sculptural corner/edge chips cut via BMesh planes."""
    w, h, d = size
    tx, tz = taper if isinstance(taper, tuple) else (taper, taper)
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    s_base = _coord_seed(center, 3.7) if seed is None else float(seed)

    bm = bmesh.new()
    local_pts = []
    for sy, sx_scale, sz_scale in ((-0.5, 1.0, 1.0), (0.5, 1.0 - tx, 1.0 - tz)):
        for sx, sz in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
            local_pts.append((sx * w * sx_scale, sy * h, sz * d * sz_scale))
    v_objs = [bm.verts.new(p) for p in local_pts]
    for f in [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
        bm.faces.new([v_objs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))

    min_dim = min(w, h, d)
    if chips is None:
        sx = 1.0 if _det_hash(s_base + 1.1) > 0.5 else -1.0
        sz = 1.0 if _det_hash(s_base + 2.3) > 0.45 else -1.0
        cut = min(0.46, max(0.055, min_dim * (0.28 + 0.18 * _det_hash(s_base + 3.9))))
        chips = [((sx, 1.0, sz), cut)]
        if _det_hash(s_base + 5.7) > 0.48 and max(w, h, d) > 0.50:
            cut2 = min(0.36, max(0.045, min_dim * (0.22 + 0.14 * _det_hash(s_base + 7.1))))
            sy2 = -1.0 if h > 1.1 and _det_hash(s_base + 8.3) > 0.55 else 1.0
            chips.append(((-sx, sy2, sz), cut2))

    core_insets = []
    for idx, spec in enumerate(chips):
        signs, cut_depth = spec[0], spec[1]
        csx, csy, csz = signs
        top_scale_x = (1.0 - tx) if csy > 0 else 1.0
        top_scale_z = (1.0 - tz) if csy > 0 else 1.0
        corner = Vector((csx * w * 0.5 * top_scale_x, csy * h * 0.5, csz * d * 0.5 * top_scale_z))
        nx = csx * (0.56 + 0.24 * _det_hash(s_base + idx * 4.1 + 0.7)) if abs(csx) > 0.1 else 0.12
        ny = csy * (0.48 + 0.26 * _det_hash(s_base + idx * 4.1 + 1.9)) if abs(csy) > 0.1 else 0.18
        nz = csz * (0.54 + 0.24 * _det_hash(s_base + idx * 4.1 + 2.8)) if abs(csz) > 0.1 else 0.12
        normal = Vector((nx, ny, nz)).normalized()
        plane_co = corner - normal * cut_depth
        geom_all = list(bm.verts) + list(bm.edges) + list(bm.faces)
        ret = bmesh.ops.bisect_plane(
            bm, geom=geom_all, plane_co=plane_co, plane_no=normal, clear_outer=True
        )
        cut_edges = [g for g in ret["geom_cut"] if isinstance(g, bmesh.types.BMEdge) and g.is_valid]
        if len(cut_edges) >= 3:
            bmesh.ops.contextual_create(bm, geom=cut_edges)
            core_insets.append((plane_co - normal * (cut_depth * 0.12), cut_depth))

    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    pts = [_rot_pt(center, v.co.x, v.co.y, v.co.z, cos_a, sin_a) for v in bm.verts]
    faces = [tuple(v.index for v in f.verts) for f in bm.faces]
    bm.free()
    emit(label, pts, faces, color)

    if core_color and core_insets:
        co, c_depth = core_insets[0]
        sub = max(0.055, c_depth * 0.72)
        tapered_box(
            emit, label + " core",
            _rot_pt(center, co.x, co.y, co.z, cos_a, sin_a),
            (sub, sub * 0.78, sub),
            core_color, angle=angle + 0.28, taper=(0.14, 0.14),
        )


def segmented_coping(emit, label, center, width, height, depth, color, angle=0.0,
                     seg_len=1.75, gap=0.028, taper=0.05, slant=0.16, wear=0.58):
    """Splits a monolithic wall cap into slanted-joint coping stones with subtle settling & chipped corners."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    along_x = width >= depth
    span = width if along_x else depth
    cross = depth if along_x else width
    count = max(1, round(span / seg_len))
    s_base = _coord_seed(center, 11.3)
    if count == 1 or span < 1.1:
        if wear >= 0.55 and min(width, depth) >= 0.24 and height >= 0.12:
            chipped_box(emit, label, center, (width, height, depth), color, angle=angle,
                        taper=(taper, taper), seed=s_base)
        else:
            tapered_box(emit, label, center, (width, height, depth), color, angle=angle, taper=(taper, taper))
        return

    step = span / count
    max_slant = min(step * 0.20, cross * slant * 0.5) if wear > 0.05 else 0.0
    # Alternating slanted joint offsets along the coping run
    joint_slants = [0.0]
    for i in range(1, count):
        sign = 1.0 if (i + int(_det_hash(s_base + i) * 4)) % 2 == 0 else -1.0
        joint_slants.append(sign * max_slant * (0.65 + 0.35 * _det_hash(s_base + i * 2.7)))
    joint_slants.append(0.0)

    chip_idx = int(_det_hash(s_base + 9.1) * count) if (wear >= 0.42 and count >= 3) else -1
    breach_idx = int(_det_hash(s_base + 17.4) * count) if (wear >= 0.72 and count >= 4) else -1
    if breach_idx == chip_idx and count >= 4:
        breach_idx = (chip_idx + 2) % count

    for i in range(count):
        h_rand = _det_hash(s_base + i * 5.3 + 1.7)
        # Subtle settling / height & lateral jitter so stones feel hand-laid & lived-in
        dy = (h_rand - 0.52) * 0.026 * wear if count >= 3 else 0.0
        d_lat = (_det_hash(s_base + i * 3.1 + 4.2) - 0.5) * 0.024 * wear if count >= 3 else 0.0
        s0 = -span * 0.5 + i * step + gap * 0.5
        s1 = -span * 0.5 + (i + 1) * step - gap * 0.5
        if s1 - s0 < 0.14:
            continue

        # Weathered notch / broken coping gap: two asymmetric broken stubs flanking a visible V-breach
        if i == breach_idx and (s1 - s0) >= 0.65 and height >= 0.12:
            stub_a = (s1 - s0) * 0.34
            stub_b = (s1 - s0) * 0.28
            for st_mid, st_len, st_h, st_sign in (
                (s0 + stub_a * 0.5, stub_a, height * 0.86, 1.0),
                (s1 - stub_b * 0.5, stub_b, height * 0.72, -1.0),
            ):
                u, w = (st_mid, d_lat) if along_x else (d_lat, st_mid)
                sub_c = _rot_pt(center, u, dy - (height - st_h) * 0.5, w, cos_a, sin_a)
                sub_sz = (st_len, st_h, cross * 0.96) if along_x else (cross * 0.96, st_h, st_len)
                cut_s = (st_sign, 1.0, 1.0) if along_x else (1.0, 1.0, st_sign)
                chipped_box(emit, label, sub_c, sub_sz, color, angle=angle,
                            taper=(taper, taper), chips=[(cut_s, min(0.16, st_h * 0.58))], seed=s_base + i * 7.0)
            continue

        h_piece = height
        sl0, sl1 = joint_slants[i], joint_slants[i + 1]

        if i == chip_idx and cross >= 0.22 and h_piece >= 0.11:
            mid = (s0 + s1) * 0.5
            u, w = (mid, d_lat) if along_x else (d_lat, mid)
            sub_center = _rot_pt(center, u, dy - (height - h_piece) * 0.5, w, cos_a, sin_a)
            sub_size = (s1 - s0, h_piece, cross) if along_x else (cross, h_piece, s1 - s0)
            chipped_box(emit, label, sub_center, sub_size, color, angle=angle,
                        taper=(taper, taper), seed=s_base + i * 13.0)
            continue

        # Build trapezoid prism with slanted mortar joints at both ends
        pts = []
        for sy, t_scale in ((-0.5, 1.0), (0.5, 1.0 - taper)):
            vy = dy - (height - h_piece) * 0.5 + sy * h_piece
            half_c = cross * 0.5 * t_scale
            if along_x:
                ring = [
                    (s0 - sl0 * t_scale, vy, d_lat - half_c),
                    (s1 - sl1 * t_scale, vy, d_lat - half_c),
                    (s1 + sl1 * t_scale, vy, d_lat + half_c),
                    (s0 + sl0 * t_scale, vy, d_lat + half_c),
                ]
            else:
                ring = [
                    (d_lat - half_c, vy, s0 - sl0 * t_scale),
                    (d_lat + half_c, vy, s0 + sl0 * t_scale),
                    (d_lat + half_c, vy, s1 + sl1 * t_scale),
                    (d_lat - half_c, vy, s1 - sl1 * t_scale),
                ]
            for ux, uy, uz in ring:
                pts.append(_rot_pt(center, ux, uy, uz, cos_a, sin_a))
        faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        emit(label, pts, faces, color)


def _wall_prism(emit, label, origin, angle, poly_uv, w0, w1, color, inset=0.012):
    """Extrude a 2D polygon on a wall's `(u, v)` plane from depth `w0` to `w1` with slight bevel-ready inset."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    cx = sum(p[0] for p in poly_uv) / len(poly_uv)
    cy = sum(p[1] for p in poly_uv) / len(poly_uv)
    back = [_rot_pt(origin, u, v, w0, cos_a, sin_a) for u, v in poly_uv]
    front = []
    for u, v in poly_uv:
        du, dv = u - cx, v - cy
        ln = max(math.hypot(du, dv), 1e-4)
        sh = max(0.4, (ln - inset) / ln)
        front.append(_rot_pt(origin, cx + du * sh, cy + dv * sh, w1, cos_a, sin_a))
    n = len(poly_uv)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    emit(label, back + front, faces, color)


def slanted_wall_seam(emit, origin, span, rise, angle, seam_color, trim_color,
                      tie_color=None, flip=False, seed=None):
    """Sculpted architectural slanted panel/ashlar wall seam: two opposing chamfered wall flanges
    meeting along a clean diagonal recessed joint, optionally bridged by a metal cramp tie."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    s_base = _coord_seed(origin, 29.1) if seed is None else float(seed)
    sign = -1.0 if flip else 1.0

    def pt_t(u, v, w):
        return _rot_pt(origin, u, v, w, cos_a, sin_a)

    # Clean two-stage slanted seam line across the wall
    mid_u = sign * span * (0.04 + 0.06 * _det_hash(s_base + 1.3))
    mid_v = rise * (0.04 - 0.08 * _det_hash(s_base + 2.9))
    nodes = [
        (-sign * span * 0.36, rise * 0.48),
        (mid_u, mid_v),
        (sign * span * 0.36, -rise * 0.48),
    ]
    gap_half = 0.024
    flange_w = 0.165
    for idx, ((u0, v0), (u1, v1)) in enumerate(zip(nodes, nodes[1:])):
        du, dv = u1 - u0, v1 - v0
        seg_l = math.hypot(du, dv)
        if seg_l < 0.16:
            continue
        nu, nv = -dv / seg_l, du / seg_l
        # Recessed dark joint bed sitting flush against the host wall
        bed_poly = [
            (u0 - nu * 0.055, v0 - nv * 0.055),
            (u1 - nu * 0.055, v1 - nv * 0.055),
            (u1 + nu * 0.055, v1 + nv * 0.055),
            (u0 + nu * 0.055, v0 + nv * 0.055),
        ]
        _wall_prism(emit, "Slanted wall seam groove", origin, angle, bed_poly, 0.004, 0.018, seam_color, inset=0.004)
        # Opposing slanted chamfer flanges flanking the recessed diagonal joint
        for side_s, trim_s in ((-1.0, 0.86), (1.0, 0.72)):
            a0 = 0.08 if side_s > 0 else 0.02
            a1 = 0.92 if side_s < 0 else 0.98
            su0, sv0 = u0 + du * a0, v0 + dv * a0
            su1, sv1 = u0 + du * a1, v0 + dv * a1
            fw = flange_w * trim_s
            inner = gap_half * side_s
            outer = (gap_half + fw) * side_s
            poly = [
                (su0 + nu * inner, sv0 + nv * inner),
                (su1 + nu * inner, sv1 + nv * inner),
                (su1 + nu * outer, sv1 + nv * outer),
                (su0 + nu * outer, sv0 + nv * outer),
            ]
            if side_s < 0:
                poly.reverse()
            _wall_prism(emit, "Slanted seam flange", origin, angle, poly, 0.006, 0.034, trim_color, inset=0.014)

    # Optional iron staple tie bridging across the slanted joint
    if tie_color:
        dx, dy = nodes[2][0] - nodes[0][0], nodes[2][1] - nodes[0][1]
        dl = max(math.hypot(dx, dy), 1e-4)
        nu, nv = -dy / dl, dx / dl
        p_a = Vector(pt_t(mid_u - nu * 0.13, mid_v - nv * 0.13, 0.038))
        p_b = Vector(pt_t(mid_u + nu * 0.13, mid_v + nv * 0.13, 0.038))
        _strut(emit, "Wall seam iron tie", p_a, p_b, 0.052, tie_color)


def exposed_masonry_patch(emit, origin, width, height, angle, mortar_color, brick_color,
                          alt_color=None, lip_color=None, seed=None):
    """Low-relief stepped plaster-peel patch exposing clean, broad beveled masonry blocks."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    s_base = _coord_seed(origin, 43.7) if seed is None else float(seed)
    alt = alt_color or brick_color

    def at(u, v, w):
        return _rot_pt(origin, u, v, w, cos_a, sin_a)

    # Low-profile recessed mortar bed
    tapered_box(emit, "Peel mortar bed", at(-width * 0.05, height * 0.07, 0.008),
                (width * 0.86, height * 0.66, 0.014), mortar_color, angle=angle, taper=(0.04, 0.08))
    tapered_box(emit, "Peel mortar lower bed", at(width * 0.09, -height * 0.15, 0.008),
                (width * 0.74, height * 0.54, 0.014), mortar_color, angle=angle, taper=(0.04, 0.08))

    rows = 3 if height >= 0.56 else 2
    row_h = min(0.20, height / (rows + 0.30))
    for r in range(rows):
        vy = (r - (rows - 1) * 0.5) * (row_h + 0.026)
        cols = 2
        stagger = (0.09 if r % 2 == 0 else -0.08) * width
        brick_w = min(0.44, (width * 0.78) / cols - 0.024)
        for c in range(cols):
            if r == rows - 1 and c == cols - 1 and _det_hash(s_base + 9.4) > 0.30:
                continue
            ux = stagger + (c - (cols - 1) * 0.5) * (brick_w + 0.030)
            thick = 0.026 + 0.010 * _det_hash(s_base + r * 7.1 + c * 3.3)
            b_col = brick_color if (r + c) % 2 == 0 else alt
            if r == 0 and c == 0:
                chipped_box(emit, "Exposed chipped brick", at(ux, vy, thick * 0.5 + 0.006),
                            (brick_w, row_h, thick), b_col, angle=angle,
                            taper=(0.05, 0.10), seed=s_base + r * 11 + c)
            else:
                tapered_box(emit, "Exposed worn brick", at(ux, vy, thick * 0.5 + 0.006),
                            (brick_w, row_h, thick), b_col, angle=angle, taper=(0.05, 0.10))

    if lip_color:
        # Slanted broken plaster edge framing the upper boundary
        lip_poly = [
            (-width * 0.46, height * 0.34),
            (width * 0.18, height * 0.44),
            (width * 0.14, height * 0.52),
            (-width * 0.48, height * 0.42),
        ]
        _wall_prism(emit, "Broken plaster lip", origin, angle, lip_poly, 0.005, 0.024, lip_color, inset=0.008)


def sand_drift(emit, center, rx, rz, height, angle, color, alt_color=None):
    """Low, clean faceted wind-blown sand/earth drift tucked against wall bases & corners."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    s_base = _coord_seed(center, 61.9)

    def at(u, v, w):
        return _rot_pt(center, u, v, w, cos_a, sin_a)

    sides = 7
    ring = []
    for i in range(sides):
        th = i * math.tau / sides
        irr = 0.82 + 0.30 * _det_hash(s_base + i * 2.9)
        ring.append(at(math.cos(th) * rx * irr, 0.0, math.sin(th) * rz * irr))
    bot = [at(math.cos(i * math.tau / sides) * rx * 0.75, -0.04, math.sin(i * math.tau / sides) * rz * 0.75)
           for i in range(sides)]
    crest_a = at(-rx * 0.18, height, -rz * 0.22)
    fan_pts = ring + bot + [crest_a]
    peak_i = sides * 2
    fan_faces = [tuple(range(sides, sides * 2))]
    for i in range(sides):
        j = (i + 1) % sides
        fan_faces.append((sides + i, sides + j, j, i))
        fan_faces.append((i, j, peak_i))
    emit("Windblown sand drift", fan_pts, fan_faces, color)
    if alt_color and rx > 0.7:
        # Secondary smaller leeward ripple lobe
        sub_c = at(rx * 0.42, 0.0, rz * 0.24)
        sand_drift(emit, sub_c, rx * 0.52, rz * 0.48, height * 0.62, angle + 0.4, alt_color, None)


def weathered_rubble(emit, center, spread, angle, colors, count=3, seed=None):
    """Small scatter of clean chipped stone/brick chunks beside weathered walls or broken pots."""
    s_base = _coord_seed(center, 79.3) if seed is None else float(seed)
    palette = colors if isinstance(colors, (list, tuple)) else (colors,)
    for i in range(count):
        ang = angle + i * 2.15 + _det_hash(s_base + i * 3.7) * 0.9
        dist = spread * (0.28 + 0.68 * _det_hash(s_base + i * 5.1))
        w = 0.14 + 0.13 * _det_hash(s_base + i * 7.3)
        h = 0.075 + 0.065 * _det_hash(s_base + i * 9.7)
        d = 0.12 + 0.11 * _det_hash(s_base + i * 11.9)
        pos = (center[0] + math.cos(ang) * dist, center[1] + h * 0.46, center[2] + math.sin(ang) * dist)
        col = palette[i % len(palette)]
        chipped_box(emit, "Chipped stone rubble", pos, (w, h, d), col,
                    angle=ang * 1.3, taper=(0.14, 0.12), seed=s_base + i * 19.0)


def repair_patch_plate(emit, origin, width, height, angle, plate_color, bolt_color, chipped=True, seed=None):
    """Beveled industrial/marine/station repair patch plate with corner rivets & notched corner."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    s_base = _coord_seed(origin, 97.1) if seed is None else float(seed)

    def at(u, v, w):
        return _rot_pt(origin, u, v, w, cos_a, sin_a)

    if chipped:
        chipped_box(emit, "Repair patch plate", at(0.0, 0.0, 0.020),
                    (width, height, 0.036), plate_color, angle=angle,
                    taper=(0.05, 0.10), chips=[((1.0, 1.0, 1.0), min(width, height) * 0.26)], seed=s_base)
    else:
        tapered_box(emit, "Repair patch plate", at(0.0, 0.0, 0.020),
                    (width, height, 0.036), plate_color, angle=angle, taper=(0.05, 0.10))
    for su in (-1.0, 1.0):
        for sv in (-1.0, 1.0):
            if chipped and su > 0 and sv > 0:
                continue
            tapered_box(emit, "Repair patch bolt",
                        at(su * (width * 0.5 - 0.065), sv * (height * 0.5 - 0.065), 0.042),
                        (0.048, 0.048, 0.030), bolt_color, angle=angle, taper=(0.12, 0.12))


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


def cambered_canopy(emit, origin, width, depth, drop, angle, stripe_a, stripe_b, wood_color,
                    post_h=2.06, posts=True):
    """Three-segment curved striped awning with thick scalloped valance and support brackets."""
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def pt(u, v, w):
        return _rot_pt(origin, u, v, w, cos_a, sin_a)

    # Curved profile along w in 3 segments so the awning reads as a thick molded shell, not a flat card
    curve = [(0.0, 0.0), (0.36, -drop * 0.24), (0.72, -drop * 0.58), (1.0, -drop)]
    thick = 0.085
    stripes = max(5, round(width / 0.42))
    if stripes % 2 == 0:
        stripes += 1
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
        tab_w = max(0.08, (u1 - u0) - 0.016)
        tapered_box(emit, "Canopy valance", pt(um, -drop - 0.14, depth - 0.03),
                    (tab_w, 0.24, 0.078), tone, angle=angle, taper=(-0.06, 0.06))

    # Wall ledger beam + front crossbeam + posts or cantilevered wall brackets
    tapered_box(emit, "Canopy wall ledger", pt(0.0, -0.06, 0.05),
                (width + 0.10, 0.12, 0.11), wood_color, angle=angle, taper=(0.02, 0.02))
    tapered_box(emit, "Canopy front rail", pt(0.0, -drop - 0.07, depth - 0.12),
                (width - 0.08, 0.11, 0.11), wood_color, angle=angle, taper=(0.02, 0.02))
    for side in (-1.0, 1.0):
        pu = side * (width * 0.5 - 0.16)
        pw = depth - 0.12
        if posts:
            tapered_box(emit, "Canopy post", pt(pu, -post_h * 0.5 - drop * 0.85, pw),
                        (0.145, post_h, 0.145), wood_color, angle=angle, taper=(0.12, 0.12))
            stepped_plinth(emit, "Canopy post foot", pt(pu, -post_h - drop * 0.85 + 0.07, pw),
                           0.19, 0.14, 0.19, stripe_b, angle=angle, flare=0.025)
            b0 = Vector(pt(pu, -drop - 0.52, pw))
            b1 = Vector(pt(pu, -0.14, max(0.10, pw - 0.58)))
            _strut(emit, "Canopy knee brace", b0, b1, 0.095, wood_color)
        else:
            b0 = Vector(pt(pu, -drop - 0.34, 0.06))
            b1 = Vector(pt(pu, -drop - 0.06, max(0.18, pw - 0.04)))
            _strut(emit, "Canopy wall bracket", b0, b1, 0.088, wood_color)


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
