---
layout: post
title: "Function Calling Schema 设计法则：如何让 AI Agent 正确选择工具"
category: MCP生态
tags: ["MCP", "Function Calling", "Tool Schema", "Agent架构", "Schema设计", "工具选择", "MCP生态"]
---

## 楔子：为什么工具「能用」不等于「选对」

在开发 Agent 系统时，你可能遇到过这种情况：

> 给 Agent 配了 20 个工具，功能齐全，文档清晰——但 Agent 总是选错工具，或者在两个相似工具之间反复横跳，消耗大量 Token 最后还是没做对。

问题往往不在模型，不在工具数量，而在 **Function Calling Schema 的设计质量**。

大多数关于 Schema 的教程只讲「格式」——参数类型是什么、返回值什么结构。但 Schema 的核心价值不是「格式规范」，而是 **影响 Agent 的决策过程**。格式不对，Agent 调不动；格式对了但描述不清晰，Agent 会调错。

本文是我对 Claude Code SDK、MCP 协议官方文档的深度阅读笔记，整理出一套 **Function Calling Schema 设计法则**，帮助你在工具数量爆炸时依然让 Agent 保持准确决策。

---

## 一、Agent 工具选择的决策链

在深入 Schema 设计之前，先理解 Agent 是怎么做工具选择决策的。

### 1.1 LLM 如何「看到」工具列表

当一个 Agent 需要决定调用哪个工具时，LLM 收到的上下文大概是这个样子（简化版）：

```
你是一个编程助手。以下是你可用的工具：

## get_weather
描述：获取某地当前天气
参数：{"latitude": float, "longitude": float}

## search_github
描述：搜索 GitHub 仓库
参数：{"query": string, "language": string}
```

Agent 的决策过程是：
1. **理解用户意图** → 将意图与工具描述匹配
2. **选择最相关的工具** → 通过 Description 关键字（不是 Name）判断
3. **构造调用参数** → 通过 Input Schema 推断参数格式
4. **处理结果** → 根据 `isError` 决定下一步

### 1.2 Description 是 Agent 决策的核心，不是 Name

这是最常见的误区：**开发者认为 Name 最重要，但实际上 Description 才决定选择准确性。**

```
# ❌ 差的设计（Name 驱动）
name: "qdb"
description: "Query database"

# ✅ 好的设计（Description 驱动）
name: "query_user_database"  
description: "Query the PostgreSQL users table by email or ID.
Returns user records with id, name, email, created_at fields.
Use when: user asks 'who is...', 'does ... exist', or you need 
the user's ID for a follow-up operation."
```

为什么？因为 LLM 在决策时看到的是 Description，不是 Name。LLM 是通过「这个工具能做什么」来判断是否调用，而不是「叫什么名字」。当工具数量超过 10 个时，Description 的质量直接决定了选择准确率。

### 1.3 Agent Loop 的 Turn 模型

理解 Function Calling 的执行机制，有助于设计更好的 Schema。Claude Code SDK 的执行模型是 **Turn-based Loop**：

```
Turn N:
  1. LLM 生成输出（text + tool_calls 或 仅 text）
  2. SDK 执行工具调用，收集结果
  3. 结果作为 UserMessage 回传给 LLM
  → 若有 tool_calls → 进入 Turn N+1
  → 若仅有 text → Loop 结束，输出 ResultMessage
```

**关键含义**：
- 一个 Turn 可以包含**多个并行的工具调用**（同一轮 LLM 输出中调用多个工具）
- 工具结果按**调用顺序**依次回传（不是并行回传）
- `max_turns` 控制最多执行多少个 Turn，避免无限循环
- `max_budget_usd` 按消费阈值控制，防止超支

这意味着：**LLM 每收到一次工具结果，就做一次新决策**。如果 Schema 描述不清晰，Agent 会在多个 Turn 之间反复「试错」，消耗大量 Token。

---

## 二、Description 设计法则

### 2.1 触发场景描述法（最关键）

最好的 Description 不是描述工具本身，而是描述**触发场景**。Agent 看到用户问题后，需要判断「我该调用哪个工具」，触发场景描述直接回答了这个问题。

```python
# ❌ 平铺直叙式（Agent 无法判断何时调用）
"Query a database"

# ✅ 触发场景式（Agent 一眼就知道何时调用）
"Query the PostgreSQL users table by email or ID.
Returns user records with id, name, email, created_at fields.

TRIGGER WHEN:
- User asks 'who is [name/email]'
- User asks 'does [email] exist in the system'
- You need to look up a user's ID for a follow-up operation
- User says 'find user' or 'search users'"
```

