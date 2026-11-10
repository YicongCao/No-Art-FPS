# 棕榈温室地图概念图

内置 imagegen 生成。先以货场露台和雪线天文台的实机截图为画风参考，生成南侧入口初稿，固定温室、外环和四个附属区的相对位置。其余三张以初稿和鸟瞰为参考。鸟瞰是布局基准，地面图用于看地标、二层动线和狂暴阶段。

- [上帝鸟瞰图](overview.png) · 八角玻璃温室居中，外圈是砂石环路。南侧售票亭与铁门，西侧浇水工具场，北侧育苗棚和红砖锅炉房，东侧蝴蝶馆。
- [南侧入口](forecourt.png) · 从售票前庭看敞开的温室门，内部树冠栈道和睡莲水渠隔着玻璃可见，外环从两侧分开。
- [树冠栈道](canopy-walk.png) · 半层高的薄荷绿栏杆栈道横穿温室，西端楼梯，东端坡道。下方水渠和石板桥把地面分成两条路线。
- [工具场 · 狂暴](tool-yard-frenzy.png) · 日落时温室补光灯转成洋红，喷雾管阵阵喷雾。工具场的育苗架被打散，相邻两块低矮玻璃破开，形成一条进温室的捷径。

场景辨识元素约十六类：白色铁框玻璃穹顶、扇叶棕榈、龟背竹、香蕉叶、睡莲水渠、石板桥、石砌花池、砖砌苗床、喷雾管、湿度表、植物标签牌、绿色水管卷盘、黄铜水龙头、陶盆架、育苗托盘、独轮手推车，外加锅炉烟囱与蝴蝶馆纱门。

## 白模取舍

- 栈道两端都落到外环：西侧楼梯和东侧坡道各穿过一扇侧门。地面图中的栈道转角以鸟瞰的直线东西走向为准。
- 植物只做轮廓。挡子弹的掩体用石砌花池、砖苗床、设备箱和锅炉房，叶片不加碰撞。
- 玻璃用不透明的浅青面板加白框表达，避免大片半透明排序和 Web 端过度绘制。温室下部是砖墙裙，常态只有南北门和东西侧门可进出。
- 狂暴破口固定在西墙一格低玻璃，与工具场的育苗架组成一处可破坏捷径。

## Godot 对照

| 视角 | 实机 |
| --- | --- |
| 剖切鸟瞰 | [实机图](in-engine/overview.png) |
| 南侧入口 | [实机图](in-engine/forecourt.png) |
| 树冠栈道 | [实机图](in-engine/canopy-walk.png) |
| 工具场狂暴与破口 | [实机图](in-engine/tool-yard-frenzy.png) |
| 栈道实战 | [实机图](in-engine/gameplay-deck.png) |
| 霸王龙化石 | [实机图](in-engine/trex-fossil.png) |

实机与概念的差异：破口落在西南面（概念图在西面门旁），以免和西侧楼梯口重叠。室内棕榈压低到穹顶以下，西南象限只留一株小盆棕榈，给破口进来的路线让位。温室中央立着一具瘦高的直立霸王龙化石：石座在栈道北侧的水渠里，长颈后仰，头骨悬在穹顶正中、栈道上方，不挡二层通行。化石只有石座和躯干一根细柱有碰撞，肋骨和头骨不挡子弹。玻璃用运行时透明材质，碰撞仍按实墙处理，透过玻璃能看到但打不穿。

可编辑构件在 [palm_house.blend](../../../art_source/palm_house.blend)。[Blender 构建器](../../../tools/maps/build_palm_house.py)输出 GLB 与关卡布局。Godot 导入后运行 `godot --headless --script tools/maps/save_concept_arena.gd -- palm_house` 烘焙导航，`godot --resolution 1280x720 --script tools/maps/capture_concept_arenas.gd -- palm_house` 重渲固定机位与缩略图原图。

## 生成提示词

共用要求：

> Use case: stylized-concept. Produce ONE standalone landscape 16:9 game environment concept for No-Art-FPS. Match the in-game references' Godot low-poly geometry, crisp thin dark outlines, broad flat color planes, simple textures and bold playable cover. Deliberately buildable scale and graphic clarity. No characters, weapons, HUD, legend, diagram arrows, captions, watermark, or additional panels. No photorealism or painting.

