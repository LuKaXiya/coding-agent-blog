---
layout: post
title: "BAND：确定性路由的 Agent 间通信基础设施——多 Agent 协作的下一个必争之地"
date: 2026-05-01 10:00:00 +0800
category: 多Agent
tags:
  - BAND
  - Agent间通信
  - Universal Orchestrator
  - Deterministic Routing
  - 多Agent协作
  - MCP
  - 企业级AI
---

> 当你同时运行 Claude 和 Codex，它们之间能直接对话吗？
>
> 现实是：Claude 擅长规划，Codex 擅长审查，它们各自独立运行，彼此无法感知对方的进度、状态或输出。更糟糕的是，你无法让一个 Agent 把任务委托给另一个 Agent，无法在它们之间传递上下文，也无法审计它们之间的每一次交互。
>
> 这不是工具的问题——这是协议的问题。
>
> BAND 的出现，就是为了解决这个问题。它是第一个明确提出「Agent 间通信基础设施」概念的创业公司，获得了 $1700万 Seed 轮融资，定位为「Agent 间的 Slack」。本篇深入解析它的技术架构、战略定位，以及它对 AI 编程工具多 Agent 协作格局的深层意义。

---

## 目录

- [一、从工具协作到 Agent 协作的根本差距](#一从工具协作到-agent-协作的根本差距)
- [二、BAND 的双层架构：Agentic Mesh](#二band-的双层架构agentic-mesh)
- [三、确定性路由：不用 LLM 做路由的核心原因](#三确定性路由不用-llm-做路由的核心原因)
- [四、Control Plane：企业级 Agent 治理的缺失环节](#四control-plane企业级-agent-治理的缺失环节)
- [五、实战用例：Claude + Codex 的实时协作](#五实战用例claude--codex-的实时协作)
- [六、BAND 与现有协议的竞合关系](#六band-与现有协议的竞合关系)
- [七、对 AI 编程工具格局的深层影响](#七对-ai-编程工具格局的深层影响)

---

## 一、从工具协作到 Agent 协作的根本差距

### 1.1 当前多 Agent 协作的真相

当我们谈论「多 Agent 协作」时，实际上存在两种截然不同的场景：

**假协作**：同一个 Agent 在不同任务上运行，彼此独立，无信息交换。多个 Claude Code session 同时跑，不叫协作，叫并发。

**真协作**：Agent A 的输出直接成为 Agent B 的输入，Agent B 能够理解 Agent A 的意图、上下文和约束，并基于此做决策。

现实是：大多数所谓的「多 Agent」产品实际上是「并发单 Agent」。真正的协作需要一个通信层来连接多个 Agent，而这个通信层目前几乎是空白的。

### 1.2 为什么现有协议不够用

| 协议/工具 | 解决的问题 | 不解决的问题 |
|---------|----------|------------|
| MCP | Agent → 工具 | Agent → Agent |
| Slack/Teams Webhook | 人类 → Agent | Agent → Agent |
| LangChain Agents | 单框架内的 Agent 协调 | 跨框架/跨云 |
| Anthropic Agent API | 单模型内的多 Agent | 多模型协作 |

**根本问题**：MCP 是「客户端-服务器」模式，Agent 是客户端，工具是服务器。但当你有多个 Agent 需要协作时，它们之间没有「对等」通信协议。Slack/Teams Webhook 是为人类设计的，Agent 嵌入后会「失去上下文或需要持续的 rehydration」。LangChain/CrewAI 是单框架内的编排，无法跨越框架边界。

### 1.3 BAND 的核心命题

> "In order for agents to become real players in the global economy, they need ways to communicate, just like humans do."

BAND 的 CEO Arick Goomanovsky 说：「你不能把一堆 Agent 丢进 Slack 然后期望它奇迹般地工作。」

这句话点出了当前多 Agent 协作的根本困境：我们在用人类通信工具（Slack）来管理非人类工作者（Agent），而 Agent 的行为模式（异步、非确定性、需要状态管理）与人类完全不同。

---

## 二、BAND 的双层架构：Agentic Mesh

BAND 采用双层架构，分别解决「如何通信」和「如何治理」的问题。

### 2.1 第一层：Interaction Layer（交互层）

这是 Agent 间的「消息管道」，负责：
- **Agent 发现**：跨云、跨框架找到其他 Agent
- **结构化委托**：把任务可靠地委派给其他 Agent
- **全双工多端通信**：多个 Agent（planner + coder + QA）同时在一个「room」里协作，共享上下文

**关键特性**：

1. **Multi-Peer 全双工通信**：不像传统协议那样是 peer-to-peer（点对点）或 client-server（客户端-服务器），BAND 支持多个 Agent 同时在同一个共享空间内通信。

2. **跨框架/跨云**：Agent 可以用 LangChain 构建，用 CrewAI 构建，运行在 AWS、Azure 或 GCP 上，BAND 负责把它们连接起来。

3. **消息持久化与上下文同步**：当 Agent 因失败重新进入对话时，不需要「rehydration」（重新填充上下文），BAND 维护会话状态。

### 2.2 第二层：Control Plane（控制层）

如果 Interaction Layer 是「管道」，Control Plane 就是「阀门」——负责运行时治理，是企业级采用的关键。

**Authority Boundaries（权限边界）**：
- 严格控制哪些 Agent 可以相互通信
- 控制哪些话题可以被讨论
- 这是企业在生产环境部署多 Agent 的合规前提

**Credential Traversal（凭证传递）**：
- 这是多 Agent 系统中最复杂的身份问题之一
- 如果人类用户向 Agent A 请求信息，Agent A 把任务委托给 Agent B，Agent B 的访问权限应该是什么？
- BAND 的答案是：Agent B 只能访问原始用户被授权查看的数据
- Credential traversal 确保权限不会在 Agent 间传递过程中被意外扩大

**全链路审计（Full-chain Auditing）**：
- 每个 Agent 间的交互都有 transcript 记录
- 企业可以事后审查任何 Agent 的决策过程
- 合规和问责是 Control Plane 的核心价值

---

## 三、确定性路由：不用 LLM 做路由的核心原因

### 3.1 为什么 LLM 路由是个坏主意

BAND 最反直觉的设计决策：它**不使用 LLM 来路由消息**。

你可能会问：LLM 不是最擅长理解语义吗？让它判断「这条消息应该发给哪个 Agent」不是最自然吗？

答案是否定的，原因有三：

**1. 非确定性是传播的**

如果用 LLM 做路由，路由本身引入了非确定性错误。一旦 LLM 路由出错，整个通信链路都会受影响。而 BAND 的目标是提供「像 Slack 一样可靠」的通信，Slack 不可能因为「LLM 认为消息应该发给谁」而随机投递。

**2. 延迟是不可接受的**

LLM 推理有延迟（几百毫秒到几秒），而路由应该是毫秒级的操作。在高频 Agent 交互场景中，用 LLM 做路由会成为整个系统的瓶颈。

**3. 可审计性要求确定性**

企业需要知道「为什么这条消息被发给了 Agent B 而不是 Agent C」。如果路由是 LLM 决策，这个决策本身就是不可解释的（或者说解释成本极高）。

### 3.2 BAND 的确定性路由方案

BAND 使用专利的多层架构实现确定性路由，具体技术细节未公开，但可以推断它基于：

- **结构化消息格式**：每条消息包含明确的 routing metadata（发送方、接收方、意图类型、优先级），不需要 LLM 理解语义
- **规则引擎**：基于预定义规则的路由表，类似传统中间件的智能路由
- **语义层分离**：消息内容和路由决策完全分离，路由基于结构化标签而非语义理解

这个设计理念和现代网络交换机很像：交换机不需要「理解」数据包的内容，只需要根据 header 信息做路由决策。

---

## 四、Control Plane：企业级 Agent 治理的缺失环节

### 4.1 为什么 Control Plane 是必须的

在企业环境中部署多 Agent 系统，最大的挑战不是「让它们通信」，而是「安全地让它们通信」。

考虑以下场景：

**场景 1：权限失控**

用户向「客服 Agent」请求用户数据，客服 Agent 委托「数据分析 Agent」去查询。问题是：数据分析 Agent 是否可以访问原始用户的所有数据？还是只有客服 Agent 被授权的部分？

没有 Control Plane，数据分析 Agent 会默认拥有它自己被配置的所有权限，导致权限在委托链中逐步扩大。

**场景 2：审计缺失**

多 Agent 系统出了问题，但没有人知道「Agent A 问了 Agent B 什么，Agent B 返回了什么」。这在金融、医疗等强监管行业是不可接受的。

**场景 3：跨组织边界**

企业 A 的 Agent 需要调用企业 B 的 Agent，但两者之间没有信任框架。Control Plane 可以提供基于零知识证明的交互验证。

### 4.2 BAND Control Plane 的三大能力

| 能力 | 解决的问题 | 典型用户 |
|------|----------|---------|
| Authority Boundaries | 哪些 Agent 可以通信 | 金融、医疗合规团队 |
| Credential Traversal | 权限不超扩 | 企业安全团队 |
| Full-chain Auditing | 决策可追溯 | 审计部门 |

### 4.3 与 Google/AWS Agent Stack 的关系

Google 的 Gemini Enterprise 和 AWS 的 Bedrock AgentCore 代表了「控制平面优先」（Google）和「执行速度优先」（AWS）两种路线。

BAND 的 Control Plane 与两者是正交的：

- BAND 可以部署在 Google Gemini Enterprise 之上，提供额外的治理层
- BAND 也可以部署在 AWS Bedrock AgentCore 之上，补充控制能力
- BAND 定位是独立中间件，不绑定任何云服务商

这是 BAND 的战略护城河：当 OpenAI 和 Anthropic 都在推动各自封闭生态时，BAND 作为独立中间件，让企业避免 vendor lock-in。

---

## 五、实战用例：Claude + Codex 的实时协作

### 5.1 现实中的 Agent 能力差异

BAND 的创始团队发现了一个现实：「高级开发者不使用单一的 coding agent」。

具体来说：
- **Claude**：在规划（planning）任务上表现更优，理解整体架构、任务分解
- **Codex（OpenAI）**：在代码审查（review）任务上表现更优，发现细节问题

这两个能力是互补的，但今天没有任何工具让它们实时协作。你要么在 Claude Code 里写代码，要么在 Codex 里审查代码，两者之间没有通道。

### 5.2 BAND 实现的协作模式

通过 BAND，多个 coding agent 可以这样协作：

```
[Planning Agent - Claude]
    │
    │ (通过 BAND 委托)
    ▼
[Coding Agent - 任务执行]
    │
    │ (通过 BAND 委托)
    ▼
[Review Agent - Codex]
    │
    │ (通过 BAND 反馈)
    ▼
[Planning Agent - Claude]
    │ (根据反馈调整计划)
    ▼
[下一轮迭代]
```

关键是这个流程是**实时的**，不需要人类在每个环节介入传递信息。Agent A 完成后，Agent B 立即收到上下文并开始工作，像一个真正的团队。

### 5.3 其他行业用例

**跨组织自动化（新员工入职）**：

```
[Workday Agent] → [ServiceNow Agent] → [Purchasing Agent]
       │                │                   │
       └── 通知 ────────┘                   │
              └── 采购设备 ────────────────┘
```

完整的新员工入职流程，跨越三个不同的系统，Agent 间自动协调。

---

## 六、BAND 与现有协议的竞合关系

### 6.1 BAND vs MCP

| 维度 | MCP | BAND |
|------|-----|------|
| 通信模式 | 客户端-服务器 | 对等（Peer-to-Peer）|
| 解决问题 | Agent → 工具 | Agent → Agent |
| 状态管理 | 无状态 | 有状态 |
| 路由方式 | 确定性的 URI | 确定性路由（非 LLM）|
| 治理能力 | 无 | Control Plane |
| 生态位置 | 执行层 | 协作层 |

**互补而非竞争**：BAND 可以叠加在 MCP 之上。一个 Agent 通过 MCP 调用工具（GitHub API），通过 BAND 与另一个 Agent 协调任务分配。

```
Orchestrator Agent (BAND)
    │
    ├─→ MCP → GitHub API（工具调用）
    └─→ BAND → Specialist Agent（任务委派）
                └─→ MCP → Database（ Specialist 的工具调用）
```

### 6.2 BAND vs LangChain/CrewAI

LangChain 和 CrewAI 是单框架内的 Agent 编排框架，BAND 是跨框架的通信基础设施。

- LangChain agent 可以通过 BAND 与 CrewAI agent 通信
- 这打破了框架间的壁垒，实现了真正的互操作性

### 6.3 Gartner 的预测

Gartner 预测：2029 年，90% 使用多 Agent 的企业将需要「Universal Orchestrator」。

BAND 正在把自己定位为这个赛道的先行者。在 OpenAI Workspace Agents 和 Anthropic Claude Managed Agents 等大厂方案之外，BAND 代表的是「独立中间件」路线——不绑定任何模型厂商，让企业自己选择最佳模型组合。

---

## 七、对 AI 编程工具格局的深层影响

### 7.1 从单 Agent 到 Agent 协作生态

当前的 AI 编程工具格局：

- **Claude Code**：单一 Agent，强大的规划和执行能力
- **Cursor**：单一 Agent + 多 Agent 并行（在 Agents Window 内）
- **GitHub Copilot**：Tab 补全 + agentic 功能
- **OpenAI Codex**：独立 Agent

这些工具都是「单 Agent 内优化」——Claude Code 优化自己的 Agent，Cursor 优化自己的多 Agent 编排。但**跨工具的 Agent 协作**是空白。

BAND 的出现预示着下一个战场：**Agent 间的互操作协议**。谁能够建立事实标准，谁就能成为 AI 编程工具的「TCP/IP」。

### 7.2 对开发者的实际意义

对于今天的开发者，这意味着：

1. **工具选择不再是非此即彼**：可以用 Claude Code 做规划，用 Cursor 做实现，用 GitHub Copilot 做审查——前提是它们之间可以通信

2. **企业 AI 编程平台需要新的基础设施**：MCP 处理工具调用，BAND 处理 Agent 通信，两者叠加构成完整的企业 AI 编程基础设施栈

3. **AI 编程工具正在「平台化」**：从 IDE 插件到完整的开发平台，从代码补全到端到端自动化

### 7.3 风险与挑战

BAND 也面临挑战：

- **时间问题**：Gartner 预测 2029 年是拐点，但多 Agent 协作今天还是早期市场
- **大厂竞争**：OpenAI 和 Anthropic 各自推封闭生态，可能挤压独立中间件的生存空间
- **协议碎片化**：如果多个协议同时竞争「Agent 间通信标准」，市场可能再次碎片化
- **采用门槛**：BAND 需要被同时集成到多个 Agent 和多个企业环境中，采用路径较长

---

## 结语：通信协议决定协作深度

BAND 让我们看到了一个被忽视的事实：多 Agent 协作的最大障碍，不是 Agent 本身的能力，而是 Agent 之间的通信基础设施。

就像互联网的繁荣不是因为计算机变强了，而是因为 TCP/IP 协议建立了计算机之间的通信标准。AI 编程工具的多 Agent 时代，也需要这样一个「Agent 间的 TCP/IP」。

BAND 是第一个认真做这件事的创业公司。它的确定性路由策略、双层架构、跨框架兼容性，代表了多 Agent 协作基础设施的正确方向。

接下来的问题是：这个标准最终会由谁来定义？BAND 这样的独立中间件，还是 OpenAI/Anthropic 各自的封闭生态？

答案取决于企业是否愿意接受 vendor lock-in。如果企业坚持多云、多框架的灵活性，独立中间件就有生存空间。如果大厂能够提供足够好的闭解决方案，市场的倾向就不一样了。

无论如何，多 Agent 协作的时代已经拉开序幕。BAND 只是第一个入场的选手，真正的战斗还在后面。

---

**参考资料**

- BAND 官网：https://www.band.ai/
- VentureBeat 报道：https://venturebeat.com/orchestration/talking-to-ai-agents-is-one-thing-what-about-when-they-talk-to-each-other-new-startup-band-debuts-universal-orchestrator/
- Gartner 预测（2029，90% 多 Agent 企业需要 Universal Orchestrator）
