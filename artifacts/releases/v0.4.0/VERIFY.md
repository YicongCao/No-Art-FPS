# v0.4.0 发布核验

此前最新客户端为 v0.3.0（2026-11-09）。本次 v0.4.0 为喷漆塑料风格的首个桌面正式 Release，已公开并设为 Latest。

- 发布页：https://github.com/YicongCao/No-Art-FPS/releases/tag/v0.4.0
- 标签源码：`75878b2cc39cf5dcb9996383f0856e38a951a5d1`。源码版本与 macOS Info.plist 版本均为 0.4.0。
- Windows x64：PE32+ 架构正确，ZIP CRC 通过，解压内容与导出 EXE/PCK 哈希一致；该 PCK 用 macOS Godot 挂载后确认版本、默认沙城及导航就绪。没有 Windows 运行环境，不报告 Windows 实机通过。
- macOS Universal：x86_64 + arm64；导出 app 和 ZIP 解压 app 均通过严格 ad-hoc 签名校验。使用导出的 app 实际完成启动、选沙城、开局、射击和 Esc 暂停。
- 四个显式附件均为 uploaded，GitHub 服务端 SHA-256、字节数与本地包一致；另有 GitHub 自动提供的两个源码归档。见 `build-validation.json`、`publication.json`。
- 封面为 `sandgate-gameplay.png`，1920×1080，实际 Godot 运行画面，未用概念图替代。截图保留游戏镜头、原有 HUD 和武器；为固定视角拍摄暂停了模拟，不伪造击杀数据。公开发布页内的封面和下载入口均已在浏览器核对，见 `github-release.jpg`。

## Web 同步

- GitHub Pages 工作流 43720603912 成功，按线上 manifest 验证 24 个文件的大小和 SHA-256。
- fps.yicong.me 版本 20261115-v5，23 个站点文件及四个原始/Brotli CDN 文件、CORS、Range 和 healthz 校验通过。20261115-v4 保留可回滚。
- 两站浏览器启动可见。桌面 Chrome 自动化请求鼠标锁时遇到 WrongDocumentError，游戏自动暂停，该路径不报告输入通过。自定义域名改用触控入口后，正常开局、到达结算、再次开局及开火通过，控制台无 error/warning。这不等于实体手机实测。
- 证据：`pages-http.json`、`custom-http.json`。space 开发工作树未改动。

## 复现构建与截图

```sh
godot --headless --path . --editor --import
godot --headless --path . --export-release 'Windows Desktop' builds/windows/No-Art-FPS.exe
godot --headless --path . --export-release macOS builds/macos/No-Art-FPS.app
python3 tools/qa_run.py --script tools/analysis/capture_release_sandgate.gd
cp artifacts/local/release-sandgate-long.png artifacts/releases/v0.4.0/sandgate-gameplay.png
./tools/export_web.sh
```

ZIP 包含启动说明与第三方许可；macOS ZIP 用 ditto 保留 bundle，再解压校验签名。SHA256SUMS.txt 包含两个客户端 ZIP 和截图。GitHub 并发大文件上传迟滞后保留草稿，改用 `GODEBUG=http2client=0 gh release upload` 逐包上传，四个服务端校验值通过后才公开发布。
