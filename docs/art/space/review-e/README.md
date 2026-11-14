# 枪械、HUD 与地球专项

[实机对比页](index.html)。改造前代码为 `a820da7`。当前工作在 `space`，本轮不合并主线或发布生产站。

## 本轮变化

- 第一人称枪械重新制作大比例、短护木、侧置能量腔、装甲分件、短瞄具座、握把、弹匣及手部；保持原枪口标定和瞄准轴。持枪姿态通过会话视觉配置控制，开镜插值回到原精确轴线。第三人称机甲武器保持已接受版本。
- HUD 使用矢量弹头、准确数字和绘制的无限后备符号，重排顶部数字、橙色分隔与暗色描边。五枚图形各表示四发容量，真实弹匣仍为 20 发。没有生命条，也没有新增有限后备弹药规则。
- 地球采用 NASA 的全球地表与云层合成图，替换程序噪声。地表/云层来源分别记录于 `assets/models/space/earth/SOURCE.txt`；实际 Web 包复制为 `EARTH-IMAGERY-SOURCE.txt`。原始图像不修改，导入生成 mipmap。昼夜和近似蓝色大气边缘由单球体同一不透明着色器计算，不对应实时气象或精确天象。

## 源与可复现性

- `art_source/space/heroes/build_rifle.py` 与 `ion-rifle.blend`：基础构件与可编辑源。
- `art_source/space/finish/build_finish.py --asset=ion-rifle`：材质处理后的源及游戏 GLB；不对已完成的全地图重新加工。
- `data/moonbase_visuals.tres`：第一人称持枪姿态与精确轴线。
- `scripts/hud.gd`、`assets/ui/space-cartridge.svg`、`space-reserve.svg`：专用 HUD。
- `assets/shaders/lunar_earth.gdshader`、`tools/maps/build_moonbase.gd`：地球实际渲染及构建。

基线主视角、ADS、装填和弹量状态在修改前生成，放在 `before/`，实际测试将计时与击杀设为 00:42 / 08 以统一画面。场景与相机不为对比刻意改变；持枪位置和地球半径是本轮调整内容。

地球基线的首个机位曾被玩家相机更新覆盖，已修正测试：把原地图的 OrbitalPlanet 从基线场景复制到检查环境，并通过 player.pitch/rotation 设置镜头；仅重取 `before/earth-detail.png`。两张地球检查图都使用同一 12° 视野，这不是正常游戏的 FOV。不会把看不到目标的截图作为验收证据。

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/space/heroes/build_rifle.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/space/finish/build_finish.py -- --asset=ion-rifle
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/maps/build_moonbase.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_presentation_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_heroes_check.gd -- --review-e
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/rules_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/aim_sights_check.gd
# 原生采样独立运行，不并行生成资源或读取截图。
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-e
python3 tools/export_moonbase.py --review d --review-dir docs/art/space/review-e
# 浏览器检查前启动服务，并按本机环境设置 PLAYWRIGHT_MODULE。
python3 -m http.server 8766 --directory builds/moonbase
SAMPLE_SECONDS=61 PERF_TRACE=1 NO_SAMPLE_SCREENSHOT=1 node tools/browser/check_moonbase.cjs http://localhost:8766 docs/art/space/review-e/web desktop
node tools/browser/check_moonbase_touch.cjs http://localhost:8766 docs/art/space/review-e/web-touch
python3 docs/art/space/review-e/build_report.py
```

仅复现原地球检查时：先 `git show a820da7:scenes/maps/moonbase_trial.tscn > artifacts/local/earth-baseline.tscn`，然后运行 presentation_check 并传入 `-- --baseline-earth`。普通开发不需要这个临时文件。不要在当前资产下运行 `--before` 去覆盖历史前图。

## 验证界限

实机图和自动检查不能替代用户美术评审。原生与 Web 采样均为帧间隔，不是 GPU 时间；单轮数据用于记录增量，非完整性能优化结论。触控模拟不代表真实手机。地编构图、月面和工业细节继续按后续计划推进，本轮不把它们标成完成。