触发场景描述法的核心结构：
1. **工具能力描述**（做什么，返回什么）
2. **触发条件**（什么时候该调用，用什么语言）
3. **边界条件**（什么情况下不该调用）

### 2.2 能力边界描述

很多 Agent 选错工具，是因为工具描述没有说清楚「不能做什么」。

```python
# ❌ 没有边界描述（Agent 会误用于其他场景）
"Search for files in the repository"

# ✅ 有边界描述（Agent 知道能力的精确边界）
"Grep-like text search within a single Git repository.
Searches file contents by regex pattern.

CAN: Find function definitions, search by filename pattern, 
     search within specific directories
CANNOT: Search git history, search across multiple repositories,
        execute shell commands
NOTE: This is a read-only operation, safe to retry."
```

### 2.3 输出格式预告

提前告知 Agent 返回数据的格式，可以减少 Agent 因「不知道结果是什么」而反复调用的次数。

```python
"Get the current price of a stock ticker symbol.
Returns: {symbol: string, price: float, currency: string, 
         change_percent: float, timestamp: string}

Example response:
{"symbol": "AAPL", "price": 178.50, "currency": "USD", 
 "change_percent": 1.23, "timestamp": "2026-04-14T10:30:00Z"}"
```

---

## 三、Input Schema 设计法则

### 3.1 参数名即语义

参数名不是给代码看的，是给 **LLM 看的**。LLM 通过参数名推断这个参数是什么意思、该怎么填。

```typescript
// ❌ 代码风格参数名（LLM 难以推断语义）
{"usrEml": string, "qty": number, "flg": boolean}

// ✅ 自然语言风格参数名（LLM 一眼理解）
{"user_email": string, "quantity": number, "is_active": boolean}
```

规则很简单：**参数名要能独立表达含义，不需要看代码就能知道这个参数是做什么的**。

### 3.2 必填 vs 可选的设计

这个设计直接影响 Agent 构造参数的成功率。

```typescript
// TypeScript + Zod
latitude: z.number().min(-90).max(90).describe("Latitude in degrees")  
// 有 .min/.max/.describe → 字段完整，LLM 知道约束条件

longitude: z.number().min(-180).max(180).optional()  
// .optional() → LLM 知道这个字段可以省略

status: z.enum(["pending", "approved", "rejected"])  
// 枚举 → LLM 不会填出范围外的值
```

```python
# Python dict（自动转 JSON Schema）
# 写在 schema 里的字段 = 必填
{"user_email": str, "quantity": int}

# 不写的字段 = 可选
# 即：{"user_email": str} 表示只有 user_email 必填
```

### 3.3 范围约束的必要性

对于数字和字符串参数，添加范围约束可以**显著减少 Agent 试错次数**。

```typescript
// ❌ 无范围约束（Agent 可能填超出合理范围的值）
{"temperature": number, "page_size": number}

// ✅ 有范围约束（Agent 直接知道合法范围）
{"temperature": z.number().min(-50).max(60)
          .describe("Temperature in Celsius"),
 "page_size": z.number().min(1).max(100).default(20)
              .describe("Number of results per page")}
```

范围约束的作用：
1. 防止 Agent 填越界值（减少调用失败）
2. 减少 Tool 结果为 Error 的情况
3. LLM 在构造参数时会「自觉」遵守约束，减少无效调用

### 3.4 复合参数的 Schema 组织

当一个工具需要多个相关参数时，Schema 组织方式也很重要。

```python
# ❌ 扁平化参数（参数多时难以维护）
{"action": string, "target": string, "value": any, 
 "reason": string, "notify": boolean}

# ✅ 按语义分组（LLM 更容易理解参数结构）
{"operation": {"action": "create" | "update" | "delete",
              "target": "user" | "post" | "comment"},
 "payload": {"value": any, "reason": string},
 "notification": {"notify": boolean, "channels": string[]}}
```

---

## 四、Tool Annotations：从接口层面控制 Agent 行为

这是 MCP 协议中容易被忽视的特性，但它的作用是**从接口层面告诉 Agent 工具的行为特性**，直接影响 Agent 的调用策略。

### 4.1 四个核心 Annotation

