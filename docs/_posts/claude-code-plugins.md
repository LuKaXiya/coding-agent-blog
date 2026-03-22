---
layout: post
title: "Claude Code 插件体系：MCP 不只是「连接外部工具」"
date: 2026-03-22
---


> 理解 MCP 的真正价值，以及什么时候你其实不需要它。

---

## MCP 解决了什么问题

很多人装 MCP 就是因为"别人说有用"。

但你有没有想过：**MCP 解决的是什么根本问题？**

**答案是：上下文不够的问题。**

Claude Code 再强，它的上下文只有你给它的东西。如果你每次都需要手动复制粘贴信息给它，它的效率就大打折扣。

MCP 让 Claude Code 直接连接外部系统，自动获取上下文。

---

## 什么情况下 MCP 真的有用

### 场景一：你需要反复查询同一个系统

```
不用 MCP：
1. 打开 Jira，看某个 ticket 状态
2. 复制 ticket 内容
3. 粘贴给 Claude Code
4. 让 Claude Code 分析

用 MCP：
1. "帮我分析这个 Jira ticket：PROJ-123"
2. Claude Code 自动查询 Jira，获取 ticket 内容
3. 直接分析
```

如果你每天都要重复做"查系统 → 复制 → 粘贴给 Claude"这件事，MCP 就有价值。

### 场景二：你需要跨系统关联信息

```
"帮我看看这个用户在我们的系统和支付系统里的所有相关记录"
→ Claude Code 自动查两个系统，关联数据
```

### 场景三：你需要 Claude Code 执行系统操作

```
"帮我创建这个 Jira ticket"
"帮我合并这个 PR"
"帮我查一下这个 Lambda 的日志"
```

---

## 什么情况下 MCP 是过度设计

**如果你只是偶尔查一次数据，手动复制粘贴就够了。**

安装和配置 MCP 有成本：
- 配置时间
- 维护（Token 会过期、权限会变）
- 调试（出问题排查麻烦）

**用一个 MCP 的前提：你节省的时间 > 配置和维护的成本。**

---

## 实用的 MCP 工具推荐

### 文件系统（几乎人人需要）

**用途**：让 Claude Code 能读写指定目录

适合场景：
- 项目分散在多个目录
- 需要 Claude Code 管理文件结构

### GitHub（如果你每天用 GitHub）

**用途**：查询 Issue、PR、代码库状态

适合场景：
- Code Review
- 追踪项目进度
- 自动化生成 Changelog

### 1Password（团队安全规范要求）

**用途**：获取密钥但不暴露

适合场景：
- 部署时需要配置密钥
- 不希望密钥出现在代码或日志中

### AWS（云开发者）

**用途**：查询资源、查看日志

适合场景：
- 排查线上问题
- 资源管理

---

## 配置 MCP 的正确方式

### 第一步：先想清楚要不要装

```
问题：我的日常工作流中，有哪些是"查系统 → 复制 → 粘贴"这种模式？
频率：每天 3 次以下 → 不需要 MCP
      每天 10 次以上 → 强烈推荐
```

### 第二步：从最小配置开始

不要一次配一堆。先配一个，用一周，看效果。

### 第三步：注意 Token 安全

```
❌ 错误：
.clauderc 里直接写 token

✅ 正确：
用环境变量，或者 1Password 集成
```

### 第四步：定期检查权限

MCP 的权限是你给它的。要定期检查：
- 这个 MCP Server 真的需要这么多权限吗？
- Token 是不是已经不用了但配置还在？

---

## 调试 MCP 的正确方式

### 问题一：MCP 返回的结果不对

**排查思路**：
1. MCP Server 本身有没有问题？（单独测试 MCP）
2. 返回的数据格式对吗？
3. Claude Code 理解返回结果的方式对吗？

```
# 测试 MCP Server 是否正常
claude mcp test --server <name>
```

### 问题二：Claude Code 不会用 MCP

**原因**：Claude Code 不一定会主动调用 MCP。需要你明确告诉它。

```
"请用 GitHub MCP 查询这个仓库的最近 5 个 closed PR"
      ↑
 明确告诉它用哪个工具
```

---

## MCP 的局限性

### 局限性一：MCP Server 的质量参差不齐

不是所有 MCP Server 都做得好。有的返回数据格式混乱，有的错误处理不完善。

**建议**：先测试再依赖。

### 局限性二：MCP 有延迟

每次调用 MCP 都有网络延迟。如果你的 Prompt 需要快速迭代，频繁调用 MCP 会很慢。

**建议**：批量查询，不要频繁单次调用。

### 局限性三：MCP 的错误难以排查

如果 MCP 返回错误，你需要同时排查：
- MCP Server 端
- MCP Client 端（Claude Code）
- 网络问题

**建议**：保留日志，便于排查。

---

## 替代方案：不用 MCP 也能做

### 替代一：直接给上下文

如果你只是偶尔需要查数据，直接复制粘贴可能更简单。

```
不用 MCP：30 秒复制粘贴
安装配置 MCP：30 分钟

如果你只查一次，MCP 反而是浪费。
```

### 替代二：用 API 脚本

如果你需要的操作比较固定，可以写一个简单的脚本：

```
#!/bin/bash
# 查 Jira ticket 的简单脚本
curl -u user:token https://jira.com/rest/api/2/issue/$1
```

Claude Code 可以直接调用脚本，不需要 MCP。

---

## 总结

**MCP 不是必须的。** 它解决的是"频繁跨系统操作"的问题。

如果你每天都在做"查系统 → 复制 → 粘贴"这件事，MCP 值得装。

如果你只是偶尔查一次数据，手动复制粘贴就够了。

**先想清楚你的工作流，再决定要不要用 MCP。**

---

## 相关资源

- [MCP 官方文档](https://modelcontextprotocol.io/)
- [MCP Server 列表](https://github.com/modelcontextprotocol/servers)
- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)