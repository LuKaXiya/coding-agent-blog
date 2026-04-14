---
layout: post
title: "Multi-Agent 系统故障诊断实战：四步法从"能跑"到"可靠""
category: 多Agent
tags: ["多Agent", "调试", "故障诊断", "Tracelog", "OpenClaw", "Agent架构", "因果追踪", "协作系统"]
date: 2026-04-14 10:00:00 +0800
---

> 多 Agent 系统一旦出问题，调试难度是单 Agent 的十倍。本文提供一套可操作的诊断框架：故障分类 → Tracelog 拓扑 → 四步诊断法 → 根因修复。适用于 Supervisor-Worker、Consensus、Pipeline 等主流多 Agent 架构。

---

## 目录

- [一、为什么多 Agent 调试是独立课题](#一为什么多-agent-调试是独立课题)
- [二、故障分类：协作层 vs 系统层](#二故障分类协作层-vs-系统层)
- [三、核心调试工具：Tracelog 拓扑与因果追踪](#三核心调试工具tracelog-拓扑与因果追踪)
- [四、四步诊断法](#四四步诊断法)
- [五、根因修复：改架构，不是改 Prompt](#五根因修复改架构不是改-prompt)
- [六、实战案例：从上下文污染到循环依赖](#六实战案例从上下文污染到循环依赖)
- [七、与现有博客的关联](#七与现有博客的关联)

---

## 一、为什么多 Agent 调试是独立课题

在单 Agent 场景下，调试的核心问题是：

> "Agent 输出的代码为什么有 Bug？"

调试对象是**代码**——断点、打印、日志，这些传统方法依然有效。

在多 Agent 协作场景下，问题变成了完全不同的性质：

> "为什么 Agent A 的输出导致 Agent B 行为异常？"

这不是代码问题，而是**系统架构问题**。传统调试方法失效，因为：

1. **思维过程是隐性的**：Agent 的决策链不透明，工具调用之间存在复杂的因果链
2. **故障可能在协作层**：不在任何单个 Agent 内部，而在 Agent 之间的信息传递
3. **症状和根因分离**：Agent C 报错，但根因是 Agent A 两个小时前的一个错误决策

**本文目标**：提供一套系统化的多 Agent 故障诊断方法，让"坏了知道怎么修"成为可复制的能力，而不是靠运气。

---

## 二、故障分类：协作层 vs 系统层

多 Agent 系统的故障分为两类：**协作层故障**（Agent 之间的交互问题）和**系统层故障**（底层基础设施问题）。两类故障的诊断方法不同。

### 2.1 协作层故障

#### 故障 1：上下文污染（Context Pollution）

一个 Agent 的输出包含了不该传递到下游的信息，下游 Agent 收到错误上下文。

典型场景：
```
User: "修复登录 bug"
Supervisor → Agent-A: 分析登录模块
Agent-A 回复: "登录模块的问题已定位，顺便检查了支付模块发现潜在问题"
Supervisor → Agent-B: 验证登录修复
Agent-B 回复: "你提到支付模块有问题，要不要一起修？"
```

**问题根因**：Supervisor 没有对 Agent-A 的输出做过滤，把全部内容透传给了 Agent-B。Agent-B 接收到了与当前任务无关的信息。

**诊断信号**：
- 下游 Agent 的回复内容超出了任务范围
- 某个任务中途突然出现新话题
- 上下文长度异常增长（多余的无关信息堆积）

#### 故障 2：角色漂移（Role Drift）

某个 Agent 在多轮迭代中逐渐偏离了自身角色定位，开始承担其他 Agent 的职责。

典型场景：
```
Worker Agent（负责实现）经过多轮后开始：
- 自己优化代码风格（本该 Architect 做）
- 添加注释（本该 Human Review 做）
- 重构架构（本该 Architect 做）
```

**问题根因**：Agent 的 System Prompt 没有强约束力，或者任务分解时角色边界不清晰。

**诊断信号**：
- 某个 Agent 的输出内容类型发生变化（突然开始做规划、审查）
- Supervisor 分配的任务被下级 Agent "抢着做"
- 同一个决策点反复出现多个 Agent 的参与

#### 故障 3：共识失效（Consensus Failure）

Multi-Agent Consensus 模式下，多个 Agent 独立分析同一问题，但结论差异过大，无法形成有效共识。

典型场景：
```
Agent-1 结论: "根因是数据库连接池配置太小"
Agent-2 结论: "根因是 API 超时设置不合理"
Agent-3 结论: "根因是 Redis 缓存失效"
→ 人工介入阈值设置过低，导致大量假阳性
→ 或者阈值设置过高，真问题被忽略
```

**诊断信号**：
- 共识轮次超过预期（正常应该是 2-3 轮）
- 多个 Agent 的诊断方向完全不同，没有交集
- LLM 裁判（如果用了）反复推翻自己的判断

### 2.2 系统层故障

#### 故障 4：循环依赖（Circular Dependency）

```
Agent-A 需要 Agent-B 的输出才能完成任务
Agent-B 需要 Agent-C 的输出才能完成任务
Agent-C 需要 Agent-A 的输出才能完成任务
→ 系统死锁，LLM 推理进入无限循环
```

**诊断信号**：
- 日志显示相同的 Agent 对话对反复出现
- Token 消耗异常增长（循环没有退出条件）
- Session 突然超时或被强制终止

#### 故障 5：资源竞争（Resource Contention）

多个 Agent 同时修改同一个文件/模块，后面的修改覆盖了前面的。

典型场景：
```
Agent-1 修改了 UserService.java 第 50-60 行
Agent-2 修改了 UserService.java 第 55-65 行
（由同一个 Supervisor 分配，并发执行）
git merge 时产生冲突，Agent-1 不知道 Agent-2 已经改过
```

**诊断信号**：
- 文件的 git diff 出现大量冲突标记
- 某个功能的修改在下一轮被"莫名其妙"覆盖
- 日志中有 `merge conflict` 相关错误

#### 故障 6：记忆干扰（Memory Interference）

多 Agent 系统共享的记忆被污染，Agent 用错误的历史信息做判断。

典型场景：
```
Agent-1 前一个任务处理了"用户 A 的订单问题"（含敏感数据）
Agent-2 当前任务需要"分析订单模块"
共享记忆没有做隔离，Agent-2 从记忆里读到了用户 A 的敏感信息
```

**诊断信号**：
- Agent 的回复中突然出现与当前任务无关的历史数据
- 某个任务使用了错误的用户/项目上下文
- 记忆检索结果中有明显的"张冠李戴"

---

## 三、核心调试工具：Tracelog 拓扑与因果追踪

### 3.1 多 Agent Tracelog

单 Agent 的 Tracelog 记录一个 Agent 的操作序列。多 Agent Tracelog 需要记录**整个系统的协作拓扑**：

```json
{
  "session_id": "multi-agent-debug-001",
  "timestamp": "2026-04-14T10:00:00Z",
  "agents": [
    {
      "agent_id": "supervisor-1",
      "role": "supervisor",
      "parent": null,
      "children": ["worker-1", "worker-2"]
    },
    {
      "agent_id": "worker-1",
      "role": "code-writer",
      "parent": "supervisor-1",
      "children": []
    }
  ],
  "events": [
    {
      "event_id": 1,
      "timestamp": "2026-04-14T10:00:05Z",
      "from": "user",
      "to": "supervisor-1",
      "type": "task_assignment",
      "content": "修复登录 bug"
    },
    {
      "event_id": 2,
      "timestamp": "2026-04-14T10:00:10Z",
      "from": "supervisor-1",
      "to": "worker-1",
      "type": "subtask_dispatch",
      "content": "分析 login.py",
      "tool_calls": ["Bash: grep -n session", "Read: login.py"]
    },
    {
      "event_id": 3,
      "timestamp": "2026-04-14T10:00:30Z",
      "from": "worker-1",
      "to": "supervisor-1",
      "type": "subtask_result",
      "content": "发现 session TTL 配置问题",
      "is_error": false
    }
  ]
}
```

**关键调试信号对照表**：

| 信号 | 含义 |
|------|------|
| 同一父节点连续触发多个同类型子任务 | 可能的角色漂移或过度拆分 |
| 消息传递延迟突然增大 | 某个 Agent 陷入复杂推理或死锁 |
| 子 Agent 输出被父 Agent 直接透传 | 缺乏输出过滤层（上下文污染风险）|
| 循环消息（Agent A→B→A 反复）| 循环依赖或死锁 |
| 某节点长期处于 `waiting` 状态 | 上游消息丢失或处理超时 |
| 共识轮次超过 5 轮仍无结果 | 共识失效，需要干预 |

### 3.2 消息拓扑可视化

多 Agent 系统的调试视图应该是**消息拓扑图**，而不是线性日志：

```
User
  ↓ [task: 修复登录 bug]
Supervisor
  ├→ Worker-A [analyze] → "发现 session TTL 问题"
  │                      ↓
  │                   Supervisor
  ├→ Worker-B [implement] → "已修复配置文件"
  │                      ↓
  │                   Supervisor
  └→ Worker-C [verify] → "测试通过"
                       ↓
                    Supervisor
  ↓ [result]
User
```

这个拓扑图需要标注：
- 每条消息的类型（`task` / `result` / `error` / `escalation`）
- 每个 Agent 的状态（`running` / `waiting` / `error` / `done`）
- 关键决策点（`consensus_reached` / `escalation_triggered`）
- Token 消耗（识别哪个节点消耗最多资源）

**工具实现**：
- 轻量级：Mermaid 文本图，实时生成
- 生产级：d3.js 时序图，支持缩放和点击钻取
- OpenClaw：可结合 `sessions_history` API 导出拓扑

### 3.3 因果追踪（Counterfactual Tracing）

因果追踪是多 Agent 调试的核心方法——**"如果当时不是这样做，结果会不同吗？"**

```
场景：
  Supervisor 把 Agent-A 的输出直接传给了 Agent-B
  Agent-B 基于错误上下文做出了错误决策

调试方法：
  1. 用 Agent-B 收到的"干净"输入重新运行
  2. 观察 Agent-B 的决策是否改变
  3. 如果变了 → 证明是 Agent-A 输出污染
  4. 如果没变 → 问题在 Agent-B 本身
  
OpenClaw 实现：
  sessions_spawn 创建分支 Session，同时运行两条路径对比结果
```

---

## 四、四步诊断法

### Step 1：拓扑重建——先画图，不急着看代码

在调试多 Agent 系统之前，先重建整个协作拓扑：

```
1. 导出 Session 历史（sessions_history）
2. 提取所有 Agent 间的消息传递事件
3. 生成 Mermaid 拓扑图
4. 标注每个节点的输入/输出关键内容
```

**目标**：搞清楚"谁在什么时机给了谁什么信息"。

**拓扑重建检查清单**：
- [ ] 画出了完整的 Agent 拓扑图
- [ ] 标注了每条消息的发送方、接收方、消息类型
- [ ] 标注了每个节点的关键输入和输出
- [ ] 发现了异常拓扑模式（如超长依赖链、循环引用）

### Step 2：异常信号检测——找出口和入口

**异常信号**（说明有问题）：
- 某个 Agent 的输出突然与任务无关 → Role Drift
- 消息传递链出现"断层" → 某节点没收到应该收到的消息
- 某个决策点之后所有后续节点的行为都与预期不符 → **根因在此之前**
- 循环消息（同一对 Agent 反复交换消息）→ 循环依赖

**正常信号**（说明系统运行正常）：
- 任务完成后 Agent 正常退出（`done`）
- 上报（`escalation`）有清晰的触发条件
- 共识（`consensus`）在 2-3 轮内快速达成

### Step 3：单点隔离——逐个 Agent 诊断

找到异常节点后，单独对该 Agent 做诊断：

```
1. 用该 Agent 的输入（收到的消息）重新构造独立会话
2. 单独运行，看它是否产生同样的错误
3. 如果错误消失 → 问题是上游传来的（回到 Step 2 找上游）
4. 如果错误保留 → 问题在该 Agent 内部（深入分析该 Agent）
```

**单点隔离检查清单**：
- [ ] 隔离了目标 Agent，独立运行
- [ ] 用相同的输入，得到了相同的输出
- [ ] 确认了是 Agent 内部问题还是上游传递问题

### Step 4：根因修复——改架构，不是改 Prompt

多 Agent 系统的很多问题本质上是**架构问题**，而非 Prompt 问题：

| 问题类型 | 架构修复 | Prompt 修复 |
|---------|---------|-----------|
| 上下文污染 | 在 Supervisor 层加 Filter Agent | "不要传递无关信息" |
| 资源竞争 | 在调度层加互斥锁（文件锁）| "不要修改其他 Agent 修改过的文件" |
| 记忆干扰 | 使用向量数据库做记忆分区 | "忽略其他任务的上下文" |
| 循环依赖 | 引入超时退出机制和死锁检测 | 降低 LLM 推理层数 |
| 共识失效 | 调整共识阈值或引入 LLM 裁判 | "你的结论需要与其他人一致" |

**核心原则**：能用架构解决的问题，不要用 Prompt。Prompt 是软约束，架构是硬约束。

---

## 五、根因修复：改架构，不是改 Prompt

### 5.1 协作层的架构修复

**上下文污染** → 加 Filter Agent：

```
Before: Supervisor → 直接透传 → Worker
After:  Supervisor → Filter Agent → "干净"上下文 → Worker

Filter Agent 的职责：
  - 分析 Supervisor 的输出
  - 提取与当前子任务直接相关的内容
  - 丢弃无关信息（如其他任务的发现、闲聊、推测）
```

**资源竞争** → 调度层加互斥：

```
Before: Supervisor 并发分配 → Agent-1 和 Agent-2 同时改 File-A
After:  调度层维护文件锁
        Agent-1 请求 File-A → 获得锁
        Agent-2 请求 File-A → 等待释放
```

**记忆干扰** → 向量数据库分区：

```
Before: 共享记忆，所有 Agent 看到相同的记忆上下文
After:  记忆按 Agent 角色/任务分区
        Architect Agent 只检索架构相关记忆
        Coder Agent 只检索代码相关记忆
        跨角色记忆共享需要显式授权
```

### 5.2 系统层的架构修复

**循环依赖** → 超时 + 死锁检测：

```python
# 在 Agent 调用层加入超时控制
async def call_agent(agent_id, task, timeout=30):
    try:
        result = await asyncio.wait_for(
            agent[agent_id].process(task),
            timeout=timeout
        )
        return result
    except asyncio.TimeoutError:
        # 触发死锁告警，回滚到上一个稳定状态
        trigger_deadlock_recovery(agent_id)
```

**Token 预算爆炸** → 多层熔断：

```
Layer 1: 单 Agent max_turns（防止单个 Agent 无限循环）
Layer 2: Session max_tokens（防止整个系统 Context 溢出）
Layer 3: 预算超支时强制触发 compaction
Layer 4: 超过预算阈值时触发人工告警
```

---

## 六、实战案例：从上下文污染到循环依赖

### 案例背景

```
项目：Spring Boot 微服务改造
架构：Supervisor + 3 Worker（Architect / Coder / Reviewer）
问题表现：Reviewer Agent 突然开始修改架构设计文档
```

### Step 1：拓扑重建

导出 Session 历史，重建拓扑：

```
User
  ↓ [task: 微服务拆分]
Supervisor
  ├→ Architect: "设计服务边界"
  │               ↓ "推荐按订单/支付/用户拆分"
  │            Supervisor
  ├→ Coder: "实现订单服务"
  │          ↓ "使用了 XX 框架"
  │       Supervisor
  └→ Reviewer: "Review 代码"
                ↓ "建议调整架构" ← 这里 Reviewer 开始做 Architect 的事
             Supervisor
```

### Step 2：异常信号检测

- Reviewer Agent 输出内容：包含架构建议（不是纯代码审查）
- 架构建议内容来自：Architect 第一次的输出
- **判断**：上下文污染 + 角色漂移

### Step 3：单点隔离

隔离 Reviewer Agent，用"干净"的代码审查输入运行：

```
结果：Reviewer 正常做代码审查，没有出现架构建议
结论：问题不是 Reviewer 本身，而是它接收到的上下文
```

### Step 4：根因定位

Supervisor 的消息传递拓扑：

```
Architect → [全部输出] → Supervisor → [全部内容] → Reviewer
                              ↑
                         没有 Filter 层
```

Supervisor 把 Architect 的所有输出（包括架构分析）都传给了 Reviewer，而 Reviewer 的 System Prompt 没有明确说"只做代码审查，不要提架构建议"。

### Step 5：修复

**架构修复**（根本解决方案）：

```python
class FilteringSupervisor:
    def route(self, worker_output, target_agent):
        # 只传递与目标 Agent 角色相关的内容
        relevant_context = self.filter(
            context=worker_output,
            target_role=target_agent.role  # "reviewer"
        )
        return relevant_context
```

**Prompt 修复**（临时缓解）：

```
Reviewer Agent 的 System Prompt 增加：
"你只负责代码层面的审查，包括：逻辑错误、安全漏洞、测试覆盖率。
不要提出架构调整建议——那是 Architect Agent 的职责。"
```

---

## 七、与现有博客的关联

**本文是以下博客的"反面"**：

| 已有博客 | 本文关联 |
|---------|---------|
| 多Agent编排（2026-03-22）| 编排的正面设计 → 编排的故障诊断 |
| AI辅助调试（2026-03-23）| 单 Agent 调试 → 多 Agent 调试 |
| Agent治理（2026-03-24）| 预防问题 → 出了问题怎么查 |
| 自修正模式（2026-04-12）| 单 Agent 自修正 → 多 Agent 系统级修复 |
| Agent Teams vs Subagents（2026-03-25）| 架构选择 → 架构坏了怎么修 |

**完整能力闭环**：
```
设计（编排） → 运行（自修正） → 调试（本文） → 治理（预防）
     ↑                                              ↓
     ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
```

---

## 附录：多 Agent 调试检查清单

### 每次诊断必查

- [ ] 绘制了完整的消息拓扑图
- [ ] 识别了第一条异常消息的时间和内容
- [ ] 确认了是协作层问题还是系统层问题
- [ ] 用单点隔离验证了根因位置
- [ ] 区分了架构问题和 Prompt 问题

### 预防性检查（系统上线前）

- [ ] 每个 Agent 有明确的角色边界（System Prompt + Architecture）
- [ ] Supervisor 有输出过滤层
- [ ] 文件操作有互斥保护
- [ ] 记忆系统按角色分区
- [ ] 每个关键路径有超时和熔断机制