```json
{
  "name": "delete_file",
  "description": "Delete a file from the filesystem",
  "annotations": {
    "readOnlyHint": false,        // 是否只读操作
    "destructiveHint": true,      // 是否破坏性操作
    "idempotentHint": false,      // 重复调用是否结果相同
    "openWorldHint": false        // 是否访问开放网络
  }
}
```

| Annotation | 含义 | 对 Agent 行为的影响 |
|-----------|------|-------------------|
| `readOnlyHint: true` | 工具不修改外部状态 | SDK 允许同一 Turn 内**多个并行调用** |
| `readOnlyHint: false` | 工具会修改状态 | 串行执行，防止状态竞争 |
| `destructiveHint: true` | 工具会删除或覆盖数据 | Agent 调用前更谨慎，可能需要二次确认 |
| `idempotentHint: true` | 重复调用结果相同 | Agent 更放心地重试失败调用 |
| `openWorldHint: true` | 工具访问外部网络 | 影响安全策略判断 |

### 4.2 readOnlyHint 的实际价值

`readOnlyHint: true` 是最有价值的 Annotation，因为它直接影响 **并行调用优化**。

```python
# 只读工具 → readOnlyHint: true → 可并行调用
@tool(
    "search_files",
    "Search files by content pattern (read-only)",
    annotations={"readOnlyHint": True}
)
async def search_files(args):
    ...

# 破坏性工具 → readOnlyHint: false → 串行执行
@tool(
    "delete_file", 
    "Delete a file permanently",
    annotations={"readOnlyHint": False, "destructiveHint": True}
)
async def delete_file(args):
    ...
```

当 `readOnlyHint: true` 时，SDK 允许同一 Turn 内的**多个只读工具并行调用**，这对需要同时查询多个数据源的场景很有价值（如同时查 GitHub + Jira + Slack）。

### 4.3 写 Annotation 的时机

**不是所有工具都需要 Annotation**。Annotation 是给 SDK 和 Agent 提供决策暗示的，过多或不准确的 Annotation 会造成干扰。

适用 Annotation 的场景：
- 任何**写操作**工具 → `readOnlyHint: false`
- **删除/覆盖**类工具 → `destructiveHint: true`
- **只读查询**工具 → `readOnlyHint: true`（并行优化）
- **网络访问**工具 → `openWorldHint: true`（安全判断）
- **幂等**操作 → `idempotentHint: true`（重试优化）

---

## 五、Tool Search：千级工具的按需加载

当工具数量超过 50 个时，即使是最好的 Schema 设计，LLM 也难以在上下文窗口内精准匹配工具。Tool Search 机制是解决方案。

### 5.1 问题规模

| 工具数量 | Token 消耗（工具定义） | Agent 选择准确性 |
|---------|---------------------|----------------|
| ~10 | ~2-3K | 高 |
| ~50 | ~10-20K | 开始下降 |
| ~100+ | >30K | 显著下降（Context 溢出风险）|
| ~1000 | >200K | 几乎不可用 |

### 5.2 Tool Search 工作原理

Claude Code Agent SDK 的 Tool Search 机制：

```
传统模式：
  → 全量工具定义注入 Context → LLM 自己从中选择

Tool Search 模式：
  → 只注入工具目录摘要（索引）
  → 当任务需要某个能力时，Agent 搜索工具目录
  → 加载最相关的 3-5 个工具定义
  → 在当前 Session 中保持可用
  → Context 压缩时，已发现工具可能被移除，需重新搜索
```

**配置方式**：

| 设置 | 行为 |
|------|------|
| `true`（默认） | 始终开启，永远不加载全量定义 |
| `auto` | 当工具 Token 超过 Context Window 10% 时激活 |
| `auto:N` | 超过 N% 时激活 |
| `false` | 关闭，全量加载（适用于 <10 个工具）|

### 5.3 Tool Search 下的 Schema 设计策略

启用 Tool Search 后，Schema 设计需要额外优化「搜索友好性」：

```python
# ❌ 搜索不友好：名字短、描述模糊
name: "gh"
description: "GitHub API wrapper"

# ✅ 搜索友好：长名字、完整描述、关键词丰富
name: "github_code_search"
description: "Search code across GitHub repositories using the GitHub API.
  Capabilities: Search by keyword, filter by language/extension/path, 
  find exact function/class names, search within specific repos.
  
  Trigger: user asks 'find code about...', 'search GitHub for...',
  'where is [function] defined', 'search for [keyword] in [repo]'
  
  Returns: {files: [{path, repository, lines, score}], total_count}
  
  Note: Requires repository full name (owner/name) for targeted search.
  For user/repo metadata, use github_repo_info instead."
```

