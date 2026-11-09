# 夕阳游乐园 · 实验性像素贴图

在标题页右键游乐园缩略图，或在触摸屏长按缩略图，再勾选「实验性贴图」。该选项默认关闭，应用在当前游戏会话中，重新加载游戏会恢复关闭。

| 同机位实机 | 原版 | 实验贴图 |
| --- | --- | --- |
| 步道与旋转木马 | ![原版步道](comparison/promenade-original.png) | ![贴图步道](comparison/promenade-pixel.png) |
| 滑板碗池 | ![原版碗池](comparison/skate-original.png) | ![贴图碗池](comparison/skate-pixel.png) |
| 过山车站台 | ![原版站台](comparison/station-original.png) | ![贴图站台](comparison/station-pixel.png) |

实验覆盖地面及 11 个构件实例：入口、滑板场、一座四分之一坡、斜坡、木马顶棚、木马转盘、站台地板、站台屋顶、一座摊位、一张长椅和一只花坛。原来的色板继续作为底色。

[图集](imagegen-atlas.png)由内置 imagegen 一次生成，共九种材质。切成独立可平铺的像素纹理，Blender 从原 GLB 派生带 UV 的实验网格。可用 [纹理处理脚本](../../../tools/maps/build_park_texture_tiles.py) 和 [UV 构建脚本](../../../tools/maps/build_park_texture_uv.py) 复现。

实机对照用 Godot 固定机位拍摄。运行 `godot --resolution 1280x720 --script tests/park_texture_experiment_check.gd` 可重新拍摄，并验证关闭开关后恢复到同机位原图。

## 生成提示词

> Generate a single square production texture atlas for a colorful low-poly amusement park videogame at sunset. EXACTLY 3 columns by 3 rows of nine equal square tiles. Perfectly straight tile boundaries at one third and two thirds, no margins or gutters, each panel fills its cell edge to edge. Strictly flat orthographic albedo artwork, no object perspective, no lighting, no drop shadows, no lettering, no gradients, no labels or numbers. Hand drawn 16-bit pixel art texture treatment, crisp integer-square pixel clusters, sparse details with large quiet color areas, warm playful Nintendo-like low-poly game palette. Every cell should repeat naturally like tileable surfaces; edge motifs are secondary. The nine cells in row-major order are: top left cream and peach promenade limestone pavers with staggered joints and subtle peach chips; top center warm tan compact gravel with sparse rounded pixel specks; top right muted terracotta red brick and beige mortar, orderly offset brick courses. Middle left medium cobalt blue smooth painted concrete with very sparse wear and aggregate, no brick lines; middle center golden honey brown wooden planks with light sparse grain, wide boards and a few small knots; middle right violet lavender painted sheet metal with subtle rounded fastener dots and sparse flecks. Bottom left matte vanilla woven carnival canvas, lightly textured with faint threads and tiny blocky warm glints, no obvious stripes; bottom center pale ochre powder coated enamel with sparse pixel scuffs and tiny rounded details; bottom right muted green and teal glazed ceramic tile with very subtle staggered joints and a few chipped corners. Keep contrast within each tile restrained; avoid black outlines, loud noise and chromatic outliers. Think nine 64x64 material swatches enlarged with nearest neighbor. Atlas only, no presentation.
