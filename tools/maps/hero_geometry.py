"""Authored scene forms, in Godot Y-up coordinates, using map mesh emitters.

These opt-in primitives do not replace the existing kit globally. Material
partitions share exact boundary positions and never add hidden separator faces.
"""
import math
from mathutils import Vector
from toy_kit import _rot_pt, _strut, tapered_box, stepped_plinth


def cloth_canopy(emit, origin, width, depth, drop, angle, colors, support,
                 post_h=2.02, rise=.34):
    """Continuous curved cloth shell with scalloped hem and an independent frame.

    The lowest hem and horizontal footprint match the old Sandgate kit; the extra
    curvature grows upward, keeping clearance and walking space unchanged.
    """
    ca, sa = math.cos(angle), math.sin(angle)
    def pt(u, v, w):
        return _rot_pt(origin, u, v, w, ca, sa)

    stripes = max(5, round(width / .44)) | 1
    steps, thickness = 16, .075
    def height(t):
        return rise * (1-t) - drop * (1-math.sqrt(max(0, 1-t*t)))

    for stripe in range(stripes):
        u0, u1 = -width/2 + stripe*width/stripes, -width/2 + (stripe+1)*width/stripes
        verts = [pt(u, height(j/steps)-lower*thickness, depth*j/steps)
                 for lower in (0, 1) for j in range(steps+1) for u in (u0, u1)]
        layer = 2*(steps+1)
        faces = []
        for j in range(steps):
            a = j*2
            faces.extend([(a,a+1,a+3,a+2),
                          (layer+a+2,layer+a+3,layer+a+1,layer+a)])
            if stripe == 0:
                faces.append((a,a+2,layer+a+2,layer+a))
            if stripe == stripes-1:
                faces.append((a+3,a+1,layer+a+1,layer+a+3))
        faces += [(1,0,layer,layer+1),
                  (steps*2,steps*2+1,layer+steps*2+1,layer+steps*2)]
        emit("Hero cloth continuous shell", verts, faces, colors[stripe%2])
        # Rounded hem rather than separated rigid rectangular tabs.
        profile = [(u0, -drop), (u1, -drop)]
        profile += [(u1-(u1-u0)*i/6, -drop-.13-.11*math.sin(math.pi*i/6))
                    for i in range(7)]
        points = [pt(u,v,depth+dz) for dz in (-.024,.024) for u,v in profile]
        n = len(profile)
        faces = [tuple(reversed(range(n))), tuple(range(n,2*n))]
        faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        emit("Hero cloth scalloped hem", points, faces, colors[stripe%2])

    for w,y in [(0,rise-.09),(depth-.12,-drop-.08)]:
        tapered_box(emit,"Hero canopy crossrail",pt(0,y,w),
                    (width-.08,.12,.12),support,angle=angle,taper=0)
    for side in (-1,1):
        u, w = side*(width/2-.16), depth-.12
        # A sleeve grounds the post without widening its existing footprint.
        tapered_box(emit,"Hero canopy post",pt(u,-post_h/2-drop*.85,w),
                    (.145,post_h,.145),support,angle=angle,taper=.08)
        stepped_plinth(emit,"Hero canopy post shoe",pt(u,-post_h-drop*.85+.07,w),
                       .19,.14,.19,colors[1],angle=angle,flare=.025)
        for j in range(6):
            t0,t1=j/6,(j+1)/6
            _strut(emit,"Hero canopy curved side rib",
                   Vector(pt(u,height(t0)-.11,depth*t0)),
                   Vector(pt(u,height(t1)-.11,depth*t1)),.085,support)
        _strut(emit,"Hero canopy knee brace",Vector(pt(u,-drop-.54,w)),
               Vector(pt(u,height(.52)-.12,depth*.52)),.095,support)


def profile_shell(emit, label, origin, rings, color, angle=0):
    """Closed loft of matching (u,v) profiles at local forward depths.

    Rings are (depth, [(u,v), ...]); callers author map-specific proportions.
    Useful for continuous machine casings, cabin noses, and molded furniture.
    """
    ca,sa=math.cos(angle),math.sin(angle)
    n=len(rings[0][1])
    assert len(rings)>=2 and n>=3 and all(len(p)==n for _,p in rings)
    verts=[_rot_pt(origin,u,v,w,ca,sa) for w,profile in rings for u,v in profile]
    faces=[tuple(reversed(range(n))),tuple(range((len(rings)-1)*n,len(rings)*n))]
    faces += [(r*n+i,r*n+(i+1)%n,(r+1)*n+(i+1)%n,(r+1)*n+i)
              for r in range(len(rings)-1) for i in range(n)]
    emit(label,verts,faces,color)


def rounded_profile(width, height, radius, *, y=0, steps=3):
    """Counter-clockwise rounded rectangle for authored loft sections."""
    radius=min(radius,width*.49,height*.49)
    result=[]
    for cx,cy,start in [(width/2-radius,height/2-radius,0),
                        (-width/2+radius,height/2-radius,90),
                        (-width/2+radius,-height/2+radius,180),
                        (width/2-radius,-height/2+radius,270)]:
        for step in range(steps+1):
            a=math.radians(start+90*step/steps)
            result.append((cx+radius*math.cos(a),y+cy+radius*math.sin(a)))
    return result
