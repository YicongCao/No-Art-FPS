# 上漆玩具场景建模进阶：可行性调研、五项原则与样板实施

日期：2026-11-12。作为 [`docs/art/toy/README.md`](../toy/README.md) 的场景几何深化方案，针对当前地图建筑与道具“只是给直角长方体包了一圈圆角”的造型单薄问题，完成底层管线可行性调研，并在室外地图 `sandgate` 与室内地图 `bb_office` 落地完整样板。

---

## 一、工程可行性调研

对现有全部地图构建脚本（[`tools/maps/arena_kit.py`](../../../tools/maps/arena_kit.py)、[`tools/build_sandgate.py`](../../../tools/build_sandgate.py)、[`tools/build_bb_office.py`](../../../tools/build_bb_office.py) 等）、顶点光烘焙器（[`tools/maps/bake_vertex_light.py`](../../../tools/maps/bake_vertex_light.py)）和运行时材质装配器（[`scripts/maps/map_lookdev.gd`](../../../scripts/maps/map_lookdev.gd)）排查后，确认方案**完全可行，且零碰撞与导航回退风险**，但必须先解决以下四个底层症结：

| 症结 | 代码根因 | 解决方案 |
| --- | --- | --- |
| 导出阶段丢弃倒角与法线 | 各构建器 `export()` 使用 `mesh.from_pydata()` 重新拼合裸网格，未做倒角且丢弃光滑组与自定义法线 | 新增共用模块 [`tools/maps/toy_kit.py`](../../../tools/maps/toy_kit.py)，按构件真实厚度 `体积 / 最大面面积` 自动筛选，逐件执行 `1` 段 `bmesh.ops.bevel` 后合并材质，统一施加 `WEIGHTED_NORMAL` 并开启 `export_normals=True` |
| 漆面高光被粗糙度锁死 | `build_sandgate.py` 将材质设为 `Roughness = 1.0`、`Specular = 0.0`；`map_lookdev.gd` 将石材与灰泥锁在 `0.92`，即使倒角也无法产生边缘高光 | 将玩具彩漆粗糙度调整至 `0.44`–`0.62`、石材灰泥调至 `0.68`、木质调至 `0.58`，由加权法线保证大平面哑光平整、倒角窄边承接高光 |
| 顶点烘焙细分破坏自定义法线 | `bake_vertex_light.py` 的 `refine()` 直接切分导入后的三角面，既多产生约 `40%` 碎面，又会冲掉倒角条两侧的加权法线 | 在 `refine()` 前先执行 `bmesh.ops.join_triangles` 还原四边面再做网格切分，切分后清理旧法线并重算 `WEIGHTED_NORMAL` |
| 室内缺少方向性高光光源 | `bb_office` 主光能量仅 `0.18`，全靠无方向环境光照明，立体框线与倒角缺乏明暗转折 | 在 [`scripts/maps/toy_palette.gd`](../../../scripts/maps/toy_palette.gd) 为 `bb_office` 补入侧窗暖色主光（能量 `0.46`），拉开背光面与倒角亮边 |

### 物理碰撞与性能安全边界

1. **视觉与物理完全解耦：** 各场景 `.tscn` 的 `Collision` 与 `NavigationRegion3D`（`PARSED_GEOMETRY_STATIC_COLLIDERS`）完全读取 `tools/maps/*_layout.json` 的简化碰撞盒，不解析视觉 `.glb`。升级建模时保持 `*_layout.json` 零改动，即可保证寻路、护栏、射击视线和狂暴爆破捷径不变。
2. **单段加权倒角与按需跳过：** `1` 段斜切倒角配合平滑着色与 `WEIGHTED_NORMAL(weight=100)`，法线在倒角条两侧连续插值，高光观感接近多段圆角，但面数增量仅为多段圆角的三分之一；同时自动跳过厚度小于 `2.2` 厘米的贴片（地毯砖、纸张、屏幕字符）及远景天际线（`skyline`、`city`）。

---

## 二、五项场景建模原则与概念对照

在不引入手工雕刻与写实贴图、保持 Blender Python 脚本程序化生成的前提下，按以下五项结构规则补齐微缩沙盘精度。

### 1. 三段式建筑截面：消灭光秃直墙交界

墙体不能用单个 `box()` 从地面一通到底，需要拆分为接地勒脚、墙身、分段收顶三层结构，配合顶点烘焙遮蔽稳住体积。

![三段式墙体截面对比](01-three-part-wall.png)

