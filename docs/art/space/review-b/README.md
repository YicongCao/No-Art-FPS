# 月球样片：评审 B

在评审 A 通过后，完成飞船、两类机甲、第一人称离子步枪的实机接入。本目录是本轮实际渲染、交互测试和性能记录；不代表全地图完成或性能验收通过。

入口：[评审页面](index.html)。本地试玩：`http://localhost:8766`，服务目录为 `builds/moonbase`。施工仍在 `space`，不覆盖主线或生产站。

## 完成内容

- 飞船：Tripo 主壳校准朝向与尺度，补程序化三点起落架、翼炮、挂载、警示灯；主壳离线生成碰撞，停机坪独立碰撞；导航重新烘焙。
- 机甲：暖白重装步枪兵、橙色轻装突击兵，切分刚性装甲与关节，复用当前行为和数值；保留头部判定、受伤、爆头、核心露出与死亡反馈。
- 突击兵：独立刀刃与挥刀插槽；蓄力预警通过刀刃闪亮显示，不再引用旧模型整体橙色材质。
- 枪械：程序化装甲、能量腔、枪口、瞄具、弹匣及玩家手臂；独立第一/第三人称导出；按会话资源标定枪口与 ADS 轴；换弹带动弹匣和支撑手。
- 可编辑源、内嵌纹理的归一化输入、生成脚本均保存在 `art_source/space/heroes`；三个任务各 110 credits，总计 330。参考图是设计输入，不是实机截图。

## 验证及复现

```sh
# 实机功能和画面；包含移动、近战各状态、ADS、换弹、实际爆头与狂暴
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_heroes_check.gd
# 游戏导出物的前后视角检查，不同于地图内机位
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_asset_views.gd
# 爆头全流程，包含两类机甲与受伤状态；月球禁用的搞怪模式不强行注入
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/headshot_check.gd -- --moonbase
# 原入口瞄准回归与规则
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/aim_sights_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/rules_test.gd
# 完整原生回合，独立运行，禁止同时进行浏览器渲染或模型构建
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-b
# 独立 Web 导出；默认评审 B，不改写评审 A 证据
python3 tools/export_moonbase.py --review b
python3 -m http.server 8766 --directory builds/moonbase
# 另一个终端，设置 PLAYWRIGHT_MODULE 为本机 Playwright 目录
SAMPLE_SECONDS=61 PERF_TRACE=1 NO_SAMPLE_SCREENSHOT=1 node tools/browser/check_moonbase.cjs http://localhost:8766 docs/art/space/review-b/web desktop
node tools/browser/check_moonbase_touch.cjs http://localhost:8766 docs/art/space/review-b/web-touch
python3 docs/art/space/review-b/build_report.py
```

性能采样不读回截图，使用完整 60 秒原生回合与 61 秒 Web RAF；两者不是 GPU 时间。最终报告列出 P95/P99、最长帧、43–48 秒原生区间、Web 长帧时间列表和包体审计。Web 采样从游戏开始约 1.5 秒后起算，不能直接把 RAF 采样时间当作游戏时钟。单轮结果、AI 路径与可见敌人数不同，不用少量差值宣称优化收益。

## 接入时修复的问题

- 旧突击兵蓄力代码直接修改整体橙色材质；月球保留 PBR 贴图后，该引用为空。增加独立刀刃预警，并验证 WINDUP → SLASH → RECOVER → CHASE；出错轮次不纳入最终数据。
- AI 的静态 A 姿势不能直接套用旧四肢摆动：肩肘/髋膝/脚需要独立枢轴、坐标变换及机械关节遮盖。头壳和躯干也应绕自身中心倾斜，不能绕脚底旋转。
- ADS 测试需要玩家处于允许瞄准的状态；通过关闭玩家物理移动保持机位，而不是禁用玩家。瞄准轴从视觉资源读取，原入口使用原参数。
- 弹匣、支撑手保存静止位置；切换模型或取消换弹后不会将中间姿态重新当作原点。
- 三个新归一化输入 `.blend` 内嵌纹理并纳入版本管理，避免重复装配依赖临时下载地址或另一次付费生成。

## 保留的问题和下一关

本轮只推进到评审 B。远山与服务站仍是代理，场景磨损密度未统一，第一人称枪械较干净，近景关节/握持和换弹还可精修；HUD、字体、音效、手雷与部分效果继续复用原有资源。基地室内仍关闭。完整地编、互动破坏组与全局氛围在后续阶段推进。

长帧只记录，不在本轮集中处理。单机甲网格较多、完整回合绘制调用与 55 MiB 左右 PCK 均仍高于原目标；共有旧资源依赖尚未裁剪。保留下一轮材质/批处理、阴影、重复纹理、状态首次使用和加载链路的定位入口，不提前判断是哪一项造成尖峰。

自动化原生渲染与 Chrome 触控模拟不等于人工游玩，也不等于真机手机性能通过。请主要评审飞船轮廓与尺度、两类机甲的辨识度、武器屏幕占比与材质方向。
