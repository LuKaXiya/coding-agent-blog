---
layout: post
title: "MCP 协议进阶架构：Streaming、 Sampling 与事件驱动的 Agent 协作"
date: 2026-04-26 10:00:00 +0800
category: MCP生态
tags:
  - MCP
  - Streaming
  - Sampling 协议
  - 事件驱动
  - 多Agent协作
  - 协议架构
---

> 现有的 MCP 指南大多聚焦在「如何写一个自定义 Server」。但协议本身还有很多未被充分讨论的进阶能力：流式响应的实现机制、 Sampling 协议带来的双向通信范式、以及如何用 MCP 的资源模型构建事件驱动的多 Agent 协作网络。这些能力组合在一起，让 MCP 不只是「AI 的 USB 接口」，而是成为多 Agent 系统中事实上的通信骨干。

本文假设你已经了解 MCP 的四原语（Tools、Resources、Prompts、Instructions）和基础的 Server 开发方式，重点深入协议层的进阶架构。

---

## 目录

- [一、流式架构：MCP 的实时通信机制](#一流式架构mcp-的实时通信机制)
- [二、Sampling 协议：Server 主动触发的 LLM 生成](#二sampling-协议server-主动触发的-llm-生成)
- [三、事件驱动模式：用资源订阅替代 Webhook](#三事件驱动模式用资源订阅替代-webhook)
- [四、三者结合：构建事件驱动的多 Agent 协调网络](#四三者结合构建事件驱动的多-agent-协调网络)
- [五、工程实践：实现注意事项与常见陷阱](#五工程实践实现注意事项与常见陷阱)

---

## 一、流式架构：MCP 的实时通信机制

### 1.1 为什么流式对 AI 编程 Agent 重要

AI 编程任务天然具有长时性：代码库扫描可能涉及数万个文件，构建过程可能需要数分钟，测试套件可能运行数百个用例。

在传统的请求-响应模型下，Agent 只能看到最终结果，无法感知过程。这带来三个具体问题：

**问题一：进度不可见，用户以为卡死了。**
Agent 在分析一个大型代码库，30 秒后用户看到的是「分析完成，发现 47 个模块」。但这 30 秒里用户完全不知道 Agent 在做什么——是卡住了？还是在认真工作？

**问题二：Agent 无法基于中间状态调整行为。**
传统模式下，Server 必须等所有数据都准备好才能返回。但有时候前 10% 的数据已经足够 Agent 做出关键决策，后续 90% 只是在补充细节。流式模式让 Agent 可以在过程中提前介入。

**问题三：长任务的错误处理延迟太高。**
如果 Server 在第 50 步才报错，用户已经等了 5 分钟。流式模式下，Server 可以在第 5 步出错时立即通知 Agent，Agent 可以在第 6 步就切换策略。

### 1.2 MCP 的流式实现：HTTP SSE + JSON-RPC

MCP 的流式架构不是单一技术，而是**传输层适配模式**。官方规范支持两种流式路径：

**路径一：Streamable HTTP 的分块传输**

MCP 的 HTTP 传输层支持分块响应（Chunked Transfer Encoding）。Server 可以在处理过程中多次写入响应体，Client 则通过 HTTP 分块读取实时获取增量数据：

```
HTTP/1.1 200 OK
Transfer-Encoding: chunked
Content-Type: application/json

{"jsonrpc":"2.0","method":"progress","params":{"step":1,"total":10}}
{"jsonrpc":"2.0","method":"progress","params":{"step":2,"total":10}}
{"jsonrpc":"2.0","result":{"filesAnalyzed":152,"issuesFound":3}}
```

这实际上是把 JSON-RPC 的 notification 机制（`method` 字段无 `id`）用作了进度推送。Server 可以在返回最终 `result` 之前发送任意数量的中间通知。

**路径二：SSE（Server-Sent Events）**

对于需要更强实时性保障的场景，MCP Server 可以通过 SSE 通道推送独立于 JSON-RPC 的事件流：

```
event: tool-progress
data: {"tool":"code_scanner","file":"/src/auth/service.go","status":"analyzing"}

event: tool-progress
data: {"tool":"code_scanner","file":"/src/auth/handlers.go","status":"analyzing"}

event: tool-complete
data: {"tool":"code_scanner","totalFiles":47,"issues":3,"severity":"high"}
```

SSE 的优势在于：同一 TCP 连接上可以混合 JSON-RPC 调用和纯事件推送，Client 可以用不同的处理逻辑分别消费它们。

### 1.3 流式在代码库分析中的实际应用

举一个具体场景：用 MCP Server 实现代码库的实时安全扫描。

**非流式模式**（用户等待 2 分钟，看到完整报告）：
```
Client → Server: tools/call { name: "security_scan", args: { path: "/project" } }
Server: [2分钟分析] → Client: { issues: [47个问题] }
```

**流式模式**（用户实时看到分析进度）：
```
Client → Server: tools/call { name: "security_scan", args: { path: "/project" } }
Server → Client: { method: "progress", params: { phase: "indexing", count: 0 } }
Server → Client: { method: "progress", params: { phase: "indexing", count: 1523 } }
Server → Client: { method: "progress", params: { phase: "scanning", current: "auth/service.go" } }
Server → Client: { method: "issue_found", params: { file: "auth/service.go", line: 42, severity: "HIGH" } }
Server → Client: { method: "issue_found", params: { file: "payments/webhook.go", line: 18, severity: "MEDIUM" } }
Server → Client: { result: { totalIssues: 47, high: 5, medium: 18, low: 24 } }
```

流式模式的核心价值不只是「让用户看到进度」，而是让 **Agent 可以在中途介入**：如果 Agent 发现某个文件有问题，可以在 scan 完成前就中断并开始修复，而不是等完整报告。

---

## 二、Sampling 协议：Server 主动触发的 LLM 生成

### 2.1 从单向调用到双向协商

MCP 的 Sampling 协议（实验性，0.5.0+）解决了一个之前缺失的能力：

**Server 可以在执行过程中，主动要求 Client 调用 LLM 并将结果返回给 Server。**

这个能力听起来简单，但它打开了一个全新的架构空间。之前的 MCP 交互模型是严格的单向调用：

```
Agent → Server: 发送请求
Server → Agent: 返回结果
```

Sampling 引入之后，Server 可以主动发起 LLM 调用：

```
Agent → Server: "我需要理解这段业务逻辑的含义"
Server → Client: "sampling/createMessage，需要你调用 LLM 解释业务逻辑"
Client(人) → Client: 决定是否批准、是否修改 prompt
Client → Server: 返回 LLM 生成的解释
Server → Agent: "业务逻辑是关于订单处理和库存管理"
```

### 2.2 Sampling 协议的完整流程

Sampling 的完整交互涉及多个步骤：

**Step 1：Server 发起请求**

```json
{
  "method": "sampling/createMessage",
  "params": {
    "systemPrompt": "你是一个代码架构分析助手...",
    "messages": [
      { "role": "user", "content": "分析 /src/order 中的业务逻辑" }
    ],
    "maxTokens": 500,
    "temperature": 0.3
  }
}
```

**Step 2：Client 的人类政策层介入**

这是 Sampling 区别于普通工具调用的关键：Client 不会直接把请求发往 LLM，而是先经过「人类政策」过滤。

Client 的人类政策层可以做这些事情：
- **批准**：直接转发请求
- **修改**：修改 systemPrompt 或 messages 后转发
- **拒绝**：返回空响应，不调用 LLM
- **采样**：使用本地 LLM（如 Ollama）而不是云端 API

**Step 3：响应返回给 Server**

```json
{
  "model": "claude-sonnet-4-20250514",
  "role": "assistant",
  "content": [
    { "type": "text", "text": "这段代码实现了订单的..." }
  ],
  "stopReason": "endTurn"
}
```

### 2.3 Sampling 的实际应用场景

Sampling 不是为了让 Server 变得更强大，而是为了实现**原来不可能的交互模式**。

**场景 A：多 Agent 间的自然语言协商**

一个 Supervisor Agent 和一个 Coder Agent 协作：

- Supervisor 的 MCP Server 在制定计划后，通过 Sampling 让 Client 调用 LLM 生成「计划解释」
- 如果解释不清晰，Client 可以在转发前加入追问 prompt
- 最终 Supervisor 得到的不只是一个执行计划，而是一个经过 LLM 审视的、有逻辑支撑的计划

**场景 B：动态生成代码文档**

MCP Server 在分析代码时，可以通过 Sampling 让 Client 调用 LLM 实时生成 docstring：

```python
# Server 发现新 API endpoint
server_endpoint = "/api/v2/orders/refund"
# Server 通过 Sampling 请求文档生成
sampling_request = {
    "systemPrompt": "你是一个 API 文档专家...",
    "messages": [{
        "role": "user",
        "content": f"为以下 endpoint 生成 OpenAPI 文档：\n{endpoint_code}"
    }]
}
# Client 批准，LLM 生成文档
# Server 将文档写入代码或 API Gateway 配置
```

**场景 C：实时人工审查节点**

当 Agent 的操作涉及高风险决策（如删除资源、修改权限），Sampling 请求可以让人类在 LLM 生成内容之前介入：

```json
{
  "method": "sampling/createMessage",
  "params": {
    "systemPrompt": "你是一个安全审计员...",
    "messages": [...],
    "preAuthorize": true  // 标记为高风险，必须人类确认
  }
}
```

### 2.4 Sampling 的安全边界

Sampling 引入了一个核心安全风险：**Server 可以无限触发 LLM 调用，消耗 Client 的 token 预算。**

MCP 规范明确指出：Client 必须实现人类政策层来限制 Sampling 的使用。具体来说：

- 每个 Sampling 请求都需要显式的人类批准（不能静默转发）
- Client 应该追踪每个 Server 的 Sampling 使用量，并设置限额
- `preAuthorize: true` 的请求是强制的，必须人类在场才能批准

**对于使用方来说**：如果你在使用的 MCP Server 频繁发起 Sampling 请求但你从未批准过任何一次，说明这个 Server 可能设计不当——它在用 Sampling 绕过你直接与 LLM 交互。

---

## 三、事件驱动模式：用资源订阅替代 Webhook

### 3.1 传统 Webhook 的局限性

传统 Webhook 是事件驱动集成的标准方式，但它有几个固有限制：

- **紧耦合**：Consumer 必须暴露一个公网可达的 URL
- **一次性**：Webhook 发送后，Consumer 没有持久状态，不知道历史事件
- **重试机制复杂**：发送失败后的重试逻辑需要 Consumer 自己实现
- **没有类型安全**：Consumer 不知道收到的 payload 结构，必须自己解析

在多 Agent 系统中，这些局限性会导致严重的集成复杂度。每个 Agent 都需要维护一堆 Webhook 回调，而且 Agent 之间无法共享 Webhook 状态。

### 3.2 MCP 的资源订阅模型

MCP 的资源系统（Resources + Subscriptions）提供了一种更声明式的事件驱动方式：

**声明式订阅**：

```json
// Client 订阅一个资源
{
  "method": "resources/subscribe",
  "params": {
    "uri": "git://repo/commits/main"
  }
}
```

**Server 推送更新**：

```json
// 当有新 commit 时，Server 主动通知
{
  "method": "notifications/resources/updated",
  "params": {
    "uri": "git://repo/commits/main"
  }
}
```

这个模型的几个关键特点：

**1. 订阅状态在 Server 端管理**

Consumer 不需要维护 URL 和回调状态——订阅关系由 Server 维护。当 Client 重连时，Server 会重新推送最新的资源状态（如果配置了 `ursors` 机制）。

**2. 事件被建模为「资源变更」**

这意味着所有事件都有统一的类型系统（资源 URI）。Consumer 可以用统一的方式处理所有类型的事件，而不是为每种 Webhook payload 写不同的解析器。

**3. 可以用 MCP 的工具原语做过滤**

```json
// 订阅带过滤条件的资源
{
  "method": "resources/subscribe",
  "params": {
    "uri": "git://repo/commits/main?author=alice&since=2026-04-01"
  }
}
```

### 3.3 用 MCP 实现事件驱动的多 Agent 协调

结合流式架构和资源订阅，可以构建一个完全基于 MCP 的多 Agent 协调网络：

```
┌─────────────┐     SSE 流式推送      ┌─────────────┐
│ CI/CD Agent │ ──────────────────→  │  Code Review│
│ (MCP Server)│                       │  Agent      │
└─────────────┘                       └─────────────┘
     │                                        ↑
     │ resources/subscribe                    │
     └────────────────────────────────────────┘
              资源订阅：CI 完成事件
```

具体流程：
1. CI/CD Agent 的 MCP Server 在构建完成时，通过 SSE 推送 `build.complete` 事件
2. Code Review Agent 通过 `resources/subscribe` 订阅这个事件
3. 事件到达时，Code Review Agent 自动触发代码审查任务
4. 审查结果通过 Sampling 协议通知人工审核（如果需要）

这个模式的精妙之处在于：**Agent 之间的协调完全通过 MCP 协议完成，不需要额外部署消息队列或 Webhook 网关**。

---

## 四、三者结合：构建事件驱动的多 Agent 协调网络

### 4.1 架构全貌

把 Streaming、Sampling 和事件驱动订阅结合起来，我们得到一个三层架构：

```
第一层：事件层（资源订阅）
  └── Agent 间的协调信号：任务到达、超时、异常、状态变更
  └── 协议机制：resources/subscribe + notifications/resources/updated
---
第二层：通信层（流式推送）
  └── 执行状态的实时反馈：进度、中间结果、错误通知
  └── 协议机制：JSON-RPC notifications + SSE
---
第三层：协商层（Sampling）
  └── 需要 LLM 介入的决策点：计划确认、高风险操作审批
  └── 协议机制：sampling/createMessage + 人类政策层
```

### 4.2 实际案例：自动化 Code Review 工作流

**背景**：每次代码合并到 main 分支，自动触发多语言审查（安全 + 性能 + 架构）。

**Agent 角色**：
- **CI/CD Agent**：监听 Git 事件，管理构建状态
- **Security Reviewer**：用 MCP 连接代码安全扫描工具
- **Performance Reviewer**：用 MCP 连接性能分析工具
- **Architecture Reviewer**：通过 Sampling 调用 LLM 评估架构合理性
- **Human Supervisor**：在关键决策点通过 Sampling 审批

**完整流程**：

```
[代码合并] → CI/CD Agent 推送构建完成事件（SSE）
    ↓
Security Reviewer + Performance Reviewer 订阅事件，自动开始扫描（并发）
    ↓
Security Reviewer 发现高危漏洞 → 推送 critical 事件
    ↓
Human Supervisor 通过 Sampling 审批（是否中断流程）
    ↓
Architecture Reviewer 通过 Sampling 请求 LLM 生成架构建议
    ↓
Human Supervisor 通过 Sampling 审批（是否接受建议）
    ↓
CI/CD Agent 收到所有 Review 结果，发布最终报告
```

这个流程的关键在于：**每个 Agent 都是一个独立的 MCP Server，通过资源订阅协调，不需要中心化的消息总线**。

### 4.3 这个架构与 Swarm Tax 的关系

Stanford 的 Swarm Tax 研究指出：多 Agent 系统往往消耗更多算力，但不必然带来更好的结果。

但这个研究比较的是「使用等量算力时的效果差异」。当我们把 Streaming + Sampling + 事件驱动订阅组合起来时，架构设计本身就在降低算力浪费：

- **事件驱动**确保 Agent 只在有事可做时才激活，避免空转
- **流式进度**让人类可以在中途干预，避免 Agent 在错误方向上浪费算力
- **Sampling 的前置审批**在高风险操作前强制人工介入，减少后期修复成本

换句话说：**多 Agent 架构的算力效率，很大程度上取决于协调层的质量**。Streaming/Sampling/事件订阅构成了一套高质量的协调层。

---

## 五、工程实践：实现注意事项与常见陷阱

### 5.1 Streaming 的实现注意事项

**陷阱一：混淆 notification 和 response**

JSON-RPC 的 notification（无 `id` 字段）是不期待响应的。Server 发送 notification 后不能期待 Client 做任何处理。如果 Server 需要 Client 的确认（比如人类批准），必须用有 `id` 的 request/response 模式。

**陷阱二：SSE 重连后状态丢失**

SSE 连接断开时，Server 默认不会保留订阅状态。如果需要可靠的事件传递，Client 应该在重连后重新订阅，并用资源 URI 的游标机制恢复历史状态。

**陷阱三：流式响应中的错误处理**

Server 在发送部分结果后遇到错误，应该：
1. 发送一个带错误信息的 JSON-RPC response（表明这是一个错误结果）
2. 不发送更多的 progress notification
3. 在文档中明确说明流式响应的成功/失败判断标准

### 5.2 Sampling 的实现注意事项

**陷阱一：Server 滥用 Sampling 绕过人类**

如果 Server 的每个工具调用都包装成 Sampling 请求，说明它在试图绕过 Client 的人类政策层。Client 应该在配置中限制每个 Server 的 Sampling 频率。

**陷阱二：Sampling 请求的 context 膨胀**

Sampling 请求会携带完整的 messages 数组。如果 Server 在循环中频繁发起 Sampling，每次都带上越来越多的 context，会导致 token 快速膨胀。应该在每轮 Sampling 后评估是否需要 `maxTokens` 限制。

**陷阱三：Sampling 的 model 选择**

Client 在转发 Sampling 请求时，应该有权选择使用哪个模型。使用更强的模型（如 Sonnet 4）处理复杂推理，使用更小的模型处理简单翻译任务，可以显著降低成本。

### 5.3 资源订阅的实现注意事项

**陷阱一：URI 规范不统一**

不同 MCP Server 可能用完全不同的 URI scheme 表示同类资源。Client 在订阅多个 Server 的同类资源时，需要理解每个 Server 的 URI 规范。建议在团队内制定统一的 URI 命名约定。

**陷阱二：订阅泄漏**

如果 Client 在完成一个任务后忘记取消订阅（`resources/unsubscribe`），Server 会继续推送事件到已经不关心该资源的 Client。Server 应该实现自己的订阅超时机制，避免内存泄漏。

---

## 总结

MCP 的 Streaming、Sampling 和资源订阅三套机制，分别解决了多 Agent 系统中的三个核心问题：

| 机制 | 解决的问题 | 协议原语 |
|------|-----------|---------|
| Streaming | 执行过程实时可见，Agent 可中途介入 | JSON-RPC notifications + SSE |
| Sampling | Server 可以主动触发 LLM 生成，人类在关键节点把关 | sampling/createMessage |
| 资源订阅 | Agent 间的事件协调，无需公网 Webhook | resources/subscribe |

三者结合，构成了一套**端到端的异步协调协议**，让多 Agent 系统的协调层不再需要额外的消息中间件。

如果你正在设计一个多 Agent 系统，先问自己三个问题：
1. **执行过程需要实时反馈吗？** → 用 Streaming
2. **有需要人类确认的高风险决策点吗？** → 用 Sampling
3. **Agent 之间需要事件协调吗？** → 用资源订阅

这三个问题的答案，决定了你需要 MCP 的哪些进阶能力。

---

## 相关阅读

- [MCP 深度指南：从协议原理到自定义 Server 实战](/coding-agent-blog/posts/mcp-protocol-deep-dive/)（基础概念 + Server 开发）
- [AI 多 Agent 系统的 Swarm Tax](/coding-agent-blog/posts/swarm-tax-single-agent-beats-multi-agent/)（多 Agent 算力效率研究）
- [Claude Code 持续开发循环](/coding-agent-blog/posts/claude-code-continuous-development-loop/)（流式输出在实际工具中的使用）