- **底部勒脚 / 踢脚线（`stepped_plinth`）：** 高 `0.18` 至 `0.30` 米，向外微扩 `3` 至 `5` 厘米，使用石材或深色塑料色板把墙体锚定在地面上。
- **墙裙腰线与转角护角柱：** 彩漆墙裙顶部增加外凸腰线（Belt Rail），主要建筑外转角包覆凸出 `4` 至 `5.5` 厘米的转角柱（Pilaster）。
- **分段挑檐压顶（`segmented_coping`）：** 取消整根贯通长条，按 `1.5` 至 `1.75` 米模数切出 `2.6` 厘米拼缝，下衬一层石质挑檐唇边。

### 2. 微锥度与斜切咬合：打破 90 度正交死板感

纯正交（90 度）方块堆叠会产生强烈的工程白盒感。墩柱、门洞扶壁与胸墙引入轻微的上窄下宽锥度，建立稳重的玩具重心。

![微锥度与主次体块咬合对比](02-taper-and-chamfer.png)

- **1 至 4 度微锥度（`tapered_box`）：** 门洞墩柱、扶壁、护栏立柱、女墙垛口顶面内缩 `3%` 至 `10%`，底部配独立柱础垫块。
- **拱门拱顶石（Keystone）：** 拱圈正中石块在径向与厚度方向同时外凸并改用浅亮色，强化入口视觉焦点。

### 3. 内凹深框与注塑分件缝：禁止表面平贴色块

纯色画面没有贴图阴影造假，门窗、隔断如果只是大盒体表面贴薄片，侧面与斜光下会立刻露馅。

![内凹深框与分件接缝对比](03-recessed-openings-and-seams.png)

- **三层深度窗洞（`recessed_window`）：** 深色阴影底板后退 -> 双扇百叶窗居中 -> 周围 `15` 厘米深模压外框与挑出厚窗台板（下带双牛腿托架）前探，在斜射光下形成真实口袋阴影且不与宿主墙面穿插。
- **注塑拼装分件缝：** 室内长墙与工位屏风内衬深色龙骨芯板，外挂按 `1.5` 至 `1.75` 米分块的彩漆面板，留出 `2.4` 至 `2.6` 厘米深色内凹拼缝。

### 4. 薄片改厚体块：补齐骨架与工业箍圈

微缩玩具比例下，薄于 `3` 厘米的零件在 `10` 米外接不住高光。单薄片状物与光滑长管需统一加厚并补齐支撑骨架。

![加厚道具与骨架箍圈对比](04-chunky-props-and-skeleton.png)

- **三段微弧遮阳棚（`cambered_canopy`）：** 改为 `8.5` 厘米厚的三段折弧条纹棚面，前缘挂分片垂边，下方补齐墙面横梁、前檐连杆、微锥木柱与三角斜撑。
- **带箍风管与吊顶灯盘：** 主风管每隔 `2` 米套一圈外凸法兰箍、浅色密封垫圈与四角金色螺栓耳；吊顶条灯增加模压端盖。
- **双面耐看的复古厚框终端机：** 办公室半数工位以显示器背面朝向走廊，将平板薄屏改为带奶油色厚前框、青色阶梯状 CRT 后壳与散热百叶槽的块体造型，正反两面均有玩具剪影。

### 5. 核心玩具套件工作流：共用原语拼装母版模块

将上述结构沉淀为 [`tools/maps/toy_kit.py`](../../../tools/maps/toy_kit.py) 与 [`tools/maps/arena_kit.py`](../../../tools/maps/arena_kit.py) 中的标准原语，围绕每张图出镜率最高的 5 类母版组件（掩体矮墙、拱门门洞、主题摊位、室内工位隔断、管线机械）批量升级。

![五件套微缩沙盘母版示例](05-hero-kit-sheet.png)

---

## 三、已落地样板与实机渲染对比

所有对比图均为 `1600 x 900` 本地实机渲染（左为本次几何升级前的玩具分支状态，右为升级并重烘焙顶点光后的状态）。

### 1. 室外样板：沙门（`sandgate`）

升级范围（[`tools/build_sandgate.py`](../../../tools/build_sandgate.py)）：全部可玩分区建筑立面三段式改造（石质勒脚、彩漆墙裙腰线、转角柱、分段挑檐压顶）、拱门微锥墩柱与凸出拱顶石、`15` 厘米深框百叶窗与牛腿窗台、三段弧面斜撑遮阳棚、彩带陶罐、四面内凹加固货箱，以及下沉广场与平台护墙分段压顶。`tools/maps/sandgate_layout.json` 碰撞与导航数据零改动。

