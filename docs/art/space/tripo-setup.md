# Tripo 官方 MCP 接入记录

日期：2026-11-14。本记录不包含 API key、账户身份或余额；余额只在本地与本轮聊天报告，避免提交到公开仓库。

## 已完成

- 通过官方文档指向的 npm 包安装 `tripo-cli@0.11.2`，使用用户目录安装，未改动系统目录权限。
- 本机命令：`/Users/cong/.local/bin/tripo`；Node v26.1.0。
- Chrome 中核对账户站点为 `developers.tripo3d.ai`，使用国际区 `ov` 和命名 profile `moonbase`。
- 用户完成官方设备授权，CLI 自动接收凭据。密钥保存在 `~/.tripo/config.json`，权限 `0600`，不进入项目、MCP 参数或版本控制。
- 在 `~/.codex/config.toml` 新增 `mcp_servers.tripo`，修改前创建私有备份；其余 MCP 保留。
- MCP 使用绝对 Node/脚本路径，参数为 `mcp --toolset full --profile moonbase`，避免 GUI 的 PATH 与终端不同。

## 验证

- `tripo doctor --profile moonbase --json`：认证、API 网络、凭据文件权限和余额检查通过。
- 直接使用配置中的 stdio 启动命令完成 MCP initialize / initialized / tools/list，返回 `tripo-cli 0.11.2`、协议 `2024-11-05`、26 个工具。
- 通过 MCP `tools/call` 调用 `tripo_balance` 成功，结果与 CLI 一致。
- 没有调用生成、上传、纹理、重拓扑、绑定或其他计费任务。
- 本轮聊天的工具列表未验证热加载；若看不到 `tripo_*`，重载 Codex 后再检查。此限制不影响已验证的官方 MCP stdio 服务或 CLI。

本地握手与余额证据在已忽略目录 `artifacts/local/tripo-setup/`。不要提交凭据、登录设备码、私人余额证据或包含签名下载 URL 的完整服务端响应。

## 后续使用

```sh
/Users/cong/.local/bin/tripo doctor --profile moonbase --json
/Users/cong/.local/bin/tripo balance --profile moonbase --json
/Users/cong/.local/bin/tripo mcp --toolset full --profile moonbase
```

最后一条启动 stdio MCP，供客户端连接，不是在终端交互聊天。工具接入不要求 Blender 在线；导入、整理、绑定与 Godot 验收是独立后续步骤。

生成前读取实际工具 schema 与估价，保留任务 ID。超时先查询原任务和冻结额度，不重复提交付费任务。生成及后处理可能分别计费；余额查询成功不能证明建模质量或 Godot 兼容性。

依据：[Tripo CLI](https://developers.tripo3d.ai/en/docs/cli)、[Codex MCP 配置](https://developers.openai.com/codex/mcp)。
