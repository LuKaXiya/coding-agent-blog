---
layout: post
title: "AI Coding Agent 自修正模式：构建可靠的自主纠错系统"
date: 2026-04-12 10:00:00 +0800
category: 深度思考
tags: ["自修正", "Self-Correction", "Reflexion", "错误恢复", "Claude Code", "Agent架构", "工程化", "Hooks", "Subagents"]
---

> 如果一个 AI 编程工具只能"一次做对"，它本质上只是一个高级自动补全。真正的 Coding Agent 必须在出错后能自主发现、分类并修复问题——这就是自修正能力的价值。本文系统梳理自修正的四层架构、核心设计模式，以及在 Claude Code 中的工程化实现。

---

## 目录

- [一、为什么自修正是 Agent 的核心能力](#一为什么自修正是-agent-的核心能力)
- [二、自修正的四层架构](#二自修正的四层架构)
- [三、五种核心自修正模式](#三五种核心自修正模式)
- [四、Claude Code 中的自修正工程实现](#四claude-code-中的自修正工程实现)
- [五、自修正系统的设计原则与陷阱](#五自修正系统的设计原则与陷阱)
- [六、实战：从零构建一个自修正 Hook](#六实战从零构建一个自修正-hook)

---

## 一、为什么自修正是 Agent 的核心能力

传统软件中，错误处理是显式编写的——开发者预判每一种错误，写下对应的处理逻辑。但 AI Coding Agent 运行在**完全不同的环境**中：

- **输入是非结构化的**：用户需求可能是模糊的、不完整的，甚至是错误的
- **执行路径是动态生成的**：Agent 自己决定下一步做什么，不是预先编程的
- **错误类型是无法穷举的**：编译错误、运行时错误、逻辑错误、幻觉错误……

在这样的环境中，靠"预判所有错误"来写处理逻辑是根本不可能的。Agent 必须具备**自修正能力**——当发现结果不符合预期时，能自主判断问题所在，生成并执行修正方案。

这不只是"健壮性"的问题，更是**自主性**的定义本身。一个只能在理想情况下工作的 Agent，本质上只是一个受限的自动化脚本；只有能处理意外、处理失败、并从中学习的 Agent，才是真正的 coding agent。

---

## 二、自修正的四层架构

自修正不是单一能力，而是一套分层的能力体系。理解这个层次结构，是设计自修正系统的基础。

### Level 1：Token 级修正

这是最底层、也最隐性的修正——发生在模型的推理链内部。当模型在生成下一步工具调用时，它会隐式地根据前几步的结果调整当前决策。例如，发现上一步 `grep` 没找到结果，这一步就换一个搜索词。

**特点**：
- 完全隐式，不需要额外机制
- 受模型本身能力限制（GPT、Claude 等基座模型的推理能力）
- 是其他所有层的基础

### Level 2：Turn 级修正

单轮对话内的修正。当 Agent 执行了一个操作、观察到了结果，然后决定重试同一个操作但使用不同的参数或策略。

典型场景：
```
Agent: 执行 git commit -m "fix: ..."
结果: error: failed to push some refs
Agent: 发现是远程分支有更新，执行 git pull --rebase 后再 push
```

**实现方式**：
- 在 Claude Code 中，这通常通过一句自然语言指令触发重试
- 更自动化的方式：通过 `preToolCall` hook 拦截错误，自动注入修正 prompt

### Level 3：Plan 级修正

这是更深层的修正——Agent 不仅重试当前操作，而是重新审视整个任务计划。

典型场景：
```
Agent 计划：读取 A.py → 修改 B.py → 删除 C.py
执行到第2步时发现：A.py 和 B.py 的接口不匹配
Agent 决策：先重构接口，再执行原计划的后两步
```

**关键信号**：
- 多次连续的 turn 级修正都失败了
- 出现了与原计划前提矛盾的新信息
- 任务目标本身发生了变化（用户补充了新需求）

**实现方式**：
- 在 Claude Code 中，这通常需要显式地告诉 Agent "当前方法有问题，重新思考"
- 更系统的方式：通过 `maxTurns` + 触发条件，自动在特定时机注入重新规划指令

### Level 4：Session 级修正

识别出系统性的失败模式，上报到人类寻求指导。

典型场景：
```
Agent: 尝试用 Playwright 自动化测试 UI
连续 5 次都在选择器定位这一步失败
Agent 决策：这个问题超出自动化范围，询问用户："这个页面的选择器结构比较特殊，
能否手动告诉我正确的选择器，或者直接手动测试这个流程？"
```

**关键设计**：
- 必须有最大重试次数限制，防止 Agent 在同一个问题上无限循环
- 需要区分"值得人工介入"和"再试一次就能解决"——这是自修正系统里最难的判断

---

## 三、五种核心自修正模式

### 模式 1：Retry Pattern（重试模式）

最简单的自修正——失败后用调整过的参数重试同一操作。

**结构**：
```
attempt = 0
max_attempts = 3
while attempt < max_attempts:
    result = execute(operation, params)
    if is_success(result):
        return result
    params = adjust(params, result.error)
    attempt += 1
return escalate(result.error)
```

**关键点**：
- 每次重试必须调整参数，否则结果不变
- 设置最大次数，防止死循环
- 每次调整要有明确的方向（不能随机变化）

**适用场景**：工具调用格式错误、权限不足、临时网络问题等非系统性失败。

### 模式 2：Reflection Loop（反思环）

这是 Reflexion 论文（Shinn et al., 2023）提出的经典模式：**行动 → 观察 → 反思 → 重新行动**。

```
def reflection_loop(task):
    plan = decompose(task)
    for step in plan:
        result = execute(step)
        if not verify(result):
            reflection = analyze_failure(step, result)
            # 注入反思结果到下一步的 prompt
            step = incorporate_reflection(reflection, step)
    return final_result
```

**反思的内容包括**：
- 这步失败的根本原因是什么？
- 之前有没有类似问题成功解决了？用了什么方法？
- 下次遇到类似情况应该优先尝试什么？

**在 Claude Code 中的实现**：可以通过多次对话自然实现——用户对 Agent 说"不对，结果不对，重新想想"，Agent 就会进入反思环。工程化的方式是通过 hooks 自动化这个过程。

### 模式 3：Error Classification Router（错误分类路由）

将错误分类后路由到专门的处理模块——这是大规模 Agent 系统中的核心设计。

```
def handle_error(error):
    category = classify(error)
    if category == "compilation":
        return code_fix_expert.resolve(error)
    elif category == "runtime":
        return debugger_expert.resolve(error)
    elif category == "permission":
        return permission_expert.resolve(error)
    elif category == "resource":
        return resource_manager.resolve(error)
    else:
        return human_escalation.resolve(error)
```

**优势**：
- 不同类型的错误由不同的专业 Agent 处理
- 可以并行处理多个不同类型的错误
- 系统可扩展，新错误类型加新的 handler 即可

**在 Claude Code 中的实现**：通过 Subagents 实现——为每类错误启动一个专门的 subagent，各自从错误信息出发独立解决，最后主 agent 汇总结果。

### 模式 4：Verification Layer（验证层）

类似数据库事务的 ACID 原则：**在执行变更之前，先验证前置条件**。

```
def safe_execute(change, preconditions):
    # 验证前置条件
    for check in preconditions:
        if not check():
            return VerificationError(check.name)
    
    # 执行变更
    result = apply(change)
    
    # 验证后置条件
    for check in postconditions:
        if not check():
            rollback(change)
            return PostConditionError(check.name)
    
    return result
```

**典型应用场景**：
- 大规模代码重构前：先验证所有测试可运行
- 数据库迁移前：先验证连接和备份
- 删除文件前：先验证文件不在使用中

**在 Claude Code 中的实现**：通过 MCP 协议定义自定义验证工具，在 `preToolCall` hook 中调用这些工具进行前置检查。

### 模式 5：Multi-Agent Consensus（多 Agent 共识）

让多个 Agent 独立解决同一个问题，只有当 N 个 Agent 的结果一致时才接受——这是一种**冗余式自修正**。

```
def consensus_solve(problem, n=3):
    agents = [spawn_agent(problem) for _ in range(n)]
    solutions = [agent.solve() for agent in agents]
    
    # 找最常见的解决方案（共识）
    consensus = most_common(solutions)
    
    # 如果没有明显共识，上报到人类
    if frequency(consensus) < n * 0.6:
        return human_review(solutions)
    
    return consensus
```

**适用场景**：
- 关键安全修复（要求多个视角确认）
- 架构决策（不同 Agent 从不同角度评估）
- Bug 修复（两个 Agent 独立诊断，交叉验证根因）

**在 Cursor 3 Agents Window 中的实现**：开 N 个并行的 Agent Tab，让它们各自独立分析，最后汇总。

---

## 四、Claude Code 中的自修正工程实现

### 4.1 基于 Hooks 的自动重试

```javascript
// ~/.claudeerc 中配置
{
  "hooks": {
    "preToolCall": [
      {
        "match": "Edit|Write",
        "fn": async (tool, input) => {
          // 写文件前验证目录存在
          const path = input.file_path || input.path;
          const dir = path.substring(0, path.lastIndexOf('/'));
          if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
          }
          return { action: "continue" };
        }
      }
    ],
    "onToolResult": [
      {
        "match": "Bash",
        "fn": async (tool, result) => {
          if (result.exit_code !== 0) {
            const error = result.stdout + result.stderr;
            // 如果是编译错误，自动注入修复提示
            if (error.includes("error:")) {
              return {
                action: "retry",
                prompt: `The previous command failed with a compilation error:\n${error}\n\nAnalyze the error and fix the code accordingly.`
              };
            }
          }
          return { action: "continue" };
        }
      }
    ]
  }
}
```

### 4.2 基于 Subagent 的错误分类路由

```bash
#!/bin/bash
# classify_and_route.sh

ERROR_MSG="$1"
ERROR_TYPE=$(echo "$ERROR_MSG" | claude --print \
  "Classify this error into one of: compilation, runtime, permission, resource, logic, unknown")

case "$ERROR_TYPE" in
  compilation)
    claude -p "Fix this compilation error:\n$ERROR_MSG"
    ;;
  runtime)
    claude -p "Debug this runtime error:\n$ERROR_MSG"
    ;;
  permission)
    claude -p "Fix this permission error:\n$ERROR_MSG"
    ;;
  *)
    echo "需要人工介入: $ERROR_MSG"
    ;;
esac
```

### 4.3 Reflection Loop 的 Prompt 模板

当发现结果不符合预期时，向 Agent 注入反思指令：

```
## 当前状态
- 任务：{original_task}
- 已执行步骤：{executed_steps}
- 最后结果：{last_result}
- 问题：{observed_problem}

## 反思要求
请分析：
1. 当前结果与预期不符的根本原因是什么？
2. 到目前为止，哪一步的决策可能有问题？
3. 有没有类似问题的成功解决经验可以借鉴？
4. 重新设计下一步行动

请给出重新执行的完整计划。
```

### 4.4 Verification Hook 的 MCP 工具

通过 MCP 协议扩展验证能力：

```json
{
  "mcpServers": {
    "code-verifier": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "tools": {
        "verify_tests_pass": {
          "description": "运行测试套件，验证代码修改没有破坏现有功能",
          "params": { "testDir": "string" }
        },
        "verify_imports": {
          "description": "验证文件的所有 import 是否都可解析",
          "params": { "file": "string" }
        }
      }
    }
  }
}
```

---

## 五、自修正系统的设计原则与陷阱

### 原则 1：最大重试次数必须硬性限制

没有上限的重试是危险的。Agent 可能在同一个失败上无限循环，消耗大量资源而不产生进展。

```
MAX_RETRIES = {
    "compilation": 3,    // 编译错误通常容易定位
    "runtime": 5,       // 运行时错误可能需要多次调试
    "logic": 3,         // 逻辑错误需要重新理解
    "unknown": 2        // 未知错误保守处理
}
```

### 原则 2：修正要有方向，不能随机变化

"试试这个，不行再试试那个"不是自修正，是随机搜索。每次修正都必须基于对失败原因的分析，给出有方向的调整。

**好的修正**：
- 编译错误：找到报错行，对照错误信息调整语法
- 权限错误：检查文件权限，用 `chmod` 或 `sudo` 解决

**坏的修正**：
- 随机换一个 API 调用方式碰运气
- 在不了解上下文的情况下重写整个函数

### 原则 3：区分可修正错误和不可修正错误

有些错误本质上无法通过重试解决：
- **需求本身矛盾**：用户要求实现两个互相冲突的功能
- **缺少必要信息**：Agent 没有权限访问某个关键文件
- **环境约束**：要求的依赖版本与系统不兼容

对这些情况，应该尽快上报人类，而不是在错误的路径上继续尝试。

### 原则 4：自修正日志是学习的基础

每次修正都应该留下记录：
```
{
  "task": "...",
  "failure_type": "compilation",
  "attempts": [
    { "attempt": 1, "action": "直接执行", "result": "fail", "error": "..." },
    { "attempt": 2, "action": "修改 import 顺序", "result": "fail", "error": "..." },
    { "attempt": 3, "action": "升级依赖版本", "result": "success" }
  ],
  "root_cause": "依赖版本冲突",
  "lesson": "遇到类似问题先检查 package.json"
}
```

这些日志可以用于训练更好的错误分类器，也可以作为团队的 troubleshooting 知识库。

### 陷阱 1：过度修正（Over-correction）

有时候前一次修正本身引入了新的错误，Agent 继续修正反而让情况更糟。这就是"修复债务"的来源。

**对策**：在大改动前先创建 git commit，形成可回退的基线。

### 陷阱 2：修正循环（Correction Loop）

两个 Agent 互相纠正对方，形成死循环。

**对策**：引入仲裁机制或人工介入节点。

### 陷阱 3：成功标准不清晰

如果"成功"没有精确定义，Agent 可能在一个错误的方向上不断修正。

**对策**：在任务开始前明确定义验证条件（测试通过、文件存在、输出一致等）。

---

## 六、实战：从零构建一个自修正 Hook

下面是一个完整的生产级示例：构建一个自动处理 `PermissionDenied` 的自修正 Hook，当 Agent 遇到权限错误时，自动尝试诊断并修复。

```javascript
// ~/.claude/projects/default/.clauderc.json
{
  "permissions": {
    "allow": [
      "Read: **",
      "Write: src/**",
      "Bash: npm test, npm run build"
    ]
  },
  "hooks": {
    "onDenied": async (tool, reason) => {
      // 分类权限问题
      const isWriteDenied = tool === "Write" && reason.includes("Permission denied");
      const isBashDenied = tool === "Bash" && reason.includes("EACCES");
      
      if (isWriteDenied) {
        // 尝试修复文件权限
        const filePath = extractFilePath(tool.input);
        await exec(`chmod 644 ${filePath}`);
        return { action: "retry" };
      }
      
      if (isBashDenied) {
        // 检查是否是 npm/node 权限问题
        if (tool.input.includes("npm")) {
          return {
            action: "prompt",
            prompt: "遇到了 npm 权限问题。你可以尝试：\n" +
              "1. 使用 npm cache clean --force 清理缓存\n" +
              "2. 检查 package.json 的 scripts 是否有语法错误\n" +
              "3. 尝试使用 npx 直接运行\n" +
              "如果还是不行，请把完整错误信息告诉我。"
          };
        }
      }
      
      // 无法自动处理，上报人类
      return {
        action: "escalate",
        message: `无法自动处理这个权限问题：${tool} 因为 ${reason}`
      };
    }
  }
}
```

**运行效果**：
- 文件权限问题：Hook 自动修复，Agent 无感知继续执行
- npm 问题：Hook 注入专家级修复建议，Agent 在指导下解决
- 其他问题：及时上报，避免无效重试

---

## 总结

自修正能力是 AI Coding Agent 从"工具"进化为"伙伴"的关键能力。本文梳理了：

- **四层架构**：Token 级 → Turn 级 → Plan 级 → Session 级，越高层越需要显式机制
- **五种核心模式**：Retry、Reflection Loop、Error Router、Verification Layer、Multi-Agent Consensus
- **Claude Code 工程实现**：Hooks、Subagents、MCP 工具的组合使用
- **设计原则**：最大重试限制、方向性修正、区分可修与不可修错误、修正日志

这些不是孤立的技巧，而是一整套**自修正工程体系**的不同组件。掌握它们，你构建的 Agent 系统才能在真实、复杂、充满意外的工程环境中真正可靠地运行。

---

*如果你觉得这篇文章有帮助，欢迎分享。*
