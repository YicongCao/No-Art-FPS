# 月球基地：全地图美术与可破坏物

评审 B 已通过，本轮继续扩展地图外景；主入口见 [全图评审页](index.html)。本地 Web 预览为 `http://localhost:8766`，服务目录 `builds/moonbase`。开发仍在 `space`，不覆盖主线生产站。

## 本轮落地

- 原球状山体占位替换为连续 220 × 220 米月面山脊；固定种子的分形地形和制作端烘焙矿物纹理。游玩区域与外围碰撞保持原布局，天体使用风格化球面程序纹理。
- 服务站保持原 5 × 4 米包络，补齐封闭气闸、控制窗、百叶、屋顶散热器、管线、天线和灯。没有新增室内。
- 工业区补横置氧气储罐、箍带、法兰、支撑和圆形管道；原矩形管线占位被替换。
- 围墙模块、太阳能阵列、货箱锁扣/嵌板/搬运孔、停机坪标线和暖色灯具、平台接缝与坡道防滑条补齐。增加三盏无阴影局部灯，沿用既有主光与一次更新反射探针。
- 四类可破坏装置共 8 组 20 个目标：电池架 6 个、阀门 6 个、控制台屏幕 4 个、补给箱舱板 4 个。支持独立残件、电池延迟连锁、阀门短促喷泄、面板火花、两发耐久、狂暴一发、范围破坏、暂停及重开复原。
- 破坏装置不增加击杀分数，不改变敌人伤害，不增加范围伤害爆炸桶；沿用装饰交互目标层，静态掩体和主通路保留。

生产源：`art_source/space/environment/build_environment.py` 和同目录可编辑 Blender 文件。全部新资产程序化生成，新增 Tripo 消费为 0。源模型保留独立构件；运行端只读取 GLB，不在战斗或狂暴中生成这些几何体和纹理。

## 验证命令

```sh
# 制作端与地图重建
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/space/environment/build_environment.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/maps/build_moonbase.gd
# 新场景、真实子弹、残件、连锁、暂停、范围破坏和复原
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_world_check.gd
# 原九图交互回归，证据写入忽略目录，避免改写旧评审材料
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/interactive_props_check.gd -- --space-regression
# 顺序单独运行；采样期间不读取截图、不并行启动其他渲染或资产生成
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-c
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-c --prop-stress
python3 tools/export_moonbase.py --review c
python3 -m http.server 8766 --directory builds/moonbase
# 另一个终端，按本机环境设置 PLAYWRIGHT_MODULE
SAMPLE_SECONDS=61 PERF_TRACE=1 NO_SAMPLE_SCREENSHOT=1 node tools/browser/check_moonbase.cjs http://localhost:8766 docs/art/space/review-c/web desktop
node tools/browser/check_moonbase_touch.cjs http://localhost:8766 docs/art/space/review-c/web-touch
python3 docs/art/space/review-c/build_report.py
```

## 性能口径

普通与压力回合都运行完整 60 秒。压力回合额外在第 12 秒触发全部目标破坏、第 30 秒复原、第 44.4 秒再次触发破坏，以记录其与第 45 秒狂暴的叠加；这不是与普通回合相同工作量的比较。

原生使用单调时钟帧间隔并关闭上限/VSync；Web 使用 Chrome RAF，采样从游戏开始约 1.5 秒后起算。它们都不是 GPU 时间。单轮结果与 AI 路径差异不能用来推断小幅优化收益。桌面触控模拟不代替物理手机性能验证。报告保留完整帧序列、长帧清单、事件时刻、绘制调用与实际 PCK 大小。

定位入口见 [后续优化记录](optimization-backlog.md)。长帧按用户要求仅记录，留到后续集中优化；没有为帧数削弱本轮轮廓、删去主要设备或泛化成低细节代理。

## 画面检查中的修正

- 初版矿物贴图使用多层正弦产生了规律条纹，改为固定种子的频谱噪声。
- 服务站标识最初从字模背面观察导致镜像，按 Blender +Y 正面重新校正。
- 边界原黑色碰撞盒的视觉面被移除，碰撞保留，外观由足够高度的模块化围墙替换。
- 控制台与货箱面板按实际玩家接近方向旋转，目标可从真实无遮挡位置命中；不通过强行穿墙射线证明可用。
- 新增地面补光曾使近处枪械泛白；月球持枪模型改用专用层，场景局部灯只照场景层，保留太阳与持枪专用光。原入口继续使用原层设置。
- 屏幕/指示灯挂在破坏目标下，主体破损时一起隐藏，不残留悬空发光件。
- 破坏反馈的青色大球改为小闪光和细电火花，避免遮住残件和附近敌人。

## 尚未达到概念图的部分

主要场景组成、轮廓与交互已接入，但概念图的微磨损密度、写实月壤、近景岩石、接触阴影仍有明显差距；新程序化资产比基地云模型更干净。统一材质密度和进一步画面精修仍可继续。HUD、字体、音效、手雷造型未在本轮改动，室内没有制作。运行包仍包含共享旧资源依赖，未进行集中资源裁剪、LOD 或批处理优化。
