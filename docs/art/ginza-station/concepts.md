# 东京银座站地图概念图

虚构的东京地铁银座站换乘层，内置 imagegen 生成。先以行李转盘和雪线天文台的实机截图为画风参考生成站台初稿，固定站名牌、线路色和站台设施，其余三张以初稿与鸟瞰为参考。鸟瞰是布局基准。

- [上帝鸟瞰图](overview.png) · 南北向长箱体。由西向东依次是丸之内线换乘通道、停着银座线列车的西轨道、中央岛式站台、空的东轨道和出口检票大厅。北侧和中部各有一座跨线天桥，用楼梯落到三条地面带。
- [岛式站台](platform.png) · 站名牌“銀座 G09”两侧是京橋和新橋，黑底琥珀色发车屏，橙色线路色带的瓷砖柱，半高站台门和黄色盲道。
- [出口检票大厅](exit-gates.png) · 自动检票机、售票机、站务室窗口，楼梯通向天桥，远处是黄色出口 A2 和日比谷线换乘牌。
- [通过列车 · 狂暴](passing-frenzy.png) · 照明切到红色警示灯，回送列车从东轨道高速通过，发车屏显示“通過 注意”。扶梯旁的工事中围挡被打碎，打开一条捷径。

## 日本地铁辨识元素

银座线橙色 G 线路符号与站号 G09，站名牌的相邻站标注，黄色点状和条状盲道，半高站台门与车厢位置编号，琥珀色 LED 发车屏，黄色出口牌与出口编号，丸之内线红色 M 和日比谷线银色 H 换乘牌，自动检票机与 IC 读卡面板，触屏售票机和票价图，站务室窗口，投币储物柜，红白自动售货机，站台小卖部，分类垃圾箱，橙色连排座椅，白底绿白斜纹的工事中围挡，隧道口红绿信号灯，柠檬黄车身的银座线列车。

## 白模取舍

- 两座天桥高 3.6 m，楼梯坡度约 21°。中央站台的两组楼梯和扶梯都朝向天桥，站台两侧各留 2.5 m 以上通道，天桥下方地面贯通。
- 两侧通道靠外墙各有两段直梯，形成站台、天桥、侧通道之间的多重回路。
- 轨道下沉 1.1 m，站台门碰撞做到 2.4 m，避免玩家跳进轨道。停着的列车只作视觉与挡弹，不进入导航。
- 检票机通道放宽到 1.2 m，保证寻路可通过。
- 狂暴破口是站台东侧通道中的工事中围挡，打碎后不必绕到站台另一侧。
- 站内日文标识用 Glow Sans 字形轮廓生成 SVG，不依赖运行时字体。

## 生成提示词

共用要求：

> Use case: stylized-concept. Produce ONE standalone landscape 16:9 game environment concept for No-Art-FPS. Match the in-game references' Godot low-poly geometry, crisp thin dark outlines, broad flat color planes, simple textures and bold playable cover. Buildable scale, graphic clarity. No characters, people, weapons, HUD, legend, arrows, captions, watermark, extra panels. No photorealism.

**岛式站台（初稿）**

> Fictional stylized Tokyo Metro "Ginza Station" (銀座駅) underground transfer station, late evening, bright fluorescent interior. Camera: eye level standing on a wide island platform, looking lengthwise along it. Pale grey terrazzo with continuous yellow tactile paving along both edges; waist-high platform screen doors with numbered car-position plates and door lamps. Behind the left doors a stopped lemon-yellow and orange Ginza Line train; on the right an empty track with a tunnel mouth and signal. Square columns in cream tiles with an orange line-color band and a G roundel. A stair and escalator pair rising to an upper concourse. Hanging LED departure board, station name sign 銀座 with "Ginza G09" and neighbors 京橋 and 新橋, yellow 出口 signs. Orange bench seats, red and white vending machines, a kiosk, a three-bin recycling station. Palette: Ginza orange, Marunouchi red accents, cream tile, cool grey, yellow tactile strips, deep navy tunnel.

**上帝鸟瞰图**

> God's-eye cutaway, tilted about 60-65 degrees downward from the south-east, no sky, ceiling removed like an architectural model. From west to east: a west transfer passage for the Marunouchi Line with coin lockers, vending machines, ticket machines and a construction hoarding; a west track pit with a parked Ginza Line train; the central island platform with screen doors, columns, benches, kiosk and two stair blocks (one with escalators) rising to two pedestrian bridge concourses spanning both tracks; an empty east track with tunnel mouths and red signals; an east exit concourse with automatic ticket gates, a station office window, ticket machines and a yellow 出口 exit stair. Each bridge also lands by long straight stairs into both side passages.

**出口检票大厅**

> Standing in the east exit concourse looking north. Grey automatic ticket gates with blue IC readers, green arrows and red no-entry marks; ticket machines under a fare map; station office window 駅事務室; the long stair to the upper bridge; tiled partition with advertising light boxes; yellow 出口 A2 sign and a silver Hibiya Line 日比谷線 transfer sign; yellow tactile guide line; recessed square ceiling lights.

**通过列车 · 狂暴**

> Frenzy phase on the island platform near its east edge, looking south along the east track. An out-of-service 回送 train in silver with an orange stripe blasts through behind the platform screen doors, lit window band smeared into streaks. Emergency lighting: most tubes dark, red rotating beacons; door lamps red; LED board shows red 通過 注意. A white 工事中 construction hoarding beside the escalator block shot apart into angular shards and a toppled barrier, opening a shortcut lane. Effects local and passage readable.
