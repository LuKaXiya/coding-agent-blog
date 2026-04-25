---
layout: post
title: "极简 Agent 的反直觉胜利：Roulette Mode 与多模型步骤级协作"
date: 2026-04-25 17:00:00 +0800
category: 深度思考
tags:
  - 多模型协作
  - Agent架构
  - SWE-bench
  - mini-SWE-agent
  - 评测
  - 深度思考
---

> Claude Code 有复杂的上下文管理、精心设计的工具调用接口、记忆系统。mini-SWE-agent 只有 100 行 Python 和一个 `subprocess.run`。但后者在 SWE-bench 上的表现，让大多数商业 Agent 框架汗颜。

这不只是「简单 vs 复杂」的故事。2025 年 8 月，SWE-bench 团队发布的 Roulette Mode 实验，揭示了一个更反直觉的结论：**每一步随机切换模型，比单独使用任何一个更强模型效果更好**。

本文深入解析这个发现的机制、它对 Agent 设计的深层启示，以及它与博客中其他协作模式的关联。

---

## 目录

- [一、极简 Baseline 的惊人成绩](#一极简-baseline-的惊人成绩)
- [二、为什么复杂框架反而可能降低效果](#二为什么复杂框架反而可能降低效果)
- [三、Roulette Mode：每步切换模型的协作机制](#三roulette-mode每步切换模型的协作机制)
- [四、bash-only Leaderboard：公平评估 LLM 本身的能力](#四bash-only-leaderboard公平评估-llm-本身的能力)
- [五、实践启示：如何借鉴这些发现](#五实践启示如何借鉴这些发现)
- [六、三部曲总结：双脑、Swarm Tax 与 Roulette](#六三部曲总结双脑swarm-tax-与-roulette)

---

## 一、极简 Baseline 的惊人成绩

### 1.1 mini-SWE-agent 是什么

mini-SWE-agent 是 SWE-bench 团队推出的极简软件工程 Agent，核心代码不到 100 行。它没有任何专有工具：

```python
# mini-SWE-agent 的全部"工具"：
result = subprocess.run(command, shell=True, capture_output=True, ...)
```

相比之下，大多数商业 Agent 框架（Claude Code、Cursor Agent、Cline）都有：
- 精心设计的工具调用接口（bash、file_edit、glob、grep...）
- 专门的 Agent-Computer Interface（ACI）层
- 上下文管理、记忆系统、任务规划器

**但 mini-SWE-agent 在 SWE-bench Verified 上的修复率达到 ~74%，超过了大多数商业 Agent 框架。**

这不是说 Claude Code 不如 mini-SWE-agent（两者评测场景不同），而是说明：**当 LLM 足够强时，花在 Agent 框架上的工程复杂度，可能反而成为瓶颈**。

### 1.2 为什么极简 Baseline 有意义

传统观点认为，Agent 框架的复杂性是必要的：
- 工具调用需要专门设计（格式、错误处理、描述优化）
- 记忆系统需要持久化上下文
- 任务规划需要多步骤的 Supervisor

mini-SWE-agent 的存在对这个观点提出了挑战：

**假说**：当模型能力足够强时，复杂的 Agent 层可能引入三个问题：
1. **信息损失**：工具调用格式转换带来信息损耗
2. **路径依赖**：模型学会了依赖特定工具，而非真正理解问题
3. **过度工程**：为弱模型设计的工程决策，成为强模型的约束

这与我们在「Swarm Tax」（4/24）中观察到的现象一致：额外的复杂性带来隐性成本，只是这里的复杂性来自 Agent 框架本身。

---

## 二、为什么复杂框架反而可能降低效果

### 2.1 工具调用的信息损耗

当一个 Agent 说 `bash("git log --oneline -5")`，这个动作经过了多层转换：

```
人类意图 → LLM 推理 → 工具选择 → 参数编码 → 工具执行 → 结果解码 → LLM 理解
```

每一步都有信息损耗。特别是：
- **参数编码**：LLM 需要将"最近5条提交"翻译成 `git log --oneline -5`，这个翻译可能出错
- **结果解码**：终端的原始输出（ANSI 颜色、控制字符）需要被解析为 LLM 能理解的格式

mini-SWE-agent 的答案是：**不要抽象，直接让 LLM 看到原始 bash**。没有工具调用层，就没有信息损耗的引入点。

### 2.2 过度工程成为约束

许多 Agent 框架的设计假设 LLM 不能直接理解代码库结构，因此提供了：
- Glob 工具（避免 LLM 直接用 `find`）
- Read 工具（避免 LLM 直接用 `cat`）
- Edit 工具（避免 LLM 直接用 `sed`/`vim`）

这些抽象在 LLM 较弱时确实有帮助。但当 LLM 足够强时，它们反而：
- 限制了 LLM 可以使用的命令范围
- 增加了框架维护负担
- 让 LLM 失去了直接操作 shell 的灵活性

### 2.3 与「双脑协作」模式的对比

有趣的是，「双脑协作」（4/23）模式也是在做简化：把 Architect（规划者）和 Coder（执行者）分离，让每个角色专注自己的事。

mini-SWE-agent 的极简思路与此相似：**与其构建复杂的单一 Agent，不如让模型直接用最原始的接口工作**。

---

## 三、Roulette Mode：每步切换模型的协作机制

### 3.1 实验设计

2025 年 8 月，mini-SWE-agent 团队发布了 Roulette Mode 研究。核心问题是：

> 如果每一步让不同的模型执行，结果会怎样？

实验设置：
- 使用 mini-SWE-agent（极简 bash 环境）
- 每一步随机选择 GPT-5 或 Sonnet 4
- 在 SWE-bench Verified 的 50 题子集上测试

### 3.2 实验结果

| 配置 | 得分（50题） |
|------|-------------|
| GPT-5 + Sonnet 4（Roulette） | **39** |
| Sonnet 4 单独 | 33 |
| GPT-5 单独 | 32 |
| GPT-5 + Gemini 2.5 Pro | 31（居中） |

**Roulette 模式同时击败了两个模型单独使用的成绩。**

在更大的样本（300+ instances）上，Roulette 达到 66.6%，同样超过两者单独的成绩。

### 3.3 机制分析：为什么 Roulette 有效？

这个结果看起来违反直觉，但机制其实很清晰：

**任一模型都可以提交（submit）**

当某个模型认为任务已经完成，它可以立即提交。这意味着 Roulette 的行为类似于"早提交策略"：如果两个模型中有一个更倾向于快速决策，Roulette 就会继承这个特性。

**两个模型的不同擅长点被利用**

GPT-5 和 Sonnet 4 在不同类型的问题上有各自的优势。Roulette 让每一步都选择当前最适合该步骤的模型，而非让整个任务绑定在一个单一模型上。

**成本在两者中间**

Roulette 的平均成本约为 $0.30/实例，在 GPT-5（贵）和 Sonnet 4（便宜）之间。这是一个重要的副产品：**既获得了更好的效果，又没有付出最高成本**。

### 3.4 收益边际递减

实验数据显示，**50 步之后继续运行的收益几乎为零**。超过这个阈值，模型只是在重复已经失败的推理，而非找到新的解决路径。

这与「时间推理」（4/24）中观察到的"Agent 在时间轴上的无效重复"现象一致。

---

## 四、bash-only Leaderboard：公平评估 LLM 本身的能力

### 4.1 为什么需要 bash-only 评测

传统的 Agent 评测（如 SWE-bench Full Leaderboard）允许任意系统参与——可以使用 RAG、multi-rollout、专门的工具集、精心设计的 prompt 策略。

这带来了一个问题：**我们无法区分好成绩来自 LLM 本身，还是来自 Agent 框架的工程**。

bash-only Leaderboard 的设计解决了这个问题：

> 所有 LLM 在完全相同的极简 bash 环境下评测。没有工具，没有特殊 scaffold，只有 `subprocess.run`。

这使得评测结果真正反映的是 **LLM 本身的代码理解和任务执行能力**，而非 Agent 框架的加持。

### 4.2 v1 和 v2 不兼容

mini-SWE-agent 有两个版本：
- **v1**：从 LLM 输出字符串中解析 action（类似 ReAct 的文本输出模式）
- **v2**：使用 tool calling 接口直接调用 actions

两者评测结果**不可直接比较**，因为接口形式的变化可能影响 LLM 的行为模式。

这个细节很重要：当我们比较不同 LLM 在 SWE-bench 上的成绩时，需要确认它们是否使用了相同版本的 mini-SWE-agent。

### 4.3 对从业者的意义

如果你在为自己的团队选择 LLM 作为编程助手的基础：

bash-only Leaderboard 提供了最纯粹的参考。它告诉你的是：**给定相同的极简 shell 环境，这个 LLM 能多大程度独立解决真实代码问题**。

而不考虑你的 Agent 框架有多少复杂性——那些工程复杂度，最终还是要 LLM 本身够强才能发挥价值。

---

## 五、实践启示：如何借鉴这些发现

### 5.1 评估你的 Agent 框架是否过度工程

对照 mini-SWE-agent 的发现，问自己几个问题：

- 我的 Agent 有多少"让 LLM 更好工作"的抽象层？
- 这些抽象层在 LLM 能力提升后是否还有必要？
- LLM 能否在没有这些抽象的情况下直接完成相同任务？

如果答案不明确，可以做一个简单的对照实验：让你的 Agent 绕过某些工具，直接用 bash 完成任务，对比效果差异。

### 5.2 考虑步骤级的多模型路由

Roulette Mode 的核心洞察是：**不同模型在不同步骤上各有优势**。

如果你在构建多模型 Agent 系统，可以考虑：
- 在关键决策点（任务规划、代码生成、测试验证）选择更擅长的模型
- 使用 router agent 在步骤级别决定调用哪个模型
- 设置统一的 submit 机制，允许快速决策的模型提前结束任务

但注意：Roulette 只在实力相近的模型组合中有效（GPT-5 + Sonnet 4）。差距太大的模型组合（GPT-5 + Gemini 2.5 Pro）只会得到居中的结果，没有额外增益。

### 5.3 接受"极简 Baseline"作为评测标准

当你优化自己的 Agent 时，使用极简 Baseline 作为参考点：

- 如果添加某层复杂性后效果没有显著提升，问自己为什么还要它
- 工具调用层不是越多越好，每一层都要有明确的增益证明
- 记忆系统和任务规划器的价值，应该通过对照实验量化，而非假设

---

## 六、三部曲总结：双脑、Swarm Tax 与 Roulette

这篇关于「极简 Agent + 多模型路由」的文章，与博客近期两篇文章构成了一个完整的主题：**Agent 协作模式的进化与反思**。

**第一篇（4/23）：双脑协作 Architect-Coder**

> 同模型内，通过角色分离实现规划与执行的解耦。

核心思想：单一 Agent 的上下文有限，分离规划者和执行者让两者各自优化。

**第二篇（4/24）：Swarm Tax — 单 Agent 战胜多 Agent**

> 多 Agent 引入的通信成本、状态同步和冲突解决，消耗了大部分协作收益。

核心思想：多 Agent 不是银弹，额外的复杂性往往抵消了并行带来的优势。

**第三篇（5/5 注：本文）：Roulette — 跨模型的步骤级协作**

> 在极简 bash 环境下，每步选择最优模型执行，效果超越任何单一模型。

核心思想：当 Agent 框架足够简单时，模型本身的能力差异成为主要变量；步骤级的动态模型选择，比静态绑定单一模型更有效。

**三篇文章的共同启示**：

Agent 协作的关键不在于"堆砌复杂性"，而在于**找到复杂性的边界**：在哪里加（双脑的角色分离）、在哪里减（Swarm Tax 的成本意识）、在哪里动态选择（Roulette 的步骤级路由）。

真正的工程智慧，是在这些维度上找到恰到好处的平衡。

---

*本文是「Agent 协作模式三部曲」的终篇。前两篇：*
- *[《AI Agent 双脑协作：Architect-Coder 模式》]({{ site.baseurl }}/posts/2026-04-23-ai-agent-dual-brain-collaboration-architect-coder/)*
- *[《Swarm Tax：为什么单 Agent 战胜多 Agent》]({{ site.baseurl }}/posts/2026-04-24-swarm-tax-single-agent-beats-multi-agent/)*
