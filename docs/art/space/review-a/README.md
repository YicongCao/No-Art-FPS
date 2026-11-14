# 月球样片：评审 A

施工分支为 `space`。本目录保留灰盒和基地角落实机证据；飞船、敌人、武器及全场美术要在约定的评审后继续。

## 阶段 1：独立可玩灰盒

- 独立入口 `scenes/moonbase.tscn`，会话 `moonbase_trial`，分数键 `score_moonbase_trial_v1`。原入口与九张地图保留。
- 44 × 48 米环路，双坡道服务平台，8 个开局敌人、12 个补充位置和 6 个复活候选点。基地室内关闭。
- 复用原来的 60 秒计时、45 秒狂暴、射击、换弹、手雷、暂停和结算；隐藏换图及搞怪模式。
- 使用 `tools/maps/build_moonbase.gd -- --grey` 可重建灰盒；不带参数生成美术版。导航从独立简化碰撞烘焙。
- `tools/export_moonbase.py` 导出 `builds/moonbase`，显式递归收集脚本资源，审计最终 PCK。Godot 的仅选中资源导出不会自动包含全部 GDScript preload，已加入显式闭包，避免“导出成功但浏览器解析失败”。

验证：规则测试通过；原生实际渲染完成导航、坡道行走、暂停、完整回合、狂暴、结算和重开检查。Chrome 1280 × 720 连续 61 秒发射/换弹，无脚本错误。灰盒 P95 帧间隔原生 4.51 ms、Web 16.70 ms；两者测量方式不同，不能当作 GPU 时间互相比较。

运行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/moonbase.tscn
python3 tools/export_moonbase.py
python3 -m http.server 8766 --directory builds/moonbase
```

打开 `http://localhost:8766`。本地预览不代表公网发布。
