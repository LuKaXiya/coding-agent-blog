# 🔌 Claude Code 插件体系大全

> 从入门到精通：如何用扩展生态让 Claude Code 效率翻倍

---

## 📖 目录

- [🤔 为什么需要插件？](#-为什么需要插件)
- [🔧 MCP 架构解析](#-mcp-架构解析)
- [🚀 快速开始](#-快速开始)
- [📦 必备插件推荐](#-必备插件推荐)
- [💻 配置与集成](#-配置与集成)
- [🛠️ 自定义 MCP Server](#-自定义-mcp-server)
- [⚡ 高级技巧](#-高级技巧)
- [🐛 常见问题](#-常见问题)

---

## 🤔 为什么需要插件？

Claude Code 本身已经很强，但插件可以：

| 能力 | 原生支持 | 插件扩展 |
|------|----------|----------|
| 代码补全 | ✅ 基础 | ✅ 高级语义补全 |
| 数据库操作 | ❌ | ✅ 直接查询 SQL/NoSQL |
| API 调用 | ❌ | ✅ 轻松接入第三方服务 |
| 文件处理 | ✅ 基础 | ✅ 云存储、压缩、批处理 |
| Git 操作 | ✅ 基础 | ✅ 高级分支分析、changelog |
| 外部工具 | ❌ | ✅ 1Password、Kubernetes、AWS |

---

## 🔧 MCP 架构解析

**MCP (Model Context Protocol)** 是 Anthropic 推出的开放协议，让 AI 能无缝调用外部工具。

### 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code / Claude                 │
└──────────────────────┬──────────────────────────────────┘
                       │ MCP Protocol
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │  MCP    │   │  MCP    │   │  MCP    │
   │ Server  │   │ Server  │   │ Server  │
   │ (Files) │   │ (Git)   │   │ (Cloud) │
   └─────────┘   └─────────┘   └─────────┘
```

### MCP vs 传统 API 调用

| 对比项 | 传统 API | MCP |
|--------|----------|-----|
| 连接方式 | 手动写 HTTP | 自动发现、标准化 |
| 认证 | 每次手动处理 | 可配置持久化 |
| 错误处理 | 各自实现 | 统一协议 |
| 工具定义 | 自定义格式 | JSON Schema |

---

## 🚀 快速开始

### 1. 查看已安装的 MCP

```bash
# 列出可用的 MCP servers
claude mcp list

# 状态检查
claude mcp status
```

### 2. 安装官方 MCP Server

```bash
# 通过 npm 安装
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-git

# 安装 Python 版本
pip install mcp-server-filesystem
```

### 3. 配置 `.clauderc`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

---

## 📦 必备插件推荐

### 1. 📁 文件系统 (`@modelcontextprotocol/server-filesystem`)

**功能**：让 AI 读写指定目录

**使用场景**：
- 读取项目文件分析代码结构
- 批量修改文件
- 生成文件树

```bash
npx -y @modelcontextprotocol/server-filesystem /your/project/path
```

### 2. 🐙 Git (`@modelcontextprotocol/server-git`)

**功能**：Git 操作、changelog 生成、分支分析

**使用场景**：
- 自动生成 CHANGELOG
- 分析开发进度
- 管理分支

```bash
npx -y @modelcontextprotocol/server-git /your/project/path
```

**示例 Prompt**：`分析这个仓库最近 30 天的 commit 情况，生成一份开发总结`

### 3. 📦 GitHub (`@modelcontextprotocol/server-github`)

**功能**：Issues、PRs、Repos 操作

**使用场景**：
- 查看和管理 Issues
- 审核 PRs
- 自动更新状态

```bash
npx -y @modelcontextprotocol/server-github
# 需要 GITHUB_TOKEN 环境变量
```

### 4. 🌲 1Password (`@modelcontextprotocol/server-1password`)

**功能**：安全获取密钥，永不硬编码

**使用场景**：
- 从 1Password 获取 AWS credentials
- 获取数据库密码
- 安全注入敏感信息

```bash
npx -y @modelcontextprotocol/server-1password
```

### 5. ☁️ AWS (`@modelcontextprotocol/server-aws`)

**功能**：S3 操作、Lambda 调用、EC2 管理

```bash
npx -y @modelcontextprotocol/server-aws
```

### 6. ☸️ Kubernetes (`kubernetes-mcp-server`)

**功能**：集群管理、Pod 监控、日志查看

```bash
npm install -g kubernetes-mcp-server
```

---

## 📦 按场景选插件

| 你的需求 | 推荐插件 |
|---------|---------|
| 读写项目文件 | `server-filesystem` |
| Git 操作、生成 changelog | `server-git` |
| 管理 Issues 和 PRs | `server-github` |
| 安全获取密钥 | `server-1password` |
| 操作 AWS 资源 | `server-aws` |
| 管理 Kubernetes | `kubernetes-mcp-server` |
| 操作数据库 | `server-sqlite` 或社区数据库 MCP |
| 发送通知 | `server-slack` 或 `server-email` |

---

## 💻 配置与集成

### 完整 `.clauderc` 示例

```json
{
  "permissions": {
    "allow": [
      "read:all",
      "write:all",
      "exec:all",
      "browser:all"
    ]
  },
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./projects"],
      "description": "项目文件访问"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": {
          "type": "env",
          "name": "GITHUB_TOKEN"
        }
      }
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "."]
    }
  }
}
```

### 环境变量配置

```bash
# .env 文件
GITHUB_TOKEN=ghp_xxxxx
AWS_ACCESS_KEY_ID=AKIAxxxxx
AWS_SECRET_ACCESS_KEY=xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

---

## 🛠️ 自定义 MCP Server

有时候官方插件不够用，可以自己写。

### 1. 创建 MCP Server (Node.js)

```typescript
import { MCPServer } from '@modelcontextprotocol/sdk/server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server-stdio';
import { CallToolRequestSchema } from '@modelcontextprotocol/sdk/types';

const server = new MCPServer({
  name: 'mytool-mcp',
  version: '1.0.0',
  tools: {
    myCustomTool: {
      description: '执行自定义工具',
      inputSchema: {
        type: 'object',
        properties: {
          action: { type: 'string', enum: ['start', 'stop', 'status'] },
          service: { type: 'string' }
        },
        required: ['action', 'service']
      },
      handler: async ({ action, service }) => {
        return {
          content: [{ type: 'text', text: `Service ${service}: ${action} done` }]
        };
      }
    }
  }
});

server.connect(new StdioServerTransport());
```

### 2. 注册到 Claude Code

```json
{
  "mcpServers": {
    "mytool": {
      "command": "node",
      "args": ["./mcp-server-mytool.js"]
    }
  }
}
```

---

## ⚡ 高级技巧

### 1. 多工作区配置

```json
{
  "workspaces": {
    "primary": "./projects/main",
    "secondary": [
      "./projects/shared-lib",
      "./projects/common-utils"
    ]
  }
}
```

### 2. 工具权限控制

```json
{
  "permissions": {
    "allow": [
      "read:projects/**",
      "write:projects/**",
      "exec:projects/**/*.sh"
    ],
    "deny": [
      "exec:sudo *",
      "write:~/.ssh/**"
    ]
  }
}
```

### 3. MCP Server 热重载

修改 `.clauderc` 后不需要重启 Claude Code：

```
/reload
```

### 4. 调试 MCP

```bash
# 查看 MCP 日志
claude mcp debug

# 测试特定 server
claude mcp test --server github
```

---

## 🐛 常见问题

### Q: MCP Server 启动失败？

```bash
# 检查依赖
npm list @modelcontextprotocol/sdk

# 确认 Node 版本
node --version  # 需要 >= 18
```

### Q: 权限被拒绝？

```json
{
  "permissions": {
    "allow": ["read:./**", "write:./**"]
  }
}
```

### Q: GitHub Token 失效？

确保 Token 有 `repo` 权限，刷新后更新环境变量。

### Q: 如何卸载 MCP Server？

从 `.clauderc` 删除对应配置即可。

---

## 🔗 相关资源

- [MCP 官方文档](https://modelcontextprotocol.io/)
- [MCP SDK](https://github.com/modelcontextprotocol/sdk)
- [官方 MCP Servers](https://github.com/modelcontextprotocol/servers)
- [Anthropic Cookbook](https://github.com/anthropics/anthropic-cookbook)

---

## 📝 下一步

- [ ] 搭建私有 MCP Server（连接内部系统）
- [ ] MCP Server 安全加固
- [ ] MCP 性能优化

---

*有问题？欢迎提交 Issue！*
