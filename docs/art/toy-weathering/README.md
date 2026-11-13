# 十二张地图风格化微缩沙盘做旧（Stylized Diorama Weathering）

日期：2026-11-13，分支：`toy`（仅本地客户端，不发布 Web）。解决 12 张地图建筑、地面与道具“太平滑、太崭新”的问题，在不引入写实高频脏乱贴图、零新增纹理内存（复用已驻留 `512 x 512` `surface_noise.png`）、零额外 Draw Call 且严守“远看干净大色块、近看丰富使用痕迹”美术规则的前提下，为全图建立统一的玩具沙盘手涂做旧体系。

---

## 一、核心做旧机制（四大场景着色器统一升级）

覆盖 [`assets/shaders/toy_paint.gdshader`](../../../assets/shaders/toy_paint.gdshader)、[`assets/shaders/map_surface.gdshader`](../../../assets/shaders/map_surface.gdshader)、[`assets/shaders/wall_paint.gdshader`](../../../assets/shaders/wall_paint.gdshader) 与 [`assets/shaders/market_surface.gdshader`](../../../assets/shaders/market_surface.gdshader)：

1. **真实 3D 倒角干扫掉漆（Dry-Brushed Bevel Edge Wear）：** 利用世界法线曲率梯度 `length(fwidth(world_normal)) / length(fwidth(world))` 自动捕捉此前在 12 张地图中建好的 3D 倒角、肋条、窗框与压顶边缘，结合笔触遮罩在 `14`–`42` 米近中景浮现不连续的浅色底漆磨白（金属件露出亮银钢边，彩漆与石木露出暖白粉化边），远景自动淡出以保持干净色块。
2. **接地飞溅渍迹与烘焙暗角积尘（Base Splash & AO Crevice Grime）：** 墙根 `0.45`–`0.70` 米内按地图气候叠加上返泥沙、青苔或踢擦痕迹，并与静态建筑的离线烘焙顶点遮蔽（`COLOR.rgb`）联动，使污渍自然沉淀在墙角、檐下与台阶根部；货场喷绘壁画（`SECTOR 01`、`WAREHOUSE`）边缘同步做轻微斑驳剥落。
3. **立面雨水流挂与顶部日晒褪色（Vertical Drip Streaks & Sun-Chalking）：** 在垂直立面拉伸竖向水渍/锈迹条纹，朝上平面做柔和的日晒粉化与手涂色温起伏。
4. **地面动线踩踏与粗糙度破光（Traffic Scuffs & Roughness Breakup）：** 打破恒定粗糙度造成的“全新注塑反光”，污渍区转为哑光，常摩擦的棱角与通道地面微抛光，配合极克制的余切微浮雕打碎死板直线高光。

---

## 二、逐地图主题化风化色板（`scripts/maps/toy_palette.gd`）

每张地图通过 `weather: [wear_amount, grime_tint, edge_tint, streak_amount]` 注入专属环境故事感：

