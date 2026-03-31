---
layout: post
title: "Harness Engineering：让 AI 编程 Agent 从「能用」到「可靠」"
date: 2026-03-31 17:00:00 +0800
category: 深度思考
tags: ["Harness Engineering", "AI编程", "可靠性", "Claude Code", "Agent", "Structured Handoff", "Session管理"]
---

> 当一个 AI coding agent 能跑起来，这不是本事。当它跑了两个小时、中途出错、换了模型、从断点恢复、最终交付正确结果——这才是本事。
>
> 前者叫"演示"，后者叫"工程"。

过去一年，行业讨论 AI 编程工具的焦点几乎都在**生成能力**：模型够不够强、上下文够不够长、支持多少种工具。但到了 2026 年，真正开始分出高下的已经不是"能不能生成"，而是**"跑的过程可不可控、结果可不可信、出错了能不能恢复"**。

这个从"能生成"到"可靠运行"的跨越，就是 **Harness Engineering** 要解决的核心问题。

---

## 一、为什么 AI coding agent 总是"跑着跑着就崩了"

用过 AI coding agent 做长任务的人，几乎都遇到过这个场景：

- 你给 agent 一个大型重构任务
- 它跑了 20 分钟，做了很多改动
- 然后突然遇到 context 满了，或者网络断了，或者模型报错了
- 你重新开 session，发现它完全不知道之前做了什么
- 要么从头来，要么接受一个"做到一半"的状态

这个问题的本质，不是模型不够强，而是**没有 harness**——没有一套控制结构让 autonomous agent 在复杂环境中可靠运行。

类比一下：赛车的引擎可以非常强大，但没有方向盘、刹车、安全气囊，这辆车在真实道路上照样不能开。Harness 就是那套控制装置。

---

## 二、什么是 Harness Engineering

**Harness Engineering** 是为 autonomous coding agent 设计可靠控制结构的工程学科。这个概念来自 Anthropic 的一篇关于 LLM agent 可靠性的研究，核心观点是：

> Long-horizon autonomous coding 的关键结构，不是更长的 context window，而是**独立 evaluator + 结构化 handoff + context reset** 三者的组合。

更直白地说：可靠 agent 的核心不是"一个人干到底"，而是**多人接力 + 每棒交接清楚 + 有人检查结果**。

具体来说，harness engineering 包括四个核心维度：

### 1. Session 生命周期管理

一个 autonomous coding agent 在真实环境中运行，会遇到各种中断：

- **主动中断**：人类发现它走错了方向，需要纠正
- **被动中断**：context 满了、API 报错、网络断了、token 限额到了
- **计划中断**：任务太大，需要分成多个阶段多次执行

Session 生命周期管理要回答的问题是：每次启动/恢复时，agent 怎么知道**"我从哪里开始、现在在哪、任务完成度是多少"**？

Claude Code 的 **compaction**（上下文压缩）是这个问题的产品级答案：当 context window 接近满时，将历史交互压缩为摘要，释放空间继续工作，同时保留关键决策记录。这让长时任务不需要从头开始。

### 2. Structured Handoff（结构化交接）

接力赛中，交接棒是最容易掉棒的环节。Agent 之间交接任务也是一样。

Structured Handoff 是指：当前一个 agent 完成后，不是把一坨原始对话记录扔给下一个 agent，而是用一种**双方都能理解的结构化格式**传递上下文。

Handoff 有四种常见模式，按信息密度和复杂度递增：

**模式 A：Pass-through（直传）**
把完整上下文直接传给下一个 agent。信息不丢失，但 token 成本高，下一个 agent 需要重新理解全部历史。

适用场景：同一任务的连续阶段，比如 planner agent 做完需求分析，直接把结构化需求文档交给 coder agent。

**模式 B：Structured Summary（结构化摘要）**
将前序 agent 输出压缩为结构化格式——状态机、决策树、或任务清单。Token 高效，下一 agent 只接收决策相关信息。

适用场景：跨专业方向的交接，比如 coder agent 完成后，把"改了什么文件、为什么这么改、还有什么没做"整理成摘要交给 reviewer agent。

