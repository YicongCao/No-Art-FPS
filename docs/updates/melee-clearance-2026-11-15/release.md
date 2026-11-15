# 发布验证

最终游戏源码为 `e2f1d7dfc5dac0e2bc1f98316d8daa2b29af9a79`，已推送 origin/main；发布快照的工作树干净。小台阶的停距换算和掩体绕路例外均包含在该版本中。

- [正式域名](https://fps.yicong.me/)：`20261115-v4`。healthz 版本、23 份站点文件哈希、WASM/PCK 原始和 Brotli 四份 CDN 文件哈希、CORS、Range、重定向验证通过。见 `custom-http.json`。
- [GitHub Pages](https://yicongcao.github.io/No-Art-FPS/)：[工作流 43719190033](https://github.com/YicongCao/No-Art-FPS/actions/runs/43719190033) 成功，head SHA 与最终游戏源码一致。按线上 manifest 验证 24 个文件的字节数与 SHA-256，见 `pages-http.json`。
- 两个线上入口在桌面 Chrome 的 844×390 触控视口中手动开局、射击，Pages 另验证转向，自定义域名验证暂停。console error / warning 为空。
- `live-custom.jpg` 为正式站点正常对局中近战兵已经接近的画面；`live-pages.jpg` 为 Pages 对局验证。没有开启自动对战基准或无敌。
- 这是桌面浏览器触控模拟，实体手机手感未人工验证。图中的性能读数不是新的手机性能基准。
- `before.png` / `after.png` 为受控 Godot 实际渲染对比；后者已按最终代码重新生成。
- 当前直接前版 `20261115-v3` 保留；优化前的 `20261115-v1` 也仍在，可用既有 activate 流程回滚。未改动 space 开发工作树。
