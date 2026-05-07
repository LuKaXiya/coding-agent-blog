---
layout: post
title: "AI 编程的脚手架崩塌：LlamaIndex CEO 说 95% 的代码是 AI 写的，然后呢？"
date: 2026-05-07 10:00:00 +0800
category: 深度思考
tags:
  - LlamaIndex
  - 脚手架崩塌
  - RAG
  - Context
  - AI编程工具
  - MCP
  - 框架
  - Jerry Liu
---

> Jerry Liu（LlamaIndex CEO）最近说了一句让整个 AI 编程圈沉默的话：「LlamaIndex 95% 的代码是 AI 生成的。工程师实际上不是在写真正的代码，他们是在用自然语言打字。」
>
> 这句话的真正含义不只是"AI 很强"，而是整个 AI 编程工具链正在发生结构性重塑——脚手架层（scaffolding）正在被颠覆，而"context"正在成为新的护城河。

---

## 目录

- [一、什么是"脚手架层"，为什么它在崩塌](#一什么是脚手架层为什么它在崩塌)
- [二、崩塌的三个层次：从框架到自然语言](#二崩塌的三个层次从框架到自然语言)
- [三、Coding Agent 是催化剂，也是证明](#三coding-agent-是催化剂也是证明)
- [四、Context 的竞争从 Orchestration 转向 Document Processing](#四context-的竞争从-orchestration-转向-document-processing)
- [五、对 AI 编程工具的实际影响：框架在消失，context 在变贵](#五对-ai-编程工具的实际影响框架在消失-context-在变贵)
- [六、开发者行动指南：脚手架崩塌时代的策略](#六开发者行动指南脚手架崩塌时代的策略)
- [七、SageOX 的补充视角：团队知识本来就丢失了](#七sageox-的补充视角团队知识本来就丢失了)
- [八、结论：复杂性没有消失，只是搬家了](#八结论复杂性没有消失只是搬家了)

---

## 一、什么是"脚手架层"，为什么它在崩塌

### 1.1 脚手架层的历史背景

2022-2024 年，AI 应用开发的核心挑战是：LLM 有能力，但缺少连接到真实世界数据和工具的桥梁。

为了解决这个桥接问题，开发者社区构建了一套复杂的中间件：

- **Indexing 层**：把文档切块、向量化、存储到向量数据库
- **Query 引擎**：把用户问题转换成向量检索，召回相关片段，重新排序
- **Retrieval 管道**：把检索结果注入 LLM 上下文
- **Agent 循环**：ReAct、Reflection、Plan-Execute 等模式，让 LLM 能够多步推理和工具调用

LlamaIndex、LangChain、RAGflow、DSPy 都是这个脚手架层的代表性产物。

### 1.2 脚手架层为什么现在在崩塌

**理由一：模型的缺陷已经被修复**

2023 年的 RAG 框架之所以必要，是因为 LLM 有三个根本缺陷：

| 缺陷 | RAG 的解决方案 |
|------|---------------|
| 无法访问私有数据 | Retrieval 注入上下文 |
| 长上下文会退化 | Chunking + Indexing |
| 多步推理不稳定 | Agent loop 显式编排 |

2026 年的模型已经大幅改进：
- **长上下文**：Claude 3.7 Sonnet 200K，Gemini 2.0 1M tokens——不再需要 chunking
- **推理能力**：o3、Claude 3.7 在复杂推理上接近人类专家——不再需要 ReAct 显式循环
- **工具调用**：MCP 协议让模型原生发现工具——不再需要手写 tool wrapper

**理由二：Coding Agent 把"脚手架"反向颠覆了**

最讽刺的事实：LlamaIndex 是"脚手架框架"，但 LlamaIndex 的工程师现在 95% 的代码是 AI 生成的。

这意味着：
- **框架的构建者**也在用 AI coding tool 写代码
- 如果连框架开发者都不再手写"框架代码"，那么框架本身的复杂性对谁还有价值？
- Jerry Liu 的结论：「新的编程语言本质上是英语」

这不是说编程变简单了，而是说**中间层的复杂性被压缩了**。

---

## 二、崩塌的三个层次：从框架到自然语言

### 2.1 第一层：Orchestration 编排层在消失

以前实现一个"带记忆的 Agent"需要：

```python
# 需要手写状态管理、工具注册、ReAct 循环
class ReActAgent:
    def __init__(self):
        self.tools = [search_tool, calculator_tool]
        self.memory = ConversationBufferMemory()
    
    def step(self, observation):
        # 手动写思考-行动循环
        thought = self.llm.think(observation, self.memory)
        if thought.action:
            return self.execute_tool(thought.action)
```

现在只需要告诉 Agent：

> 「你是一个带记忆的代码审查 Agent，每次审查前先查一下上次审查的反馈模式」

这就是"managed agent diagram"（Anthropic 提出的架构）——harness 层+工具+MCP 连接器+技能插件，不需要手写编排代码。

**结果**：学习 LangChain/LlamaIndex 的复杂 API 变得不再必要。

### 2.2 第二层：Integration Glue 在消失

2023 年的另一个复杂性来源：把各种工具和数据源接入 Agent 需要大量 glue code。

```python
# 以前：手写工具发现、API 认证、错误处理
class SlackTool:
    def __init__(self, token):
        self.client = SlackClient(token)
    
    def search_messages(self, query):
        # 50 行认证和错误处理代码
        ...

# Agent 需要知道 Slack 工具的所有接口
```

MCP 协议改变了这个：
- **工具发现**：Agent 自动发现可用工具，不需要手写注册
- **标准接口**：所有 MCP 工具用同一套接口规范
- **认证抽象**：MCP Server 处理认证细节，Agent 只调用工具

**结果**：学习每个工具的 API 细节变得不再必要。

### 2.3 第三层：Prompt 和 Context 的边界在消失

最深刻的崩塌发生在 Prompt 层和 Context 层之间。

以前：
- **Prompt**：你给 Agent 的指令
- **Context**：Agent 用来做决策的信息

现在，这两者的界限变得模糊：
- 你可以在一句话里同时包含指令和上下文
- Agent 能够自主判断"我还需要什么 context"
- Claude Code 的 `Read` 工具可以动态注入文件，不需要提前规划

这意味着**你给 Agent 什么 context 比你会什么框架更重要**。

---

## 三、Coding Agent 是催化剂，也是证明

### 3.1 Claude Code 的架构哲学就是脚手架崩塌的体现

Claude Code 没有复杂的 RAG pipeline，没有内置向量数据库，没有繁重的索引层。

它的架构是：
- **Harness**：负责任务分解、执行控制、错误恢复
- **Memory**：CLAUDE.md + 项目文件 + 工具输出
- **Context**：动态注入，用户手动控制

这正是 Jerry Liu 说的"managed agent diagram"在 Claude Code 中的实现。

结果是：
- Claude Code 可以在任何语言、任何框架、任何项目上工作
- 它不需要"为项目配置 RAG 系统"
- 它只需要知道"这个项目是做什么的"（CLAUDE.md）

### 3.2 从"会框架"到"会描述任务"

脚手架时代的能力模型：

```
Python/JavaScript → LangChain/LlamaIndex API → RAG/Agent 模式 → 会用 AI 工具
```

脚手架崩塌后的能力模型：

```
自然语言描述任务 → AI 工具执行 → 验证和迭代
```

这意味着：
- 学习 LangChain API 的投入产出比在急剧下降
- 学习"如何清晰地描述任务"的投入产出比在急剧上升
- 能说清楚需求的人比能写复杂代码的人更有价值

### 3.3 95% AI 代码的真正含义

Jerry Liu 说「LlamaIndex 95% 的代码是 AI 写的」，这句话有三个层次的含义：

**第一层（表面）**：LlamaIndex 工程师用 AI coding tool 提高效率

**第二层（实质）**：LlamaIndex 的工程师现在在做 prompt engineering 和 context management，而不是写框架代码

**第三层（结构）**：脚手架框架的开发者自己不再需要脚手架——他们用 AI 直接构建应用，而不是用框架构建应用

第三层才是颠覆性的：框架的价值主张（降低 AI 应用开发门槛）在被 AI coding tool 直接取代。

---

## 四、Context 的竞争从 Orchestration 转向 Document Processing

### 4.1 当 orchestration 不再稀缺，什么才稀缺？

Jerry Liu 在访谈中明确指出了 LlamaIndex 的战略转型：

> 「Context 才是护城河。模型们都需要的是 context。」

脚手架崩塌后，所有人都能轻易构建 retrieval 管道和 agent loop。这意味着：
- **Orchestration 能力**：不是差异化（人人都能做）
- **Document processing 能力**：是差异化（把数据喂给 agent 的能力）

LlamaIndex 的新定位不是"更好的 RAG 框架"，而是：
- **Agentic document processing**：OCR、结构化提取、PDF/Word/Excel 解析
- **多格式数据理解**：从各种文件格式容器中解锁数据

这是从"orchestration"（编排）到"ingestion"（摄取）的战略转移。

### 4.2 对 AI 编程工具的直接含义

同样的逻辑适用于 AI 编程工具：

**当所有 AI coding tool 都能做代码补全、代码审查、测试生成时，差异化在哪里？**

答案是：**Context 的质量和丰富度**。

Claude Code 的差异化不是"能做什么"，而是"知道什么"：
- CLAUDE.md 让它知道项目的业务逻辑
- 团队 commit history 让它知道设计决策的演变
- 项目文档让它知道架构约束

这些 context 决定了 Claude Code 的输出质量上限——同样的模型，给不同质量的 context，输出质量差异巨大。

### 4.3 Context 是新的"框架护城河"

脚手架时代的护城河：
- 你知道多少 LangChain API
- 你能搭建多复杂的 RAG pipeline
- 你的 agent loop 有多少步推理

脚手架崩塌后的护城河：
- 你能给 Agent 提供多高质量的 context
- 你对项目 domain 的理解有多深
- 你能否快速构建针对特定领域的 context pipeline

这意味着：**一个熟悉业务领域的开发者 + AI coding tool，可能比一个框架专家更能产生价值**。

---

## 五、对 AI 编程工具的实际影响：框架在消失，context 在变贵

### 5.1 开发者能感受到的具体变化

**变化一：调试链路变短了**

以前：当 AI 输出错误，先要检查 RAG retrieval 是否正确 → 检查 chunking 策略 → 检查 embedding 模型 → 检查 LLM 输出

现在：当 AI 输出错误，直接检查 context 是否正确 → 检查 prompt 是否清晰 → 检查 model 是否适合这个任务

框架层消失后，调试链路从 4-5 步减少到 2-3 步。

**变化二：框架学习的优先级下降**

以前："我需要先学 LangChain 才能用 AI 编程"
现在："我需要先理解这个项目的业务逻辑才能用 AI 编程"

**变化三：Context 文件的价值被重新发现**

Claude Code 的 CLAUDE.md 不只是一个提示词文件——它是项目的"背景知识库"。

一个好的 CLAUDE.md 带来的效率提升，远大于学习任何 RAG 框架。

### 5.2 仍然有价值的东西

脚手架崩塌并不意味着所有框架知识都过时。以下技能反而变得更值钱：

**技能一：测试和验证**

当 AI 生成代码的速度大幅提升，人工验证成为主要瓶颈。测试驱动开发的投入产出比反而上升了——你需要更高效的测试能力来跟上 AI 的生成速度。

**技能二：Domain 理解**

脚手架帮你跳过"怎么做"，但不能帮你跳过"做什么"。对业务领域的深度理解成为真正的差异化。

**技能三：Context 工程**

知道给 Agent 什么信息、信息的组织方式、如何保持 context 的准确性和时效性——这是新时代的核心工程能力。

---

## 六、开发者行动指南：脚手架崩塌时代的策略

### 6.1 停止做的事情

- **停止深入学习 LangChain/LlamaIndex 的高级 API**：除非你要做框架开发者，否则投入产出比极低
- **停止为项目搭建复杂的 RAG pipeline**：除非你的场景有特殊需求，Claude Code 的原生检索已经足够
- **停止追求"最新框架"**：框架迭代速度远快于稳定速度，追新往往是浪费时间

### 6.2 开始做的事情

- **开始写高质量的 CLAUDE.md**：这是你最能控制的 context 来源
- **开始把团队决策记录到可被 Agent 读取的地方**：Git commit messages、ADR、架构文档
- **开始用自然语言描述任务**：把"写代码"思维转成"下达任务"思维

### 6.3 持续投入的事情

- **Domain 知识**：理解业务逻辑，理解用户需求，理解行业约束
- **测试能力**：验证 AI 输出的能力变得越来越重要
- **Context 管理**：系统化管理项目 context 的质量、时效性和可维护性

---

## 七、SageOX 的补充视角：团队知识本来就丢失了

VentureBeat 同期报道了 SageOX（Context Infrastructure 创业公司），他们的发现从另一个角度印证了"脚手架崩塌"的深层问题：

**AI Agent 在隔离的 session 中工作，缺乏团队先前决策的共享记忆。每个任务都从零开始。**

SageOX 的核心解决方案是：捕获"为什么"（Slack threads、白板讨论、会议决策），而不只是"是什么"（代码、文档）。

这与我们之前写的 Context Caching（2026-04-20）一文形成呼应：
- **Context Caching**：解决"记住了但没找到"的问题
- **SageOX**：解决"根本没记住"的问题

两者共同指向一个结论：**Context 是整个 AI 编程工具链中最薄弱的环节，而不是框架层**。

---

## 八、结论：复杂性没有消失，只是搬家了

### 8.1 脚手架崩塌的本质

脚手架层的崩塌不是"复杂性消失了"——复杂性从**代码层**（框架、编排管道）转移到了**问题层**（domain 知识、业务理解）。

Jerry Liu 的判断是对的：「新的编程语言本质上是英语」。这意味着：
- 更多的人可以参与 AI 辅助编程
- 但参与者的核心竞争力从"会写代码"变成了"会说清楚需求"

### 8.2 新的机会在哪里

脚手架崩塌后的新护城河：

| 领域 | 为什么是护城河 |
|------|-------------|
| Context infrastructure | 数据提取、文档处理、team memory |
| Domain expertise | AI 无法替代的领域理解 |
| Verification/testing | AI 生成速度越快，验证越重要 |
| AI tooling integration | 把 AI 能力组合成特定场景的解决方案 |

### 8.3 对 AI 编程工具的最终判断

LlamaIndex 95% AI 代码这个数字，是一个时代的分水岭。

它意味着：
- **框架时代正在结束**：脚手架的门槛被 AI 直接跨越
- **Context 时代正在开始**：谁能把 context 管理得更好，谁就能在 AI 时代产生更多价值
- **Developer 的定义在改变**：不再只是"写代码的人"，而是"能让 AI 正确做事的人"

对于每天在使用 Claude Code、Cursor、Copilot 的开发者来说，脚手架崩塌是一个好消息——你不再需要成为框架专家才能高效编程。

但它也是一个挑战——框架带来的"专业壁垒"消失了，竞争的基础变成了更难以量化的东西：context 的质量、domain 的深度、描述任务的清晰度。

这是更难建立的优势，也是更难被替代的优势。

---

## 延伸阅读

- [Context Caching 与 RAG 驱动的 AI Agent 记忆检索系统]({{ site.baseurl }}/posts/2026-04-20-context-caching-rag-agent-memory-retrieval/)
- [Claude Code 记忆架构深度指南]({{ site.baseurl }}/posts/2026-03-24-claude-code-memory-architecture/)
- [Tree-sitter 与 AI Coding Agent 的结构化理解力]({{ site.baseurl }}/posts/2026-05-05-tree-sitter-ai-coding-agent-structural-code-understanding/)
- VentureBeat: [The AI scaffolding layer is collapsing — LlamaIndex's CEO explains what survives](https://venturebeat.com/infrastructure/the-ai-scaffolding-layer-is-collapsing-llamaindexs-ceo-explains-what-survives)
- VentureBeat: [SageOX: Agentic context infrastructure](https://venturebeat.com/technology/ai-agents-are-missing-all-the-discussions-your-team-is-having-sageox-has-an-answer-agentic-context-infrastructure)