**模式 C：Checkpoint Resume（检查点恢复）**
在任务中途保存为可恢复的 checkpoint——文件系统的快照加上决策记录。出错时从 checkpoint 恢复，而不是从头。

适用场景：大型重构、长时间测试套件运行。比如重构进行到 60% 时保存 checkpoint，下次恢复时 agent 能直接继续，而不是重新扫描整个代码库。

**模式 D：Verifiable Output（可验证输出）**
Agent 输出后，不直接接受，而是经过独立验证层检查后才推进。验证层可以是测试套件、类型检查器、lint 规则，或者——另一个 agent。

这是防止"agent 自信地错了"的最有效手段。Agent 往往会过度自信自己的输出，尤其是当它已经花了大量 token 之后。

### 3. 独立 Evaluator（独立评估层）

Anthropic harness 论文的核心洞察之一：**Agent 不应该自己验证自己的输出**。

这听起来反直觉，但如果你用过 AI coding agent 做复杂任务，会发现这个原则出奇地准确。Agent 在生成代码时做了大量假设，随着 context 积累，这些假设会悄悄累积偏差，agent 越来越难发现自己的错误——因为它已经在错误的方向上走了太远。

独立 Evaluator 的设计原则：
- **验证逻辑与生成逻辑解耦**：不是让 coder agent 判断自己写的代码对不对，而是引入独立的 checker agent 或自动化测试
- **覆盖度要有优先级**：不需要验证全部输出，只需要验证最关键的几类错误（功能正确性、安全边界、回归检测）
- **Evaluator 的置信度也需要评估**：如果 evaluator 本身也由 AI 驱动，它的误报率和漏报率同样需要被监控

在 Claude Code 的架构里，这个角色可以由 subagent 扮演：主 agent 生成代码，专门的 reviewer subagent 运行测试、类型检查、安全扫描，再把结果汇报给主 agent。

### 4. State Persistence（状态持久化）

如果一个任务跑了两个小时，中途崩溃了，重启后 agent 怎么知道**"任务做到哪了、哪些决策已经做了、还需要做什么"**？

State Persistence 要解决的是这个问题。当前主要有三种实现路径：

**路径 1：外部状态存储（External State Store）**
通过 MCP resource、数据库或文件系统存储任务状态。每个 checkpoint 包含：当前进度快照、待办清单、已完成的决策记录。下次恢复时读取状态文件，agent 直接从断点继续。

**路径 2：Memory 系统（Agent-native Memory）**
Claude Code 的 memory architecture 允许 agent 把关键信息写入持久化 memory，后续 session 可以查询这些 memory 来重建上下文。Memory 解决了"我知道这件事"的问题，但本身不解决"我知道这件事做到哪一步"的问题。

**路径 3：Hybrid（混合模式）**
Checkpoint 放在文件系统（保证可恢复），摘要写入 agent memory（保证快速理解），决策记录写入结构化日志（保证可审计）。这是目前最完整的方案，但实现成本也最高。

---

## 三、Claude Code 的 Harness 实现：现状与差距

如果你在用一个 2026 年的 AI coding 工具，Claude Code 已经是目前 harness 实现最完整的产品之一。让我拆解一下它的 harness 层次：

### Subagents（会话内隔离）

Subagents 在单一 session 内启动独立工作线程，有自己的 context window，不污染主 session 上下文。

典型用法：
- 长任务中需要探索多个方向（"先试试 React，再试试 Vue"），用 subagent 并行探索，主 agent 汇总结果
- 需要独立验证（"生成代码后，另起一个 subagent 运行测试"）
- 需要隔离有风险的实验操作

Claude Code 文档明确指出 subagent 和 agent teams 的选择依据：如果 workers 之间不需要相互通信，subagent 更高效；如果需要横向通信和协调，agent teams 更适合。

### Agent Teams（跨 session 协作）

这是目前最接近"真实 harness"的官方实现：多个 Claude Code 实例组成团队，有 lead agent 分配任务、协调进度、汇总结果。

