# 月球基地：概念缺项补齐（D）

本轮承接 `space` 的 `db53cec`，补齐 C 报告中缺失的表面材质、地表与近景岩石、静态接触、外窗、武器近景、专属手雷/手套、字体/HUD 和音色。保持一分钟规则、已批准英雄资产与主要通路。基地室内不在范围内。

[实机对比与逐项需求核对](index.html)。本地 Web 预览为 http://localhost:8766，服务目录 `builds/moonbase`；只在本机服务运行时可访问。没有覆盖 GitHub Pages 或正式域名。

## 实装与验收的区别

原策划案 36 项保留原验收标准，派生核对结果写入 [requirements-audit.json](requirements-audit.json)，不改写历史提案。主要资产和系统已接入；三局人工出生公平性走查、物理移动设备、听感定位、美术最终验收与性能目标仍有未完成项。没有将自动截图等同于人工游玩。

相较概念图，实机的岩层形态、工业细节密度、关节动作、握持、玻璃与接触阴影仍较简化。地球样式背景是程序化风格化行星，非真实地理纹理。当前工程不是写实概念图的逐像素复现。

## 源与生成方式

- `art_source/space/heroes/build_rifle.py`：缩小瞄具，打开能量腔；ADS 轴随资源同步标定。
- `art_source/space/finish/build_finish.py`：在原始环境/设备/武器源副本上完成确定性表面处理，保存可编辑 `.blend`，导出 GLB；另生成四种岩石、手雷与手套。支持 `--asset=lunar-glove` 等单资产导出。原有 Tripo 贴图不再覆盖重画，破坏 Target/Remnant 枢轴不合并。
- `art_source/space/finish/build_regolith.py`：离线生成地表颜色与法线；不增加运行时多层噪声。
- `art_source/space/finish/build_ui_audio.py`：本地字体源裁子集，保存 OFL；原创确定性合成音效和 60 秒音乐，不使用外部音频采样。字体原件位于忽略目录 `artifacts/local/moonbase-plan`，可直接使用已提交的成品子集；许可证来源记录在原策划案 `fonts` 目录。
- `art_source/space/finish/check_ui_audio.py`：翻译表字形覆盖、等宽数字、音频时长与峰值检查。未替代人工耳机听感测试。
- `tools/maps/build_moonbase.gd`：静态接触面、近景岩块、镀膜外窗和预建过载灯。接触面只用于不移动的大型设施，不跟随可破坏目标。

表面处理在 Blender 5.2.2 执行。字体与地表脚本需要 Python 的 `numpy`、`fonttools`、`brotli`；本轮使用本地忽略目录中的虚拟环境。无需再次请求 Tripo、无新增云积分消耗。

## 复现验证

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/maps/build_moonbase.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_heroes_check.gd -- --review-d
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_world_check.gd -- --review-d
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/moonbase_finish_check.gd -- --review-d
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/rules_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/aim_sights_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/grenade_check.gd
# 独立顺序运行：采样时不并行渲染、生成资产或读回截图。
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-d
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn -- --qa --moonbase-check --perf-only --review-d --prop-stress
python3 tools/export_moonbase.py --review d
python3 -m http.server 8766 --directory builds/moonbase
# 另一个终端，设置 PLAYWRIGHT_MODULE 为本机安装位置。
SAMPLE_SECONDS=61 PERF_TRACE=1 NO_SAMPLE_SCREENSHOT=1 node tools/browser/check_moonbase.cjs http://localhost:8766 docs/art/space/review-d/web desktop
node tools/browser/check_moonbase_touch.cjs http://localhost:8766 docs/art/space/review-d/web-touch
python3 docs/art/space/review-d/build_report.py
```

`gameplay` 为 C 同机位主视角，`industrial` / `landing` / `service` / `terrain` / `overview` 由 `moonbase_world_check.gd` 的固定坐标生成。`readability-*` 为相同机甲在 8/15/20 米的采样，不是人工辨识成功率测试。

## 修复记录

- 一块新近景岩石与 Spawn4 重合，地图构建检查拒绝通过；移到边界侧后重新烘焙并验证。
- 持枪白漆与补光偏亮，降低专属材质基础值和灯能量，不改变全场曝光。
- SVG 在绘制函数中临时加载，没有持久引用时出现白块；改为 HUD 初始化后缓存，实际截图恢复正常。
- 手雷体积使用完整世界模型，手持比例单独配置；保持原弹道、碰撞半径与释放时刻，避免缩小世界模型后悬空。
- 外窗收进原窗框，不盖住上方灯条；窗口只表达封闭外立面，不伪造室内。
- 磨损纹理初版产生重复独立法线，改为同资产共享法线，并移除无引用的初版提取文件。

## 性能边界

原生帧间隔来自单调时钟，Web 来自 Chrome RAF，均不是 GPU 时间。普通与集中破坏回合工作量不同，单轮最大值和微小差异不能说明优化收益。旧阶段原始证据保留，D 写独立目录。

下一轮定位绘制调用、关节网格、材质/纹理重复、阴影、首次状态切换及 Web 加载。保留 [C 的优化入口](../review-c/optimization-backlog.md)，26 个 GLB 的实际统计与哈希见 [资产统计](asset-stats.json)。D 增量数据见 [长帧清单](performance-issues.json)、[实际包审计](package-audit.json)。不以删除本轮主要视觉物件作为优化结论。
