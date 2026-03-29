---
layout: post
title: "OpenClaw 命令速查：常用命令全集与场景解释"
date: 2026-03-29 11:20:00 +0800
category: AI编程工具
tags: ["OpenClaw", "CLI", "命令速查", "AI Agent", "教程"]
---

> OpenClaw 是一个运行在终端里的 AI Agent 框架，通过 `openclaw` 这条命令可以完成从配置网关、切换模型、管理会话、发送消息、到定时任务的一切操作。本文把所有常用命令按场景整理成速查表，方便随时查阅。

---

## 一、先搞懂两个核心概念：Gateway 和 TUI

在开始之前，有必要弄清楚 OpenClaw 的架构：

- **Gateway（网关）**：OpenClaw 的核心服务，负责管理 Agent、会话、插件、消息通道等所有运行时组件。可以理解为"AI Agent 的后台服务器"。
- **TUI（终端用户界面）**：连接到 Gateway 的交互界面，你输入 prompt、Agent 回复内容，都在这个界面里进行。

大部分 `openclaw` 命令要么是在**控制 Gateway**（`openclaw gateway *`），要么是在**通过 Gateway 做事情**（`openclaw tui`、`openclaw message`、`openclaw cron` 等）。

---

## 二、最最常用的四个命令

### `openclaw tui` — 进入 Agent 交互界面

```
openclaw tui
```

这是你每天最常用的命令。运行之后会打开一个全屏终端界面，连接到你本机或远程的 Gateway，直接和 AI Agent 对话。

常用选项：

| 选项 | 作用 |
|------|------|
| `--url <url>` | 指定 Gateway WebSocket 地址（默认读配置文件） |
| `--token <token>` | 如果 Gateway 开启了 token 认证，用这个传 token |
| `--password <password>` | 如果 Gateway 开启了密码认证，用这个传密码 |
| `--session <key>` | 指定连接哪个会话，默认 `"main"` |
| `--message <text>` | 连接后自动发一条消息（适合脚本自动化） |
| `--timeout-ms <ms>` | Agent 单次响应超时，单位毫秒 |
| `--thinking <level>` | 覆盖 Agent 的思考深度（off/low/medium/high） |
| `--history-limit <n>` | 加载多少条历史消息，默认 200 条 |
| `--deliver` | 把 Agent 的回复直接发到消息通道（而非只在 TUI 显示） |

**场景举例：**

```bash
# 连接到本地 Gateway，进入对话界面
openclaw tui

# 指定连接到远程 Gateway
openclaw tui --url ws://your-server.com:18789

# 连接时附带 token
openclaw tui --token your-gateway-token

# 连接后自动发一条消息，然后退出（适合脚本）
openclaw tui --message "帮我总结今天的 session 记录"
```

---

### `openclaw dashboard` — 打开 Web 控制台

```
openclaw dashboard
```

运行后会自动用浏览器打开 OpenClaw 的 Web 控制台界面（Control UI）。在这个界面里你可以：

- 查看当前会话列表
- 查看插件状态
- 查看 Gateway 配置
- 手动触发各种操作

常用选项：

| 选项 | 作用 |
|------|------|
| `--no-open` | 只打印 URL，不自动打开浏览器（适合远程服务器无头环境） |

**场景举例：**

```bash
# 本地直接打开浏览器控制台
openclaw dashboard

# 远程服务器上只打印 URL（然后本地浏览器打开）
openclaw dashboard --no-open
```

---

### `openclaw config` — 配置 OpenClaw

`openclaw config` 是一个命令簇，支持多个子命令，是管理 OpenClaw 配置的核心入口：

```
openclaw config [子命令]
```

**子命令一览：**

| 子命令 | 作用 |
|--------|------|
| `openclaw config`（不带参数） | 启动交互式配置向导，逐步引导你完成所有配置 |
| `openclaw config file` | 打印当前激活的配置文件路径 |
| `openclaw config get <dot-path>` | 读取某个配置项（支持点号路径，如 `gateway.mode`） |
| `openclaw config set <dot-path> <value>` | 设置某个配置项的值 |
| `openclaw config unset <dot-path>` | 删除某个配置项 |
| `openclaw config validate` | 校验当前配置是否符合 schema（不启动 Gateway） |
| `openclaw configure` | 交互式安装向导（配置凭证、通道、网关、Agent 默认值） |

**场景举例：**

