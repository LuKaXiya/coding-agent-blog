---
layout: post
title: "AI Coding Agent 评估体系：从 SWE-bench 到 Tracelog，量化 Agent 是否在变好"
date: 2026-04-01 10:00:00 +0800
category: 深度思考
tags: ["AI评估", "Benchmark", "SWE-bench", "Tracelog", "Agent", "工程化", "Claude Code"]
---

> 一个 AI coding agent，上个月跑赢了 70% 的 SWE-bench 题目，这个月跑赢了 72%——这说明它真的在变好吗？

这是一个看似简单、实则复杂的问题。整个行业对 AI coding agent 的评估，要么停留在"跑个 benchmark 分数"，要么停留在"我用了半年感觉还行"。真正系统性地评估一个 AI coding agent 是否在变好、哪个维度在变好、哪个维度在退化——这套方法论目前几乎是空白的。

这篇文章尝试填补这个空白。我们会从 benchmark 的本质局限性出发，深入过程指标和输出质量评估，最终给出一个可操作的评估框架，适用于正在使用或研发 AI coding agent 的工程团队。

---

## 一、为什么"SWE-bench 分数"远远不够

SWE-bench（SWE = Software Engineering）是目前最被广泛引用的 AI coding 评估基准。它的测试方法是：给一个 AI agent 一个 GitHub Issue， agent 需要生成一个可接受 Pull Request，最后用测试套件验证这个 PR 是否正确解决了问题。

这个基准有价值，但它的局限性被严重低估了：

### 1. 它只测"解题"，不测"解题过程"

一个 agent 可能花 50 步解决了一个问题，另一个 agent 花 5 步解决了同一个问题——SWE-bench 给两者的分数是一样的。这意味着 SWE-bench 完全忽略了**效率**和**推理质量**。一个 agent 可能在错误的路径上探索了很长时间，最终碰巧找到正确答案；另一个 agent 精准定位问题并直接修复——两者都能通过测试，但工程价值天差地别。

### 2. 它无法评估非功能性维度

- **代码审查能力**：agent 是否能发现潜在 bug、安全漏洞、架构异味？
- **API 设计建议**：给定一个糟糕的接口设计，agent 能否提出改进方案？
- **大型重构安全性**：在数十个文件的大型重构中，agent 是否保持了行为一致性？
- **与人类工程师的协作体验**：agent 是否能理解模糊指令？是否能主动确认不确定的地方？

这些维度才是工程团队真正关心的东西，但没有一个被 SWE-bench 覆盖。

### 3. 数据集时效性问题

SWE-bench 的题目来自 2021-2022 年的真实 GitHub Issues。到了 2026 年，主流编程语言、框架、工具链已经发生了显著变化。用 2022 年的题目评估 2026 年的 agent，就像用 2022 年的编译器版本评估 2026 年的代码质量——参考价值有限。

### 4. 可操控性风险

随着 SWE-bench 被广泛引用，一些 agent 开始针对 SWE-bench 的题目模式进行优化，但这不代表它们在真实编程任务上变强了。这是 benchmark 评估的固有困境：**一旦某个指标被当作目标，它就不再是完美的衡量标准**。

---

## 二、评估的三个层次

基于上述问题，我提出一个更完整的评估框架，分三个层次：

### Level 1：任务完成率（Task Completion Rate）

**定义**：给定一组真实任务，agent 完成的比例。

这是最基础的指标，但必须控制好"任务集"的构成。一个有代表性的任务集应该包含：

```
任务分布建议：
├── 简单任务（修复单文件 bug）：30%
├── 中等任务（跨文件功能实现）：40%
├── 困难任务（大型重构、多模块依赖）：20%
└── 边界任务（模糊需求、安全敏感操作）：10%
```

任务完成率的局限我们已经讨论过——它只看结果，不看过程。因此，必须配合 Level 2 和 Level 3 的指标一起看。

### Level 2：过程指标（Process Metrics）

这是真正区分"好 agent"和"凑合 agent"的地方。

**2.1 工具调用效率（Tool Call Efficiency）**

一个高质量的 agent 应该在每个推理步骤选择正确的工具。工具调用效率的衡量方式：

```
工具误用率 = 工具误用次数 / 总工具调用次数

其中"工具误用"定义为：
- 用 Read 工具读取了一个二进制文件
- 用 Bash 执行了一个应该用专用工具完成的操作
- 在可以用 Read 的地方用了 Bash（效率低下）
```

**2.2 Context 消耗速率（Context Consumption Rate）**

这个指标衡量 agent 在解决问题时消耗 context 的效率。

```python
def calc_context_efficiency(trace: Trace) -> float:
    """
    返回每步平均 context 消耗。
    理想状态：步数少且每步 context 消耗合理。
    """
    total_context = sum(step.context_used for step in trace.steps)
    step_count = len(trace.steps)
    # 效率 = 解决问题消耗的总 context / 步数
    return total_context / step_count
```

