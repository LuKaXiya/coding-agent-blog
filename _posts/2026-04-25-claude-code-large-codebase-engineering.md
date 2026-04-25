---
layout: post
title: "Claude Code 大型代码库实战：上下文管理、会话设计与多模块并行协作"
date: 2026-04-25 10:00:00 +0800
category: AI编程工具
tags: ["Claude Code", "大型代码库", "上下文管理", "monorepo", "多模块协作", "工程实践"]
---

> 小项目里 Claude Code 是帮手，大项目里 Claude Code 是队友——但这两件事需要的能力完全不同。小项目靠的是「生成」，大项目靠的是「导航」。

当你面对一个 50 万行代码的 monorepo，几十个微服务，复杂的依赖图谱，Claude Code 的默认行为几乎注定会失败：

- 每次新会话都是空白上下文，从零开始
- Agent 在不完整的信息上做决策，产出南辕北辙
- 多模块并行任务时，各自为政，边界冲突

这不是工具的问题，是使用方式的问题。

本文来自真实 monorepo 场景的工程实践，涵盖：**上下文管理策略、会话设计模式、依赖感知的任务规划**，以及** Shared Brain 在大型项目中的扩展用法**。

---

## 目录

- [一、大项目里 Claude Code 为什么会「失灵」](#一大项目里-claude-code-为什么会失灵)
- [二、上下文管理：不让 Agent 在信息真空中工作](#二上下文管理不让-agent-在信息真空中工作)
- [三、会话设计：按生命周期而不是按任务碎片](#三会话设计按生命周期而不是按任务碎片)
- [四、依赖感知的任务规划：先地图后路径](#四依赖感知的任务规划先地图后路径)
- [五、多模块并行协作：Shared Brain 扩展用法](#五多模块并行协作shared-brain-扩展用法)
- [六、工程检查清单：大项目接入 Claude Code 必做事项](#六工程检查清单大项目接入-claude-code-必做事项)

---

## 一、大项目里 Claude Code 为什么会「失灵」

### 1.1 根本问题：上下文爆炸与上下文缺失同时存在

大项目的核心矛盾不是「上下文太多塞不下」，而是「关键上下文在错误的时间出现/消失」。

典型场景：你想让 Claude Code 重构 `auth-service` 中的 token 验证逻辑。这段逻辑依赖：
- `shared-lib/token.ts`（底层工具库）
- `auth-service/middleware.ts`（中间件层）
- `common-types/auth.ts`（类型定义）

Claude Code 在一个干净会话里，对这三个文件一无所知。你给它的上下文窗口里，只有你手动粘贴进去的那些内容——而一个50万行的项目，任何人都无法手动「填完」所有依赖。

**结果**：Agent 基于残缺的信息生成代码，表面逻辑对，实际运行崩。

### 1.2 症状清单：你的项目是否已经遇到问题

如果你在大型项目里用 Claude Code，出现了以下任意一种症状，说明上下文管理已经出了问题：

| 症状 | 说明 |
|------|------|
| Agent 说「我找不到这个函数的定义」 | 它真的找不到，因为依赖没进上下文 |
| 生成的代码导入了不存在的模块 | Agent 脑补了一个你以为有的依赖 |
| 修了一个 bug 出现三个新 bug | 改了共享依赖，其他模块不知道 |
| 并行任务结果互相覆盖 | 多个会话各自改同一个文件的不同版本 |
| Agent 拒绝了任务，说「我需要更多上下文」 | 这是好事，说明它知道自己的局限 |

### 1.3 失败的根因：把 Claude Code 当成「工具」而不是「环境」

小项目里 Claude Code 是一个工具：你提需求，它给代码。

大项目里 Claude Code 必须成为你的开发环境：你和它共享同一个项目状态，它知道你改了什么，你知道它在做什么。

这两种使用模式需要的配置、流程、心态完全不同。

---

## 二、上下文管理：不让 Agent 在信息真空中工作

### 2.1 三层上下文模型

大型项目的上下文不是一个平面，而是一个三层结构：

```
第一层：当前任务上下文（Task Context）
  └── 你正在操作的文件、最近修改、以及这次会话的目标
  
第二层：模块依赖上下文（Module Context）
  └── 当前模块的导入树、接口契约、类型定义
  
第三层：项目全局上下文（Project Context）
  └── 项目架构、模块间依赖图、共享规范
```

Claude Code 默认只能看到第一层。第二层和第三层需要你主动喂进去，或者通过工程手段让它「默认就知道」。

### 2.2 喂上下文的正确姿势

#### 方式一：.cursorrules 文件（项目级规则）

在项目根目录放置 `.cursorrules`（也适用于 Claude Code 的 `.claude` 目录），定义项目架构：

```markdown
# 项目架构说明
本项目为 Node.js monorepo：
- /packages/core：核心业务逻辑，所有 service 的依赖基础
- /packages/auth：认证服务，依赖 core
- /packages/api-gateway：API 网关，依赖 auth 和 core
- /apps/web：前端应用

## 模块依赖规则
任何 service 修改 core 时，必须运行 /scripts/deploy-core.sh 重新发布
auth 服务不可直接访问 database，只通过 core 提供的接口
```

这种项目级上下文，Claude Code 每次新会话都能读到，不需要每次手动输入。

#### 方式二：Read 会话中的依赖文件

当你让 Claude Code 理解一个文件时，不要只粘贴那个文件，而是把它的依赖链一起读：

```bash
# 先读依赖（从底层到上层）
/workspace/shared-lib/token.ts
/workspace/auth-service/middleware.ts
/workspace/common-types/auth.ts
# 再读目标文件
/workspace/auth-service/handlers.ts
```

这样 Claude Code 能看到完整的引用关系，而不是在真空中生成代码。

#### 方式三：使用 MCP Server 注入结构化上下文

对于复杂项目，可以实现一个项目上下文 MCP Server，持续追踪：
- 模块间的导入关系（实时更新的 import graph）
- 最近修改的文件列表
- API 接口契约（OpenAPI schema 或 proto 文件）

让 Claude Code 通过 MCP 调用「给我这个模块的所有下游依赖」，而不是靠猜测。

### 2.3 上下文注入的常见错误

**错误一：只给错误信息，不给上下文**

❌ `"帮我修这个 bug：TypeError: Cannot read property 'id' of undefined"`

✅ `"在 /packages/user-service/src/handlers.ts 第 47 行，有个 bug：传入的 user 对象是 undefined。这个函数依赖 userService.getById()，但用户说这个接口昨天还有返回。请先读 user-service 的接口文件，然后告诉我可能哪里出了问题。"`

**错误二：一次性喂太多**

上下文窗口是有限的。大项目的正确姿势是**按需逐步加载**：先给最近相关的，然后让 Agent 发现缺什么，再补充。

**错误三：不给 Agent「知道自己不知道」的机会**

每次会话开始，告诉 Claude Code：

```markdown
当你需要了解某个模块的具体实现时，请先说明「我目前对 XXX 模块的了解是 YYY」，然后提出「为了完成这个任务，我需要更多信息：具体是 ZZZ」。不要猜测。
```

---

## 三、会话设计：按生命周期而不是按任务碎片

### 3.1 短会话 vs 长会话：什么时候用什么

| 场景 | 推荐会话长度 | 理由 |
|------|-------------|------|
| 快速修复（1-2个文件） | 短会话 | 上下文干净，不需要历史 |
| 新功能开发（跨3+文件） | 长会话 | 需要上下文连续性 |
| 跨模块重构 | 超长会话或专用 Agent | 一个会话管不了 |
| Code Review | 短会话 | 每次都是独立任务 |

**关键原则**：每个会话对应一个「连续的工作流」，不是「一个任务」。任务可以拆碎，会话不能。

### 3.2 长会话的管理技巧

大项目中，一个任务可能横跨几天。如果 Claude Code 的会话在第一天就关闭了，第二天重新打开时，Agent 完全没有记忆。

**解决方案**：使用外部记忆系统（Shared Brain），会话不是唯一的连续性来源。

```
Day 1 会话：
  → 完成 auth middleware 重构 70%
  → 记录：还剩 token validation 逻辑未完成，第三步依赖 shared-lib 新增的 function
  
Day 2 会话：
  → 首先从 Shared Brain 读取昨天状态
  → 直接从「token validation 逻辑」开始，而不是从头读代码
```

### 3.3 会话状态的交接清单

当你需要交接一个长会话（自己休息，或者换人），完整的交接应该包含：

```markdown
## 当前会话状态

### 已完成
- auth middleware 重构 70%
- 中间件链已改为 async/await 风格
- 错误处理改为统一抛出 CustomError

### 未完成
- [ ] token validation 逻辑（第三步，依赖 shared-lib 的 `verifyToken()` 新接口）
- [ ] middleware 测试覆盖（第二步的自测还没做）

### 最近修改文件
- /packages/auth/middleware.ts（第 43-120 行重写）
- /packages/auth/errors.ts（新建）

### 下一步行动
1. 运行 shared-lib 的 `npm run build` 确认新接口
2. 继续 middleware.ts 第 121-180 行
3. 自测用 /test/auth-middleware.test.ts

### 已知风险
- shared-lib 的 `verifyToken()` 接口尚未发布，需要先确认版本
```

把这个交接清单放到 Shared Brain，Claude Code 下次启动时就能通过 MCP 调用或者直接读取了解状态。

---

## 四、依赖感知的任务规划：先地图后路径

### 4.1 大项目里为什么不能直接「做任务」

小项目的任务规划很简单：我要做 A，做完就好。

大项目的任务规划必须先回答：**A 依赖谁？谁依赖 A？改了 A 会不会把 B 弄坏？**

在 50 万行代码里，一行看似安全的修改，可能触发级联故障。

### 4.2 依赖图谱：Claude Code 的元技能

让 Claude Code 在大项目里发挥价值的第一件事：**让它知道项目地图**。

```javascript
// project-map.js —— 项目模块依赖图生成脚本
const fs = require('fs');
const path = require('path');

function generateMap(dir, depth = 0) {
  if (depth > 3) return null;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const modules = [];
  
  for (const entry of entries) {
    if (!entry.isDirectory() || entry.name.startsWith('.')) continue;
    const pkgPath = path.join(dir, entry.name, 'package.json');
    if (fs.existsSync(pkgPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      modules.push({
        name: pkg.name,
        path: path.relative(process.cwd(), path.join(dir, entry.name)),
        deps: Object.keys(pkg.dependencies || {}).filter(d => d.startsWith('@yourorg/')),
      });
    } else {
      const subModules = generateMap(path.join(dir, entry.name), depth + 1);
      if (subModules) modules.push(...subModules);
    }
  }
  return modules;
}
```

运行这个脚本，输出一个 `project-map.json`，Claude Code 可以通过 `Read` 工具快速了解模块关系。

### 4.3 改共享依赖的标准流程

当你要修改 `shared-lib` 中的任何内容，必须遵循以下流程：

**第一步**：确认谁依赖这个模块
```bash
grep -r "from '@yourorg/shared-lib'" --include="*.ts" /packages
```

**第二步**：评估影响范围
- 如果只有 1-2 个模块依赖 → 可以直接改，注意通知
- 如果超过 5 个模块依赖 → 必须走 code review，不能自己合并
- 如果涉及核心基础设施 → 需要 full team review

**第三步**：通知下游模块负责人
在 Shared Brain 里记录变更：

```markdown
## [变更通知] shared-lib v2.3.0

变更内容：`verifyToken()` 接口签名改变，新增 `options` 参数
影响范围：auth-service、api-gateway、mobile-backend
迁移期限：2026-05-01 之前必须迁移
变更方式：在各模块中执行 `npx @yourorg/shared-lib/migrate`
```

---

## 五、多模块并行协作：Shared Brain 扩展用法

### 5.1 为什么大项目需要多 Agent 并行

大项目中，Claude Code 处理单个模块游刃有余，但一个会话里处理多个模块就会顾此失彼：

- 改完 service A 忘改 service B 的引用
- 三个模块并行改同一个共享类型，冲突了
- 每个 Agent 都不知道其他 Agent 在做什么，重复劳动

**多 Agent 并行的前提**：有一个可靠的协调层，确保不冲突、不遗漏、不重复。

Shared Brain 在大型项目中的角色升级为「项目级协调记忆」，而不是「双人对话记录」。

### 5.2 项目级 Shared Brain 的数据结构

```markdown
# 🧠 项目协调记忆（所有 Agent 共享）

## 项目状态

| 模块 | 负责人 Agent | 当前阶段 | 最后更新 |
|------|-------------|---------|---------|
| shared-lib | Agent-Architect | 维护中 | 2026-04-25 09:30 |
| auth-service | Agent-Coder-A | 重构进行中 | 2026-04-25 09:45 |
| api-gateway | Agent-Coder-B | 待启动 | 2026-04-25 09:00 |

## 正在进行中的跨模块任务

### 🔴 auth-service 重构（进行中）
- 范围：middleware.ts 重构为 async/await
- 依赖：等待 shared-lib 的 `verifyToken()` 接口就绪
- 阻塞：Agent-Coder-A 等待 shared-lib 更新（预计今天中午）
- 状态：70% 完成，剩余 token validation 部分

### 🟡 api-gateway 迁移（等待中）
- 依赖：auth-service 重构完成后才能迁移（接口契约变化）
- 预计开始：2026-04-25 14:00

## ⚠️ 冲突警告

**无冲突**：当前没有并行修改同一个文件的情况
**注意**：shared-lib 的 `TokenOptions` 接口正在重构，不要基于当前版本写死类型

## 项目公告

- shared-lib 下周发布 v2.4.0，届时 auth-service 需要同步更新
- api-gateway 的负载测试计划在 04-28 执行，测试期间不要部署
```

### 5.3 多 Agent 的任务分配协议

当有多个 Agent 并行处理不同模块时，使用以下分配协议：

```markdown
## Agent 任务分配记录

| 任务 ID | 模块 | 负责人 | 状态 | 开始时间 | 预计结束 |
|---------|------|--------|------|---------|---------|
| TASK-007 | auth-service middleware | Coder-A | 进行中 | 09:30 | 12:00 |
| TASK-008 | api-gateway handlers | Coder-B | 待启动 | 14:00 | 17:00 |
| TASK-009 | shared-lib verifyToken | Architect | 进行中 | 09:00 | 11:30 |

### 规则
1. 每个任务开始前，Agent 必须先 Lock 要修改的文件（避免冲突）
2. 任务完成后必须更新状态为「已完成」并记录关键产出
3. 如果一个任务依赖另一个任务，依赖方必须等被依赖方「已完成」后才能开始
```

这听起来像项目管理软件在做的事——没错，但当 Agent 能够读取这个协调层时，它就能做出正确的「等待还是继续」决策。

---

## 六、工程检查清单：大项目接入 Claude Code 必做事项

### 6.1 第一天必做

```
□ 在项目根目录创建 .cursorrules（或 .claude/），描述项目架构和模块关系
□ 运行 project-map.js 生成当前模块依赖图，上传或记录在共享位置
□ 在 shared-lib 的 README 中明确接口契约和稳定性标注（Stable / Beta / Deprecated）
□ 设置 .gitignore，确保 Claude Code 的工作产物（如果是文件）不会被意外提交
□ 建立 Shared Brain 的初始化状态，记录当前项目各模块负责人和状态
```

### 6.2 每次开始新任务前

```
□ 确认要修改的模块当前状态（从 Shared Brain 读取）
□ 确认修改是否会触发共享依赖变更
□ 列出要读的文件清单（按依赖顺序：底层先读）
□ 如果修改共享模块，通知所有下游模块负责人
```

### 6.3 任务完成后

```
□ 填写交接清单（已完成/未完成/下一步/已知风险）
□ 更新 Shared Brain 中的项目状态
□ 如果修改了共享模块，执行影响范围扫描，确认没有遗漏
□ 确认自测覆盖了修改的直接和间接影响
```

---

## 结论：让 Claude Code 成为大项目的队友，而不是工具

大项目里 Claude Code 的最大价值，不是帮你写代码，而是帮你**在复杂的依赖网络中找到正确的路径**。

上下文管理做不好，Claude Code 就是一个在黑暗中给你错误答案的勤奋傻子。

上下文管理做好了，Claude Code 就是你在这个复杂系统里最可靠的导航员。

这个差异不在于工具本身，而在于你为它创造了什么样的信息环境。

---

*本文是大项目 Claude Code 工程实践系列的第一篇，后续会覆盖：多 Agent 冲突解决、项目级 MCP Server 实现、以及大型重构的 Session 管理策略。*