"""Derive experimental, metre-scaled UV meshes from the original park GLBs."""
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/models/park"
OUTPUT = ROOT / "assets/models/park_experiment"
ASSETS = (
    "grounds", "entry", "skate", "quarter_pipe", "skate_bank", "carousel_roof",
    "carousel_deck", "station_foundation", "station_roof", "kiosk", "bench", "planter",
)


def add_uvs(mesh):
    uv_layer = mesh.uv_layers.new(name="PixelMaterials")
    # Project each hard face onto its dominant local plane. Coplanar faces
    # share a metre scale and origin, so long surfaces repeat continuously.
    for face in mesh.polygons:
        axis = max(range(3), key=lambda index: abs(face.normal[index]))
        u, v = ((1, 2), (0, 2), (0, 1))[axis]
        for loop_index in face.loop_indices:
            point = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            uv_layer.data[loop_index].uv = (point[u], point[v])


def build():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for asset in ASSETS:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(SOURCE / f"{asset}.glb"))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        assert len(meshes) == 1, asset
        add_uvs(meshes[0].data)
        bpy.ops.export_scene.gltf(filepath=str(OUTPUT / f"{asset}.glb"), export_format="GLB",
                                  export_yup=True, export_apply=False)


if __name__ == "__main__":
    build()
