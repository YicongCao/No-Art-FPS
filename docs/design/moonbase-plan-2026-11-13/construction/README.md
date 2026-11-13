# 地编与程序化构件手册 v1.1

打开 [index.html](index.html)，或从 [完整制作策划案](../index.html) 首页、建模与地编章节进入。

14 章细化环境生产方案：43 类基础构件、215 个正投影、43 个轴测辅助、12 组总装图、一张地编总平面、16 个生产生成器家族提案。包括飞船、基地外壳、氧气设备、气管、储物箱、障碍、围墙、通信碟、天线、太阳能阵列、灯、发生器、卷盘与月岩。基地室内不进入本轮范围。

## 图册使用

- 图册支持分组、文字检索、总装 BOM 到构件跳转、批量展开/收起；筛选藏住的构件仍可通过编号链接打开。
- 每类构件有正、后、左、右、顶五视图。来自同一份米制几何；同张图纸的五个正投影采用同一比例。第六格为轴测辅助。
- 每页说明名义尺寸、实际包络、接口、参数、几何/材质分工、碰撞与 LOD 要求。图纸内的尺寸包含外凸附件，名义尺寸用于生成器预设。
- “放大图纸”允许在窄屏容器内平移查看原始矢量；“适配宽度”恢复完整图面。
- [sheets/](sheets/) 保存 43 张独立 SVG；[assemblies/](assemblies/) 保存 12 张总装 SVG；[layout-v1.1.svg](layout-v1.1.svg) 为总平面。SVG 字体使用系统回退；HTML 正文有独立内嵌字体。
- [five-views-v1.1.zip](five-views-v1.1.zip) 打包全部 SVG、构件清单与此说明，便于交接。

图纸是尺寸化设计代理，表达轮廓、结构、拆件和装配意图。背面、接口和尺寸是原创补充设计。它们尚未包含生产 UV、PBR 烘焙、GLB、运行时碰撞或引擎接入；轴测用面排序展示辅助体块，复杂遮挡和接头须在 Blender 样板校准。

## 生产路线

优先采用制作端参数化与模块化，导出 .blend/GLB、共享图集、碰撞与 LOD 并缓存。运行时保留轻量状态参数；Triplanar 先用于岩石样板，面板与文字保留 UV。月球场景以干燥装甲、金属和月尘为基线，平面镜像反射不列为默认效果。程序化纹理中，同一磨损/尘积蒙版驱动相关 PBR 通道。

本轮只细化方案和绘图。生产生成器的参数是实施合同，图纸脚本未实现所有参数范围组合。先用箱体、压力容器家族验证收益，再扩展全场。

## 重建与检查

`build_kit.py` 和 `build_layout.py` 仅依赖 Python 标准库。HTML 构建及字体覆盖检查需要 `fonttools[woff]`、`brotli`，沿用主案 README 的原始字体输入。核查版本：fonttools 4.68.0、brotli 1.2.1。

按顺序执行，不要在前一步尚未结束时读取产物：

```sh
python3 docs/design/moonbase-plan-2026-11-13/construction/build_kit.py
python3 docs/design/moonbase-plan-2026-11-13/construction/build_layout.py
python3 docs/design/moonbase-plan-2026-11-13/construction/build_handbook.py
python3 docs/design/moonbase-plan-2026-11-13/construction/validate_kit.py
```

`kit.json` 是去掉代理几何后的完整清单，保留总装 BOM 与局部变换。几何和五视图可从脚本重建。`build-info.json` 记录 HTML 与字体输入；`static-validation.json`、`export-validation.json` 和 [VALIDATION.md](VALIDATION.md) 区分静态、浏览器与隔离脚本检查。

二维路线校验只针对选定矩形包络、以 1.75 m 半宽沿中心线采样；它不能替代实际角色胶囊、跳跃、完整美术包络、碰撞或导航验证。

所有文件在 `docs/`；项目的 `docs/.gdignore` 和导出排除规则避免它们作为游戏资产导入或打包。本轮不更新游戏发布站点。