```bash
# 打印配置文件路径
openclaw config file

# 读取当前使用的模型
openclaw config get agents.defaults.model

# 设置默认模型
openclaw config set agents.defaults.model minimax-portal/MiniMax-M2.7

# 校验配置是否有语法错误
openclaw config validate

# 启动交互式配置向导
openclaw config
```

> 💡 `config set` 和 `config unset` 是最常用的两个写操作。修改配置后 Gateway 会自动重启生效。

---

### `openclaw gateway` — 控制 Gateway 服务

`openclaw gateway` 是管理 OpenClaw 网关服务的命令簇，是运维层面最核心的工具：

```
openclaw gateway [子命令]
```

**子命令一览：**

| 子命令 | 作用 |
|--------|------|
| `openclaw gateway run` | 前台运行 Gateway（调试用，日志直接输出到终端） |
| `openclaw gateway start` | 启动 Gateway 服务（后台常驻，通过 launchd/systemd/schtasks 管理） |
| `openclaw gateway stop` | 停止 Gateway 服务 |
| `openclaw gateway restart` | 重启 Gateway 服务 |
| `openclaw gateway status` | 查看 Gateway 服务状态，并探测连通性 |
| `openclaw gateway health` | 仅获取 Gateway 健康状态 |
| `openclaw gateway probe` | 探测 Gateway 可达性 + 发现 + 健康 + 状态摘要 |
| `openclaw gateway discover` | 通过 Bonjour 发现局域网内的 Gateway（本地 + 广域） |
| `openclaw gateway install` | 把 Gateway 安装为系统服务（launchd/systemd/schtasks） |
| `openclaw gateway uninstall` | 卸载系统服务 |
| `openclaw gateway call <method>` | 直接调用 Gateway 的 RPC 方法（如 `health`、`status`） |
| `openclaw gateway usage-cost` | 从会话日志拉取用量和费用汇总 |

**常用启动选项（`gateway run` / 启动服务时用）：**

| 选项 | 作用 |
|------|------|
| `--port <port>` | 指定 Gateway WebSocket 端口，默认读配置文件 |
| `--bind <mode>` | 绑定模式：`loopback`（仅本机）、`lan`（局域网）、`tailnet`（Tailscale）、`auto` |
| `--auth <mode>` | 认证模式：`none`、`token`、`password`、`trusted-proxy` |
| `--token <token>` | 指定共享 token |
| `--password <password>` | 设置密码认证 |
| `--force` | 启动前先 kill 占用目标端口的进程 |
| `--dev` | 开发模式：配置和状态隔离到 `~/.openclaw-dev`，默认端口 19001 |
| `--verbose` | 输出详细日志到 stdout/stderr |
| `--raw-stream` | 把模型流式输出记录到 jsonl 文件 |
| `--tailscale <mode>` | Tailscale 暴露模式：`off`、`serve`、`funnel` |

**场景举例：**

```bash
# 前台调试运行（日志直接打印到终端，Ctrl+C 停止）
openclaw gateway run

# 带详细日志前台运行
openclaw gateway run --verbose

# 指定端口强制启动（先 kill 占用端口的进程）
openclaw gateway run --port 18789 --force

# 开发模式（隔离配置，不影响正式环境）
openclaw --dev gateway run

# 查看 Gateway 服务状态
openclaw gateway status

# 探测连通性（本地 + 远程）
openclaw gateway probe

# 直接调用 Gateway RPC 查看健康状态
openclaw gateway call health

# 把 Gateway 安装为系统服务（Linux systemd）
openclaw gateway install

# 重启 Gateway 服务
openclaw gateway restart

# 停止 Gateway 服务
openclaw gateway stop
```

---

## 三、日常运维高频命令

### `openclaw status` — 查看整体状态

```
openclaw status
```

一键查看所有通道（WhatsApp、Telegram、Discord、Slack、Signal 等）的连接状态，以及最近活跃的会话。是最常用的"系统有没有问题"快速检查命令。

| 选项 | 作用 |
|------|------|
| `--deep` | 深入探测各通道（WhatsApp Web + Telegram + Discord + Slack + Signal） |
| `--usage` | 显示各模型提供商的用量 / 配额快照 |
| `--json` | 输出 JSON 格式（方便脚本处理） |
| `--all` | 完整诊断模式（只读，可直接复制粘贴） |
| `--timeout <ms>` | 探测超时时间，默认 10000ms |

**场景举例：**

