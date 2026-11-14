# 月球样片：评审 A

施工分支为 `space`。本目录保留灰盒和基地角落实机证据；飞船、敌人、武器及全场美术要在约定的评审后继续。

## 阶段 1：独立可玩灰盒

- 独立入口 `scenes/moonbase.tscn`，会话 `moonbase_trial`，分数键 `score_moonbase_trial_v1`。原入口与九张地图保留。
- 44 × 48 米环路，双坡道服务平台，8 个开局敌人、12 个补充位置和 6 个复活候选点。基地室内关闭。
- 复用原来的 60 秒计时、45 秒狂暴、射击、换弹、手雷、暂停和结算；隐藏换图及搞怪模式。
- 使用 `tools/maps/build_moonbase.gd -- --grey` 可重建灰盒；不带参数生成美术版。导航从独立简化碰撞烘焙。
- `tools/export_moonbase.py` 导出 `builds/moonbase`，显式递归收集脚本资源，审计最终 PCK。Godot 的仅选中资源导出不会自动包含全部 GDScript preload，已加入显式闭包，避免“导出成功但浏览器解析失败”。

验证：规则测试通过；原生实际渲染完成导航、坡道行走、暂停、完整回合、狂暴、结算和重开检查。Chrome 1280 × 720 连续 61 秒发射/换弹，无脚本错误。最终对照使用单调时钟重测，数据见评审页面；原生与 Web 测量方式不同，不能当作 GPU 时间互相比较。

运行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn
python3 tools/export_moonbase.py
python3 -m http.server 8766 --directory builds/moonbase
```

打开 `http://localhost:8766`。本地预览不代表公网发布。

## 阶段 2：基地角落与评审 A

当前入口：[可视化评审](index.html)。已接入现有基地的主壳、程序化气闸/栏杆/入口坡道，以及箱体、氧气瓶、工业塔、月壤、一次更新反射探针和两盏无阴影局部灯。服务平台与两条可行走坡道独立制作，不把不可玩的装饰网格当作碰撞。

基地导出不减面，仍为 18,757 个三角形；采用小型 Albedo/PBR 参数图集，将 17 个原混合网格变为 3 个游戏网格。统一实验室正面绘制调用 57 → 16，第一人称 64 → 17，细节 72 → 18。新道具也按非发光/发光材质分批；原始基地源不改写，新道具保存 Blender 源文件，脚本负责重复生成。

纹理生成留在制作端。月壤使用低对比 Albedo、法线与 mipmap；不在 Web 片元中运行多层 FBM。不使用水面反射、SSR、体积雾或额外全屏描边。没有新增 Tripo 消费。

验证命令：

```sh
# 重建资产与地图
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/space/trial/build_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/maps/build_moonbase.gd

# 实机截图；只在该截图模式快进到狂暴
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --visual-only

# 完整 60 秒测量，不读回截图；使用单调时钟，不用模拟 delta 当帧耗时
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only

# 规则与 Web
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/rules_test.gd
python3 tools/export_moonbase.py
# 设置 PLAYWRIGHT_MODULE 为本机 Playwright 安装目录，然后运行：
SAMPLE_SECONDS=61 PERF_TRACE=1 NO_SAMPLE_SCREENSHOT=1 node tools/browser/check_moonbase.cjs http://localhost:8766 docs/art/space/review-a/web-corner desktop
node tools/browser/check_moonbase_touch.cjs http://localhost:8766 docs/art/space/review-a/web-touch
python3 docs/art/space/review-a/build_report.py
```

`*-clean-performance.json` 是最终单调时钟数据。早期 `grey-performance.json` 使用 Godot delta 且包含截图，作为历史证据保留，不能拿其最大值与最终采样直接比较。Web RAF 指标与原生帧间隔也不是同一口径。触控验证为桌面 Chrome 的 844 × 390 模拟，不是真机性能测试。

已知边界：飞船、服务站和远山仍为占位；旧机甲、武器、HUD、音效未替换；新道具未接破坏逻辑。道具的微磨损尚未统一到云模型的密度。全场绘制调用仍高于后续 300 次目标，偶发长帧仍需定位：Web 本轮最长约 300 ms，43–44 秒附近仍有 100–117 ms 长帧。没有把 1280 × 720 的结果宣称为 1440 × 810 或手机达标。

按批准的流程在评审 A 停下，确认材质/光照和基地尺度后再进入飞船、机甲与枪械的评审 B。仅提交 `origin/space`，不将该预览覆盖到生产站。