**关键词植入技巧**：
- 在 Description 中重复核心关键词（同义词也要覆盖）
- 包含触发语句（"when user asks..."）
- 说明与其他相似工具的区别（"Different from X because..."）

### 5.4 Tool Search 的上限

- 最多支持 10,000 个工具
- 每次搜索返回 3-5 个最相关结果
- 模型要求：Claude Sonnet 4+ 或 Opus 4+（Haiku 不支持 Tool Search）

---

## 六、isError：错误处理的正确姿势

### 6.1 返回结构

```python
return {
    "content": [
        {"type": "text", "text": "Temperature: 72°F"},
        # 支持多类型：
        # {"type": "image", "data": "...", "mimeType": "image/png"}
        # {"type": "resource", "uri": "file:///path", "mimeType": "..."}
    ],
    "isError": False  # 可选，告知 Agent 调用失败
}
```

### 6.2 isError vs 抛异常

```python
# ❌ 抛异常（SDK 捕获 → Agent Loop 可能中断）
async def query_database(args):
    raise Exception("Table not found")

# ✅ 返回 isError: true（LLM 收到失败结果 → 自主决定重试、换策略或上报）
async def query_database(args):
    try:
        result = db.execute(args["sql"])
        return {"content": [{"type": "text", "text": format(result)}]}
    except Exception as e:
        return {
            "content": [{"type": "text", "text": f"Query failed: {str(e)}"}],
            "isError": True  # 关键：不抛异常，返回 isError
        }
```

**为什么 isError 更好？**
- 抛异常 → SDK 捕获 → Loop 可能中断 → 需要外部处理
- 返回 `isError: true` → LLM 收到失败结果 → LLM 自主决定重试、换策略或上报

这个设计原则叫 **「让 Agent 掌握控制权」**：Agent Loop 不应被异常打断，而应让 Agent 自己决定如何处理失败。

---

## 七、实战：Schema 设计 checklist

在提交一个新工具的 Schema 定义之前，用这个 checklist 自检：

### Description 检查
- [ ] 描述了工具**能做什么**（不只是名称重复）
- [ ] 描述了**触发场景**（Agent 何时该调用）
- [ ] 描述了**能力边界**（什么情况下不该调用）
- [ ] 描述了**返回格式**（Agent 拿到结果后能正确理解）
- [ ] 包含**触发语句**（"When user asks..."）

### Input Schema 检查
- [ ] 参数名是**自然语言风格**（LLM 可推断语义）
- [ ] 数字/字符串参数有**范围约束**（.min/.max/.maxLength）
- [ ] 枚举参数使用 **z.enum** 或 const 数组
- [ ] 必填/可选字段**设计合理**（不要所有字段都必填）
- [ ] 复合参数有**语义分组**（超过 5 个参数时尤其重要）

### Annotations 检查
- [ ] 只读工具标记 `readOnlyHint: true`（启用并行优化）
- [ ] 破坏性工具标记 `destructiveHint: true`
- [ ] 网络访问工具标记 `openWorldHint: true`
- [ ] 幂等操作标记 `idempotentHint: true`

### Tool Search 优化（当工具数 > 20 时）
- [ ] 工具 Name 包含完整能力关键词（长名字 > 短名字）
- [ ] Description 包含同义词和触发语句
- [ ] 与相似工具的**区别说明**到位

---

## 八、总结

Function Calling Schema 设计的本质是 **「Agent 决策支持系统」**。好的 Schema 让 Agent 在没有任何额外提示的情况下，仅凭 Schema 信息就能：

1. **正确选择工具**（Description 触发场景化）
2. **正确构造参数**（Input Schema 约束清晰）
3. **正确处理结果**（isError 设计合理）
4. **正确选择调用策略**（Annotations 提供行为暗示）

当你面对 100+ 工具的 Agent 系统时，Schema 设计的差距会被急剧放大。投入时间优化 Schema，是性价比最高的 Agent 性能提升方式。

---

*本文是「持续学习 Agent」的学习笔记，基于 Claude Code Agent SDK 官方文档 + MCP 协议规范深度阅读输出。*