| 起点实战视角（左：升级前 / 右：升级后） | 全景机位（左：升级前 / 右：升级后） |
| --- | --- |
| ![沙门实战视角前后对比](renders/compare-sandgate-play.png) | ![沙门全景视角前后对比](renders/compare-sandgate-view.png) |

单张高清图：[`renders/sandgate-play.png`](renders/sandgate-play.png)、[`renders/sandgate-view.png`](renders/sandgate-view.png)。

### 2. 室内样板：办公室（`bb_office`）

升级范围（[`tools/build_bb_office.py`](../../../tools/build_bb_office.py)）：走廊与会议室紫色隔墙分缝面板化（深色内凹缝、双面踢脚底座、分段顶冠）、三类工位屏风模块化重构（外凸立柱、外扩稳固底座脚、奶油色分段压顶、内嵌软包面板与磨砂窗台）、厚框复古 CRT 显示器（正反双面造型）、微锥桌腿与扶手椅、带垫圈与金色螺栓耳的法兰风管及吊顶灯具端盖。`tools/maps/bb_office_layout.json` 碰撞与导航数据零改动。

| 起点实战视角（左：升级前 / 右：升级后） | 全景机位（左：升级前 / 右：升级后） |
| --- | --- |
| ![办公室实战视角前后对比](renders/compare-bb_office-play.png) | ![办公室全景视角前后对比](renders/compare-bb_office-view.png) |

单张高清图：[`renders/bb_office-play.png`](renders/bb_office-play.png)、[`renders/bb_office-view.png`](renders/bb_office-view.png)。

---

## 四、验证与性能实测

### 自动化验证

已通过以下自动化检查（尚未进行人工完整对局手感试玩）：

- `godot --headless --path . --editor --import`
- `godot --headless --path . --script tests/rules_test.gd`
- `godot --headless --path . --script tests/map_scene_test.gd`
- `godot --headless --path . --script tests/color_material_check.gd`
- `godot --headless --path . --script tests/aim_sights_check.gd`
- `godot --headless --path . --fixed-fps 60 --script tests/sandgate_check.gd`（开局爆头视线、全图巡游路线、高低护栏阻挡、狂暴破墙捷径、终局与重置全部通过）
- `godot --headless --path . --fixed-fps 60 --script tests/bb_office_check.gd`（开局视线、全走廊连通、双经理门破拆、48 张办公桌破坏、6 盏狂暴扫光、电弧与重置全部通过）

### 资源体积与本地渲染性能

测试环境：Apple M4 Pro，Godot 4.7.2 `gl_compatibility`（OpenGL on Metal），窗口 `1280 x 720`（内部视口 `1440 x 810`），VSync 开启，敌人 AI 实时运行、镜头缓慢扫动采样 `8` 秒（`tools/maps/capture_visual_performance.gd`）：

| 地图 | 烘焙后静态建筑三角面 | 模型目录体积 | Draw Calls P50 | 图元数 P50 | 帧间隔 P50 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `sandgate` | `118,006` | `4.7 MB` | `930` | `391,998` | `9.88 ms` |
| `bb_office` | `89,588` | `4.4 MB` | `2,629` | `717,803` | `15.60 ms` |

### 后续推广与合入 `main` 前注意事项

1. **其余地图按同管线铺开：** [`tools/maps/arena_kit.py`](../../../tools/maps/arena_kit.py) 已接入 `export_toy_parts` 选择性单段加权倒角与 `plinth` / `coping` / `taper` 接口，后续重跑 `hogwarts`、`palm_house`、`snowline`、`baggage_below`、`ginza_station`、`rain_market` 构建与烘焙脚本即可直接继承倒角高光，并按每图 5 个核心构件逐步深化轮廓。
2. **高频实例道具减面（Web 预算）：** `bb_office` 静态建筑仅 `8.96` 万面，但场内实例化了 `48` 套高细节工位（含键盘按键、马克杯、手办与多层显示器），使总图元达到 `71.8` 万。合回 `main` 发布 Web 前，建议为 `8` 米外工位桌面小摆件设置 `visibility_range_end` 距离裁剪或合并远景桌面细节。

### 复现命令

```sh
blender --background --python-exit-code 1 --python tools/build_sandgate.py
blender --background --python-exit-code 1 --python tools/maps/bake_vertex_light.py -- sandgate
blender --background --python-exit-code 1 --python tools/build_bb_office.py
blender --background --python-exit-code 1 --python tools/maps/bake_vertex_light.py -- bb_office
godot --headless --path . --editor --import
```