一个 context 效率低的 agent 会在简单任务上浪费大量 context，而一个高效的 agent 会把 context 留给真正需要的复杂推理。

**2.3 错误恢复率（Error Recovery Rate）**

```
错误恢复率 = 自主恢复的错误数 / 总错误数

"自主恢复"定义：错误发生后 agent 自行修正并继续执行，不需要人工介入或重启 session。
```

这个指标直接反映了 agent 的自主性和鲁棒性。一个错误恢复率低的 agent 在 CI/CD 场景中是危险的——它很可能在遇到一个常见错误后就卡住，需要人类工程师介入。

**2.4 路径探索效率（Exploration Efficiency）**

这个指标衡量 agent 在解决问题时是否走了"冤枉路"：

```
路径效率 = 有效步数 / 总步数

有效步：直接推动问题解决的步骤
冤枉路：方向错误的探索、重复尝试同一个失败方案
```

获取这个数据需要分析 tracelog（见第三节）。

### Level 3：输出质量（Output Quality）

任务完成了不代表完成得好。输出质量评估需要独立的验证层——这就是 Harness Engineering 中"独立 Evaluator"概念的核心应用。

**3.1 代码正确性（Correctness）**

- 单元测试通过率
- 集成测试通过率
- 类型检查（TypeScript/Python mypy）通过率
- Lint 检查（ESLint/Pylint）通过率

**3.2 代码可维护性（Maintainability）**

- AI 生成代码的圈复杂度
- 重复代码片段比例
- 命名一致性
- 注释覆盖率

**3.3 变更安全性（Change Safety）**

这个维度对于大型重构尤其重要：

```
变更安全性 = 未变更的相关文件数是否正确 × 行为回归测试通过率

"未变更的相关文件"：在重构 A 模块时，B 模块不应被意外修改。
```

---

## 三、Tracelog：最有价值的自我评估手段

Tracelog（轨迹日志）是 Claude Code 提供的 `--output-format tracelog` 模式下生成的完整运行轨迹。每一个工具调用、每一个推理步骤、每一段 context 消耗都被完整记录下来。

Tracelog 的价值在于：它把"黑盒推理"变成了"可审计的过程数据"。即使你不做系统性评估，定期分析 tracelog 也能帮助你发现 agent 的行为模式和问题。

### 如何开启 Tracelog

```bash
claude --output-format tracelog \
  --output-dir ./tracelogs \
  "帮我修复这个 null pointer exception"
```

运行完成后，`./tracelogs/` 目录下会生成一个 `.jsonl` 文件，包含完整的执行轨迹。

### 从 Tracelog 中提取关键指标

```python
import json
from collections import Counter

def analyze_tracelog(path: str) -> dict:
    with open(path) as f:
        events = [json.loads(line) for line in f]

    tool_calls = [e for e in events if e["type"] == "tool_use"]
    errors = [e for e in events if e["type"] == "error"]
    context_breaks = [e for e in events if e["type"] == "context_compact"]

    # 1. 工具调用分布 — 识别异常模式
    tool_distribution = Counter(tc["tool"] for tc in tool_calls)
    excessive_reads = tool_distribution.get("Read", 0)

    # 2. 错误分析
    error_types = Counter(e["error_type"] for e in errors)

    # 3. 路径探索检测：同一文件被反复读取 = 可能的探索迷路
    file_reads = Counter(tc["path"] for tc in tool_calls if tc["tool"] == "Read")
    repeated_reads = {f: c for f, c in file_reads.items() if c > 3}

    return {
        "total_steps": len(events),
        "tool_calls": len(tool_calls),
        "errors": len(errors),
        "error_recovery_rate": calc_recovery(events),
        "tool_distribution": dict(tool_distribution),
        "repeated_file_reads": repeated_reads,
        "context_compacts": len(context_breaks),
    }
```

### Tracelog 分析的三个关键模式

**模式 1：重复读取同一文件（> 3 次）**

这通常意味着 agent 在记忆缺失和上下文不足之间挣扎——它读取了一个文件，但因为 context 窗口压力被清除，之后又需要这个信息，于是重新读取。这不是"错误"，而是 context 管理效率低下的信号。

**模式 2：错误后立即重试相同的失败命令**

在 tracelog 中，agent 遇到 `Command failed` 后立即用完全相同的命令重试——这说明 agent 没有从错误中学习。重试应该伴随参数调整或策略变化。

**模式 3：工具链断裂**

例如：agent 调用了 `Bash: pytest` 运行测试，测试失败后，agent 没有调用任何诊断工具（Read 测试文件、Bash 查看错误输出），而是直接修改了源代码。这说明 agent 在面对失败时缺乏系统的调试流程。

