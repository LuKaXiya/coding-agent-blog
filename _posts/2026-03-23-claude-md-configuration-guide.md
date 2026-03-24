---
layout: post
title: "CLAUDE.md 完全指南：让 AI 准确理解你的项目"
date: 2026-03-23
category: AI编程工具
tags: ["Claude Code", "配置", "CLAUDE.md", ".clauderc", "最佳实践"]
---

> CLAUDE.md 写得好不好，直接决定 Claude Code 能不能真正帮你高效工作。

---

## 📖 目录

- [🤔 三个配置文件，到底什么区别](#-三个配置文件到底什么区别)
- [📝 CLAUDE.md 的正确打开方式](#-claude-md-的正确打开方式)
- [⚙️ 不同项目类型的配置示例](#-不同项目类型的配置示例)
- [🔧 .clauderc 完整配置项详解](#-clauderc-完整配置项详解)
- [⚠️ 常见配置错误和解决方案](#-常见配置错误和解决方案)
- [👥 团队共享配置策略](#-团队共享配置策略)
- [🚀 进阶：环境差异化配置](#-进阶环境差异化配置)

---

## 🤔 三个配置文件，到底什么区别

很多人把三个配置混着用，结果发现 Claude Code "不听话"。

先搞清楚每个文件的定位：

| 文件 | 作用域 | 存储位置 | 内容类型 | 修改频率 |
|------|--------|---------|---------|---------|
| **CLAUDE.md** | 项目级 | 项目根目录 | 项目上下文、代码规范、工作流 | 每个项目创建一次 |
| **.clauderc** | 用户级 | 项目根目录 | CLI 行为配置、快捷命令 | 几乎不变 |
| **~/.claude/mcp.json** | 用户级 | home 目录 | MCP Server 连接配置 | 按需添加 |

### 三个文件的典型内容

**CLAUDE.md** — 回答"这个项目是什么，应该怎么做"：
```
这个项目是电商后端，使用 Java 17 + Spring Boot 3。
所有 API 必须有 @ApiOperation 注解。
事务在 Service 层管理。
```

**.clauderc** — 回答"Claude Code 默认怎么工作"：
```json
{
  "model": "sonnet",
  "timeout": 120,
  "prompt": "你是一个专业的 Java 后端工程师"
}
```

**~/.claude/mcp.json** — 回答"AI 能调用哪些外部工具"：
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

### 核心原则

> **项目规范 → CLAUDE.md**
> **工具行为 → .clauderc**
> **外部工具 → MCP 配置**

把项目代码规范写到 `.clauderc` 里，切换项目时就会互相污染。把 MCP 配置写到项目根目录，AI 就不理解你在做什么。搞清楚每个文件的职责，是正确配置的第一步。

---

## 📝 CLAUDE.md 的正确打开方式

### CLAUDE.md 被加载的时机

Claude Code 启动时，会自动从当前目录向上查找 `CLAUDE.md` 文件，找到第一个就加载。

```
/projects/
├── CLAUDE.md              ← 找到这个，加载停止
│   └── ecommerce/
│       └── CLAUDE.md      ← 不会加载，因为父目录已有
```

这意味着你在 `ecommerce/` 子目录工作时，Claude Code 用的是 `/projects/CLAUDE.md` 的规范，而不是 `/projects/ecommerce/CLAUDE.md`。

### CLAUDE.md 的内容结构

一个高质量的 CLAUDE.md 应该按这个顺序组织：

```
1. 项目概述（一句话说明项目是什么）
2. 技术栈（让 AI 知道用什么语言/框架）
3. 代码规范（AI 要遵守的规则）
4. 工作流（分支策略、Commit 规范、PR 要求）
5. 架构决策（关键的技术选择和约束）
6. 禁止事项（AI 绝对不能做的事）
```

**示例：**

```markdown
# 订单履约系统

处理电商订单的履约流程，支持创建、支付、发货、退款全链路。

## 技术栈

- Java 17 + Spring Boot 3.2
- PostgreSQL 15 + Redis 7
- MyBatis-Plus 3.5
- Kafka 3.6（事件总线）

## 代码规范

- 命名：Java 用 camelCase，数据库表/字段用 snake_case
- 日志：使用 Slf4j（log.info/warn/error），禁止 System.out
- 异常：必须捕获并转换，禁止吞异常
  - Service 层：自定义业务异常（BusinessException）
  - Controller 层：统一异常处理器返回 API 错误码
- 单元测试：覆盖率 > 70%，使用 JUnit 5 + Mockito

## 工作流

- 分支命名：feature/xxx, fix/xxx, hotfix/xxx
- Commit 格式：<type>(<scope>): <message>
  - type: feat, fix, docs, style, refactor, test, chore
- PR 要求：必须通过 CI（单元测试 + 集成测试）

## 架构决策

- 事务边界：Service 层开启，@Transactional(readOnly = true) 用于查询
- 缓存策略：读多写少用 Redis，读写都频繁不用缓存
- API 规范：RESTful，/api/v1/ 前缀，统一响应 {code, message, data}
- ID 生成：使用 Snowflake 算法，禁止自增 ID 暴露

## 禁止事项

- ❌ 不要在 Controller 写业务逻辑
- ❌ 不要直接操作数据库（必须通过 Mapper/Repository）
- ❌ 不要硬编码配置（使用 @Value 或@ConfigurationProperties）
- ❌ 不要绕过鉴权直接访问内部接口
```

### CLAUDE.md 的黄金法则

**法则一：简洁再简洁**

Claude Code 对配置有截断机制。超过一定长度，后面的内容会被忽略。

实际测试：
- 500 行以内：基本完整加载
- 1000 行：后半部分可能被截断
- 2000 行：大量内容丢失

**建议**：把最重要的 5 条规范放最前面。如果规范很多，按优先级分批写。

**法则二：具体而非抽象**

```
❌ 不好："代码要写好"
✅ 好："每个 public 方法必须有 Javadoc，格式：
/**
 * 方法功能描述
 * @param paramName 参数说明
 * @return 返回值说明
 */"

❌ 不好："注意性能"
✅ 好："数据库查询必须走索引，单次查询 < 50ms（可监控）"
```

**法则三：告诉 AI 验收标准**

AI 不知道你满意的标准是什么。你要明确说出来：

```
✅ 好："API 响应时间必须 < 200ms"
✅ 好："所有对外接口必须有幂等处理"
✅ 好："新增功能必须同步更新 README 相关说明"
```

**法则四：按项目类型定制**

不同项目，CLAUDE.md 的侧重点完全不同：

| 项目类型 | 重点内容 |
|---------|---------|
| **Java 后端** | 事务边界、异常处理、数据库规范、API 规范 |
| **React 前端** | 组件规范、状态管理、样式规范、API 调用方式 |
| **Python 数据** | 依赖管理、数据处理规范、笔记本规范 |
| **全栈项目** | API 契约、前后端边界、共享类型定义 |

---

## ⚙️ 不同项目类型的配置示例

### Java Spring Boot 后端

```markdown
# XXX 订单服务

## 技术栈
- Java 17, Spring Boot 3.2, Spring MVC
- MyBatis-Plus 3.5, PostgreSQL 15
- Redis 7（缓存）, Kafka 3.6（事件）

## 核心规范

### 异常处理
- 业务异常：throw new BusinessException("E001", "用户不存在")
- 禁止：catch (Exception e) { e.printStackTrace(); }
- Controller 通过 GlobalExceptionHandler 统一处理

### 事务管理
- @Transactional 默认 readOnly = false
- 查询方法显式标注 readOnly = true
- 事务超时：timeout = 5（秒）

### API 规范
- 路径：/api/v1/{resource}
- 响应：{code: string, message: string, data: object}
- 分页：GET /api/v1/orders?page=1&size=20
- 错误码：E开头（如 E001），详见 error-codes.md

### 日志
- 使用 Slf4j：log.info("orderId={}, status={}", id, status)
- 禁止：System.out, e.printStackTrace()
- 敏感信息：禁止写入日志（密码、Token、手机号）

### 测试
- 单元测试：Service 层，JUnit 5 + Mockito
- 集成测试：使用 @SpringBootTest
- 覆盖率：核心业务 > 70%

## 禁止事项
- ❌ Controller 禁止写业务逻辑
- ❌ 禁止 SQL 拼接（必须用 MyBatis 参数化查询）
- ❌ 禁止硬编码魔法值（必须用常量或配置）
```

### React + TypeScript 前端

```markdown
# XXX 管理后台前端

## 技术栈
- React 18, TypeScript 5, Vite 5
- Ant Design 5（UI 组件库）
- React Query（服务端状态）
- Zustand（客户端状态）

## 组件规范

### 文件结构
```
src/
├── components/       # 通用组件
│   └── Button/
│       ├── index.tsx
│       └── index.less
├── pages/           # 页面组件
├── hooks/           # 自定义 Hooks
├── utils/           # 工具函数
└── types/           # TypeScript 类型定义
```

### 命名规范
- 组件：PascalCase（如 UserList.tsx）
- 工具函数：camelCase（如 formatDate.ts）
- CSS 类名：BEM 风格（如 user-list__item--active）

### API 调用
- 使用 React Query 的 useQuery/useMutation
- 禁止在组件内直接 fetch
- 错误处理：统一拦截，展示 Toast

### 禁止事项
- ❌ 禁止 any（必须用具体类型）
- ❌ 禁止直接操作 DOM（用 Ref 或 API）
- ❌ 禁止内联样式（用 CSS Modules 或 Tailwind）
- ❌ 禁止提交时不做防抖处理
```

### Python 数据分析项目

```markdown
# XXX 数据分析项目

## 技术栈
- Python 3.11, pandas 2.x, numpy 2.x
- Jupyter Notebook / JupyterLab
- matplotlib, seaborn（可视化）

## 代码规范

### Notebook 规范
- 每个 Notebook 有明确标题（第一行 Markdown）
- 单元格执行顺序：从上到下，禁止跳格
- 耗时操作标注耗时：%%time

### 数据处理
- 读取数据：使用相对路径，禁止硬编码文件路径
- 列操作：使用 .pipe() 链式调用
- 缺失值：必须显式处理（drop/fill/标注）

### 可复现性
- 所有依赖版本固定：requirements.txt
- 禁止 %reset（清除变量破坏可复现性）

## 禁止事项
- ❌ 禁止 print 调试后忘记删除
- ❌ 禁止修改原始数据文件
- ❌ 禁止硬编码阈值（写入配置文件）
```

---

## 🔧 .clauderc 完整配置项详解

`.clauderc` 是 JSON 格式的配置文件，放在项目根目录（或 home 目录作为全局配置）。

### 完整配置项

```json
{
  "model": "sonnet",
  "timeout": 120,
  "maxTokens": 8192,
  "prompt": "你是一个专业的后端工程师，...",
  
  "permissions": {
    "allow": ["Read", "Write", "Bash", "Glob", "Grep", "WebFetch", "WebSearch"],
    "deny": [
      "Bash:rm -rf /",
      "Bash:rm -rf /*",
      "Bash:mkfs",
      "Bash:dd"
    ]
  },
  
  "aliases": {
    "review": "仔细审查代码，重点检查：安全性、异常处理、边界条件",
    "test": "为当前文件或选中的代码生成单元测试",
    "docs": "根据代码变更更新相关文档"
  },
  
  "env": {
    "EDITOR": "vim",
    "GIT_EDITOR": "vim"
  },
  
  "planMode": {
    "enabled": true,
    "autoSwitchBack": true
  },
  
  "output": {
    "showToolResults": true,
    "showPlanProgress": true
  }
}
```

### 各配置项详解

**model**：指定使用的模型
```
可选值：haiku, sonnet, opus
建议：
- 快速任务（补全、重构）：haiku
- 标准开发任务：sonnet
- 复杂分析、设计决策：opus
```

**timeout**：单次工具调用超时（秒）
```
默认值：60
建议：
- 简单操作：60
- 复杂重构或调试：120-300
```

**permissions**：权限控制
```
allow：允许的操作列表
deny：禁止的操作（支持通配符）

⚠️ deny 优先于 allow
⚠️ 永远不要把 rm -rf / 加入 allow
```

**aliases**：快捷命令
```
定义后，可以用 /review, /test, /docs 触发对应 prompt
适合团队标准化工作流
```

### .clauderc 的常见配置场景

**场景一：限制危险操作**
```json
{
  "permissions": {
    "allow": ["Read", "Write", "Bash", "Grep", "Glob"],
    "deny": [
      "Bash:rm -rf",
      "Bash:mkfs",
      "Bash:dd",
      "Bash:>/dev/sd*"
    ]
  }
}
```

**场景二：设置默认角色**
```json
{
  "prompt": "你是一个经验丰富的 Java 架构师，
  擅长设计高性能、高可用的分布式系统。
  在做任何设计决策前，先问自己：
  1. 这个方案的可扩展性如何？
  2. 失败模式是什么？
  3. 如何测试这个设计？"
}
```

**场景三：启用 Plan Mode 默认行为**
```json
{
  "planMode": {
    "enabled": true,
    "autoSwitchBack": true,
    "prompt": "先用 Plan Mode 理解问题，确认方案后再执行"
  }
}
```

---

## ⚠️ 常见配置错误和解决方案

### 错误一：CLAUDE.md 写成了 README

**症状**：Claude Code 输出了项目介绍，但开始写代码时"失智"了。

**原因**：README 是给人看的（安装步骤、使用说明），CLAUDE.md 是给 AI 看的（代码规范、验收标准）。

**解决**：
```
README.md → 面向人类（安装、使用）
CLAUDE.md → 面向 AI（规范、约束）
```

不要在 CLAUDE.md 里写"如何安装"或"这个项目用 yarn 管理"。把这些留给 README。

### 错误二：把项目规范写到 .clauderc

**症状**：切换项目后，Claude Code 还在用上一个项目的规范。

**原因**：.clauderc 是用户级/全局配置，不应该包含项目特定的内容。

**解决**：.clauderc 只写工具行为配置，项目规范必须写到 CLAUDE.md。

```
❌ 错误：
.clauderc 里写："这个项目必须用 Java 17"

✅ 正确：
CLAUDE.md 里写："本项目使用 Java 17"
.clauderc 不涉及项目语言版本
```

### 错误三：CLAUDE.md 过长

**症状**：Claude Code "忘记"了一些规范，或者行为前后不一致。

**原因**：Claude Code 对 CLAUDE.md 有最大加载长度，超过后截断。

**解决**：
1. 把最重要的规范放前 500 行
2. 把次要规范拆分到独立文件（如 `docs/coding-standards.md`）
3. 在 CLAUDE.md 里引用：`详见 docs/coding-standards.md`

```markdown
# 项目规范索引

详细规范请参考：
- 代码规范：docs/coding-standards.md
- API 规范：docs/api-standards.md
- 错误码说明：docs/error-codes.md
```

### 错误四：规范描述太抽象

**症状**：Claude Code 生成的代码质量不稳定，好的时候很好，差的时候完全不符合预期。

**原因**：规范没有具体的验收标准，AI 只能靠猜测。

**解决**：用具体数字和可验证的标准。

```
❌ 不好："API 要高性能"
✅ 好："API p95 响应时间 < 200ms，使用 Redis 缓存热点数据"

❌ 不好："要写好测试"
✅ 好："核心业务逻辑测试覆盖率 > 70%，使用 JUnit 5 + Mockito"

❌ 不好："注意代码风格"
✅ 好："Java 代码用 Google Java Style Guide，提交前运行 mvn spotless:check"
```

### 错误五：禁止事项描述不够精确

**症状**：Claude Code 绕过了你写的禁止规则。

**原因**：禁止规则不够具体，AI 找到了"合理解释"来绕过。

**解决**：禁止规则要精确，附上反例。

```
❌ 不好："不要直接操作数据库"
✅ 好："禁止在 Controller 层直接写 SQL。必须通过 XxxMapper/XxxRepository 访问数据库。

反例（禁止）：
@Controller
public class OrderController {
    @Autowired JdbcTemplate jdbc;
    jdbc.query("SELECT * FROM orders"); // ❌ 禁止
}

正例：
@Service
public class OrderService {
    @Autowired private OrderMapper orderMapper;
    orderMapper.selectById(id); // ✅ 正确
}
```

---

## 👥 团队共享配置策略

### 方式一：Git 模板仓库

创建一个公司内部的模板仓库：

```
company-claude-templates/
├── java-spring-boot/
│   └── CLAUDE.md
├── react-ts/
│   └── CLAUDE.md
└── python-data/
    └── CLAUDE.md
```

新项目初始化时：
```bash
git init
git remote add template git@github.com:your-org/company-claude-templates.git
git sparse-checkout set java-spring-boot
git pull template main
```

### 方式二：Git Hook 强制检查

在 `pre-commit` hook 里检查 CLAUDE.md 是否存在：

```bash
#!/bin/bash
# .git/hooks/pre-commit

if [ ! -f CLAUDE.md ]; then
    echo "❌ 错误：项目根目录必须包含 CLAUDE.md"
    echo "请参考：https://github.com/your-org/company-claude-templates"
    exit 1
fi
```

### 方式三：AI 辅助生成初始 CLAUDE.md

Claude Code 可以根据现有代码帮你生成 CLAUDE.md：

```bash
# 在项目根目录执行
claude --print "分析这个项目的代码结构、技术栈和代码风格，
生成一个 CLAUDE.md 文件。

要求：
1. 识别主要技术栈
2. 总结代码规范（命名、异常处理、测试等）
3. 识别架构模式
4. 输出完整的 CLAUDE.md 内容"
```

---

## 🚀 进阶：环境差异化配置

### 问题

同一项目，在开发、测试、生产环境需要不同的规范（如日志级别、调试开关）。

### 方案一：CLAUDE.md 条件加载

在 CLAUDE.md 里用标记区分：

```markdown
# XXX 订单系统

## 环境配置

<!-- DEV_ONLY_START -->
## 开发环境
- DEBUG 日志：开启
- 模拟支付：可用
<!-- DEV_ONLY_END -->

<!-- PROD_ONLY_START -->
## 生产环境
- DEBUG 日志：关闭
- 真实支付：必须
- 禁止：console.log
<!-- PROD_ONLY_END -->
```

在启动 Claude Code 时，告诉它当前环境：
```
claude --print "当前环境：production"
```

### 方案二：多文件分层

```
项目/
├── CLAUDE.md              ← 基础配置（所有环境共享）
├── CLAUDE.dev.md          ← 开发环境追加配置
├── CLAUDE.test.md         ← 测试环境追加配置
└── CLAUDE.prod.md         ← 生产环境追加配置
```

CLAUDE.md 里引用：
```markdown
## 环境配置

开发环境补充：参见 CLAUDE.dev.md
测试环境补充：参见 CLAUDE.test.md
生产环境补充：参见 CLAUDE.prod.md
```

### 方案三：.env 文件 + CLAUDE.md 联动

```markdown
<!-- 读取 .env 获取当前环境 -->
<!-- 如果 NODE_ENV=production，执行以下约束：-->
- 禁止任何 console.* 调用
- 所有 API 必须有超时设置
- 错误不能返回详细堆栈（必须转为通用错误码）
```

---

## 总结：CLAUDE.md 配置检查清单

创建或审核 CLAUDE.md 时，对照这个清单：

```
□ 1. 项目概述清晰（一句话说明项目是什么）
□ 2. 技术栈明确（语言、框架、数据库、关键中间件）
□ 3. 代码规范具体（不是抽象原则，是可执行的规则）
□ 4. 规范有验收标准（数字化的指标）
□ 5. 禁止事项明确（附反例）
□ 6. 工作流清晰（分支、Commit、PR）
□ 7. 架构决策记录（关键技术选择）
□ 8. 长度合理（< 500 行，核心内容在前）
□ 9. 按项目类型定制（不是通用模板）
□ 10. 与 README 分工明确（不重复）
```

**CLAUDE.md 不是一次性的配置**。随着项目演进，规范会变化，CLAUDE.md 也应该定期更新。建议每个 sprint 或每个版本迭代时回顾一次 CLAUDE.md，确保它仍然准确反映项目的实际规范。

---

## 相关资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)
- [MCP 协议生态](./mcp-ecosystem.md)
- [多 Agent 编排实战](./multi-agent-orchestration.md)
- [AI 测试工具大全](./ai-testing-tools.md)
