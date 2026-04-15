---
layout: post
title: "Supervisor Pattern 深度指南：任务分解质量与工作流级错误恢复"
category: 多Agent
tags: ["Supervisor", "任务分解", "工作流", "错误恢复", "编排", "Multi-Agent", "Supervisor Pattern", "Agent治理"]
date: 2026-04-15 17:30:00 +0800
---

> 多 Agent 系统一旦出了问题，人们习惯于怪 Worker——「这个 Worker 能力不行」「这个 Worker 总是在犯错」。但在实际项目中，多 Agent 系统的大多数故障，根因不在 Worker，而在 Supervisor 的任务分解。当一个 Worker 反复失败时，第一反应不应该是换一个 Worker，而是问：Supervisor 把任务分对了吗？

本文是《Multi-Agent 系统故障诊断实战》的姊妹篇。上文解决了「坏了怎么查」，本文解决「查到后怎么处理」——Supervisor 如何通过高质量的任务分解和系统化的错误恢复机制，让整个工作流在故障发生时依然可靠运行。

---

## 目录

- [一、多 Agent 系统的大多数失败，根因在 Supervisor](#一多-agent-系统的大多数失败根因在-supervisor)
- [二、任务分解的三种失败模式](#二任务分解的三种失败模式)
- [三、任务分解质量的衡量框架](#三任务分解质量的衡量框架)
- [四、工作流级错误恢复决策树](#四工作流级错误恢复决策树)
- [五、Checkpoint 回退与增量恢复机制](#五checkpoint-回退与增量恢复机制)
- [六、Supervisor 的自我监控与自我调整](#六supervisor-的自我监控与自我调整)
- [七、实战：实现一个自监控的 Supervisor](#七实战实现一个自监控的-supervisor)
- [八、Supervisor 的设计原则与职责边界](#八supervisor-的设计原则与职责边界)

---

## 一、多 Agent 系统的大多数失败，根因在 Supervisor

先破除一个常见误解。

当一个 Worker 反复失败时，团队通常的反应是：
- 换一个更强的 Worker（升级模型）
- 给 Worker 更多的上下文（扩大 context）
- 优化 Worker 的 System Prompt（改 prompt）

这些方法有时有效，但更多时候是在治标不治本。

**更应该问的问题是**：Supervisor 把任务分对了吗？

```
典型场景：
Supervisor 把「修复登录 bug」分解为：
  Worker-A: 修复登录 bug（没有任何上下文）
  → Worker-A 反复失败（不知道代码库结构、不知道登录流程）
  → 团队认为是 Worker 能力问题
  
实际：
Supervisor 应该先分解为：
  1. 分析登录模块（Worker-A）
  2. 定位 bug 根因（Worker-B）
  3. 修复代码（Worker-C）
  4. 验证修复（Worker-D）
```

这个例子里，Worker 的失败是 Supervisor 分解失败的结果。换个更强的 Worker 不如换个更好的分解方式。

**Supervisor 的核心职责**不只是「把任务分下去」，而是：
1. 保证每个子任务可以在**没有其他子任务输出的情况下独立完成**
2. 保证子任务之间的**依赖关系被显式标注且可执行**
3. 保证子任务的**粒度与 Worker 能力匹配**
4. 当 Worker 失败时，**正确路由到对应的恢复策略**

---

## 二、任务分解的三种失败模式

### 模式 1：过度分解（Over-decomposition）

把一个本该独立的完整任务，强行拆成多个碎片，并行分给不同的 Worker。

```
Supervisor 把「修复登录 bug」分解为：
  Worker-A: 读取 login.py 第 1-50 行
  Worker-B: 读取 login.py 第 51-100 行
  Worker-C: 读取 login.py 第 101-150 行
  Worker-D: 汇总分析
```

**症状**：Worker 各说各话，汇总时发现信息碎片化、无法形成完整理解。

**根因**：Supervisor 假设「越细越好」，但过度拆分破坏了任务的完整性。每个 Worker 只看到局部，没有人理解整体。

**判断信号**：
- 多个 Worker 的输出没有交集，无法合并
- 某个 Worker 的输出是另一个 Worker 的输入的超集（说明分解时机不对）
- 并行执行时间 > 串行执行时间（并行收益为负）

### 模式 2：欠分解（Under-decomposition）

把一个超出任何单个 Worker 能力范围的任务，直接交给一个 Worker 处理。

```
Supervisor 把「重构整个订单模块」分解为：
  Worker-A: 重构整个订单模块（涉及 20+ 文件，多个领域概念）
```

**症状**：Worker 陷入无限循环，或者给出质量极低的输出（因为无法在有限 context 内理解完整系统）。

**根因**：Supervisor 低估了任务的复杂度。一个「看起来简单」的任务，可能涉及多个领域知识和大量上下文。

**判断信号**：
- Worker 的执行时间远超预期
- Worker 的输出质量随 context 增长而下降（说明超出处理能力）
- Worker 主动上报「任务太复杂，需要更多上下文」

### 模式 3：依赖缺失（Missing Dependencies）

分解时没有标注清楚依赖关系，导致执行顺序错误。

```
Supervisor 分解（假设并行执行）：
  Worker-A: 实现支付接口（需要 UserService.get_user(id) 方法）
  Worker-B: 实现用户服务

并行执行时：
  Worker-A 开始 → 需要 UserService → UserService 还不存在 → 失败
  Worker-B 开始 → 正常执行
```

**症状**：某个 Worker 在执行时发现「需要的东西还不存在」。

**根因**：Supervisor 没有做拓扑排序，或者假设了错误的执行顺序。

**判断信号**：
- 某个 Worker 的失败消息包含「not found」「undefined」「not yet available」
- 日志显示 Worker 在等待某个资源，但该资源没有被优先分配
- 任务分解图存在环（循环依赖）

---

## 三、任务分解质量的衡量框架

在写代码前，可以用这个框架检查分解质量。

### 3.1 分解充分性

每个子任务必须能够在**没有其他子任务输出的情况下独立完成**。

```python
def check_decomposition_quality(tasks):
    """
    检查分解质量

    每个任务应该能回答：
    1. 这个任务的输入是什么？（来自 Supervisor 还是其他 Worker）
    2. 这个任务的输出是什么？
    3. 其他任务是否依赖这个任务的输出？
    """
    issues = []

    for task in tasks:
        # 检查1：输入是否已就绪
        for dep in task.dependencies:
            if not dep.is_produced_before(task):
                issues.append(f"[{task.id}] 依赖 {dep.id}，但该任务的执行时机无法保证在 {task.id} 之前")

        # 检查2：任务是否太简单（过度分解）
        if task.complexity < COMPLEXITY_THRESHOLD:
            # 再检查是否值得单独成为一个任务
            if not task.has_side_effects:
                issues.append(f"[{task.id}] 过于简单，考虑合并到其他任务")

        # 检查3：任务是否太复杂（欠分解）
        if task.complexity > COMPLEXITY_THRESHOLD * 3:
            issues.append(f"[{task.id}] 过于复杂，考虑拆分为多个子任务")

    return issues
```

### 3.2 依赖清晰性

子任务之间的依赖关系必须构成**有向无环图（DAG）**。

```python
def check_dependency_graph(tasks):
    """
    依赖关系必须是 DAG（有向无环图）
    - 每条边从依赖方指向被依赖方
    - 不能有环
    """
    # 构建邻接表
    graph = {task.id: [] for task in tasks}
    in_degree = {task.id: 0 for task in tasks}

    for task in tasks:
        for dep in task.dependencies:
            graph[dep.id].append(task.id)
            in_degree[task.id] += 1

    # 检测环（Kahn 算法）
    queue = [t for t in tasks if in_degree[t.id] == 0]
    processed = 0

    while queue:
        node = queue.pop(0)
        processed += 1
        for neighbor in graph[node.id]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    if processed != len(tasks):
        # 有环
        cycle_nodes = [t for t in tasks if in_degree[t.id] > 0]
        raise CycleDetectedError(f"检测到循环依赖: {cycle_nodes}")

    return True
```

### 3.3 粒度合理性

子任务的复杂度应该与 Worker 的能力匹配。

```
任务复杂度等级：
  L1（简单）：单文件、单函数的修改
  L2（中等）：跨文件但同模块的实现
  L3（复杂）：跨模块、涉及多个领域
  L4（极复杂）：跨服务、涉及架构决策

Worker 能力等级：
  W1（执行者）：只能执行明确指令，不擅长规划
  W2（专家）：在特定领域有深度理解
  W3（通才）：能够处理复杂、多领域的任务

匹配原则：任务复杂度 ≤ Worker 能力 + 1
```

---

## 四、工作流级错误恢复决策树

当 Worker 返回错误时，Supervisor 的第一反应不应该是「重试」，而是**分析错误类型**，然后路由到正确的处理策略。

### 4.1 五种错误类型的分类

| 错误类型 | 特征描述 | 典型信号 |
|---------|---------|---------|
| 瞬时错误 | 网络、权限、临时不可用 | timeout, permission denied, connection reset |
| 能力不足 | 任务超出 Worker 理解范围 | context overflow, unknown tool, malformed output |
| 依赖失败 | 上游任务未产生预期输出 | not found, undefined, upstream not ready |
| 资源耗尽 | Token/时间/内存超出限制 | max_tokens, timeout, out of memory |
| 未知错误 | 无法归类的错误 | unexpected error, unknown |

### 4.2 错误路由决策树

```
Worker 返回错误
    │
    ├─ 是瞬时错误？（timeout / permission / connection）
    │   ├─ 重试（指数退避，最多 3 次）
    │   │      ├─ 第 1 次重试：等待 1 秒
    │   │      ├─ 第 2 次重试：等待 2 秒
    │   │      └─ 第 3 次重试：等待 4 秒
    │   │             ├─ 成功 → 继续
    │   │             └─ 失败 → 路由到未知错误
    │   │
    │   └─ 否 ↓
    │
    ├─ 是能力不足？（context overflow / unknown tool）
    │   ├─ 检查任务是否过度复杂（欠分解）
    │   │      ├─ 是 → 重新分解（拆成更小的子任务）
    │   │      └─ 否 → 升级 Worker 能力（换更强的模型）
    │   │
    │   └─ 否 ↓
    │
    ├─ 是依赖失败？（not found / undefined）
    │   ├─ 检查依赖拓扑
    │   │      ├─ 依赖尚未执行 → 调整执行顺序（拓扑重排）
    │   │      └─ 依赖执行失败 → 递归处理上游错误
    │   │
    │   └─ 否 ↓
    │
    ├─ 是资源耗尽？（max_tokens / timeout）
    │   ├─ 检查是否是 context 溢出
    │   │      ├─ 是 → 压缩 context（摘要/清理）后重试
    │   │      └─ 否 → 检查任务是否太复杂（拆解任务）
    │   │
    │   └─ 否 ↓
    │
    └─ 是未知错误？
        └─ 是 → 上报人类（含完整上下文和已尝试的恢复策略）
```

### 4.3 恢复策略的工程实现

```python
from enum import Enum
from typing import Callable
import time

class ErrorType(Enum):
    TRANSIENT = "transient"       # 瞬时错误
    CAPABILITY = "capability"    # 能力不足
    DEPENDENCY = "dependency"    # 依赖失败
    RESOURCE = "resource"        # 资源耗尽
    UNKNOWN = "unknown"           # 未知错误

class RecoveryStrategy:
    def __init__(self):
        self.strategies: dict[ErrorType, Callable] = {
            ErrorType.TRANSIENT: self._handle_transient,
            ErrorType.CAPABILITY: self._handle_capability,
            ErrorType.DEPENDENCY: self._handle_dependency,
            ErrorType.RESOURCE: self._handle_resource,
            ErrorType.UNKNOWN: self._handle_unknown,
        }

    def classify(self, error_msg: str, context: dict) -> ErrorType:
        """根据错误信息和上下文分类错误类型"""
        error_lower = error_msg.lower()

        # 瞬时错误信号
        transient_signals = ["timeout", "connection", "permission denied", "econnreset", "etimedout"]
        if any(signal in error_lower for signal in transient_signals):
            return ErrorType.TRANSIENT

        # 能力不足信号
        capability_signals = ["context.*overflow", "unknown.*tool", "malformed.*output", "does not understand"]
        if any(signal in error_lower for signal in capability_signals):
            return ErrorType.CAPABILITY

        # 依赖失败信号
        dependency_signals = ["not found", "undefined", "not.*available", "upstream"]
        if any(signal in error_lower for signal in dependency_signals):
            return ErrorType.DEPENDENCY

        # 资源耗尽信号
        resource_signals = ["max_tokens", "out of memory", "budget"]
        if any(signal in error_lower for signal in resource_signals):
            return ErrorType.RESOURCE

        return ErrorType.UNKNOWN

    def recover(self, error: Exception, task: dict, context: dict) -> dict:
        """根据错误类型执行对应的恢复策略"""
        error_type = self.classify(str(error), context)
        strategy = self.strategies[error_type]

        # 记录恢复尝试
        recovery_log = {
            "error": str(error),
            "error_type": error_type.value,
            "task_id": task.get("id"),
            "attempt": context.get("retry_count", 0),
            "timestamp": now_iso(),
        }

        result = strategy(task, context, error)
        recovery_log["result"] = result

        return recovery_log

    def _handle_transient(self, task: dict, context: dict, error: Exception) -> dict:
        """瞬时错误：指数退避重试"""
        retry_count = context.get("retry_count", 0)
        max_retries = 3

        if retry_count >= max_retries:
            return {"action": "escalate", "reason": "max_retries_exceeded"}

        # 指数退避：1s, 2s, 4s
        wait_seconds = 2 ** retry_count
        time.sleep(wait_seconds)

        return {"action": "retry", "wait_seconds": wait_seconds, "task": task}

    def _handle_capability(self, task: dict, context: dict, error: Exception) -> dict:
        """能力不足：检查是否欠分解，或升级 Worker"""
        task_complexity = context.get("task_complexity", "unknown")

        if task_complexity == "over_decomposed":
            # 过度分解 → 合并相关任务
            return {"action": "merge_tasks", "tasks_to_merge": context.get("related_tasks", [])}

        elif task_complexity == "under_decomposed":
            # 欠分解 → 拆分为更小的子任务
            return {"action": "refine_task", "original_task": task}

        else:
            # Worker 能力不足 → 升级
            return {"action": "upgrade_worker", "task": task}

    def _handle_dependency(self, task: dict, context: dict, error: Exception) -> dict:
        """依赖失败：重新拓扑排序"""
        dag = context.get("dependency_graph")

        if dag.has_cycle():
            return {"action": "escalate", "reason": "circular_dependency_detected"}

        # 重新排序
        new_order = dag.topological_sort()
        return {"action": "reschedule", "new_order": new_order}

    def _handle_resource(self, task: dict, context: dict, error: Exception) -> dict:
        """资源耗尽：压缩 context 或拆分任务"""
        resource_type = context.get("resource_type", "unknown")

        if resource_type == "context":
            # Context 溢出 → 摘要清理后重试
            return {"action": "compress_context", "task": task}
        else:
            # 其他资源 → 拆分任务
            return {"action": "split_task", "task": task}

    def _handle_unknown(self, task: dict, context: dict, error: Exception) -> dict:
        """未知错误：上报人类"""
        return {
            "action": "escalate",
            "reason": "unknown_error",
            "error": str(error),
            "task": task,
            "context_summary": summarize_context(context),
        }
```

---

## 五、Checkpoint 回退与增量恢复机制

### 5.1 为什么需要 Checkpoint

当工作流执行到一半失败时，最简单的方式是「从头重跑」——但这在复杂工作流中成本极高。

```
工作流有 10 个任务，执行到第 8 个时失败
从头重跑：需要重新执行 1-7
实际只需要重新执行 7-10（假设 7 的输出因 8 的失败而失效）
```

Checkpoint 机制：在关键节点保存状态快照，失败时只回退到上一个有效的检查点。

### 5.2 Checkpoint 的设置策略

不是每个任务后都需要 checkpoint，而是选择**关键节点**：

```python
# Checkpoint 策略
CHECKPOINT_AFTER = [
    "task_type: architecture_decision",  # 架构决策影响后续所有实现
    "task_type: refactoring",            # 重构改变多个文件，容易引发连锁反应
    "task_type: schema_change",          # Schema 变更影响上下游
    "status: needs_human_review",        # 需要人工审核的节点
]

def should_checkpoint(task: dict) -> bool:
    """判断任务完成后是否需要 checkpoint"""
    return (
        task.get("type") in CHECKPOINT_AFTER
        or task.get("status") == "needs_human_review"
        or task.get("risk_level") == "high"
    )
```

### 5.3 增量恢复（只重做必要的部分）

```python
def recover_workflow(failed_task_id: str, checkpoint_manager: CheckpointManager):
    """
    增量恢复：只重做失败任务及其下游
    1. 找到失败任务的上一个有效 Checkpoint
    2. 恢复状态到 Checkpoint
    3. 只重新执行 Checkpoint 之后的任务（而不是整个工作流）
    """
    # Step 1: 找到最近的有效 Checkpoint
    last_valid_checkpoint = checkpoint_manager.get_last_valid(failed_task_id)

    # Step 2: 恢复状态
    restored_state = checkpoint_manager.restore(last_valid_checkpoint)

    # Step 3: 确定需要重做的任务范围
    # 只重做：checkpoint 之后的任务 + 失败任务的下游
    tasks_to_rerun = get_downstream_tasks(last_valid_checkpoint.task_id)
    tasks_to_rerun.add(failed_task_id)

    # Step 4: 按依赖顺序重做
    for task in topological_sort(tasks_to_rerun):
        result = execute_task(task, restored_state)
        if result.is_failed():
            # 如果重做仍然失败，说明问题不在下游，可能是 Checkpoint 之前的问题
            # 递归回退到更早的 Checkpoint
            return recover_workflow(task.id, checkpoint_manager)
        restored_state.update(task.id, result)

    return restored_state
```

---

## 六、Supervisor 的自我监控与自我调整

### 6.1 健康度指标体系

Supervisor 需要持续监控整个工作流的健康状态：

```python
class SupervisorHealthMonitor:
    def __init__(self):
        self.metrics = {
            "task_completion_rate": [],   # 任务完成率
            "retry_rate": [],              # 重试率（过高说明分解有问题）
            "escalation_rate": [],         # 上报率（过高说明 Worker 不匹配）
            "avg_task_duration": [],       # 平均任务时长
            "context_contamination": 0,    # 上下文污染事件数
        }

    def record_task_outcome(self, task_id: str, outcome: dict):
        """记录任务结果，用于计算健康度"""
        self.metrics["task_completion_rate"].append(
            1.0 if outcome["status"] == "success" else 0.0
        )
        self.metrics["retry_rate"].append(outcome.get("retry_count", 0))
        self.metrics["escalation_rate"].append(
            1.0 if outcome["status"] == "escalated" else 0.0
        )
        self.metrics["avg_task_duration"].append(outcome.get("duration_seconds", 0))

    def compute_health_score(self) -> float:
        """
        计算工作流健康度得分（0-100）

        权重：
          完成率（30%）：任务是否顺利完成
          重试率（25%）：重试次数是否异常高
          上报率（20%）：需要人工介入的比例
          时效性（15%）：任务执行时间是否正常
          稳定性（10%）：上下文污染事件
        """
        completion_rate = mean(self.metrics["task_completion_rate"])
        retry_rate = normalize_retry_rate(mean(self.metrics["retry_rate"]))
        escalation_rate = mean(self.metrics["escalation_rate"])
        duration_anomaly = self._detect_duration_anomaly()

        score = (
            completion_rate * 0.30
            + retry_rate * 0.25
            + (1 - escalation_rate) * 0.20
            + duration_anomaly * 0.15
            + self._compute_stability() * 0.10
        )

        return round(score * 100, 1)

    def should_self_adjust(self) -> bool:
        """判断是否需要自我调整"""
        score = self.compute_health_score()
        return score < 70  # 健康度低于 70 时触发调整
```

### 6.2 自我调整策略

当健康度低于阈值时，Supervisor 应该能自动调整：

| 健康度信号 | 问题诊断 | 调整策略 |
|-----------|---------|---------|
| 低完成率 + 高重试率 | 任务分解粒度太粗 | 自动拆分任务为更小的子任务 |
| 高上报率 + 低完成率 | Worker 能力不匹配 | 重新分配到更合适的 Worker |
| 上下文污染事件 | 缺乏 Filter 层 | 在消息传递路径中注入过滤规则 |
| 任务时长异常增长 | 任务复杂度过高 | 自动拆分任务或提高资源配额 |

```python
def self_adjust(supervisor: Supervisor, health_report: dict):
    """根据健康度报告自动调整"""
    actions_taken = []

    if health_report["retry_rate"] > 0.5:
        # 高重试率 → 检查是否欠分解
        for task in supervisor.tasks:
            if task.retry_count > 3:
                subtasks = decompose_smaller(task)
                supervisor.replace_task(task, subtasks)
                actions_taken.append(f"拆分了任务 {task.id} 为 {len(subtasks)} 个子任务")

    if health_report["escalation_rate"] > 0.2:
        # 高上报率 → 检查 Worker 能力匹配
        for assignment in supervisor.task_assignments:
            if assignment.worker.capability < assignment.task.required_capability:
                new_worker = find_better_worker(assignment.task)
                supervisor.reassign(assignment.task, new_worker)
                actions_taken.append(f"重新分配 {assignment.task.id} 到更强的 Worker")

    return actions_taken
```

---

## 七、实战：实现一个自监控的 Supervisor

下面展示一个完整的自监控 Supervisor 实现，整合了任务分解质量检查、错误路由和健康度监控。

```python
class IntelligentSupervisor:
    """
    自监控 Supervisor：
    1. 任务分解时自动检查分解质量
    2. Worker 失败时自动路由到正确的恢复策略
    3. 持续监控工作流健康度，自动调整分解策略
    """

    def __init__(self, workers: list[Worker], config: dict):
        self.workers = workers
        self.config = config
        self.recovery = RecoveryStrategy()
        self.health_monitor = SupervisorHealthMonitor()
        self.checkpoint_manager = CheckpointManager()

    def decompose_and_validate(self, task: Task) -> list[Task]:
        """分解任务并验证分解质量"""
        subtasks = self._decompose(task)

        # 质量检查
        issues = check_decomposition_quality(subtasks)
        if issues:
            # 尝试自动修复
            subtasks = self._auto_fix_decomposition(subtasks, issues)

        return subtasks

    def execute_with_recovery(self, task: Task, worker: Worker) -> dict:
        """带错误恢复的任务执行"""
        context = {"retry_count": 0, "task_complexity": "normal"}

        while context["retry_count"] < 5:
            result = worker.execute(task, context)

            if result.is_success():
                self.health_monitor.record_task_outcome(task.id, {
                    "status": "success",
                    "duration_seconds": result.duration,
                })
                self.checkpoint_manager.save_checkpoint(task.id, result)
                return result

            # 分类错误
            recovery_action = self.recovery.recover(
                result.error, task, context
            )

            if recovery_action["action"] == "retry":
                context["retry_count"] += 1
                continue

            elif recovery_action["action"] == "escalate":
                self.health_monitor.record_task_outcome(task.id, {
                    "status": "escalated",
                    "duration_seconds": result.duration,
                    "error": result.error,
                })
                return self._escalate_to_human(task, recovery_action)

            elif recovery_action["action"] == "reschedule":
                # 重新拓扑排序后重试
                new_order = recovery_action["new_order"]
                return self._reschedule_and_execute(new_order)

            elif recovery_action["action"] == "refine_task":
                # 拆分任务后重新分配
                refined = self._refine_task(task)
                return self.execute_with_recovery(refined, worker)

        # 达到最大重试次数，上报
        return self._escalate_to_human(task, {"reason": "max_retries_exceeded"})

    def run(self, workflow: Workflow) -> dict:
        """运行完整工作流"""
        # Step 1: 分解 + 验证
        tasks = self.decompose_and_validate(workflow.root_task)

        # Step 2: 拓扑排序，确定执行顺序
        execution_order = topological_sort(tasks)

        # Step 3: 执行 + 监控
        for task in execution_order:
            worker = self._select_worker(task)
            result = self.execute_with_recovery(task, worker)

            if result.is_failed() and result.needs_human():
                return {"status": "needs_review", "task": task, "result": result}

        # Step 4: 健康度检查
        if self.health_monitor.should_self_adjust():
            adjustments = self.self_adjust()
            return {"status": "completed_with_adjustments", "adjustments": adjustments}

        return {"status": "completed", "results": execution_order}
```

---

## 八、Supervisor 的设计原则与职责边界

### 原则 1：Supervisor 负责「分」，不负责「做」

Supervisor 的核心职责是任务分解、路由和监控，而不是直接执行具体任务。把自己变成一个纯粹的管理者，是 Supervisor 最重要的设计决策。

### 原则 2：分解质量是 Supervisor 的第一指标

一个 Supervisor 的好不好，首先看它的任务分解质量：
- 分解后的任务是否独立可执行？
- 依赖关系是否清晰无环？
- 粒度是否与 Worker 能力匹配？

任务分解做不好，后续的错误恢复、工作流监控都是徒劳。

### 原则 3：错误恢复策略要系统性，而不是碰运气

每个错误类型必须有明确的处理策略。不能「试试这个，不行再试试那个」。决策树必须预先定义，并且每个分支都要有明确的退出条件（防止无限循环）。

### 原则 4：Supervisor 必须可观测

Supervisor 必须能够回答：
- 当前工作流的健康度是多少？
- 哪个任务最容易失败？
- 错误恢复策略的成功率是多少？
- 是否需要人工介入？

没有可观测性，Supervisor 就是一个黑盒，出问题时无法诊断。

### 原则 5：Supervisor 必须能自我调整

静态的 Supervisor 无法适应变化的工作负载和 Worker 状态。健康的 Supervisor 应该能根据健康度指标自动调整分解策略和 Worker 分配。

---

## 总结：从「能分」到「可靠」

Supervisor 是多 Agent 系统的核心。一个可靠的 Supervisor 必须具备：

```
高质量分解
  ↓ 看得见分解质量（通过检查框架）
  ↓ 错误后能恢复（通过决策树 + 恢复策略）
  ↓ 持续自我监控（通过健康度指标）
  ↓ 能自动调整（通过自我调整机制）
  ↓ 可观测可审计（通过完整的日志和状态记录）
```

这不是一次性设计好的，而是在生产环境中持续迭代出来的。

当你的 Supervisor 具备了这五种能力，多 Agent 系统才能真正「可靠」——不是「不会出错」，而是「出了错知道怎么处理，并且能从错误中学习」。

---

*本文是「多 Agent 能力进化系列」的第四篇。前三篇分别是《多 Agent 编排框架对比》《Multi-Agent 系统故障诊断实战》和《AI Coding Agent 自修正模式》，构成「编排 → 诊断 → 恢复 → 治理」的完整能力闭环。*