---

## 四、四象限评估法：工程团队的实用工具

基于上述三个层次的指标，我设计了一个实用的四象限评估法，适用于团队定期审查 AI coding agent 的表现：

```
                        高 正确性（测试通过率 > 90%）
                           │
         ┌─────────────────┼─────────────────┐
         │   Quadrant A    │   Quadrant B    │
         │   "Gold Zone"   │  "Need Review"  │
         │  正确 + 高效    │  正确但低效    │
低 速度  │  ✅ 继续保持    │  ⚠️ 优化 prompt│
(步数/   ├─────────────────┼─────────────────┤  高速度
context) │   Quadrant C    │   Quadrant D    │
         │   "High Risk"   │   "Fast Enough" │
         │  低效且低效    │  ⚠️ 假阳性风险 │
         │  ❌ 需人工复核  │  需边界测试    │
         └─────────────────┴─────────────────┘
                        低 正确性
```

**Quadrant A（Gold Zone）**：正确且高效，是理想状态。持续监控，警惕质量下滑。

**Quadrant B（Need Review）**：任务完成了，但花了太多步或太多 context。优化 prompt 或 task decomposition 策略。

**Quadrant C（High Risk）**：不正确且低效——这代表 agent 可能在错误的路径上运行了很长时间还不自知。必须立即人工介入并分析 tracelog。

**Quadrant D（Fast Enough）**：速度快但质量不稳定。这是很多"激进配置"的典型状态：为了追求响应速度关闭了某些安全检查。需要增加边界测试，确保在困难任务上不会出错。

---

## 五、如何建立团队级评估流水线

对于每天高频使用 AI coding agent 的工程团队，建立持续评估流水线比偶尔跑 benchmark 更有价值。

### 架构设计

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  任务采集器   │───▶│  Agent 执行器 │───▶│  Tracelog    │
│ (真实 Issue) │    │ (隔离环境)    │    │  收集器      │
└──────────────┘    └──────────────┘    └──────┬───────┘
                                                │
                    ┌───────────────────────────┘
                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  自动评分器   │───▶│  四象限判定   │───▶│  报告面板    │
│ (独立 Eval)  │    │              │    │ (趋势追踪)   │
└──────────────┘    └──────────────┘    └──────────────┘
```

### 关键实现要点

**1. 任务采集器必须来自真实场景**

不要用预设的 benchmark 题目，而是从团队真实的 issue tracker 中采样。当一个 agent 能稳定处理你们团队典型难度的真实任务，它才是真正有效的。

**2. Agent 执行必须在隔离环境中运行**

避免 agent 的操作对生产代码造成影响。使用临时工作目录或专门构建的测试仓库。

**3. 评分器必须是独立的 agent 或规则系统**

不要让执行 agent 自己评价自己的输出。评分 agent 应该只看到任务描述和最终产物，不应该知道执行过程（避免 bias）。

**4. 趋势比单点数据更有价值**

```
# 每周追踪的核心指标趋势
{
  "week": "2026-W13",
  "task_completion_rate": 0.84,     # vs 上周 0.81
  "avg_steps_per_task": 12.3,      # vs 上周 14.1 ↓ 改善
  "error_recovery_rate": 0.67,     # vs 上周 0.71 ↓ 需关注
  "quadrant_A_ratio": 0.72         # vs 上周 0.68 ↑ 改善
}
```

---

## 六、总结：评估不是为了证明 AI 有多强，而是为了知道它有多不可靠

写这篇文章的过程中，我越来越感觉到：评估 AI coding agent 的真正目的，不是证明"AI 越来越强了"，而是**系统性地知道它在什么情况下会失败**。

任何声称"我们的 agent 在 SWE-bench 上达到了 90% 正确率"的团队，如果不能回答以下三个问题，这个数字就没有太大意义：

1. **它在哪类任务上失败了？** 是并发/多线程？是安全敏感操作？是模糊需求？
2. **它失败了会怎样？** 是静默失败？是无限重试？是破坏性变更？
3. **你能提前知道吗？** 是否有检测手段能在 agent 走向错误路径的前期就发出预警？

这三个问题才是 AI coding agent 工程化的核心。也是为什么 Tracelog 分析、四象限评估、独立 Evaluator 这些看似"额外工作"的东西，实际上是 AI coding agent 从"能用演示"走向"生产可靠"的关键一步。

Benchmark 分数是起点，不是终点。真正重要的是建立一个持续的、可量化的反馈循环——让你的 agent 的每一次进步都能被看见，每一次退步都能被及时发现。

---

*附：如果你在团队中已经有了一套评估 AI coding agent 的实践，欢迎分享——这个领域目前最缺的不是更好的模型，而是更好的测量方法。*
