"""Shared painted-toy edge treatment for Blender asset builders.

Rounds hard outer edges in proportion to the part, then uses weighted normals so
broad faces stay flat while the bevel catches a highlight. Thin parts get small
edges; nothing exceeds 4 cm, so silhouettes, origins and collisions are unchanged.
"""
import bpy
import math

MAX_WIDTH = .04
RATIO = .18

def toy_soften(obj, smallest, minimum=0.0, segments=2):
    width = max(minimum, min(MAX_WIDTH, smallest * RATIO))
    bpy.context.view_layer.objects.active = obj
    if width > .002:
        bevel = obj.modifiers.new('Toy bevel', 'BEVEL')
        bevel.width = width
        bevel.segments = segments
        bevel.limit_method = 'ANGLE'
        bevel.angle_limit = math.radians(50)
        bevel.harden_normals = True
        bevel.use_clamp_overlap = True
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.shade_smooth()
    weighted = obj.modifiers.new('Flat faces', 'WEIGHTED_NORMAL')
    weighted.keep_sharp = True
    weighted.weight = 100
    bpy.ops.object.modifier_apply(modifier=weighted.name)
