# 沙城双门概念图

用内置 imagegen 生成的美术和机位参考。俯视图用于讨论空间关系，门洞宽度、低坑深度和两条回路以 Godot 白模为准。

| 视角 | 看点 |
| --- | --- |
| [俯视总览](overview.png) | 右侧 A 大道和高台，中央中门和小道，左侧 B 院与隧道。 |
| [A 大道](a-long.png) | 从长门看到低坑、红白雨棚和 A 台。 |
| [中路双门](mid-doors.png) | 双门的射击缝、右侧小道的高差和左侧通往 B 的侧门。 |
| [B 隧道口](b-tunnel.png) | 从阴影进入亮庭院，正面能看到 B 窗、堆箱和油桶。 |

## Godot 对照

| 机位 | 概念 | 实机 |
| --- | --- | --- |
| 俯视总览 | [概念图](overview.png) | [实机](in-engine/overview.png) |
| A 大道 | [概念图](a-long.png) | [实机](in-engine/a-long.png) |
| 中路双门 | [概念图](mid-doors.png) | [实机](in-engine/mid-doors.png) |
| B 隧道口 | [概念图](b-tunnel.png) | [实机](in-engine/b-tunnel.png) |

实机保留长门、低坑、A 台、中门与小道高差、B 窗和穹顶塔。门扇留出角色通行宽度，低坑和小道配连续坡面碰撞，市集侧墙在狂暴时可以拆开。以实机为准看门洞净宽、战斗空间和光照。

可编辑构件在 [sandgate.blend](../../../art_source/sandgate.blend)，地图在 [sandgate.tscn](../../../scenes/maps/sandgate.tscn)。复现时先运行 [Blender 构建脚本](../../../tools/build_sandgate.py)，导入 Godot 后运行 [场景烘焙脚本](../../../tools/maps/save_sandgate.gd)。[四个对照机位](../../../tools/maps/capture_sandgate.gd)由 Godot 实际渲染。

## 生成提示词

参考图依次为[雪藏版 B 院实机](../../../artifacts/dust-revised-b.png)、[雪藏版长廊实机](../../../artifacts/dust-revised-long.png)和[路线与色板示意](../../design/dust2-adaptation.png)。每张图使用以下共用提示加对应的机位提示。

> Use case: stylized-concept. Create one new standalone wide 16:9 videogame environment concept, one continuous image, for No-Art-FPS's fifth arena, a compact Dust2-inspired original desert market called Sandgate (沙城双门). References 1 and 2 are ONLY for the project's actual bold low-poly game rendering, near-flat saturated blocks, fine dark outlines, blocky props, and the familiar barrel/crate/stall scale. Upgrade their empty blockout to thoughtful architectural silhouettes. Reference 3 is ONLY the broad route topology and palette, not the graphic format. The same art bible across all views: pale sand pavement, predominantly cream and pale ochre masonry, angular roofs and a few cobalt shutters, brick red and cream striped awnings on A Long, a teal dado at Mid, gold crate groups and dusty violet wall accents at B, deep blue clear sky, dry warm sunlight, compact market stalls and terracotta pots, occasional cactus. Classic tall split wooden double doors with iron straps set into sandstone archways, stylized original assets. Grounded walkable FPS scale, readable doorway clearances and cover silhouettes, bold clean geometry, hard directional shadows, thin restrained ink outlines, no detailed grunge, no photographic or realistic textures, no cinematic depth of field. Visible arena architecture first. No HUD, labels, text, logo, watermarks or weapon blocking the foreground. Show a normal daylight round.

**俯视总览**

> Camera: bird's-eye oblique isometric overview of the entire compact arena, roofs below camera and large enough to see walkable ground, 35-degree downward angle, full layout fits with air around it. Frame as a full-width high-quality 3D environment render, no infographic or arrows. Orient A on image right: A Long runs up the right side from its wooden Long Doors past a clearly stepped-down rectangular pit and bends up to the raised A platform. A Short runs from that platform along an inner elevated catwalk back to Mid, visibly sharing the height over Mid. At center show the sandstone Mid Doors, legible as a gap in the terrain, with a quick connection toward B. B on image left: violet-accented open courtyard with yellow crate stacks, distinct large square Window above a wall shelf, and a shaded arched western tunnel whose entrance and exit can be inferred from open ends. Central building masses divide two interconnected running loops, not a maze. Add a small domed tower beyond B to fix orientation. Keep important structures large in frame; no expansive empty desert.

**A 大道**

> Camera: at human eye level just inside the iconic A Long wooden double doors, looking out through both open leaves. Both worn dark brown angular doors frame the composition with black iron straps, cream sandstone arch. Immediately on one side of the open lane is the unmistakable lower rectangular pit, accessible by a short sloped lip, not a trench crossing the whole road. Along the other side a few brick-red and cream striped market stalls and a terracotta pot, clear walk lane. In the distance the main lane bends then climbs a clear ramp to a raised A platform with a cream parapet and gold crates. Make the doorway, pit and raised platform all readable in this single widescreen eye-level composition, a thumbnail-ready game view.

**中路双门**

> Camera: human eye level in the lower Mid lane approaching the partly open wooden Mid Doors obliquely. Show both tall hinged door leaves and their thin shooting gap, a single shaft of natural light across the floor, and a raised playable A Short catwalk hugging the wall on the right visibly higher than Mid. Its cream parapet, teal wall base and short climb lead toward A. The small exit passage toward B is visible off the lower lane. Use clean shade underneath the high route and warm sun on its top to distinguish floors. This is the lower middle of the same compact sand market, with muted teal wall bases and cobalt shutters. Keep the door gap and the high path both visible and readable from ground level.

**B 隧道口**

> Camera: human eye level a pace inside the shadowed sandstone B tunnel, looking through its wide arch into the bright compact B courtyard. Curved masonry rim gives a bold dark foreground, but the tunnel floor and threshold are readable. At the far side of the courtyard, show the recognizable large square B Window high in a cream wall with dusty violet trim, a low stone shelf beneath and gold stacked crate silhouettes near it. A smaller side door leads back toward Mid. Place a clay pot and cactus along the edge, one red explosive oil drum near a crate stack, and the low domed tower behind the B wall. Maintain a clear near-to-far run-and-shoot lane between the arch and cover. B should feel like a distinct close-range arena inside the same map.