```bash
# 快速检查
openclaw status

# 深入探测所有通道
openclaw status --deep

# 查看模型用量
openclaw status --usage

# 完整诊断（结果可分享）
openclaw status --all
```

---

### `openclaw doctor` — 自动诊断 + 修复问题

```
openclaw doctor
```

运行一系列健康检查，检测 Gateway 和各通道的配置问题，并给出修复建议。发现问题后可以自动修复。

| 选项 | 作用 |
|------|------|
| `--fix` / `--repair` | 应用推荐修复（需要确认） |
| `--force` | 激进修复（会覆盖自定义配置） |
| `--generate-gateway-token` | 生成并配置一个 Gateway token |
| `--deep` | 扫描系统额外 Gateway 安装 |
| `--non-interactive` | 不提示，直接执行安全迁移 |

**场景举例：**

```bash
# 诊断问题（只读）
openclaw doctor

# 自动修复发现的问题
openclaw doctor --fix
```

---

### `openclaw logs` — 查看 Gateway 日志

```
openclaw logs
```

通过 RPC 实时拉取 Gateway 的文件日志，不用 SSH 到机器上。

```bash
# 实时查看日志
openclaw logs

# 可以配合其他工具过滤
openclaw logs | grep ERROR
```

---

### `openclaw update` — 更新 OpenClaw

```
openclaw update [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `openclaw update run` | 执行更新（更新依赖或 git，然后重启） |
| `openclaw update`（查看状态） | 检查当前更新通道和版本状态 |

> ⚠️ 更新前建议确认没有正在运行的长任务。

---

## 四、消息与通道管理

### `openclaw message` — 发送和管理消息

```
openclaw message [子命令]
```

这是通过 OpenClaw 向外发消息的核心命令，子命令非常丰富：

| 子命令 | 作用 |
|--------|------|
| `send` | 发送文本消息 |
| `read` | 读取最近的聊天记录 |
| `broadcast` | 向多个目标广播同一条消息 |
| `search` | 搜索消息（Discord） |
| `poll` | 发送投票 |
| `react` | 添加 / 移除 emoji 反应 |
| `pin` / `unpin` | 置顶 / 取消置顶消息 |
| `delete` | 删除消息 |
| `edit` | 编辑已发送的消息 |
| `ban` / `kick` / `timeout` | 管理群成员 |
| `role` | 变更角色 |
| `thread` | 线程操作 |

**场景举例：**

```bash
# 给手机号发短信（通过 webchat 或配置的通道）
openclaw message send --target +15555550123 --message "任务完成了"

# 通过 Telegram 机器人发消息
openclaw message send --channel telegram --target @mychat --message "Hello"

# 发送带图片的消息
openclaw message send --target +15555550123 --message "截图如下" --media photo.jpg

# 发送投票（Discord）
openclaw message poll --channel discord --target channel:123 \
  --poll-question "午饭吃什么？" \
  --poll-option 披萨 --poll-option 寿司

