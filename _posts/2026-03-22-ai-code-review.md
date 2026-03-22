---
layout: post
title: "🤖 用 AI 做代码审查：PR 审核、CodeQL 集成、安全扫描实战指南"
date: 2026-03-22
category: 测试自动化
tags: ["AI", "代码审查", "CodeQL", "安全扫描"]
---


> AI 不是帮你找 Bug，是帮你站在更高的地方看代码

---

## 📖 目录

- [🤔 AI 代码审查是什么，能帮我们什么](#-ai-代码审查是什么能帮我们什么)
- [🧰 工具选型：哪种 AI 适合做代码审查](#-工具选型哪种-ai-适合做代码审查)
- [⚡ 5 分钟快速上手：用 Claude Code 审查一个 PR](#-5-分钟快速上手用-claude-code-审查一个-pr)
- [💼 日常工作流：5 个接地气场景](#-日常工作流5-个接地气场景)
- [🛡️ CodeQL + AI：让安全漏洞无处遁形](#-codeql--ai让安全漏洞无处遁形)
- [🤝 深度使用：多人协作中的 AI Review 策略](#-深度使用多人协作中的-ai-review-策略)
- [📈 如何借助 AI 代码审查提升自己](#-如何借助-ai-代码审查提升自己)

---

## 🤔 AI 代码审查是什么，能帮我们什么

**AI 代码审查 = 让 AI 帮你从另一个视角看代码。**

它不是简单的语法检查，不是 ESLint 那种规则匹配。它更接近于：一个经验比你丰富 10 倍的同事，坐在你旁边，逐行跟你讨论"这段逻辑有没有问题"。

### 人工 Review 的困境

代码 Review 这件事，理论上每个团队都在做。实际上大多数团队的 Review 存在三个问题：

**1. Review 变成了走过场**
   - PR 太大（几百行改动）， reviewer 看不完
   - Review 时间紧，只能看个大概
   - 评审会上挨个过代码，2 小时起步，没人能全程集中注意力

**2. 经验差距导致发现问题不均匀**
   - 高级工程师看得出深层问题，但没时间仔细看
   - 初级工程师有心帮忙，但经验不足容易漏掉关键问题
   - 团队成员水平参差，Review 质量不稳定

**3. 特定类型的问题容易被忽视**
   - 安全漏洞（SQL 注入、XSS、越权）
   - 并发问题（竞态条件、死锁）
   - 性能隐患（N+1 查询、大循环中的远程调用）
   - 边界条件（空指针、数组越界、整数溢出）

这些问题靠肉眼 review，资深工程师也不一定能全发现。

### AI 代码审查能帮什么？

| 人工 Review 痛点 | AI 能帮什么 |
|-----------------|------------|
| PR 太大看不完 | AI 可以处理任意大小的代码变更，分析完给你摘要 |
| Review 时间不够 | AI 几秒钟完成初筛，揪出重点问题 |
| 安全漏洞难发现 | AI + 规则双重扫描，常见漏洞模式基本都能覆盖 |
| 并发问题隐蔽 | AI 擅长分析控制流和状态变更路径 |
| 边界条件漏掉 | AI 会主动猜测边界情况并提问 |
| 经验差距大 | AI 的知识和经验是均等的，每个 PR 都能被同等质量地 review |

**但 AI 不是银弹。** AI 不了解你的业务逻辑、团队规范、架构历史，所以 AI Review 的定位应该是：**初筛 + 辅助发现问题，最终判断还是靠人。**

---

## 🧰 工具选型：哪种 AI 适合做代码审查

### 主流工具横向对比

| 工具 | 集成方式 | 安全扫描 | 并发分析 | 学习成本 | 适合团队 |
|------|---------|---------|---------|---------|---------|
| **Claude Code** | CLI / VS Code / Cursor | ✅ 内置 | ✅ 较强 | 低 | 所有团队 |
| **GitHub Copilot** | GitHub PR 评论 | ⚠️ 基础 | ⚠️ 弱 | 极低 | GitHub 用户 |
| **GPT-4 + 代码解释器** | API 调用 | ✅ 可配置 | ✅ 较强 | 中 | 有定制能力的团队 |
| **CodeQL + AI 后处理** | GitHub Advanced Security | ✅ 深度 | ✅ 深度 | 高 | 安全要求高的团队 |
| **Semgrep + AI** | CI/CD 集成 | ✅ 强 | ✅ 中 | 中 | DevOps 成熟团队 |

### 推荐组合策略

**小型团队 / 个人开发者：**
```
Claude Code（日常 review） + GitHub Copilot（IDE 内联提示）
```

**中型团队（GitHub）：**
```
GitHub Copilot Review（PR 评论） + CodeQL（安全扫描）
```

**安全敏感型团队：**
```
CodeQL（深度扫描） + Claude Code（架构层面 review） + Semgrep（自定义规则）
```

本文重点讲 **Claude Code + CodeQL** 的组合方案，这是目前最实用、门槛适中、覆盖全面的方案。

---

## ⚡ 5 分钟快速上手：用 Claude Code 审查一个 PR

### 准备工作

```bash
# 1. 安装 Claude Code
npm install -g @anthropic-ai/claude-code

# 2. 在项目目录初始化（会创建 .claude 目录）
cd your-project
claude

# 3. 拉取要 review 的 PR
git fetch origin
git checkout -b review-branch origin/PR-123
```

### 第一次 AI Review

进入 Claude Code 后，直接告诉它你要 review：

```
请 review 这个 PR（#123），重点关注：
1. 安全性：注入、越权、敏感信息泄露
2. 并发问题：多线程/异步环境下的数据一致性
3. 异常处理：错误是否被正确捕获和处理
4. 性能隐患：N+1 查询、不必要的循环、阻塞调用

PR 描述：[粘贴 PR 描述]
```

Claude Code 会：
1. 分析所有变更的文件
2. 理解业务逻辑（如果有 PR 描述）
3. 逐文件输出 review 意见
4. 给出一个总体评价（可合并 / 需要修改 / 建议大改）

### 典型输出示例

Claude Code 的输出大致是这样的：

```
📁 src/services/OrderService.java

⚠️ [安全性] 第 85 行：`String.format` 拼接 SQL
   query = String.format("SELECT * FROM orders WHERE id = %s", orderId);
   → 存在 SQL 注入风险，请使用 PreparedStatement

⚠️ [并发] 第 120-140 行：余额扣减缺少原子性保证
   this.balance -= amount;
   → 多线程环境下可能导致超扣，建议使用原子操作或分布式锁

✅ [逻辑] 第 45 行：边界条件处理正确
   if (balance < amount) throw new InsufficientBalanceException();

🔵 [建议] 第 200 行：可以使用 Optional 替代 null 返回
   → 提升代码可读性

---

总体评价：⚠️ 需要修改后合并
建议修复 SQL 注入问题和并发问题再合入。
```

### 让 AI 专注特定维度

有时候你不需要全面 review，只需要关注某个方面：

```
只 review 这个 PR 的并发安全性，不需要看其他问题。
只 review 新的 API 接口是否有越权风险。
只关注性能，不要关注安全。
```

---

## 💼 日常工作流：5 个接地气场景

### 场景一：Review 别人的 PR（日常协作）

**痛点**：PR 太大（500+ 行改动），看不下去

**AI 介入方式**：
```
/review PR#456 --focus=security,concurrency
```

Claude Code 会先给你一个变更摘要，然后按优先级列出问题。reviewer 可以快速决定：这个 PR 风险高不高，主要问题在哪。

**实操技巧**：
- 把 PR 描述一起粘贴给 AI，AI 能更好理解改动意图
- 让 AI 标注"必须改"和"建议改"两类问题，分清主次
- 大 PR 让 AI 按文件拆分 review，每个文件单独输出

### 场景二：自己的代码提交前自检

**痛点**：不好意思让同事看自己的初稿

**AI 介入方式**：写完代码后，自己先用 AI review 一遍再提交

```
请在我提交之前 review 这个分支的改动，重点检查：
1. 是否有调试代码 / console.log 遗留
2. 是否有敏感信息硬编码（API Key、密码）
3. 命名是否一致
4. 注释和代码是否一致
```

**好处**：减少"低级问题"被同事发现的尴尬，提升代码形象

### 场景三：安全敏感模块的深度 review

**痛点**：支付、权限、认证模块不能有任何闪失

**AI 介入方式**：对安全敏感模块使用更严格的 prompt

```
请对 src/security/ 模块进行深度安全 review，包括：
1. 认证绕过风险
2. 授权/权限检查完整性
3. 敏感数据加密和存储
4. Session/Cookie 安全配置
5. 加密算法选择（是否使用了不安全的算法）

这个模块处理 [业务描述]
```

### 场景四：老代码回归审查

**痛点**：接手老项目，不敢改，怕改坏

**AI 介入方式**：改之前先用 AI 了解风险

```
我要重构 src/legacy/BillingService.java，
把同步调用改成异步消息队列。请先帮我分析：
1. 这个类的所有外部依赖（数据库、外部服务、缓存）
2. 可能被影响的调用方
3. 改动后的兼容性问题
```

### 场景五：跨技术栈的代码 review

**痛点**：团队成员用不同语言，你 review 不了别人的代码

**AI 介入方式**：让 AI 先解释，再 review

```
我主要写 Java，不太熟悉 TypeScript。请：
1. 先解释 src/frontend/api/auth.ts 的逻辑（让我能看懂）
2. 再对这个文件进行安全 review
```

---

## 🛡️ CodeQL + AI：让安全漏洞无处遁形

### 为什么需要 CodeQL + AI 的组合？

Claude Code 的内置安全扫描覆盖常见问题，但对于：
- 复杂的数据流分析（从用户输入到数据库查询的完整路径）
- 特定框架的安全配置（Spring Security、React 安全上下文）
- 自定义业务逻辑漏洞（与金额计算相关的逻辑错误）

需要 CodeQL 做深度静态分析，再用 AI 对 CodeQL 报告的问题进行业务影响评估。

### CodeQL 安装和基本用法

```bash
# 1. 安装 CodeQL CLI
brew install codeql     # macOS
# 或参考 https://github.com/github/codeql-cli-binaries

# 2. 创建代码库
codeql database create --language=java ./codeql-db

# 3. 运行内置安全查询
codeql database analyze ./codeql-db   --format=sarif-latest   --output=security-results.sarif   github/security-and-quality
```

### CodeQL + Claude Code 联合使用

**第一步**：CodeQL 跑全量扫描，生成报告

```bash
# Java 项目常见漏洞扫描
codeql database analyze ./codeql-db   --categories=security   --format=csv   --output=codeql-findings.csv
```

**第二步**：把 CodeQL 的发现丢给 Claude Code

```
以下是 CodeQL 安全扫描的结果，请帮我评估每个问题的业务影响：

[粘贴 codeql-findings.csv 内容]

评估维度：
1. 这个漏洞在真实攻击场景下能造成什么后果？
2. 结合我们的业务（[业务描述]），优先级是否需要调整？
3. 建议的修复方案是什么？
```

**第三步**：让 AI 帮你理解 CodeQL 的查询结果

CodeQL 的输出有时候很技术化，不容易理解。直接问 AI：

```
帮我解释 CodeQL 的这个发现（PATH-INJECTION）：
[粘贴具体告警]
```

AI 会用业务语言解释这个问题是什么、为什么危险、如何修复。

### 常见安全扫描规则推荐

**高频高危（必查）**：
- `java/sql-injection` — SQL 注入
- `java/path-injection` — 路径遍历
- `java/xxe` — XML 外部实体注入
- `java/hardcoded-credential` — 硬编码密码
- `java/unsafe-deserialization` — 不安全反序列化

**中等风险（建议查）**：
- `java/stored-xss` — 存储型 XSS
- `java/weak-crypto` — 弱加密算法
- `java/weak-random` — 弱随机数
- `java/insufficient-logging` — 日志不足

---

## 🤝 深度使用：多人协作中的 AI Review 策略

### 团队 review 流程设计

```
PR 创建
    ↓
AI 初审（Claude Code） → 快速筛选，低风险直接通过
    ↓
AI 安全扫描（CodeQL） → 发现问题打回
    ↓
人工 review（针对性）
    ↓
合并
```

**关键原则**：AI 审的不是"代码风格"，是"代码风险"。风格问题用 ESLint/Prettier 自动处理，不要浪费 AI review 的注意力。

### 配置 Claude Code 的 review 行为

在项目根目录创建 `.claude/commands/review.md`：

```markdown
# 代码审查标准

## 必须检查的维度（每次必查）
1. 安全性：注入、越权、敏感信息泄露
2. 并发安全：多线程/异步环境下的状态一致性
3. 错误处理：异常是否被正确捕获和处理
4. 性能：N+1 查询、不必要的循环、阻塞调用

## 建议检查的维度（可省略）
5. 代码可读性：命名、注释、结构
6. 测试覆盖：关键逻辑是否有对应测试

## 忽略的维度（自动化处理）
- 代码风格（ESLint/Prettier 处理）
- import 顺序（IDE 自动处理）
- 简单的格式问题

## 输出格式
每个问题请标注：
- [严重/警告/建议] 问题类型
- 文件和行号
- 问题描述
- 修复建议
```

### 处理 AI 的误报

AI review 有一个常见问题：**误报多**。AI 看到可疑模式就报，但实际可能不是问题。

**处理方式**：
1. 每个 AI 标记的问题先问 AI："这个在 [具体业务场景] 下是否真的是问题？"
2. 如果 AI 确认没问题，记录为"已知误报，忽略"
3. 持续误报的问题可以加到白名单

```
/review 时告诉 AI：
"以下模式在正常业务场景下不是问题，请忽略：
- getClass().getName() 用于日志记录
- String.format 用于日志消息格式化（非 SQL）"
```

### AI Review 在 CI/CD 中的集成

如果团队有 GitHub Actions，可以配置自动 AI review：

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Run AI Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          claude --print --no-input "
          请 review PR#${{ github.event.number }} 的改动，
          重点关注安全性和并发问题。
          "
```

---

## 📈 如何借助 AI 代码审查提升自己

### 从"被动接收"到"主动学习"

很多人用 AI review 只是为了找人帮忙挑刺，这只发挥了 50% 的价值。

**更有价值的方式**：

1. **问"为什么"而不是"对不对"**
   ```
   ❌ "这段代码有问题吗？"（被动）
   ✅ "为什么这段代码在高并发下会出问题？"（主动学习）
   ```

2. **让 AI 讲原理，不只是给结论**
   ```
   "请解释你判断这里有并发问题的推理过程，
   我想学习如何自己发现这类问题。"
   ```

3. **对比 AI 的 review 和自己的 review**
   - 先自己 review 一遍，记录自己的发现
   - 再让 AI review，对比差异
   - AI 发现了你没想到的 → 补充知识盲区
   - 你发现了 AI 漏掉的 → 记录，思考为什么 AI 没发现

### 建立个人代码审查知识库

每次 AI review 让你学到新东西，记下来：

```markdown
# 我的代码审查知识库

## 安全（AI review 学到的）
- [2026-03] String.format 拼接 SQL 即使在 MyBatis 也要警惕
- [2026-03] LocalDateTime.now() 在分布式环境可能导致时间不一致
- ...

## 并发（AI review 学到的）
- [2026-03] SimpleDateFormat 不是线程安全的，替换为 DateTimeFormatter
- ...

## 架构（AI review 学到的）
- [2026-03] 贫血模型 vs 充血模型：领域逻辑放 Service 还是 Entity？
- ...
```

### 从 review 对象变成 reviewer

**阶段一（初学者）**：依赖 AI 帮你 review，你审核 AI 的结论
**阶段二（进阶）**：你能判断 AI 的结论对不对，知道 AI 的边界
**阶段三（高手）**：你能指导初级工程师用 AI 做 review，成为团队 review 的最后一道防线

AI review 工具降低了你成为 reviewer 的门槛，但你最终还是要建立自己的判断力和知识体系。

---

## 🔗 相关资源

- [Claude Code 官方文档 - Review](https://docs.anthropic.com/claude-code)
- [CodeQL 官方文档](https://codeql.github.com/docs/)
- [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
- [Semgrep 规则集](https://semgrep.dev/r)

---

## 🔗 其他博客

- [多Agent编排实战](./multi-agent-orchestration.md)
- [AI需求分析指南](./ai-requirements-analysis.md)
- [AI测试工具大全](./ai-testing-tools.md)
- [Claude Code插件体系](./claude-code-plugins.md)