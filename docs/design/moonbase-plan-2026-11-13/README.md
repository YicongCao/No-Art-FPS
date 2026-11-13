# 月球基地一分钟射击制作策划案

打开 [index.html](index.html) 阅读完整方案。单文件内嵌三张概念图、三套字体、样式、地图示意与交互脚本，约 14.4 MiB；来源链接仅在点击时联网。

当前是制作提案，不是已实现的月球游戏。代码核查基线为 `73f0968`；本次只新增文档，不修改游戏运行时，不发布新的游戏版本。

## 内容

23 章覆盖继承玩法与范围、美术方向与色板、模型比例与机械结构、UV 与贴图、八类材质、月面与天空、光照与反射、灰盒尺寸与路线、地编流程、飞船／基地／氧气设备、两类机甲、第一人称枪械、可破坏物、音效与特效、字体与 HUD、资产台账、性能预算、需求依赖、制作阶段与验收。

36 项需求包含 34 项 P0 与 2 项 P1。优先级、工作域和关键字可以组合筛选；评审勾选只保存在当前浏览器本地，不代表已实施。可导出完整需求 JSON，目录中的 [requirements.json](requirements.json) 是不含浏览器评审记录的静态版本。页面提供打印入口，打印分页未单独制作 PDF 验收。

[preview.png](preview.png) 是桌面首页实拍；[typography-preview.png](typography-preview.png) 是字体交互试排实拍；[mobile-preview.png](mobile-preview.png) 是 390×844 窄屏排版检查。宽表格在自己的容器内横向滚动。

## 文件与验证

- `build_plan.py`：内容、样式与生成器；修改后重新生成 HTML。
- `fonts/`：本报告使用的字体子集及 OFL 许可。它们不是游戏发布用的完整字符集。
- `build-info.json`：图片与原始字体 SHA-256、子集规模、文档体积。
- `static-validation.json`：锚点、唯一 ID、内嵌依赖、中文覆盖与需求依赖检查。
- `export-validation.json`：隔离 JavaScript 环境中的 JSON 导出数据验证。
- [VALIDATION.md](VALIDATION.md)：浏览器检查结果与测试边界。

## 重建

Python 依赖为 `fonttools[woff]` 与 `brotli`。原始字体放在项目忽略的 `artifacts/local/moonbase-plan/`，不重复提交整套 CJK 字库。生成器还使用项目已提交的概念图、`web/Rajdhani-Bold.woff2` 与字体许可。

```sh
python3 -m venv artifacts/local/moonbase-plan/venv
artifacts/local/moonbase-plan/venv/bin/python -m pip install 'fonttools[woff]' brotli
curl --fail --location 'https://raw.githubusercontent.com/google/fonts/main/ofl/oxanium/Oxanium%5Bwght%5D.ttf' --output artifacts/local/moonbase-plan/Oxanium.ttf
curl --fail --location 'https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Medium.otf' --output artifacts/local/moonbase-plan/NotoSansCJKsc-Medium.otf
artifacts/local/moonbase-plan/venv/bin/python docs/design/moonbase-plan-2026-11-13/build_plan.py
```

核对原始输入 SHA-256：

```text
Oxanium.ttf
2ce01d946e1e1ffc8d7eecfffbda8623bedd63eaf811a20488c4b69af45babb0
NotoSansCJKsc-Medium.otf
ca094f6b0001fb048ca39ddd797a0cdb0179e1e55c6561e111c49c3e6a61d7b7
```

上游地址可能随版本更新；若哈希变化，应重新检查度量与许可再重建。子集工具版本和字体时间戳可能改变输出字节，不承诺逐字节复现。

Oxanium：Copyright 2019 The Oxanium Project Authors。Noto Sans CJK SC Medium 的内嵌版权字段：© 2014–2021 Adobe。Rajdhani：Copyright 2014 Indian Type Foundry。许可证全文已随字体保存并内嵌于 HTML。原始字体版权字段在子集中保留。