# 对消息添加 emoji 反应
openclaw message react --channel discord --target 123 --message-id 456 --emoji "✅"
```

---

### `openclaw channels` — 管理聊天通道

```
openclaw channels [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `openclaw channels login` | 登录聊天通道（如 WhatsApp Web）并显示 QR 码 |
| `openclaw channels list` | 列出所有已连接 / 已配置的通道 |
| `openclaw channels status` | 查看各通道状态 |

```bash
# 登录 WhatsApp Web（显示 QR 码 + 连接日志）
openclaw channels login --verbose

# 列出所有通道
openclaw channels list
```

---

## 五、Agent 与会话管理

### `openclaw agents` — 管理多个隔离 Agent

```
openclaw agents [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有已配置的 Agent |
| `add` | 添加一个新的隔离 Agent |
| `delete` | 删除一个 Agent 及其工作区 / 状态 |
| `set-identity` | 更新 Agent 的身份（名称 / 主题 / emoji / 头像） |
| `bind` | 添加路由绑定（让特定条件匹配到指定 Agent） |
| `unbind` | 移除路由绑定 |
| `bindings` | 列出所有路由绑定规则 |

```bash
# 列出所有 Agent
openclaw agents list

# 添加一个新 Agent
openclaw agents add my-agent

# 设置 Agent 身份
openclaw agents set-identity my-agent --name "代码助手" --emoji "🤖"
```

---

### `openclaw sessions` — 管理会话历史

```
openclaw sessions [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `openclaw sessions`（列出） | 列出所有会话 |
| `cleanup` | 清理会话存储 |
| `--agent <id>` | 查看指定 Agent 的会话 |
| `--all-agents` | 聚合所有 Agent 的会话 |
| `--active <minutes>` | 只显示最近 N 分钟有活动的会话 |
| `--json` | JSON 格式输出 |

```bash
# 列出所有会话
openclaw sessions

# 列出最近 2 小时有活动的会话
openclaw sessions --active 120

# 查看某个 Agent 的会话
openclaw sessions --agent work

# 聚合所有 Agent 的会话
openclaw sessions --all-agents

# 机器可读格式
openclaw sessions --json
```

---

### `openclaw memory` — 搜索记忆文件

```
openclaw memory [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `search <query>` | 搜索记忆文件 |
| `status` | 查看记忆索引状态 |
| `index --force` | 强制重新索引 |

```bash
# 搜索记忆
openclaw memory search "项目会议"

# 查看索引状态
openclaw memory status

# 强制重建索引
openclaw memory index --force
```

---

### `openclaw agent` — 单次调用 Agent（不走 TUI）

```
openclaw agent --message "你的 prompt"
```

不走 TUI 界面，直接调用 Agent 返回结果，适合脚本或一次性任务。

| 选项 | 作用 |
|------|------|
| `--message <text>` | 传入的 prompt |
| `--to <target>` | 指定发送目标（如手机号、channel ID） |
| `--deliver` | 把 Agent 回复发到消息通道 |
| `--session <key>` | 指定会话 |
| `--timeout-ms <ms>` | 超时毫秒数 |

```bash
# 单次调用，结果打印到终端
openclaw agent --message "帮我总结今天的笔记"

# 调用后把结果发到 WhatsApp
openclaw agent --to +15555550123 --message "运行日报生成" --deliver
```

---

## 六、插件、Hooks 与扩展

### `openclaw plugins` — 插件管理

```
openclaw plugins [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有已发现的插件 |
| `install` | 安装插件（支持路径、压缩包、npm 包名） |
| `uninstall` | 卸载插件 |
| `enable` | 启用插件（在配置中开启） |
| `disable` | 禁用插件 |
| `info` | 查看插件详情 |
| `doctor` | 报告插件加载问题 |

```bash
# 列出所有插件
openclaw plugins list

# 安装插件
openclaw plugins install ~/.openclaw/my-plugin

# 查看插件详情
openclaw plugins info my-plugin

# 诊断插件问题
openclaw plugins doctor
```

---

### `openclaw hooks` — 管理 Agent Hooks

```
openclaw hooks [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有已安装的 hooks |
| `info` | 查看 hook 详情 |
| `enable` | 启用 hook |
| `disable` | 禁用 hook |
| `install` | 安装 hook 包 |
| `update` | 更新 hook（仅限 npm 安装的） |
| `check` | 检查 hooks  eligibility 状态 |

```bash
# 列出所有 hooks
openclaw hooks list

# 查看 hook 详情
openclaw hooks info my-hook

# 禁用某个 hook
openclaw hooks disable my-hook
```

---

## 七、定时任务与系统事件

### `openclaw cron` — 定时任务管理

```
openclaw cron [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有定时任务 |
| `add` | 添加新定时任务 |
| `update` | 修改已有定时任务 |
| `remove` | 删除定时任务 |
| `run` | 立即触发某个定时任务 |
| `runs` | 查看任务运行历史 |
| `status` | 查看调度器状态 |

定时任务支持多种调度方式：一次性时间（`at`）、循环间隔（`every`）、Cron 表达式（`cron`）。

---

### `openclaw system` — 系统事件与心跳

```
openclaw system [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `event` | 注入一个系统事件并可选触发心跳 |
| `heartbeat` | 心跳控制 |
| `presence` | 列出系统存在条目 |

---

## 八、模型管理

### `openclaw models` — 模型配置

```
openclaw models [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有已配置的模型 |
| `status` | 显示当前模型的配置状态 |
| `set` | 设置默认模型 |
| `set-image` | 设置图片生成模型 |
| `aliases` | 管理模型别名 |
| `auth` | 管理模型认证配置 |
| `scan` | 扫描 OpenRouter 免费模型（支持 tools + 图片） |
| `fallbacks` | 管理模型降级列表 |
| `image-fallbacks` | 管理图片模型降级列表 |

```bash
# 列出所有模型
openclaw models list

# 查看当前模型状态
openclaw models status

# 设置默认模型
openclaw models set minimax-portal/MiniMax-M2.7

# 设置图片生成模型
openclaw models set-image minimax/Imagen3

# 扫描 OpenRouter 免费模型
openclaw models scan
```

---

## 九、其他实用命令

### `openclaw docs` — 快速查文档

```
openclaw docs [查询词]
```

直接在终端搜索 OpenClaw 官方文档，不需要开浏览器。

```bash
# 搜索 gateway 相关的文档
openclaw docs gateway config

# 查看 tui 命令文档
openclaw docs tui
```

---

### `openclaw browser` — 浏览器自动化

```
openclaw browser [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `openclaw browser start` | 启动专用浏览器 |
| `openclaw browser stop` | 停止浏览器 |
| `openclaw browser snapshot` | 截图当前页面 |
| `openclaw browser screenshot` | 全页截图 |
| `openclaw browser act` | 执行 UI 操作（点击、输入等） |

```bash
# 启动浏览器
openclaw browser start

# 全页截图
openclaw browser screenshot --path screenshot.png

# 对页面执行操作
openclaw browser act --ref 1 --kind click
```

---

### `openclaw pairing` / `openclaw devices` — 设备配对

```
openclaw pairing [子命令]
openclaw devices [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `pairing list` | 列出待配对请求 |
| `pairing approve` | 批准配对请求 |
| `pairing reject` | 拒绝配对请求 |
| `devices list` | 列出已配对设备 |
| `devices remove` | 移除设备 |
| `devices revoke` | 撤销设备令牌 |
| `qr` | 生成 iOS 配对 QR 码 / 设置码 |

```bash
# 生成配对 QR 码
openclaw qr

# 列出已配对设备
openclaw devices list

# 批准一个配对请求
openclaw pairing approve <request-id>
```

---

### `openclaw backup` — 数据备份

```
openclaw backup [子命令]
```

| 子命令 | 作用 |
|--------|------|
| `openclaw backup create` | 创建本地备份归档 |
| `openclaw backup verify` | 验证备份完整性 |

```bash
# 创建备份
openclaw backup create

# 验证备份
openclaw backup verify
```

---

### `openclaw security` — 安全审计

```
openclaw security [子命令]
```

运行本地安全审计，检查配置风险、权限问题、暴露面等。

```bash
# 安全检查
openclaw security audit
```

---

### `openclaw onboard` — 交互式引导安装

```
openclaw onboard
```

启动交互式向导，引导你完成 Gateway、工作区、Skills 的初始配置。适合第一次安装或重置后首次启动。

---

## 十、一图流速查表

| 场景 | 推荐命令 |
|------|---------|
| 进入对话界面 | `openclaw tui` |
| 打开 Web 控制台 | `openclaw dashboard` |
| 修改配置 | `openclaw config set <path> <value>` |
| 启动 Gateway | `openclaw gateway start` |
| 前台调试 Gateway | `openclaw gateway run --verbose` |
| 查看运行状态 | `openclaw status` |
| 诊断问题 | `openclaw doctor --fix` |
| 查看日志 | `openclaw logs` |
| 发消息 | `openclaw message send --target <xxx> --message "..."` |
| 管理定时任务 | `openclaw cron list` |
| 切换默认模型 | `openclaw models set <model>` |
| 搜索记忆 | `openclaw memory search <query>` |
| 管理插件 | `openclaw plugins list` |
| 备份数据 | `openclaw backup create` |
| 查文档 | `openclaw docs <关键词>` |

---

## 十一、总结

OpenClaw 的命令设计非常清晰，所有操作都通过 `openclaw` 这一条主命令驱动：

- **配置相关**：`openclaw config *`
- **Gateway 运维**：`openclaw gateway *`
- **日常交互**：`openclaw tui`、`openclaw dashboard`
- **消息通道**：`openclaw message *`、`openclaw channels *`
- **Agent 与会话**：`openclaw agents *`、`openclaw sessions *`、`openclaw memory *`
- **定时与自动化**：`openclaw cron *`、`openclaw system *`
- **扩展能力**：`openclaw plugins *`、`openclaw hooks *`
- **辅助工具**：`openclaw browser`、`openclaw docs`、`openclaw doctor`、`openclaw backup`

掌握这些命令，就足够熟练操作 OpenClaw 的方方面面了。

---

*文档版本：OpenClaw 2026.3.13*