但 Claude Code 官方文档也诚实列出了 **agent teams 的已知限制**：
- Session resumption 仍不完善
- Task coordination 在某些边界情况下可能出错
- Shutdown 行为有时不如预期

这说明即使是官方产品，harness engineering 在 2026 年初仍然是**未完全解决的工程问题**。这是正常的——任何复杂系统的可靠性工程都是迭代的。

### Compaction（上下文压缩）

Claude Opus 4.6 引入的 compaction 是 long-running agent 的关键技术。没有它，context window 再长也终究会满，agent 在长任务中必然会遇到"记不住了"的问题。

Compaction 的核心工程挑战是：**压缩不能丢失关键决策逻辑**，而这往往需要在 token 节省和决策连续性之间做 tradeoff。

---

## 四、为什么企业采纳的最后一关是 Harness

回到开头的那个问题：为什么很多团队引进 AI coding agent 后，用了一阵子就放弃了？

表面原因是"不准"、"容易出错"。深层原因是：**在真实工作流中，agent 的不可靠性带来的协调成本，超过了它带来的效率提升**。

当一个任务需要 2 小时，agent 在第 30 分钟崩溃了，你需要花 20 分钟恢复上下文、理解它做到哪了、决定要不要接受当前状态。这个"恢复成本"在 demo 阶段不会显现，在生产环境中却会变成主要摩擦。

这就是为什么企业采纳 AI coding agent 的路径是：

1. **单点工具阶段**（Copilot 自动补全）→ 已在大量团队落地
2. **会话 Copilot 阶段**（Claude Code / Cursor Composer）→ 正在普及
3. **Harness-Compliant Agent 阶段**（有完整 session 管理、checkpoint、可验证输出）→ 2026 年开始探索

第三阶段的核心变化是：不再问"这个 agent 够不够强"，而是问"**这个 agent 系统靠不靠谱**"。

这个问题，只有 harness engineering 能回答。

---

## 五、如何评估一个 AI Coding Agent 的 Harness 质量

如果你正在选型或评估 AI coding 平台，可以用以下五个问题快速评估它的 harness 成熟度：

**问题 1：Session 中断后能恢复吗？**
具体问：如果 agent 在任务中途崩溃，下次启动时它能从哪里继续？有没有 checkpoint？有没有决策记录？

**问题 2：Agent 的输出有独立验证吗？**
具体问：生成的代码谁来检查？是同一个 agent 自我验证，还是有独立的检查层？检查层的覆盖率是多少？

**问题 3：跨 Agent 交接时怎么传递上下文？**
具体问：当一个 subagent 完成后，主 agent 怎么知道它做了什么决定？是用自然语言摘要，还是结构化交接文档？

**问题 4：长任务中 context 满了怎么办？**
具体问：是用 compaction 压缩历史，还是直接崩溃？如果是压缩，压缩后的摘要保留了多少决策逻辑？

**问题 5：平台侧能看到 agent 做了什么吗？**
具体问：企业管理者能看到 agent 的操作日志吗？能追溯到具体哪个 session、哪个任务、哪个决策吗？这直接影响企业采纳的可审计性。

---

## 结语：工具在变，工程的本质没变

Harness Engineering 听起来是一个新概念，但它解决的是工程领域里最古老的问题之一：**如何让不可靠的组件组合成可靠的系统**。

软件工程花了五十年建立的可靠性实践——版本控制、CI/CD、自动化测试、监控告警——在 AI coding agent 时代同样适用，只是需要重新设计适配 AI agent 的版本。

Claude Code 的 subagents、compaction、agent teams、MCP 集成……这些功能合在一起，本质上是在构建一个**AI coding 领域的可靠性基础设施**。MCP 是工具的连接协议，agent teams 是协作模式，compaction 是长时运行的支撑——而把它们组合起来的那层设计，就是 harness。

理解这层设计，不只是技术选型的需要，更是**用好 AI coding agent 的前提**。只有知道工具背后的控制逻辑，你才能设计出让 AI agent 可靠工作的工程流程，而不是把一个强大的模型扔进混乱的工作流里，期待它自己搞定一切。

**工具变强了，工程还得跟上。**
