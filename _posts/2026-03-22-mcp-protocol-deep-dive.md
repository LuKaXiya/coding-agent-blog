---
layout: post
title: "MCP 深度指南：从协议原理到自定义 Server 实战"
date: 2026-03-22
category: MCP生态
tags: ["MCP", "协议", "自定义Server"]
---


> 为什么说 MCP 不只是"接插件"——它是 AI 应用与外部系统交互的通用接口标准

---

## 📖 目录

- [🤔 重新认识 MCP：从"接工具"到"协议层"](#-重新认识-mcp-从接工具到协议层)
- [🔬 MCP 协议架构：四原语详解](#-mcp-协议架构四原语详解)
- [⚖️ 决策树：什么时候真的需要 MCP](#-决策树什么时候真的需要-mcp)
- [🛠️ 自定义 MCP Server 实战（Python + TypeScript）](#-自定义-mcp-server-实战python--typescript)
- [🔗 MCP 在团队协作中的高级模式](#-mcp-在团队协作中的高级模式)
- [🔒 MCP 安全配置最佳实践](#-mcp-安全配置最佳实践)
- [📊 常见 MCP Server 生态盘点](#-常见-mcp-server-生态盘点)

---

## 🤔 重新认识 MCP：从"接工具"到"协议层"

很多人对 MCP 的理解是：**"它是一种让 AI 连接外部工具的协议"**。

这个理解没有错，但只理解了表面。

MCP 的本质是：**一套标准化的上下文交换协议**。它解决的问题不是"AI 怎么调用工具"，而是**"AI 应用和外部系统之间，怎么用统一的方式交换上下文"**。

这个区别很重要。

当你把 MCP 理解为"接工具"，你只会想到"Jira 插件"、"GitHub 插件"。当你把 MCP 理解为"上下文交换协议"，你会想到更多：**数据流如何序列化、如何做能力协商、如何处理实时通知、如何在服务端复用 LLM。**

### MCP 的类比：USB-C 而不是 Lightning

MCP 社区喜欢用 USB-C 做类比：**MCP 之于 AI 应用，就像 USB-C 之于电子设备**。

这个类比为什么贴切？

- **USB-C** 让各种设备（显示器、硬盘、充电器）用同一种接口连接电脑
- **MCP** 让各种数据源（数据库、API、文件系统）用同一种协议连接 AI 应用

更重要的是，这个类比隐含了 MCP 的**设计哲学**：
1. **一次构建，到处运行** — 你的 MCP Server 实现，可以在 Claude Code、VS Code、Cursor、ChatGPT 等任何支持 MCP 的客户端上使用
2. **标准化但可扩展** — 协议定义了标准原语，但具体实现完全自定义
3. **双向通信** — 不只是客户端调用服务端，服务端也可以反过来调用客户端的能力

---

## 🔬 MCP 协议架构：四原语详解

MCP 协议有两个核心层次：**数据层**（JSON-RPC 2.0）和**传输层**（STDIO / Streamable HTTP）。理解四原语（Primitives）是理解 MCP 的关键。

### 原语一：Tools（工具）

**定义**：Server 暴露给 AI 可调用的函数。

这不是普通函数调用——每个 Tool 都有完整的元数据：
- `name`：唯一标识符
- `description`：AI 理解工具用途的依据（AI 通过 description 判断什么时候该调用）
- `inputSchema`：JSON Schema，定义参数类型和约束

```json
{
  "name": "query_database",
  "description": "执行 SQL 查询，返回符合条件的所有记录",
  "inputSchema": {
    "type": "object",
    "properties": {
      "sql": {
        "type": "string",
        "description": "要执行的 SELECT 语句（仅支持查询，不支持写操作）"
      },
      "limit": {
        "type": "integer",
        "description": "最大返回行数",
        "default": 100
      }
    },
    "required": ["sql"]
  }
}
```

**关键设计点**：Tool 的 description 是 AI 理解"什么时候该用这个工具"的唯一依据。description 写得好不好，直接决定 AI 会不会正确调用这个工具。

### 原语二：Resources（资源）

**定义**：Server 暴露给 AI 的只读数据。

与 Tools 的区别：
- **Tools** 是"做某事"（有副作用）
- **Resources** 是"获取数据"（无副作用）

```json
{
  "uri": "project://schema",
  "name": "数据库 Schema",
  "description": "当前项目的完整数据库结构，包括所有表、列和关系",
  "mimeType": "application/json"
}
```

Resources 类似于"文件系统中的文件"，AI 可以读取但不应该修改。典型用途：
- 数据库 Schema（让 AI 理解数据结构）
- 项目文档（让 AI 获取上下文）
- API 规范（让 AI 理解接口契约）

### 原语三：Prompts（提示模板）

**定义**：Server 暴露的可复用的交互模板。

这是 MCP 中最容易被忽视的原语，但它实际上非常强大：

```json
{
  "name": "security_review",
  "description": "对代码变更进行安全审查的标准流程",
  "arguments": [
    {
      "name": "changes",
      "description": "代码变更内容",
      "required": true
    }
  ]
}
```

当 AI 调用这个 Prompt 时，相当于预置了一个专家级的工作流程：
1. 分析变更的安全风险
2. 检查常见漏洞模式
3. 输出结构化的安全报告

Prompts 的价值在于**让团队的最佳实践标准化**——你团队里最厉害的工程师的安全审查逻辑，可以固化成 Prompt，供所有工程师使用。

### 原语四：Sampling（采样）

**定义**：服务端向客户端请求 LLM 完成的能力。

这是 MCP 最独特的设计：**Server 可以调用 Client 的 LLM**。

为什么需要这个？

考虑一个场景：你写了一个代码审查 MCP Server，它本身不内置 LLM，但当它收到一个复杂的代码片段时，需要 LLM 来分析安全性。Sampling 让这个 Server 向 Claude Code 请求 LLM 完成：

```python
# MCP Server 端伪代码
async def analyze_code(security_server, code: str):
    # 向 Client 请求 LLM 分析
    result = await security_server.send_sampling_request(
        prompt=f"分析以下代码的安全漏洞：
{code}",
        model="sonnet"
    )
    return result.completion
```

这样设计的好处：
1. **Server 不需要内置 LLM SDK**：降低 Server 的复杂度
2. **保持模型无关性**：Server 可以对接任何 MCP Client 提供的 LLM
3. **多租户支持**：不同团队用不同的 LLM，但都用同一个 Server

### 传输层：STDIO vs Streamable HTTP

| 维度 | STDIO | Streamable HTTP |
|------|-------|----------------|
| 适用场景 | 本地进程，单用户 | 远程服务，多客户端 |
| 认证方式 | 无 | OAuth / Bearer Token / API Key |
| 延迟 | 极低（无网络）| 有网络延迟 |
| 典型用例 | Claude Desktop | 企业内网服务 |

对于个人开发者，STDIO 就够了。对于团队，建议用 Streamable HTTP + OAuth，便于集中管理和审计。

---

## ⚖️ 决策树：什么时候真的需要 MCP

**核心原则：MCP 有配置成本和维护成本。**

MCP 的成本：
- 配置时间（5 分钟到几小时不等）
- Token 维护（认证会过期）
- 调试成本（出问题要在 Client 和 Server 两端排查）
- 权限管理（MCP 持有你给的权限）

**MCP 值得用的场景：**

```
每天重复"查系统 → 复制 → 粘贴"这个动作 3 次以上？
    → YES：MCP 值得装

需要跨系统关联信息（数据来自两个以上的独立系统）？
    → YES：MCP 值得用

需要 AI 执行系统操作（创建 Issue、合并 PR、写数据库）？
    → YES：MCP 强烈推荐

每次工作流只需要查一次数据，之后再也不查？
    → NO：手动复制粘贴就够了
```

**一个实用的公式：**

```
MCP 价值 = (每天节省的操作次数 × 操作耗时) - (配置时间 + 每周维护时间 / 7)
         > 阈值 → 值得装
```

如果你每天用 Jira 查 ticket 10 次，每次复制粘贴 30 秒：
- 节省：10 × 30s = 300s ≈ 5 分钟/天
- 一周节省：35 分钟
- 只要 MCP 配置加调试时间在 35 分钟以内，就值得

**不值得用 MCP 的场景：**

- 一次性查询（查完再也不查）
- 简单到不值得配置的系统（如查天气）
- 需要极其频繁交互的场景（每次回复都要调用，延迟受不了）
- 你不信任这个 MCP Server 的开发者

---

## 🛠️ 自定义 MCP Server 实战（Python + TypeScript）

下面用一个具体场景演示：构建一个"内部代码库文档 Server"。

### 场景

你有一个内部代码库，包含几十个微服务，每个服务有独立的 README、API 文档和架构说明。你希望 Claude Code 能直接查询这些文档，而不需要你手动复制粘贴。

### Python 实现

```python
# file: internal_docs_server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, Resource
from pydantic import AnyUrl
import json
from pathlib import Path

# 创建 Server 实例
server = Server("internal-docs")

# ========== Tools ==========
@server.list_tools()
async def list_tools() -> list[Tool]:
    """列出所有可用工具"""
    return [
        Tool(
            name="search_docs",
            description="在内部文档库中搜索关键词，返回匹配的文档列表",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "搜索关键词"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "最多返回结果数",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="get_doc",
            description="获取指定文档的完整内容",
            inputSchema={
                "type": "object",
                "properties": {
                    "doc_id": {
                        "type": "string",
                        "description": "文档唯一标识符"
                    }
                },
                "required": ["doc_id"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict) -> str:
    """执行工具调用"""
    if name == "search_docs":
        return search_internal_docs(arguments["query"], arguments.get("limit", 5))
    elif name == "get_doc":
        return get_document_content(arguments["doc_id"])
    else:
        raise ValueError(f"Unknown tool: {name}")

# ========== Resources ==========
DOCS_INDEX = Path("/data/internal-docs/index.json")

@server.list_resources()
async def list_resources() -> list[Resource]:
    """列出所有可用资源"""
    return [
        Resource(
            uri="docs://index",
            name="文档索引",
            description="所有内部文档的索引，包含标题、路径和标签",
            mimeType="application/json"
        )
    ]

@server.read_resource()
async def read_resource(uri: AnyUrl) -> str:
    """读取资源内容"""
    if str(uri) == "docs://index":
        return json.dumps(load_index(), indent=2)
    raise ValueError(f"Unknown resource: {uri}")

# ========== 业务逻辑 ==========
def search_internal_docs(query: str, limit: int) -> str:
    """搜索内部文档"""
    # 这里接入你们的搜索引擎（如 Elasticsearch）
    results = search_engine.query(query, limit=limit)
    return json.dumps(results, indent=2, ensure_ascii=False)

def get_document_content(doc_id: str) -> str:
    """获取文档内容"""
    doc_path = Path(f"/data/internal-docs/{doc_id}")
    if not doc_path.exists():
        raise FileNotFoundError(f"文档不存在: {doc_id}")
    return doc_path.read_text(encoding="utf-8")

def load_index() -> dict:
    """加载文档索引"""
    if DOCS_INDEX.exists():
        return json.loads(DOCS_INDEX.read_text())
    return {"documents": []}

# ========== 启动服务 ==========
async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

### TypeScript 实现

```typescript
// file: internal-docs-server.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

// 创建 Server 实例
const server = new Server(
  {
    name: 'internal-docs',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

// ========== Tools 实现 ==========
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'search_docs',
        description: '在内部文档库中搜索关键词',
        inputSchema: {
          type: 'object',
          properties: {
            query: { type: 'string', description: '搜索关键词' },
            limit: { type: 'integer', description: '最多返回数', default: 5 },
          },
          required: ['query'],
        },
      },
      {
        name: 'get_doc',
        description: '获取指定文档的完整内容',
        inputSchema: {
          type: 'object',
          properties: {
            doc_id: { type: 'string', description: '文档唯一标识符' },
          },
          required: ['doc_id'],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'search_docs') {
    const results = searchInternalDocs(args.query, args.limit ?? 5);
    return { content: [{ type: 'text', text: JSON.stringify(results) }] };
  }

  if (name === 'get_doc') {
    const content = getDocumentContent(args.doc_id);
    return { content: [{ type: 'text', text: content }] };
  }

  throw new Error(`Unknown tool: ${name}`);
});

// ========== Resources 实现 ==========
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: 'docs://index',
        name: '文档索引',
        description: '所有内部文档的索引',
        mimeType: 'application/json',
      },
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  if (request.params.uri === 'docs://index') {
    const index = loadIndex();
    return { contents: [{ uri: 'docs://index', mimeType: 'application/json', text: JSON.stringify(index) }] };
  }
  throw new Error(`Unknown resource: ${request.params.uri}`);
});

// ========== 业务逻辑 ==========
function searchInternalDocs(query: string, limit: number) {
  // 接入你们的搜索引擎
  return [{ id: 'svc-auth-001', title: '认证服务文档', score: 0.95 }];
}

function getDocumentContent(docId: string): string {
  return `# ${docId}

文档内容...`;
}

function loadIndex() {
  return { documents: [] };
}

// ========== 启动服务 ==========
const transport = new StdioServerTransport();
server.connect(transport).catch(console.error);
```

### 注册到 Claude Code

```bash
# 使用 claude mcp add 命令注册
claude mcp add internal-docs python /path/to/internal_docs_server.py
```

```json
// .claude/mcp.json 配置（手动编辑方式）
{
  "mcpServers": {
    "internal-docs": {
      "command": "python",
      "args": ["/path/to/internal_docs_server.py"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

---

## 🔗 MCP 在团队协作中的高级模式

### 模式一：团队共享 MCP Server

最实用的团队场景：**把团队内部的工具和数据封装成 MCP Server，让所有成员共享**。

```
团队 MCP Server 架构：

                    ┌─────────────────┐
                    │  团队 MCP Hub   │
                    │  (共享 Server)  │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ 内部文档库   │   │  Jira 集成  │   │  代码库索引 │
  │ (代码规范)   │   │  (任务追踪) │   │  (服务地图) │
  └──────────────┘   └──────────────┘   └──────────────┘
```

团队成员只需要配置一次，之后每个成员都可以让 Claude Code 调用这些内部工具。

### 模式二：分层 MCP 架构

对于大型组织，可以设计分层 MCP：

```
第一层（个人级）：本地工具
  - 文件系统
  - GitHub（个人 token）

第二层（团队级）：共享服务
  - 内部文档库
  - 团队 Wiki
  - CI/CD 状态

第三层（组织级）：企业服务
  - LDAP/SSO 认证
  - 企业数据库
  - 安全扫描服务
```

每层用不同的认证方式和权限级别。

### 模式三：MCP + Agent Teams

当 MCP Server 本身需要 AI 能力时，可以用 Sampling 模式：

```
MCP Server（无 LLM）
    ↓ Sampling 请求
Claude Code Client（持有 LLM）
    ↓
返回分析结果给 Server
```

这实现了一种"Server 端 AI 能力"的共享——多个 Server 可以复用同一个 LLM，而不需要各自集成。

---

## 🔒 MCP 安全配置最佳实践

MCP 持有你授权的权限。如果配置不当，可能造成安全风险。

### 原则一：最小权限

每个 MCP Server 只给它完成工作所需的最小权限：

```
❌ 错误：
Jira MCP 配置了"所有项目、所有权限"

✅ 正确：
Jira MCP 只配置"你负责的几个项目、仅读+评论权限"
```

### 原则二：Token 不写在配置文件里

```bash
# ❌ 错误：Token 明文写在配置里
claude mcp add github --auth "ghp_your_token_here"

# ✅ 正确：使用环境变量
claude mcp add github
# 然后在环境变量中设置 GITHUB_TOKEN
```

### 原则三：定期审计 MCP 配置

每季度检查一次：
1. 哪些 MCP Server 还在用？哪些已经不用了？
2. 每个 Server 的权限是否还符合最小权限原则？
3. Token 是否过期？是否需要刷新？

```bash
# 查看当前配置的 MCP Server
claude mcp list

# 测试某个 Server 是否正常
claude mcp test --server <name>
```

### 原则四：区分 STDIO 和 HTTP Server

- **STDIO**：本地进程，通过父进程通信。安全风险较低，但注意 Claude Code 进程能访问的东西，这个子进程也能访问。
- **HTTP**：暴露到网络。要确保有认证机制，不要把没有认证的 MCP Server 暴露到公网。

### 原则五：隔离不同来源的 Server

不要在一个 Claude Code 实例里混用：
- 可信来源（MCP 官方生态）
- 内部自建（你的团队）
- 第三方（网上的开源 Server）

建议分类配置，用 Profile 隔离：
```
Claude Code Profile: work-dev
  → 内部文档 Server（可信）
  → GitHub Server（可信）

Claude Code Profile: experimental
  → 各种第三方 Server（隔离）
```

---

## 📊 常见 MCP Server 生态盘点

### 数据源类

| Server | 功能 | 适用场景 |
|--------|------|---------|
| Filesystem | 本地文件读写 | 任何需要访问本地文件的场景 |
| GitHub | PR/Issue/代码库 | Code Review、进度追踪 |
| Jira | 任务管理 | 项目管理、任务状态查询 |
| PostgreSQL | 数据库查询 | 数据分析、Schema 理解 |
| Redis | 缓存读写 | 缓存管理、状态查看 |

### 开发工具类

| Server | 功能 | 适用场景 |
|--------|------|---------|
| Slack | 消息发送 | 团队通知、值班播报 |
| Sentry | 错误监控 | 线上问题排查 |
| AWS | 云资源管理 | 运维、线上问题排查 |
| Puppeteer | 浏览器自动化 | Web 截图、数据抓取 |

### 信息检索类

| Server | 功能 | 适用场景 |
|--------|------|---------|
| Google Search | 网页搜索 | 技术调研、文档查找 |
| Brave Search | 隐私搜索 | 技术调研 |
| Notion | Wiki 查询 | 团队知识库 |

### 自建类（团队内部）

| Server | 功能 | 适用场景 |
|--------|------|---------|
| 内部文档库 | 文档搜索 | 让 AI 理解团队规范 |
| 内部 API 索引 | API 发现 | 微服务查询 |
| 代码库地图 | 服务依赖 | 架构理解 |

---

## 总结

MCP 不是一个"接插件"的工具，它是 **AI 应用与外部系统交互的通用协议标准**。

理解 MCP 的四个原语（Tools、Resources、Prompts、Sampling）帮助你更好地：
- 评估一个 MCP Server 是否值得用
- 设计自己团队的 MCP 架构
- 调试 MCP 相关问题

**MCP 的核心价值**：把"AI 需要什么上下文"标准化，让外部系统可以按统一方式提供上下文。

下次配置 MCP 时，先问自己：**这个 Server 是给我提供了 Tools（做事情）、Resources（读数据）、Prompts（专业流程），还是 Sampling（AI 能力）？** 回答清楚这个问题，你就知道这个 MCP 到底在解决什么问题。

---

## 相关资源

- [MCP 官方文档](https://modelcontextprotocol.io/)
- [MCP SDK（Python）](https://github.com/modelcontextprotocol/python-sdk)
- [MCP SDK（TypeScript）](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Server 生态列表](https://github.com/modelcontextprotocol/servers)
- [Claude Code 官方 MCP 集成指南](https://docs.anthropic.com/claude-code)

---

## 🔗 其他博客

- [Claude Code 插件体系](./claude-code-plugins.md)
- [多Agent编排实战](./multi-agent-orchestration.md)
- [AI代码审查指南](./ai-code-review.md)
- [AI测试工具大全](./ai-testing-tools.md)