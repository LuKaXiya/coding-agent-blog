---
layout: post
title: "Claude Code 高级 CLI 模式：print / repl / resume 的产品化实战"
date: 2026-03-23
category: AI编程工具
tags: ["Claude Code", "CLI", "CI/CD", "自动化", "生产环境"]
---

> Claude Code 不只是交互式工具——它的 CLI 模式让 AI 编程融入了完整的工程化流程。

---

## 背景：为什么 CLI 模式很重要

大多数人对 Claude Code 的印象是：一个交互式 CLI 工具，运行 `claude` 后进入对话模式。

但这只是 Claude Code 能力的冰山一角。

Claude Code 提供了三种 CLI 模式，覆盖了从"快速单次查询"到"完整 CI/CD 自动化"的全部场景。把这些模式用好，意味着你可以把 AI 编程能力嵌入到任何工程流程里：**Git Hook、CI/CD 流水线、定时任务、批处理脚本**——全部不需要人工干预。

本文深度讲解这三种模式，结合真实产品化案例，让 Claude Code 从"对话工具"变成"工程基础设施"。

---

## 📖 目录

- [🤔 三种 CLI 模式的核心区别](#-三种-cli-模式的核心区别)
- [⚡ 模式一：--print 非交互式执行](#-模式一-print-非交互式执行)
- [💬 模式二：--repl 无状态交互](#-模式二-repl-无状态交互)
- [🔄 模式三：--resume 会话恢复](#-模式三-resume-会话恢复)
- [🛠️ GitHub Actions 自动化 Code Review](#-github-actions-自动化-code-review)
- [🔗 Git Hooks 集成：自动化检查](#-git-hooks-集成自动化检查)
- [🧪 自动化测试生成流水线](#-自动化测试生成流水线)
- [📊 会话管理与最佳实践](#-会话管理与最佳实践)
- [⚠️ 常见陷阱与避坑指南](#-常见陷阱与避坑指南)

---

## 🤔 三种 CLI 模式的核心区别

| 模式 | 命令 | 会话状态 | 适用场景 | 典型用途 |
|------|------|---------|---------|---------|
| **交互模式** | `claude` | 持久 | 日常开发 | 探索性任务、长任务 |
| **print 模式** | `claude --print` | 无状态 | 自动化脚本 | CI/CD、Hook、批处理 |
| **repl 模式** | `claude --repl` | 无状态 | 快速查询 | 单次独立问题 |
| **resume 模式** | `claude --resume` | 恢复指定会话 | 长任务继续 | 跨天任务、大型重构 |

**理解无状态 vs 有状态**：

```
交互模式 / resume：
  每次输入基于之前的上下文
  Claude 记得你之前说了什么

print / repl：
  每次执行完全独立
  Claude 不记得上次说了什么
```

---

## ⚡ 模式一：--print 非交互式执行

`--print` 是产品化场景最重要的模式。它让 Claude Code 成为"一次性执行命令"，输出到 stdout，退出。

### 核心参数

```bash
# 基本语法
claude --print "你的指令"

# --no-input：禁止等待用户输入（自动化必加）
claude --print --no-input "审查这段代码" < file.java

# 指定模型
claude --print --model opus "复杂架构分析" < spec.md

# 输出到文件
claude --print "生成代码" > Output.java

# 组合：管道 + 文件输入 + 输出重定向
cat request.json | claude --print --no-input "审查这个 API 设计" > review.txt
```

### `--no-input` 的作用

`--no-input` 是自动化场景的**关键标志**。它告诉 Claude Code 两件事：

1. **不要等待用户输入**：Claude Code 遇到需要澄清的问题时，不会停下来问你
2. **适用于管道场景**：数据从 stdin 流入，结果从 stdout 流出

```bash
# ❌ 没有 --no-input：Claude 会停下来问你
cat file.java | claude --print "审查"

# ✅ 有 --no-input：完全自动化执行
cat file.java | claude --print --no-input "审查"
```

### GitHub Actions 自动化 Code Review

这是最实用的产品化案例之一。

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

      - name: Get PR diff
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # 获取 PR 变更
          git diff origin/${{ github.base_ref }}...HEAD > pr-diff.txt

          # 如果 diff 为空（仅文档变更），跳过 review
          if [ ! -s pr-diff.txt ]; then
            echo "No code changes, skipping review"
            exit 0
          fi

      - name: Run AI Code Review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          claude --print --no-input "
          请审查以下 PR 变更，重点关注：

          1. **安全性**：注入攻击、越权访问、敏感信息泄露
          2. **并发安全**：多线程/异步环境下的数据一致性
          3. **错误处理**：异常是否被正确捕获和转换
          4. **性能隐患**：N+1 查询、不必要的循环、阻塞调用

          PR 描述：
          ${{ env.PR_BODY }}

          如果没有问题，输出：
          ✅ 代码审查通过，无重大问题

          如果有问题，按以下格式输出：
          ## 🔴 需要修复
          - [文件:行号] 问题描述 → 修复建议

          ## 🟡 建议优化
          - [文件:行号] 优化建议
          " < pr-diff.txt > review-result.txt

      - name: Post review comment
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const result = fs.readFileSync('review-result.txt', 'utf8');
            const prNumber = context.payload.pull_request.number;

            // 检查是否通过
            const passed = result.includes('✅');

            // 已有评论则更新，否则创建
            const comments = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber
            });

            const existingComment = comments.data.find(
              c => c.user.login === 'github-actions[bot]' &&
                   c.body.includes('## 🤖 AI Code Review')
            );

            const commentBody = '## 🤖 AI Code Review\n\n' + result;

            if (existingComment) {
              await github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: existingComment.id,
                body: commentBody
              });
            } else {
              await github.rest.issues.createComment({
                issue_number: prNumber,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: commentBody
              });
            }
```

### 预提交 Hook：把 AI 当守门员

Git Hook 让你在代码提交前自动运行检查。把 Claude Code 加入 pre-commit hook，可以实现：

- **敏感信息扫描**：提交前检测硬编码的 API Key、密码
- **代码质量检查**：调试语句、TODO 标记检查
- **变更影响分析**：大型重构前评估影响范围

```bash
#!/bin/bash
# .git/hooks/pre-commit

MAX_FILE_SIZE=102400  # 100KB，超过跳过

echo "🔍 运行 AI 预提交检查..."

while IFS= read -r file; do
  # 跳过非代码文件
  [[ "$file" =~ \.(md|json|yml|yaml|txt)$ ]] && continue

  # 跳过过大的文件
  size=$(wc -c < "$file")
  if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
    echo "⏭️  跳过 $file（文件过大）"
    continue
  fi

  # 检测敏感信息
  result=$(claude --print --no-input "
    检查这段代码是否包含硬编码的敏感信息。

    检测范围：
    - API Key / Token（sk-, ak-, ghp_ 等前缀）
    - 密码和私钥（password=, secret=）
    - 真实手机号（1[3-9]\d{9} 格式）
    - 邮箱（非 example@ 开头的）
    - AWS 密钥（AKIA 开头）

    如果有发现，输出格式：
    ⚠️ [文件] 发现敏感信息：[类型] 在 [行号附近]
    示例：⚠️ [config.java] 发现敏感信息：API Key 在第 15 行

    如果没有，输出：
    ✅ 无敏感信息
  " < "$file" 2>/dev/null)

  if echo "$result" | grep -q "⚠️"; then
    echo "❌ $file: $result"
    exit 1
  fi
done < <(git diff --cached --name-only --diff-filter=ACM)

echo "✅ 预提交检查通过"
```

安装 hook 的方法：

```bash
# 方式一：复制到项目 .git/hooks
cp scripts/pre-commit .git/hooks/

# 方式二：使用 Husky（推荐，团队共享）
npx husky add .husky/pre-commit "bash scripts/pre-commit"
```

### 与 Git 深度集成的常用命令

```bash
# 获取某个分支的所有变更
git diff origin/main...HEAD

# 获取文件变更历史（用于理解代码演进）
git log -p --follow -- src/OrderService.java

# 获取提交消息生成 changelog
git log --oneline --format="%s" v1.0.0..v2.0.0

# 获取变更统计
git diff --stat HEAD~10 HEAD

# 获取特定 commit 的变更文件列表
git diff-tree --no-commit-id --name-only -r <commit-hash>
```

---

## 💬 模式二：--repl 无状态交互

`--repl` 模式提供一个交互式界面，但每次对话完全独立，不保留历史。

### 典型使用场景

```bash
# 启动 REPL
claude --repl

# 每次输入独立执行
# 适合：快速问一个问题，不需要上下文关联
```

### 什么时候用 REPL vs Print

```
REPL 适合：
- 快速语法转换（TypeScript ↔ JavaScript）
- 单次代码片段解释
- 不需要记住上下文的探索

Print 适合：
- 需要基于文件内容的分析（< file 传入）
- 自动化流水线
- 批处理
```

**实际例子**：把一个 Python 脚本翻译成 Go，用 REPL：

```bash
$ claude --repl
> 把这个 Python 代码翻译成 Go
# [粘贴 Python 代码]
# Claude 输出 Go 代码

> 再把错误处理改成 Result 模式
# Claude 记住了上文吗？不记得！
# 因为 REPL 是无状态的，每次都独立

> 把这个 Python 代码翻译成 Go，错误处理用 Result 模式
# [重新粘贴 Python 代码]
# Claude 正确执行
```

**教训**：REPL 模式下，如果你需要上下文关联，必须在同一条消息里提供所有必要信息。涉及多轮对话的任务，不要用 REPL。

---

## 🔄 模式三：--resume 会话恢复

`--resume` 让你恢复之前的工作会话，继续未完成的任务。

### 核心命令

```bash
# 恢复最近一次会话
claude --resume

# 恢复指定会话
claude --resume <session-id>

# 列出所有可恢复的会话
claude sessions list

# 查看会话详情
claude sessions show <session-id>

# 删除不需要的会话
claude sessions delete <session-id>
```

### 真实场景：跨天的大型重构

```bash
Day 1:
$ claude
> 把整个订单模块从 MySQL 迁移到 PostgreSQL
[Claude 开始执行，进行了 2 小时，涉及 50+ 文件]

[突然有事，需要中断]

Day 2:
$ claude sessions list
SESSION-ID  LAST ACTIVE        PROJECT
abc123      2026-03-22 18:30   订单模块迁移
def456      2026-03-22 10:15   用户认证重构

$ claude --resume abc123
[Claude 恢复了昨天的工作上下文]
> 继续迁移，今天完成 User 和 Product 模块
[Claude 从上次中断的地方继续]
```

### 会话存储与清理策略

会话存储在 `~/.claude/sessions/` 目录。每个会话是一个独立文件，包含完整的消息历史。

**定期清理脚本**：

```bash
#!/bin/bash
# scripts/cleanup-sessions.sh

# 清理 30 天前的会话
find ~/.claude/sessions -type f -mtime +30 -delete

# 清理超过 100MB 的会话目录
current_size=$(du -sm ~/.claude/sessions | cut -f1)
if [ "$current_size" -gt 100 ]; then
  echo "会话目录超过 100MB，开始清理..."
  # 按最后修改时间排序，删除最旧的 50%
  ls -t ~/.claude/sessions | tail -n $(ls ~/.claude/sessions | wc -l | xargs -I {} expr {} / 2) | xargs -r rm
fi

echo "清理完成，当前大小：$(du -sh ~/.claude/sessions | cut -f1)"
```

**会话优先级建议**：

```
高优先级（手动备份）：
- 正在进行的重构（50+ 文件）
- 重要调试任务（跨天追踪）
- 未完成的设计工作

低优先级（可清理）：
- 一次性的代码查询
- 过期的调研会话
- 测试性质的实验
```

---

## 🧪 自动化测试生成流水线

结合 `--print` 和脚本，可以构建完整的自动化测试生成流水线。

### 场景：PR 触发测试生成

```yaml
# .github/workflows/ai-test-generation.yml
name: AI Test Generation

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup
        run: |
          npm install -g @anthropic-ai/claude-code
          npm install

      - name: Find changed service files
        id: changed
        run: |
          git diff origin/${{ github.base_ref }}...HEAD --name-only \
            | grep -E 'Service\.java$' \
            | head -5 \
            > changed-services.txt
          echo "count=$(wc -l < changed-services.txt)" >> $GITHUB_OUTPUT

      - name: Generate tests
        if: steps.changed.outputs.count > 0
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          mkdir -p src/test/java

          while IFS= read -r file; do
            test_file=$(echo "$file" | sed 's|/main/|/test/|g' | sed 's|\.java$|Test.java|')
            test_dir=$(dirname "$test_file")
            mkdir -p "$test_dir"

            echo "为 $file 生成测试..."

            claude --print --no-input "
            为这个 Java Service 类生成 JUnit 5 单元测试。

            要求：
            1. 使用 Mockito Mock 所有外部依赖
            2. 覆盖所有 public 方法
            3. 每个方法包含：正常流程 + 异常流程 + 边界条件
            4. 命名规范：MethodName_Scenario_ExpectedBehavior
            5. 使用 @DisplayName 描述测试意图
            6. 输出完整的 Java 文件内容

            文件路径仅用于参考，不需要与输出路径一致。
            " < "$file" > "$test_file"

            if [ $? -eq 0 ]; then
              echo "✅ $test_file 生成成功"
            else
              echo "❌ $test_file 生成失败"
            fi
          done < changed-services.txt

      - name: Show results
        run: |
          echo "## 测试生成结果"
          find src/test -name "*Test.java" -newer .github/workflows/ai-test-generation.yml \
            | while read f; do
              echo "- $f ($(wc -l < "$f") 行)"
            done

      - name: Create PR comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const newTests = [];
            const output = execSync(
              'find src/test -name "*Test.java" -newer .github/workflows/ai-test-generation.yml'
            ).toString().trim().split('\n').filter(Boolean);

            const prNumber = context.payload.pull_request.number;
            const body = `## 🤖 AI 测试生成\n\n生成了 ${output.length} 个测试文件：\n\n${
              output.map(f => `- \`${f}\``).join('\n')
            }\n\n请审核测试质量后合并。`;

            github.rest.issues.createComment({
              issue_number: prNumber,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body
            });
```

### 单脚本版本的测试生成

不需要 CI/CD，也可以用简单的脚本批量生成测试：

```bash
#!/bin/bash
# scripts/generate-tests.sh

TARGET_DIR=${1:-src/main/java/com/example}

echo "🔍 查找所有 Service 文件..."
services=$(find "$TARGET_DIR" -name "*Service.java" | grep -v Test)

for file in $services; do
  test_file=$(echo "$file" \
    | sed "s|/main/java/|/test/java/|g" \
    | sed 's|\.java$|Test.java|')

  test_dir=$(dirname "$test_file")
  mkdir -p "$test_dir"

  if [ -f "$test_file" ]; then
    echo "⏭️  跳过（已存在）：$test_file"
    continue
  fi

  echo "📝 生成：$test_file"
  claude --print --no-input "
  为这个 Java 类生成 JUnit 5 单元测试。

  规范：
  - 使用 JUnit 5 + Mockito
  - 所有外部依赖 Mock
  - 覆盖 public 方法的正常/异常/边界场景
  - 测试命名：MethodName_Scenario_ExpectedBehavior
  - 使用 @DisplayName 描述测试意图

  输出完整的 Java 代码。
  " < "$file" > "$test_file"

  if [ $? -eq 0 ] && [ -s "$test_file" ]; then
    echo "✅ $test_file"
  else
    echo "❌ $test_file 生成失败"
    rm -f "$test_file"
  fi
done

echo "完成！"
```

---

## 📊 会话管理与最佳实践

### CLI 参数完整参考

```bash
# 连接和认证
claude --auth <api-key>           # 指定 API Key
claude --base-url <url>          # 代理或自托管端点

# 执行模式
claude --print                   # 非交互式（自动化）
claude --repl                    # 无状态 REPL
claude --resume [session-id]     # 恢复会话

# 输入输出
claude --no-input                # 禁止等待输入（自动化必须）
claude --input <file>           # 等同于 < file
claude --output <file>          # 输出到文件

# 模型控制
claude --model <model>          # haiku | sonnet | opus
claude --max-tokens <n>        # 最大输出 Token

# 上下文控制
claude --context-window <n>     # 上下文窗口大小
claude --no-claude-md           # 忽略 CLAUDE.md

# 调试
claude --verbose                # 详细日志
claude --debug                  # 调试模式
```

### 环境变量管理 API Key

```bash
# ❌ 错误：API Key 硬编码
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# ✅ 正确：使用 .env 文件
# .env
ANTHROPIC_API_KEY="sk-ant-..."

# ✅ 更好：使用 direnv 自动加载
# .envrc
export ANTHROPIC_API_KEY="$(cat .env | grep ANTHROPIC_API_KEY | cut -d= -f2)"

# ✅ 最佳：使用 1Password CLI 集成
export ANTHROPIC_API_KEY=$(op read "op://AI/anthropic-api-key/password")
```

### 错误处理和重试机制

```bash
#!/bin/bash
# scripts/claude-retry.sh

max_attempts=3
retry_delay=5

execute_with_retry() {
  local prompt="$1"
  local output_file="$2"
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "尝试 $attempt/$max_attempts..."

    if claude --print --no-input "$prompt" > "$output_file" 2>&1; then
      echo "✅ 执行成功"
      return 0
    else
      echo "⚠️ 尝试 $attempt 失败，${retry_delay}秒后重试..."
      sleep $retry_delay
      attempt=$((attempt + 1))
      retry_delay=$((retry_delay * 2))  # 指数退避
    fi
  done

  echo "❌ 所有尝试均失败"
  return 1
}

# 使用示例
execute_with_retry "审查这段代码" < file.java > review.txt
```

---

## ⚠️ 常见陷阱与避坑指南

### 陷阱一：忘记 `--no-input` 导致挂起

```bash
# ❌ 错误：没有 --no-input，Claude 遇到问题会等待输入
cat file.java | claude --print "审查"

# ✅ 正确：始终加 --no-input
cat file.java | claude --print --no-input "审查"
```

### 陷阱二：大文件导致上下文溢出

Claude Code 有上下文窗口限制，超过后会截断。

```bash
# ❌ 错误：直接传入大文件
cat huge-file.java | claude --print --no-input "审查"
# 可能超出上下文，导致分析不完整

# ✅ 正确：先拆分或指定关键部分
head -500 huge-file.java | claude --print --no-input "审查这个文件的前 500 行"
```

### 陷阱三：会话污染

在自动化场景里，不同任务的上下文可能互相污染。

```bash
# ❌ 错误：连续执行多个不相关的任务
claude --print "审查代码" < a.java
claude --print "生成文档" < b.md
claude --print "优化性能" < c.py

# ✅ 正确：每个任务独立上下文（--print 天然隔离）
(claude --print "审查" < a.java > review.txt) &
(claude --print "生成文档" < b.md > docs.txt) &
(claude --print "优化性能" < c.py > optimized.txt) &
wait
```

### 陷阱四：CI/CD 环境中 API Key 泄露

```bash
# ❌ 错误：API Key 出现在日志里
claude --print --no-input "审查"
# 如果 CI 失败，API Key 可能出现在错误日志中

# ✅ 正确：使用 secrets，错误输出也不显示 Key
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
run: |
  claude --print --no-input "审查" < file.java
  # 即使失败，Key 也不会出现在日志中
```

### 陷阱五：REPL 模式下的上下文丢失

```bash
# ❌ REPL 误解：以为可以多轮对话
$ claude --repl
> 我有个 Java 项目想重构
> 帮我看看 OrderService
[Claude 分析了 OrderService]

> 那 PaymentService 呢
[Claude 不记得上一条说的是 OrderService]

# ✅ REPL 正确用法：所有信息一条说完
$ claude --repl
> 我有一个 Java 项目，包含 OrderService 和 PaymentService。
  请分析 PaymentService 的代码质量问题。
[Claude 正确执行]
```

---

## 总结：CLI 模式 vs 交互模式的选择

```
日常开发（探索性任务、长任务）
  → 交互模式（claude）

快速单次查询，不需要上下文
  → --repl（claude --repl）

需要基于文件内容分析
  → --print（claude --print --no-input < file）

CI/CD 流水线、自动化脚本
  → --print（claude --print --no-input）

跨天继续长任务
  → --resume（claude --resume <session-id>）
```

**--print 是产品化的核心**。当你的团队开始在 CI/CD 流水线里集成 AI Code Review，在 pre-commit hook 里加入敏感信息检测，在 PR 创建时自动生成测试用例——Claude Code 就从"个人工具"变成了"团队基础设施"。

这个转变，才是 AI 编程工具真正融入软件工程的开端。

---

## 相关资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)
- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Git Hooks 官方文档](https://git-scm.com/docs/githooks)
- [MCP 协议生态](./mcp-ecosystem.md)
- [CLAUDE.md 完全指南](./2026-03-23-claude-md-configuration-guide.md)
- [AI 代码审查实战](./ai-code-review.md)

---

*本文基于 Claude Code 最新版本（2026-03-23）*
