# No-Art-FPS 地图制作流程

## 1. 锁定参考与动线

每张图保留一张鸟瞰与三张地面采风。鸟瞰决定分区、进出口、高差和回路。地面图分别验收主要地标、另一条路线和狂暴阶段。采风图有位置偏差时，在概念验收页记录取舍。先确定角色从出生点能去哪里，再排道具、补员点与复活点。

本批参考见[三张地图概念验收](../docs/art/next-arenas/concepts.md)。香港雨市以中央摊道、左侧唐楼石阶和右侧送货坡为主。机场以橙色员工门连接到达厅、双传送带和两侧检修天桥。天文台以室内半层环廊、室外雪地和东侧气象平台形成两个可走的回路。

[棕榈温室](../docs/art/palm-house/concepts.md)沿用同一管线：八角玻璃温室、半层树冠栈道和睡莲水渠，外环连接工具场、锅炉房和蝴蝶馆。[东京银座站](../docs/art/ginza-station/concepts.md)是岛式站台加两座跨线天桥的两层车站，日文标识由字体轮廓生成 SVG。

## 2. 拆解 Blender 构件

- 将地形、永久边界、固定建筑、可破坏物和运动组件分开。复用同一鱼档、周转箱等模型，按位置实例化。楼梯可以用台阶外观覆盖连续的斜坡碰撞。
- 为关键地标留独立构件与材质槽。先做大轮廓，再做招牌、扶手、灯具、门框、标线和能在实机机位辨认的道具。可视资产留在 `art_source/`，运行时 GLB 按地图输出至 `assets/models/`。
- 生成器以 Godot 的 Y 向上、Z 为深度为基准，导入 Blender 时换轴。地面、高差、简化碰撞、出生点、灯位及相机和模型由同一生成器输出，避免手工维护两套坐标。

从项目根目录运行本批生成器。

```sh
for map in rain_market baggage_below snowline palm_house ginza_station; do
  blender --background --python-exit-code 1 --python "tools/maps/build_${map}.py" || exit
done
```

## 3. 打包 Godot 场景

导入 GLB 后，由场景生成器读取 `tools/maps/*_layout.json`，创建碰撞、可破坏物、门洞、补员和出生点并烘焙导航。把场景与游戏规则注册到 `data/sessions/`。出入口、坡道落点、连桥、边缘和上层平台要同时通过导航查询与角色实走。

```sh
godot --headless --editor --import
for map in rain_market baggage_below snowline palm_house ginza_station; do
  godot --headless --script tools/maps/save_concept_arena.gd -- "$map" || exit
done
```

固定建筑与地图边界承担安全碰撞。破坏遮挡物时释放对应碰撞，关卡捷径变化时更新导航。每张图配置搞笑道具的独立位置，留够三枚引爆筒、周边走位与射击视线的空间。

角色没有自动上台阶，导航却按体素高度判断可攀爬：烘焙区域从 y = -0.52 起算，0.44 m 的路缘会被量化成一格台阶，导航可以跨过而角色会卡住。拦路的矮墙至少做到 0.6 m，坡道两侧用矮护栏封住侧面。

## 4. 按固定机位打磨

用同一组相机反复截图，优先比较动线和轮廓，然后看画面里的地域道具、对比度和灯光。九张地面截图与三张剖切鸟瞰存入 `artifacts/local/next-arenas/`。每轮保留最终截图并用实机图裁切选图缩略图。

```sh
godot --resolution 1280x720 --script tools/maps/capture_concept_arenas.gd
```

在命令末尾加 `-- palm_house` 之类的地图 ID，只重渲这一张。

本批主要调整了雨市的棚布和湿地反光、机场透明隔墙和传送带侧挡边、天文台旋转穹顶与雪地红光。狂暴模式沿用倒计时规则与地图自己的灯组。每张图验收常态、狂暴启动、暂停、重开和切图复位。

## 5. 验收、提交与发布

```sh
python3 tools/qa_run.py --headless --script tests/rules_test.gd
python3 tools/qa_run.py --headless --fixed-fps 60 --script tests/concept_arenas_check.gd
python3 tools/qa_run.py --headless --fixed-fps 60 --script tests/comedy_toilet_check.gd
python3 tools/qa_run.py --headless --fixed-fps 60 --script tests/map_selector_check.gd
./tools/export_web.sh
```

桌面和横屏触控分别验证选图、加载与进入关卡。自动化角色实走可以证明路线连通，固定机位截图用于判断美术还原，手动对局用于判断战斗节奏。保留 Blender 源件、GLB、碰撞布局、烘焙场景与实机缩略图，分阶段提交并推送。推送后核对 GitHub Pages 构建对应提交，再在公开页面验证新地图可以开局。