| 地图 | 风化强度 | 接地/流挂渍色 | 棱角磨白底色 | 场景风化特征 |
| --- | ---: | --- | --- | --- |
| `score_attack` (`yard`) | `0.82` | 铁锈棕褐 `543f30` | 暖米底漆 `faf1dc` | 集装箱棱角掉漆、叉车道磨损、墙面涂鸦斑驳 |
| `sandgate` | `0.84` | 沙漠赭石 `7e5e3d` | 日晒白垩 `fff5df` | 夯土墙水渍剥落、石墩磨边、沙地风蚀色差 |
| `bb_office` | `0.68` | 灰紫鞋印 `43455c` | 象牙浅底 `f7f3ea` | 工位踢脚擦痕、地毯走廊踩踏路径、风管接缝陈旧 |
| `amusement_park` | `0.76` | 海风暖褐 `64493b` | 奶油褪色漆 `fff2da` | 步道踩踏磨损、售票亭与护栏日晒掉漆 |
| `last_ferry` | `0.88` | 咸湿青灰 `323f50` | 盐霜冷白 `ebf0f6` | 船甲板潮湿水迹、引桥踏板磨边、灯柱与油桶海盐锈蚀 |
| `night_studio` | `0.70` | 舞台炭紫 `2e3145` | 浅灰底漆 `ece9f8` | 演播厅地胶车轮印、声学墙与背景板搬运磕碰边 |
| `hogwarts` | `0.82` | 高地苔藓绿 `3c4932` | 风化砂岩 `f5e2c4` | 城堡石墙青苔雨痕、草坪比赛踩踏斑块、木看台旧化 |
| `palm_house` | `0.78` | 温室湿苔 `35503b` | 白漆粉化 `f6f5e8` | 潮湿红砖底座返碱长苔、铸铁白框冷凝水痕 |
| `snowline` | `0.76` | 冻融岩灰 `4e5f78` | 冰霜冷白 `f2f7ff` | 橙色观测鼓楼冻融流挂、蓝色门柱风雪磨边 |
| `baggage_below` | `0.80` | 橡胶胎痕灰 `3b4250` | 铝白磨边 `f0f3f8` | 橙色员工门框刮擦、混凝土地面与传送带胶轮印 |
| `ginza_station` | `0.74` | 站台煤灰 `404654` | 米白釉底 `f4f1e8` | 屏蔽门下半部通勤擦痕、水磨石地面与瓷砖缝沉淀 |
| `rain_market` | `0.84` | 海旁潮霉绿 `364238` | 旧灰泥白 `f5ebd8` | 唐楼外墙雨水流挂、海鲜档台底座潮湿磨损 |

---

## 三、十二张地图同机位做旧前后实机对比

以下全部为 `1600 x 900` 本地实机渲染（**左：做旧前微缩沙盘状态 / 右：风格化手涂做旧后状态**），单张高清图保存在 [`renders/`](renders/)。

### 1. 货场（`score_attack`）与 沙门（`sandgate`）

| 货场实战视角 | 沙门实战视角 |
| --- | --- |
| ![货场做旧对比](renders/compare-score_attack-play.png) | ![沙门做旧对比](renders/compare-sandgate-play.png) |

### 2. 棕榈温室（`palm_house`）与 末班渡轮（`last_ferry`）

| 棕榈温室实战视角 | 末班渡轮实战视角 |
| --- | --- |
| ![棕榈温室做旧对比](renders/compare-palm_house-play.png) | ![末班渡轮做旧对比](renders/compare-last_ferry-play.png) |

### 3. 雪线天文台（`snowline`）与 行李层（`baggage_below`）

| 雪线天文台实战视角 | 行李层实战视角 |
| --- | --- |
| ![雪线做旧对比](renders/compare-snowline-play.png) | ![行李层做旧对比](renders/compare-baggage_below-play.png) |

### 4. 银座站（`ginza_station`）与 办公室（`bb_office`）

| 银座站实战视角 | 办公室实战视角 |
| --- | --- |
| ![银座站做旧对比](renders/compare-ginza_station-play.png) | ![办公室做旧对比](renders/compare-bb_office-play.png) |

### 5. 游乐园（`amusement_park`）与 午夜演播室（`night_studio`）

| 游乐园实战视角 | 午夜演播室实战视角 |
| --- | --- |
| ![游乐园做旧对比](renders/compare-amusement_park-play.png) | ![演播室做旧对比](renders/compare-night_studio-play.png) |

### 6. 霍格沃茨（`hogwarts`）与 香港雨市（`rain_market`）

| 霍格沃茨实战视角 | 香港雨市实战视角 |
| --- | --- |
| ![霍格沃茨做旧对比](renders/compare-hogwarts-play.png) | ![香港雨市做旧对比](renders/compare-rain_market-play.png) |

---

## 四、验证与性能实测

- **自动化检查全部通过**（尚未人工完整试玩）：`rules_test.gd`、`color_material_check.gd`、`rain_market_lookdev_check.gd`、`map_scene_test.gd`、`--combat`。
- **渲染性能零负担**：Apple M4 Pro（`1440 x 810` 视口，AI 激活扫镜采样）下，`score_attack` P50 `9.05 ms`、`sandgate` `8.75 ms`、`hogwarts` `8.61 ms`、`palm_house` `8.66 ms`、`ginza_station` `8.77 ms`、`bb_office` `11.58 ms`，纹理显存与 Draw Calls 均无额外增长。
