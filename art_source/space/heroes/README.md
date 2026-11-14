# 月球英雄资产：制作源

`inputs/` 保存三个已经定向、缩放并内嵌纹理的 Tripo 原始形体，作为可重复的装配输入。完整网络响应、下载地址、认证信息只留在忽略的本地目录；净化后的任务编号、费用与参考图见 `docs/art/space/review-b/generation-manifest.json`。

- `build_rifle.py`：程序化离子步枪与第一人称手臂；生成可编辑 `ion-rifle.blend` 和第一/第三人称 GLB。弹匣、支撑手、瞄具保持独立节点。
- `build_cloud_heroes.py`：切分刚性装甲，保留 UV，重定位肩/肘/髋/膝/脚节点；补机械手、关节、刀刃与持枪插槽；飞船补三点落架、翼炮及挂载。生成三个最终 `.blend` 和 GLB。
- `geometry.py`：倒角盒体、轮廓挤出、旋转体连杆、保持世界姿态的装配与同节点材质合并。
- `normalize_cloud.py`：首次导入记录；读取本地原始 GLB，朝向校准为 Blender +Y 前向、Z 向上，机甲高 1.95 m，飞船最大平面尺寸 11 m。后续重复装配直接使用已保存的 `inputs`，无需再次请求云服务。

先运行枪械生成器，再运行装配生成器；随后执行 Godot 导入及 `tools/maps/build_moonbase.gd`。制作端生成，游戏只读取 GLB，没有在狂暴切换时生成这些几何体。

Godot 约定：前向 -Z；第一人称枪口 `(0,.015,-1.025)`，瞄准轴 Y=.32。参数写在 `data/moonbase_visuals.tres`。`Head`、`Helmet`、`Torso` 和四肢节点兼容原有命中、破甲及死亡流程。刚性关节不是蒙皮绑定，装甲切口和极限姿态仍需要后续动作精修。材质保留云模型纹理，ORM 粗糙度下限 .46；没有把橙色 Albedo 去饱和。

源码模型和生产导出均保留。文件夹中的 `.blend1` 备份与 Python 缓存不提交。
