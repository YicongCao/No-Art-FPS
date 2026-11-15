# 发布验证

- 源码：`62ab98a24300c607ca1476d89268a5de8a27c4bf`，已推送 origin/main；发布快照时工作树干净。
- 自定义域名：[fps.yicong.me](https://fps.yicong.me/)，`20261115-v1`。healthz、23 份站点文件哈希、WASM/PCK 普通及 Brotli 共四份 CDN 文件哈希、CORS、Range 请求通过。上一版本 `20261113-v6` 保留，可用原有 activate 流程回滚。
- [GitHub Pages](https://yicongcao.github.io/No-Art-FPS/)：工作流 [43711636514](https://github.com/YicongCao/No-Art-FPS/actions/runs/43711636514) 成功，head SHA 与源码一致。按线上自身 manifest 核对 24 个文件的字节数和 SHA-256，并验证 performance.js 与本地源码匹配。
- Chrome 分别打开两个线上入口，在 844×390 触控视口中实际手动开始沙城并开火；自定义域名另验证暂停。两站未发现 console error / warning。不是实体手机人工游玩，也不是手机 GPU 基准。
- 线上验证的浏览器实际 DPR 为 1，画布 844×390；不要把这些截图的 60 FPS 和模拟 3 倍像素负载的 A/B 基准混为一谈。
- 正式包无 perfbench 特性，不会自动开局或获得无敌；截图中红色边缘是正常受伤反馈。可选诊断仅在 `?perf=1` 显示，普通入口没有额外性能面板。
- 证据：`pages-http.json`、`custom-http.json`、`live-custom.jpg/json`、`live-pages.jpg/json`、`checks.json`。
- space 开发工作树仍在原分支，本次没有发布月球基地内容。
