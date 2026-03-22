# 🧪 AI 测试工具：让测试工程师效率翻倍的实战指南

> 告别手工堆代码，拥抱 AI 辅助测试

[![Testing](https://img.shields.io/badge/AI-Testing-blue?style=social)](https://github.com/LuKaXiya/coding-agent-blog)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 目录

- [🤔 AI 测试是什么？](#-ai-测试是什么)
- [🧰 工具选型指南](#-工具选型指南)
- [⚡ 10 分钟快速上手](#-10-分钟快速上手)
- [💼 日常工作流：5 个接地气场景](#-日常工作流5-个接地气场景)
- [🤝 深度使用：Claude Code 多 Agent 测试](#-深度使用claude-code-多-agent-测试)
- [⚠️ AI 测试的难点：Mock 配置](#-ai-测试的难点mock-配置)
- [📚 测试人员如何借助 AI 提升自己](#-测试人员如何借助-ai-提升自己)
- [🔗 相关资源](#-相关资源)

---

## 🤔 AI 测试是什么？

简单说：**让 AI 帮你写测试用例，你来做审核和把关。**

### 核心工作流（测试人员必知）

```
┌─────────────────────────────────────────────────────────┐
│            测试人员 AI 辅助测试核心工作流                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   AI 读代码  →  AI 理解业务  →  AI 生成用例  →  人工审核  │
│      ↓              ↓              ↓              ↓     │
│   自动分析      上下文注入      自动生成        最终把关  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 传统测试 vs AI 辅助对比

| 环节 | 传统方式 | AI 辅助 |
|------|----------|---------|
| 写单元测试 | 手工编码，速度慢，容易遗漏 | AI 自动生成，覆盖率高 |
| 构造测试数据 | 手动准备，字段组合复杂 | AI 智能生成多样化边界数据 |
| 接口测试 | Postman 一个个点 | AI 自动生成用例 + Mock |
| 回归测试 | 全量回归耗时 | AI 智能识别变更影响范围 |
| 性能测试 | JMeter 手工配 | AI 生成场景 + 分析报告 |

### 效率提升有多大？

```
传统：1 人 1 天 → 写 50 个用例
AI 辅助：1 人 1 天 → AI 生成 200 个用例 → 人工审核 50 个核心用例
效率提升：4-5 倍
```

**但要记住**：AI 生成的不是完美答案，需要你审核、补充业务逻辑。

---

## 🧰 工具选型指南

### 工具全景图

```
┌─────────────────────────────────────────────────────────────┐
│                      AI 测试工具生态                           │
├─────────────┬─────────────┬─────────────┬───────────────────┤
│  单元测试    │  接口测试    │  性能测试    │   测试管理        │
├─────────────┼─────────────┼─────────────┼───────────────────┤
│ Codex       │ Codex       │ k6 + AI    │ TestRail AI      │
│ Claude Code │ Thunder Client│ AI 分析    │ Qase.io         │
│ Diffblue    │ Postman AI  │ JMeter AI  │ Zephyr AI        │
│ Mokkato     │ Apifox AI   │ Grafana AI │                  │
│ EvoSuite    │             │            │                   │
└─────────────┴─────────────┴─────────────┴───────────────────┘
```

### 选型建议（按场景）

| 场景 | 推荐工具 | 费用 | 上手难度 |
|------|---------|------|---------|
| Java 单元测试（企业级） | **Diffblue** | 商业/免费试用 | ⭐⭐⭐ |
| Java 单元测试（预算有限）| **Mokkato / EvoSuite** | 免费 | ⭐⭐ |
| 多语言测试 / 快速上手 | **Claude Code / Codex** | API 费用 | ⭐ |
| API 接口测试 | **Thunder Client + AI** | 免费 | ⭐ |
| 性能测试 + 分析 | **k6 + AI / JMeter + AI** | 免费 | ⭐⭐ |
| 多 Agent 协作测试 | **Claude Code Agent Teams** | API 费用 | ⭐⭐ |

### 三大工具对比

| 维度 | Claude Code / Codex | Diffblue | Mokkato |
|------|---------------------|----------|---------|
| 语言支持 | 多语言 | 仅 Java/Kotlin | 仅 Java |
| 生成速度 | 依赖 API | 快（本地运行）| 快 |
| 多 Agent 协作 | ✅ 支持 | ❌ | ❌ |
| 测试质量 | 一般（需审核）| 高（程序分析）| 较高 |
| 覆盖率控制 | 靠 Prompt | 自动分析 | 自动分析 |
| 费用 | API 调用费 | 商业软件 | 免费 |
| 适用场景 | 通用、快速原型 | 企业级、大型项目 | Java 团队 |

---

## ⚡ 10 分钟快速上手

### 工具一：Claude Code / Codex（最通用，10 分钟跑起来）

**适用场景**：任何语言的单元测试、接口测试、测试数据生成、多 Agent 协作

**安装配置**：

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# Codex
pip install openai
export OPENAI_API_KEY="sk-..."
```

**生成单元测试**（以 Java 为例）：

```bash
# Claude Code
claude --print "为 src/main/java/OrderService.java 生成单元测试，
要求：使用 JUnit 5 + Mockito，每个 public 方法覆盖正常/异常/边界三种情况"

# Codex
codex exec "为 src/main/java/OrderService.java 生成单元测试，
要求：使用 JUnit 5 + Mockito，每个 public 方法覆盖正常/异常/边界三种情况"
```

**生成测试数据**：

```bash
codex exec "为用户注册接口生成 20 条测试数据：
- 正常数据 5 条
- 手机号格式错误 3 条
- 邮箱格式错误 3 条
- 密码强度不足 3 条
- 边界长度（1字符、50字符、51字符）3 条
- 已存在用户 2 条
- SQL 注入尝试 1 条"
```

---

### 工具二：Diffblue（Java 专用，企业级）

**适用场景**：大型 Java 项目、需要高覆盖率、团队协作

**特点**：
- 本地运行，不需要调用外部 API
- 程序分析驱动，测试质量高
- 自动维护：代码变更后自动更新测试
- 支持 IntelliJ 插件 / CLI / CI 集成

**安装（IntelliJ 插件）**：
1. IntelliJ → Settings → Plugins → 搜索 "Diffblue Cover"
2. 安装后重启 IDE
3. 右键类/方法 → Diffblue Cover → Generate Tests

**CLI 安装**：

```bash
# 下载 CLI（需要许可证）
wget https://www.diffblue.com/downloads/cover-cli.zip
unzip cover-cli.zip
./cbcover generate --target src/main/java/
```

**生成效果**：
一个复杂方法（如文件上传），Diffblue 约 1.6 秒生成完整测试，覆盖所有分支路径。

---

### 工具三：Mokkato（国产 Java 工具，免费）

**适用场景**：国内 Java 团队、预算有限、想快速上手 AI 测试

**背景**：Mokkato 是国产 AI 测试工具，专注于 Java 单元测试生成，支持 JUnit + Mockito 框架。

**使用方法**：
1. 导入项目（支持 Maven/Gradle）
2. 右键类/方法 → AI 生成测试
3. 选择测试框架和覆盖率要求
4. 自动生成，可手动调整

**特点**：
- 免费使用（适合小团队）
- 支持中文界面
- 生成速度较快
- 覆盖常见测试场景

> ⚠️ Mokkato 官网目前访问不稳定，建议关注其 GitHub 或公众号获取最新版本。

---

## 💼 日常工作流：5 个接地气场景

### 场景 1：开发给了新代码，AI 如何帮你快速理解并生成用例

**痛点**：拿到新代码，不知道从哪下手测

**解决步骤**：

```
第一步：让 AI 读代码，理解逻辑
        ↓
第二步：让 AI 列出所有关键路径和边界条件
        ↓
第三步：让 AI 生成测试用例
        ↓
第四步：人工审核、补充业务规则
```

**操作示例**：

```bash
# 第一步：让 Claude Code / Codex 分析代码
claude --print "分析 OrderService.java 的代码逻辑，列出：
1. 主要 public 方法（5个以内）
2. 每个方法的输入参数和约束
3. 可能的异常情况
4. 关键的 if/else 分支"

# 第二步：生成测试用例
claude --print "基于以上分析，为 createOrder() 方法生成测试用例，
覆盖：正常下单、参数为空、商品不存在、库存不足、库存为0
输出表格格式：用例ID | 输入 | 预期输出 | 测试类型"
```

---

### 场景 2：如何让 AI 按照你的测试规范生成用例

**痛点**：AI 生成的用例格式不对，需要返工

**解决步骤**：

```
第一步：先给 AI 你的规范模板
        ↓
第二步：明确输入约束和边界值
        ↓
第三步：指定输出格式
        ↓
第四步：生成后对照检查
```

**Prompt 模板**：

```
请为 [{函数名}] 生成测试用例，必须遵循以下规范：

【输入约束】
- 参数名: 类型, 取值范围, 约束条件

【必须覆盖的测试类型】
1. 正常流程（Happy Path）
2. 异常流程（每个错误码）
3. 边界值（最小值、最大值、边界+1）
4. 空值（null, 空数组, 空字符串）

【输出格式】
| 用例ID | 输入描述 | 测试数据 | 预期输出 | 前置条件 | 测试类型 |

【禁止】
- 不要生成性能测试用例
- 不要生成与该方法无关的测试
```

**测试用例设计模式参考**：

| 模式 | 适用场景 | 示例 |
|------|---------|------|
| 边界值分析 | 输入有范围限制 | 订单数量 1-100，测 0、1、100、101 |
| 等价类划分 | 输入类型相同 | 邮箱格式：合法/非法/空 |
| 决策表 | 多条件组合 | 订单状态+支付方式→不同折扣 |
| 场景法 | 业务流程测试 | 下单→支付→退款 完整链路 |

---

### 场景 3：API 测试 AI 化（Thunder Client + AI）

**痛点**：接口多，手工点太慢

**解决方案**：Thunder Client（VS Code 插件）+ AI 自动生成测试用例

**工作流**：

```
1. 手动发送一次请求（拿到响应）
        ↓
2. 把请求和响应发给 AI
        ↓
3. AI 自动生成其他用例（边界值、异常等）
        ↓
4. 一键导入 Thunder Client
        ↓
5. 批量执行、集成 CI/CD
```

**操作步骤**：

1. **安装 Thunder Client**：VS Code 扩展市场搜索安装
2. **发送请求**：手动发一次，拿到正常响应
3. **AI 生成用例**：

```bash
claude --print "基于以下接口信息，生成 Thunder Client 测试用例：

接口：POST /api/v1/orders
请求体：{\"userId\": 1, \"items\": [{\"productId\": 1, \"quantity\": 2}]}
响应：{\"code\": 0, \"data\": {\"orderNo\": \"ORD123\", \"totalAmount\": 100}}

请生成 5 个测试用例：
1. 正常流程
2. userId 不存在
3. 商品不存在
4. 库存不足
5. 未登录（无 token）

输出 Thunder Client Collection JSON 格式"
```

4. **导入**：Thunder Client → Collection → Import → 粘贴 JSON
5. **执行**：点击 Run 批量执行

**导出 Newman CLI**（集成 CI/CD）：

```bash
# 导出命令
newman run orders-api.json --environment env.json --reporters cli,junit
```

---

### 场景 4：性能测试 AI 辅助（JMeter/k6 + AI）

**痛点**：JMeter 脚本配置复杂，性能结果不会分析

**解决方案**：AI 生成脚本 + AI 分析报告

**AI 生成 JMeter 脚本**：

```bash
claude --print "生成 JMeter 性能测试脚本，要求：
1. 测试场景：订单创建接口 POST /api/v1/orders
2. 并发用户：100，持续 5 分钟
3. 阶梯加压：每 30 秒增加 20 用户
4. 阈值：p95 < 500ms，错误率 < 1%
5. 输出：JMX 格式文件"
```

**AI 分析性能结果**：

```bash
claude --print "分析以下 k6 性能测试结果：

【测试环境】
- 并发用户: 200
- 测试时长: 15 分钟

【结果摘要】
http_req_duration:
  avg: 320ms, p(50): 280ms, p(90): 450ms, p(95): 520ms, p(99): 890ms
http_req_failed: 2.3%

【失败分布】
/api/v1/orders POST: 1.8% 失败
/api/v1/orders/{orderNo} GET: 0.3% 失败

请分析：
1. 主要瓶颈在哪里
2. 失败原因推断
3. 优化建议（应用→数据库→缓存）
4. 还需要收集哪些指标"
```

---

### 场景 5：AI 帮你写完整的 JMeter 脚本

**痛点**：手写 JMeter 脚本太慢，参数化、关联、断言都要自己配

**解决方案**：给 AI 你的接口文档，让它生成完整脚本

**示例 Prompt**：

```
【接口列表】
1. POST /api/v1/orders - 创建订单
2. GET /api/v1/orders/{orderNo} - 查询订单
3. POST /api/v1/orders/{orderNo}/pay - 支付订单

【业务逻辑】
1. 创建订单 → 获取 orderNo
2. 用 orderNo 查询订单
3. 支付订单

【测试要求】
1. 使用 CSV 数据文件参数化（userId, productId, quantity）
2. 创建订单后提取 orderNo 供后续接口使用
3. 每个接口添加响应断言
4. 生成 HTML 报告
5. 输出完整的 JMX 文件
```

**AI 生成的脚本结构**：

```
测试计划
├── 用户定义变量（baseUrl, timeout）
├── CSV 数据文件配置
├── 线程组（100 并发，10 秒预热）
│   ├── 创建订单请求
│   │   ├── 正则表达式提取 orderNo
│   │   └── 响应断言（code=0, orderNo 非空）
│   ├── 查询订单请求
│   │   ├── 引用 orderNo 变量
│   │   └── 响应断言（status=CREATED）
│   └── 支付订单请求
│       ├── 引用 orderNo 变量
│       └── 响应断言（code=0）
└── 查看结果树 / 聚合报告
```

---

## 🤝 深度使用：Claude Code 多 Agent 测试

### Claude Code v2.1.32+ 新能力：Agent Teams

Claude Code 最新版本支持**多 Agent 协作测试**，这是测试领域的重大突破。

**什么是 Agent Teams？**

```
┌──────────────────────────────────────────────────────────────┐
│                    Claude Code Agent Teams                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   📋 测试策略 Agent                                           │
│   （制定测试计划、分析覆盖率、分配任务）                        │
│          ↓                                                   │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│   │  单元测试    │  │   API 测试   │  │  性能测试   │      │
│   │   Agent      │  │   Agent      │  │   Agent      │      │
│   │              │  │              │  │              │      │
│   │ 独立上下文   │  │  独立上下文  │  │  独立上下文  │      │
│   │ 持久化记忆   │  │  持久化记忆  │  │  持久化记忆  │      │
│   └──────────────┘  └──────────────┘  └──────────────┘      │
│          ↓                 ↓                  ↓              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │           🔍 测试审核 Agent                            │   │
│   │     （汇总结果、查重、补充遗漏、质量评估）              │   │
│   └─────────────────────────────────────────────────────┘   │
│                          ↓                                   │
│                    📊 测试报告                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**两种协作模式**：

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **in-process** | 所有 Agent 在同一进程内协作 | 快速任务、轻量协作 |
| **split-pane** | Agent 在独立子会话中运行 | 复杂任务、隔离上下文 |

---

### Subagents 子代理系统

每个 Agent 有独立的上下文和持久化记忆，互不干扰：

```bash
# 启动测试团队（split-pane 模式）
claude --print --subagent "测试团队" << 'EOF'
我需要为 OrderService 生成完整的测试套件：

团队角色：
1. 单元测试 Agent - 负责 Java 单元测试
2. API 测试 Agent - 负责接口集成测试
3. 性能测试 Agent - 负责性能场景测试

工作流程：
1. 单元测试 Agent 先分析代码，生成基础测试
2. API 测试 Agent 基于接口文档生成集成测试
3. 性能测试 Agent 设计性能测试场景
4. 汇总所有测试，统一审核

每个 Agent 完成后，将结果保存到对应目录：
- tests/unit/
- tests/integration/
- tests/performance/
EOF
```

**Subagents 特点**：
- 每个 Agent 独立上下文，不会相互污染
- 支持持久化记忆（跨会话记住测试规范）
- 可以并行或串行执行
- 适合大型项目的分工协作

---

### MCP 生态：连接数百种测试工具

Claude Code 支持 MCP（Model Context Protocol），可以连接各种测试工具：

```
┌─────────────────────────────────────────────────────────────┐
│                    MCP 测试工具生态                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Claude Code                                                │
│       │                                                      │
│       ├── MCP Server 1 ──→ JUnit 测试执行                    │
│       ├── MCP Server 2 ──→ Selenium Web 测试                  │
│       ├── MCP Server 3 ──→ Postman API 测试                   │
│       ├── MCP Server 4 ──→ JMeter 性能测试                    │
│       ├── MCP Server 5 ──→ GitHub Actions CI/CD              │
│       └── ...                                                │
│                                                             │
│   支持 100+ MCP 工具（持续增加）                               │
└─────────────────────────────────────────────────────────────┘
```

**常用 MCP 测试集成**：

| MCP 工具 | 功能 |
|---------|------|
| **JUnit MCP** | 执行单元测试、获取覆盖率报告 |
| **Selenium MCP** | 浏览器自动化测试 |
| **Postman MCP** | API 测试执行和报告 |
| **GitHub MCP** | CI/CD 状态检查、Issue 管理 |
| **Database MCP** | 数据库状态验证、数据比对 |

---

### Skills 技能系统：测试规范模板化

将团队的测试规范保存为 Skills，实现复用：

```bash
# .claude/skills/testing-standards/SKILL.md
# 测试规范 Skill 示例

## 使用方法
当需要进行测试用例生成时，参考本规范执行。

## 规范要求

### 1. Mock 配置规范
每个测试必须显式配置 Mock：
- 被调用的外部服务必须 Mock
- 数据库调用使用 @MockBean 或 Mockito
- 异常场景必须 Mock 异常

### 2. 测试数据规范
- 使用 Faker 生成真实感数据
- 禁止在测试中硬编码真实用户信息
- 测试数据在测试结束后清理

### 3. 覆盖率要求
- 核心业务方法 > 90%
- 普通业务方法 > 70%
- 工具类 > 50%

### 4. 断言规范
- 必须验证关键业务字段
- 异常测试必须验证异常类型和消息
- 禁止只断言 "不为空"
```

---

### CLAUDE.md 配置：团队测试标准

在项目根目录创建 `CLAUDE.md`，让 AI 遵循团队的测试标准：

```markdown
# 测试标准

## 测试框架
- Java: JUnit 5 + Mockito
- Python: pytest + pytest-mock

## Mock 配置（必须）
当测试涉及外部依赖时，必须使用 Mock：
- 外部 API 调用 → Mock HTTP 响应
- 数据库操作 → Mock Repository
- 缓存服务 → Mock Redis

## 覆盖率要求
- 提交 PR 前，核心模块覆盖率 > 85%
- 测试失败必须提供原因说明

## 禁止事项
- 禁止在测试代码中访问生产环境
- 禁止硬编码真实 API Key
- 禁止提交未执行的测试

## 性能测试标准
- API 响应时间 p95 < 500ms
- 并发用户数 > 100 时无错误
```

---

### 多 Agent 测试实战示例

**场景**：为一个电商订单模块生成完整测试套件

```bash
# 启动多 Agent 测试
claude --print --subagent "qa-team" << 'EOF'
为 "订单模块" 生成完整测试套件：

## 模块说明
- OrderService: 订单业务逻辑
- OrderController: 订单 API 接口
- OrderRepository: 订单数据访问

## Agent 任务分配

### Agent 1: 单元测试
- 分析 OrderService 所有 public 方法
- 生成 JUnit 5 + Mockito 测试
- 覆盖率目标 > 90%

### Agent 2: API 测试
- 分析 OpenAPI 文档
- 生成 Thunder Client / Postman 测试用例
- 覆盖：正常、异常、边界、权限

### Agent 3: 性能测试
- 设计性能测试场景
- 生成 k6 / JMeter 脚本
- 阈值：p95 < 500ms, 错误率 < 1%

## 输出要求
- 测试代码保存到 tests/ 目录
- 生成测试报告 summary.md
- 列出测试覆盖的用例清单
EOF
```

---

## ⚠️ AI 测试的难点：Mock 配置

### 为什么 Mock 配置是 AI 测试的最大难点？

AI 生成的测试往往在 Mock 配置上出问题：

```
❌ AI 常见问题：
- Mock 配置不完整，导致测试执行失败
- 忘记 Mock 某个依赖，NPE 频发
- Mock 返回值不符合预期，断言失败
- Mock 顺序/次数验证缺失
```

**核心原因**：AI 不理解被测代码的依赖关系，需要你显式说明。

---

### 如何让 AI 正确配置 Mock？

**技巧一：告诉 AI 所有的外部依赖**

```bash
claude --print "为 PaymentService 生成测试，必须 Mock 以下依赖：

【外部依赖】
1. OrderRepository - 数据库操作
2. PaymentGateway - 第三方支付（返回 PaymentResult）
3. NotificationService - 发送通知（不能实际发送）
4. RedisTemplate - 缓存操作

【Mock 返回值要求】
- OrderRepository.findByOrderNo() → 返回 Order 对象或 Optional.empty()
- PaymentGateway.pay() → 返回成功/失败两种结果
- NotificationService 只需要验证调用次数，不验证实际发送

【禁止】
- 不要实际调用 PaymentGateway
- 不要实际发送通知
- 不要实际访问 Redis"
```

---

**技巧二：提供 Mock 模板**

```
【Mock 模板 - Java】
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;
    
    @Mock
    private PaymentGateway paymentGateway;
    
    @InjectMocks
    private OrderService orderService;

    @BeforeEach
    void setUp() {
        // 默认行为配置
        when(orderRepository.findByOrderNo(anyString()))
            .thenReturn(Optional.empty());
    }
}
```

---

**技巧三：指定异常 Mock**

```bash
claude --print "生成测试时，必须包含以下异常场景的 Mock：

1. 网络超时场景
   when(paymentGateway.pay(any(), any(), any()))
     .thenThrow(new RuntimeException("Connection timeout"));

2. 数据库连接失败场景
   when(orderRepository.save(any()))
     .thenThrow(new DataAccessException("DB connection failed") {});

3. 外部服务限流场景
   when(paymentGateway.pay(any(), any(), any()))
     .thenThrow(new RateLimitException("Too many requests"));
```

---

### AI 测试常见 Mock 错误排查

| 错误现象 | 原因 | 解决方案 |
|---------|------|---------|
| NPE（空指针）| 依赖未 Mock | 检查所有依赖是否都有 @Mock |
| 断言失败 | Mock 返回值不对 | 检查 when().thenReturn() 的值 |
| 测试超时 | 实际调用了外部服务 | 确保所有外部调用都已 Mock |
| 测试全红 | 缺少依赖注入 | 检查 @InjectMocks 是否正确 |

---

## 📚 测试人员如何借助 AI 提升自己

### 学习路径建议

```
阶段一：会用（1-2 周）
├── 学会使用 1-2 个 AI 测试工具（Claude Code / Codex）
├── 能让 AI 生成基本测试用例
└── 会审核和调整 AI 生成的代码

阶段二：用好（1-2 月）
├── 掌握 Prompt 编写技巧（Mock 配置、边界值说明）
├── 能按测试策略定制 AI 输出
├── 学会 Claude Code Agent Teams 多 Agent 协作
├── 建立团队的测试 Prompt 模板库
└── 将 AI 融入日常工作流

阶段三：深入（持续）
├── 理解 AI 生成测试的局限性（Mock 配置是难点）
├── 补充 AI 做不到的测试（探索性测试、安全测试）
├── 参与 AI 测试工具的选型和落地
├── 关注 AI 测试领域最新发展（多 Agent、MCP）
└── 学习 MCP 生态，连接更多测试工具
```

### 测试人员需要提升的能力

| 能力 | 为什么重要 | 如何提升 |
|------|----------|---------|
| 业务理解 | AI 不懂你的业务逻辑 | 多和业务方、开发沟通 |
| 测试策略设计 | AI 不知道哪些要重点测 | 学习测试设计方法论 |
| Mock 配置 | AI 测试的最大难点 | 掌握 Mockito / Mockk 等框架 |
| Prompt 编写 | 好的 Prompt = 好的输出 | 多练习、多总结模板 |
| 多 Agent 协作 | Claude Code 新能力 | 学会 Agent Teams 分工 |
| MCP 工具连接 | 扩展 AI 能力边界 | 了解 MCP 生态工具 |

### 必学的测试方法论（配合 AI 使用）

1. **边界值分析**：让 AI 重点测试边界
2. **等价类划分**：告诉 AI 有效/无效分类
3. **决策表**：让 AI 按条件组合生成用例
4. **场景法**：设计业务流程，让 AI 覆盖路径
5. **风险分析**：告诉 AI 哪些是高风险区域

---

## ⚠️ AI 测试的局限与注意

### AI 做不到的事

| 场景 | AI 能做吗 | 建议 |
|------|----------|------|
| 理解公司业务规则 | ❌ | 人工补充业务测试 |
| Mock 配置（完整）| ⚠️ 部分 | 需要你显式说明所有依赖 |
| 探索性测试 | ❌ | 人工执行 |
| UI/UX 体验测试 | ❌ | 人工评审 |
| 安全性渗透测试 | ❌ | 安全团队介入 |
| 复杂多方系统交互 | ⚠️ 部分 | 人工设计 + AI 辅助 |

### 安全注意事项

```
1. 不要把真实用户数据发给 AI
   → 测试数据必须脱敏

2. API Key 等敏感信息不要给 AI
   → 使用环境变量注入

3. AI 生成的代码必须人工审核
   → 防止逻辑错误或安全漏洞

4. 定期清理无效测试用例
   → 保持测试套件的健康度

5. Mock 配置必须人工复核
   → AI 容易遗漏关键依赖的 Mock
```

---

## 🔗 相关资源

### 工具官网

| 工具 | 链接 | 说明 |
|------|------|------|
| **Claude Code** | https://docs.anthropic.com/claude-code | AI 编程工具，支持 Agent Teams |
| **Diffblue Cover** | https://www.diffblue.com/ | Java AI 测试生成，商业工具 |
| **Mokkato** | https://www.mokkato.com/ | 国产 Java AI 测试工具 |
| **EvoSuite** | https://www.evosuite.org/ | 开源 Java 测试生成 |
| **k6** | https://k6.io/ | 开源性能测试工具 |
| **Thunder Client** | VS Code 插件市场 | API 测试（Postman 替代）|
| **MCP 生态** | https://modelcontextprotocol.io/ | 连接数百种工具的协议 |

### 学习资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude-code/)
- [Diffblue 官方文档](https://docs.diffblue.com/)
- [k6 性能测试指南](https://k6.io/docs/)
- [JUnit 5 官方文档](https://junit.org/junit5/docs/current/user-guide/)
- [Mockito 官方文档](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
- [MCP 工具注册表](https://modelcontextprotocol.io/tools)

---

> 💡 **记住**：AI 是你的助手，不是替代者。AI 最大的难点是 **Mock 配置**，这是你需要重点把控的环节。把 AI 当成一个 24 小时工作的实习生——它能帮你快速产出，但 Mock 配置和最终质量还是你把关。