**南侧入口（初稿）**

> Fictional Victorian-style tropical botanical glasshouse park, "Palm House", on a bright sunny late morning. Compact playable block: a central white iron-framed OCTAGONAL glass palm house with a tall faceted dome lantern, the glazing mostly clear/pale aqua panes with white mullions. Inside: a half-storey raised canopy walkway (white steel with mint-green rail) running across the interior on slim columns, with a stair at one end and a ramp at the other; under it a shallow turquoise water channel with a lily pond and a small stone-slab footbridge, splitting the ground floor into two routes. Large faceted low-poly fan palms, monstera, ferns and banana leaves as simple flat-color planes, chunky stone planters and raised brick beds as real cover. Outside ring garden path in warm sand gravel around the glasshouse: south ticket entrance forecourt with wrought-iron gate and plant label boards; north potting shed and brick boiler house with chimney; east a small butterfly house with mesh screen door; west a watering and tool yard with green hose reels, brass taps, terracotta pot racks, seedling trays, wheelbarrow. Palette: saturated emerald and lime foliage, white ironwork, pale aqua glass, terracotta, warm cream stone, turquoise water, small accents of coral and sunflower yellow flowers, bright blue sky with simple low-poly clouds. Camera: eye-level wide view (1.7 m) from the south ticket forecourt looking north into the open glasshouse doors.

**上帝鸟瞰图**

> CRITICAL near-vertical GOD'S EYE, tilted 72-78 degrees downward, NO sky and NO horizon, like an overhead drone over a small scale model. South (ticket gate) at the bottom. Pull back until the whole garden block with its boundary hedge/railing has margin on all four sides. Cut away the glass dome roof and the south half of the octagon walls so the interior reads: the raised mint-railed canopy walkway crossing the interior east-west on slim columns, a stair at its west end and a ramp at its east end that continue OUT through side doors onto the ring path; the turquoise water channel running north-south under the walkway with the lily pond and stone footbridge, splitting the floor into two ground routes. Around it a clearly walkable warm sand gravel ring path. South ticket kiosk, iron gate, forecourt. West watering and tool yard. East small octagonal butterfly house with a path through it. North red brick boiler house with chimney and a potting shed with a glass lean-to. Dense low-poly hedges and palms as boundary.

**树冠栈道**

> Eye-height standing on the raised mint-green-railed canopy walkway inside the octagonal glasshouse, near its west stair top, looking east along the walkway toward the ramp and side door. Below: the turquoise lily channel crossing under the walkway, the stone footbridge, chunky stone planters and brick raised beds, leaving two clear ground routes. Fan palm crowns and banana leaves at eye level, white iron columns and curved glass ribs overhead, misting nozzles on thin pipes, a humidity gauge on a column, hanging plant label tags, stripe shadows of glazing bars. Through the glass, the butterfly house and sandy outer ring path.

**工具场 · 狂暴**

> FRENZY phase at sunset. Eye-height from the west watering and tool yard on the outer sand ring path, looking east-northeast at the octagonal glasshouse. Inside, grow lights switched to vivid magenta and violet glowing through the panes; pulsing jets of white misting spray burst from the rib pipes into angular stylized mist puffs. One wooden seedling rack in the foreground shot apart, scattering terracotta shards, soil clods, seedlings and plant labels; one adjacent pair of low glass wall panes shattered, opening a short shortcut into the interior. Warm orange low sun, long blue shadows on the sand. Effects local and passage readable; the scene is not uniformly dark.

## 配乐

原创 60 秒配乐，128 BPM。马林巴主旋律、卡林巴琶音和指弹贝斯，配轻量桑巴手鼓。第 24 小节（45 秒）进入狂暴变奏，钢鼓加入，琶音和沙锤加倍。由 [build_palm_music.py](../../../tools/build_palm_music.py) 输出可编辑 MIDI 和 Ogg：`cd tools && python3 build_palm_music.py`。
