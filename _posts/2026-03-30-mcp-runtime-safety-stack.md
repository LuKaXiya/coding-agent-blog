---
layout: post
title: "MCP Runtime Safety Stack：2025-06-18 规范升级后，AI 编程平台该怎么重做协议层"
date: 2026-03-30 10:00:00 +0800
category: MCP生态
tags: ["MCP", "OAuth", "AI编程", "协议设计", "安全", "工程实践"]
---

> 如果你还把 MCP 只理解成“让模型多一个工具接口”，那你看到的还是 2025 年上半年的 MCP。到了 2025-06-18 这一版规范，MCP 已经开始明显从 **工具接线协议** 走向 **agent runtime control plane**。

过去很多人讨论 MCP，重点都放在生态爆发：

- 有多少 server
- 有多少聚合器
- 哪些 AI 工具有原生支持
- 能不能把 GitHub、Playwright、数据库、Slack 全都接进来

这些当然重要，但它们回答的是 **“能连什么”**。

而 2025-06-18 这一轮规范升级，真正开始回答的是另一类更关键的问题：

- token 到底发给谁，怎么防止发错？
- client 怎么知道应该去哪一个 authorization server？
- tool 的输出到底是给模型“猜着用”，还是可以结构化消费？
- server 返回的是一大坨文本，还是可以按需暴露 resource link？
- 人类在敏感工具调用里，到底只是旁观，还是仍然握着最后一道闸？

这意味着，MCP 的竞争焦点开始变化了。

以前比的是“谁工具多”，以后越来越比的是：

- **谁的协议层更稳**
- **谁的 auth plane 更完整**
- **谁的 runtime safety 设计更成熟**
- **谁能把 structured output 接进 agent planner / verifier / review loop**

这篇文章我不打算再重复“MCP 是什么”的基础科普，而是只做一件事：

**把 MCP 2025-06-18 版本里最值得工程团队重视的变化拆开讲清楚，并翻译成 AI 编程平台、MCP Server、MCP Client 的实际设计动作。**

---

## 一、先说结论：这次升级的重心不是生态，而是控制面

如果把这轮升级浓缩成一句话，我的判断是：

> MCP 正在从“统一工具调用格式”，升级为“带安全边界、协商机制和结构化结果的 agent runtime 协议”。

为什么这么说？因为 2025-06-18 的关键变化并不是某个单独 feature，而是一组彼此配合的信号：

1. **移除 JSON-RPC batching**
2. **新增 structured tool output**
3. **把 MCP server 明确归类为 OAuth Resource Server**
4. **强制 client 实现 RFC 8707 Resource Indicators**
5. **新增 resource links**
6. **新增 elicitation**
7. **HTTP 后续请求要求显式带 `MCP-Protocol-Version`**
8. **authorization 与 security best practices 明显强化**

这些变化放在一起看，就会发现一个很清楚的方向：

### 过去的 MCP 主要解决
- 工具怎么列出来
- 参数 schema 怎么描述
- 调用结果怎么回

### 新一阶段的 MCP 开始解决
- 认证与授权的责任边界
- server / client / auth server 的角色分工
- 工具结果怎样更稳定地接入自动化链路
- 客户端如何在用户同意、版本协商、资源按需加载之间建立治理能力

也就是说，MCP 正在补的是 **runtime governance**，不是单纯再加几个连接器。

---

## 二、移除 batching：看起来像减法，其实是为稳定性做减噪

很多人第一眼看到 “remove support for JSON-RPC batching” 会觉得奇怪：

> 不是功能越多越好吗，为什么反而把 batching 去掉？

但如果你从 agent runtime 的视角看，这个变化非常合理。

### batching 在理论上的好处
- 一次 HTTP 往返里塞多个请求
- 看起来更省网络开销
- 某些场景下更像“批处理”

### batching 在 agent runtime 里的现实问题
- 请求与响应对齐复杂
- 出错时局部失败语义更难处理
- 审计日志和调用链更难解释
- 用户确认流程很容易变模糊
- 某些敏感工具调用会被“打包”后失去可见性

对于普通 API 系统，这些问题未必致命；但对 **会调工具、会执行副作用、可能带用户授权、需要审计和拦截的 agent 系统** 来说，batching 反而很容易把边界搞糊。

所以这次移除 batching，本质上是在做一件很工程化的事：

**减少协议表面的自由度，换取更清晰的执行语义、拦截点和审计点。**

对 MCP client / platform 的启发很直接：

- 不要把“多个工具动作一口气塞进去”当成优化方向
- 对敏感动作，更应该强调逐步显式执行
- 把 latency 优化留给连接复用、结果缓存、resource link、结构化输出，而不是模糊请求边界

这是一种很典型的 runtime maturity 信号：

> 不是追求看起来更强，而是优先让系统更可解释、更可治理。

---

## 三、structured output 才是这次最被低估的升级

如果说 auth 相关变化解决的是安全边界，那么 **structured tool output** 解决的就是 agent 编排里的“结果可消费性”。

过去很多 MCP tool result，本质上是这样：

- 返回一段 text
- 最好还能写得清楚一点
- 模型自己去读、自己去总结、自己去决定后续动作

这当然能工作，但它有一个根本问题：

**它更适合“聊天式消费”，不适合“系统式消费”。**

### 为什么 text-only tool output 不够
因为一旦你要把工具结果接进更复杂的链路，例如：

- planner 决策
- verifier 校验
- rule engine 判定
- workflow 分支选择
- 失败重试策略
- 审核 UI 展示

纯文本就会马上暴露出问题：

- 字段名不稳定
- 语义依赖提示词约定
- 很难做严格校验
- 不同工具返回风格差异极大
- 同一个 tool 版本升级后，文本格式一变，下游就崩

而 2025-06-18 允许工具：

- 定义 `outputSchema`
- 返回 `structuredContent`
- 同时为了兼容旧 client，再附带序列化后的文本

这背后的意义非常大。

### 1）tool result 首次真正进入“typed contract”阶段
过去我们只强调 input schema，现在 output 也开始被正式约束。

这意味着：

- client 可以验证返回值是否合法
- agent planner 可以更稳地根据字段做分支
- 上层 UI 可以更清楚地渲染结果
- 自动化 review / test / governance 逻辑能直接消费结构化字段

比如一个代码审查 tool，不再只是返回：

> 发现 3 个问题，其中一个是高风险 SQL 拼接……

而是可以返回：

```json
{
  "summary": "发现3个问题",
  "riskLevel": "high",
  "issues": [
    {"type": "sql-injection", "file": "UserDao.java", "severity": "high"},
    {"type": "missing-test", "file": "OrderServiceTest.java", "severity": "medium"}
  ]
}
```

这样上层系统才能真正做到：

- 高风险才要求人工批准
- medium risk 自动进 backlog
- low risk 只做注释提醒

### 2）多 agent 系统会因此变得更稳
多 agent 协作里，一个常见失败模式是：

- agent A 调工具拿到半结构化文本
- agent B 重新理解这段文本
- lead agent 再把 B 的理解整合一次

中间每一层都在丢失精度。

有了 structured output 后，更成熟的路径就变成：

- tools 输出结构化数据
- agent 只负责解释与决策
- verifier / UI / reviewer 直接消费结构化字段

也就是说：

**把“事实层”从“叙述层”里剥离出来。**

这对构建稳定的 review agent、test agent、ops agent 特别关键。

### 3）对博客里常说的“AI 工程化”来说，这是基础设施，不是小 feature
很多人讲 AI 工程化时，喜欢讲 workflow、multi-agent、自动修复，但如果工具输出还是一坨文本，工程化天花板其实很低。

所以我会把这次 structured output 视为一个非常实在的信号：

> MCP 开始认真为“typed agent workflow”铺地基了。

---

## 四、MCP server 被定义成 OAuth Resource Server：协议终于把 auth plane 写正了

这次升级里最关键、也最容易被工程团队低估的点之一，是：

**MCP server 被明确视为 OAuth Resource Server。**

这不是术语游戏，而是责任边界的重写。

过去很多实现默认的心智模型更像：

- client 去拿一个 token
- 只要 server 认这个 token 就行
- token 从哪里来、audience 是否匹配、auth server 怎么发现，很多实现都比较松散

这类松散做法在 demo 阶段还凑合，但在真实平台里会带来很多问题：

- token 发给了错误资源也可能被接受
- client 硬编码 auth server，迁移和多 server 兼容很差
- MCP server 变成“只会转发 token 的中间代理”
- 安全审计几乎说不清一条 token 到底应该用于哪里

而这次规范把几个关键动作连起来了：

1. MCP server 必须暴露 **Protected Resource Metadata**
2. metadata 里必须声明对应的 **authorization server**
3. client 要从 `401 + WWW-Authenticate` 进入发现流程
4. 再根据资源元数据与 auth server metadata 做 OAuth 流

这件事的本质是：

**让 client 不再靠猜，而是靠 server 自己公布其授权依赖。**

### 为什么这对 AI 编程平台特别重要
因为 AI 编程平台不是单个 API client，它们往往会连很多 MCP server：

- GitHub MCP
- issue tracker MCP
- internal docs MCP
- CI/CD MCP
- database MCP
- browser MCP

如果每个 server 的 auth 都靠手写配置、静态绑定、人工填 client id，那么平台一大就会崩：

- 配置漂移
- 上线成本高
- 用户难排错
- 权限边界难审计

而当 server 自己承担 resource metadata 责任，client 依规范发现 auth server，整个系统就开始有了 **control plane 的雏形**。

也就是说，MCP 不只是“工具协议”，而是在变成：

- 工具发现平面
- 授权发现平面
- 资源寻址平面
- 结果消费平面

这就是为什么我说它越来越像 agent runtime 的控制面，而不是纯粹的接线层。

---

## 五、Resource Indicators 是这次最硬核的安全加固之一

如果你只盯着“OAuth 支持增强”这几个字，很容易忽略真正关键的那条：

> MCP client **MUST** 实现 RFC 8707 Resource Indicators，并在授权请求和 token 请求里显式带 `resource` 参数。

这条要求非常重要，因为它直接针对一个现实风险：

**token audience 混淆。**

### 这个问题为什么危险
在一个多 server、多授权源的环境里，如果 client 只是“拿到 token 就用”，而没有明确告诉 auth server：

- 这个 token 是给哪一个 MCP server 的
- 目标资源的 canonical URI 是什么

那就可能出现：

- token 被错误地签发给不该使用的资源
- 恶意 server 诱导 client 获取对其他资源有效的 token
- client 拿着 token 去访问本不该访问的 server

这类问题在 agent 世界里尤其麻烦，因为 agent 会自动化地继续执行下游动作。一旦第一步 token 边界含糊，后面就可能形成连锁风险。

### Resource Indicators 的作用
它要求 client 在 OAuth 流里明确说清楚：

- 我要访问的是哪个 MCP server
- 这个 server 的 canonical URI 是什么
- token 应该面向这个 resource 签发

这相当于把“谁是目标资源”从隐含前提，变成显式协议字段。

### 工程上怎么理解最准确
可以把它理解成：

- `scope` 说的是“我要什么权限”
- `resource` 说的是“我要在哪个资源上用这些权限”

少了后者，前者就可能失去边界。

### 对 client 实现者的启发
如果你在做 MCP client 或 AI coding platform，这一条几乎可以直接转成 checklist：

1. 不要只保留 server 名称，要保留 **canonical URI**
2. 每个 OAuth flow 都要和具体 resource 绑定
3. token cache 不能只按 provider 存，还要按 **resource audience** 隔离
4. UI 上最好能让用户看见：这个授权是授给哪一个 server 的

这看似只是 auth 细节，实际上决定的是：

**你的平台到底是在做“能跑”的 MCP，还是在做“不会悄悄串权限边界”的 MCP。**

---

## 六、Security Best Practices 已经不再是“可参考附录”，而是平台设计说明书

这一版 MCP 安全文档里，我认为最值得工程团队警惕的，不是某一条单独条款，而是它明确告诉你：

> 真实风险已经不是“tool 调错了一个参数”，而是整个授权链、代理链、同意链可能被设计错。

里面特别值得关注的是两个主题：

### 1）Confused Deputy（混淆代理）
这个问题的本质是：

- MCP proxy server 作为中间层去连接第三方 API
- 它自己对外允许动态 client 注册
- 但对第三方 auth 可能只使用一个静态 client id
- 如果 consent 设计不严密，攻击者就可能借用既有 cookie / consent 状态，把本不该给自己的授权码骗走

这类问题在传统 OAuth 系统里已经很难缠，放到 MCP 这种“client 多、server 多、agent 自动化强”的环境里会更危险。

所以规范强调几件事：

- 每个 client 级别都要有独立 consent 记录
- consent 必须在进入第三方授权前完成
- redirect URI 必须精确匹配
- state 必须单次使用、短时有效、严格校验
- cookie 要有更强的安全属性

这其实是在提醒所有 MCP proxy / gateway / aggregator 实现者：

**你不是一个无害的转发器，你是一个安全边界。**

### 2）禁止 token passthrough
这一条我觉得尤其值得反复强调。

所谓 token passthrough，就是：

- client 把自己手里的 token 交给 MCP server
- server 不认真校验这个 token 是否真的是签给自己的
- 然后直接把 token 往下游 API 传

这听起来实现简单，甚至很多 demo 会这么干，但规范已经明确把它视为 anti-pattern。

因为它会带来四类问题：

- 绕过原本应该在 server 侧做的控制
- 审计链断裂，不知道是谁以谁的身份在调用
- trust boundary 被打穿
- 后续想补安全控制会越来越难

这件事对 AI 平台尤其关键，因为 agent 很容易形成“多层代理”结构：

- AI client → MCP gateway → downstream API → more downstream tools

如果第一层就接受 token passthrough，整条链的可解释性几乎直接报废。

所以对平台方来说，最稳的原则是：

> MCP server 只接受明确签发给自己的 token，只代表自己承担与下游资源的受控交互，不做模糊的 token 搬运工。

---

## 七、resource links：MCP 不再逼你把所有上下文一次性塞进模型

另一个很容易被忽略、但我非常看好的升级，是 **resource links**。

过去很多工具有个常见问题：

- 为了让模型“看见足够多信息”，tool 会把大量文本直接塞进 result
- 上下文一长，token 暴涨
- 真正有用的信息往往只占很小一部分
- client 很难做懒加载或分层展示

resource links 提供了一个更健康的思路：

- 工具先返回核心结论
- 同时附上可进一步抓取的资源 URI
- client 再根据需要去 fetch / subscribe / 展示

这背后其实是在推动一种更成熟的 agent I/O 设计：

### 旧模式
- tool = 一次性把所有东西吐出来

### 新模式
- tool = 先给结论 + 给资源指针
- client / agent = 按需继续展开

这有几个直接好处：

1. **更省 token**
2. **更适合 UI 分层展示**
3. **更适合 agent 在需要时逐步深入**
4. **更有利于把“摘要”和“原始证据”分开**

举个很实用的例子：

一个 PR review MCP tool 不需要直接把 200 行 diff 摘进结果里。它完全可以：

- `structuredContent` 里给出风险摘要
- `resource_link` 指向具体 diff、comment、test report、coverage artifact

这样模型看到的是：

- 先判断要不要深挖
- 需要时再点读资源

这会让 future agent workflow 更像“有记忆、有引用、有证据展开”的系统，而不是“一次性大段喂上下文”的系统。

---

## 八、elicitation：协议开始承认“agent 不是永远知道下一步”

2025-06-18 还加入了 **elicitation**，允许 server 在交互中向用户请求更多信息。

这个设计我觉得非常有意思，因为它等于把一个现实正式写进协议：

> tool / server 有时候并不能也不应该自己脑补缺失信息。

过去很多工具调用失败，本质上不是工具不行，而是：

- 缺少必要参数
- 用户意图仍有歧义
- server 知道自己需要补充信息，但协议层没有优雅表达方式

结果往往变成：

- 模型自己猜
- 工具报错
- 再回到会话里补一句问题
- 整个流程断裂

elicitation 让这件事更“协议内化”了。

对 agent 系统来说，这很重要，因为它支持一种更成熟的交互模式：

- 能自动化时自动化
- 缺关键输入时显式向用户索取
- 不再把所有不确定性都压给模型瞎猜

如果你在做企业内部 MCP server，这个能力尤其值得关注。因为很多内网工具真正需要的不是“再强一点的模型”，而是：

**在关键缺口处，优雅地把用户重新拉回决策回路。**

---

## 九、Human-in-the-loop 仍然是 MCP 的底线，不是过渡方案

有些团队在谈 agent 自动化时，总想把 human-in-the-loop 视为一种“以后会消失的保守配置”。

但从 tools 规范和 security 文档的方向看，MCP 反而在更明确地强调：

- 敏感工具调用应可见
- 用户应该能理解当前暴露了哪些工具
- 有副作用的动作应允许拒绝
- 工具输入最好在调用前可审视

这说明一个很关键的现实：

> 在 AI tool use 场景里，真正成熟的系统不是“完全不需要人”，而是“知道哪些地方必须保留人的最终 veto 权”。

尤其是下面这些动作：

- 写入外部系统
- 修改生产配置
- 发消息 / 发 PR / 发工单
- 触发删除、转账、审批、发布
- 访问高敏感数据

如果你的 MCP client/platform 没有把这些动作设计成清晰可见、可中断、可审计，那你不是“更自动化”，你只是把风险藏起来了。

所以我很赞同规范的取向：

**Human-in-the-loop 不是 MCP 还不成熟的补丁，而是 runtime safety 的组成部分。**

---

## 十、把这些变化翻译成工程动作：平台方到底该怎么改

说到这里，最重要的问题就来了：

**如果你在做 AI 编程平台、MCP client、MCP server，2025-06-18 之后最值得落地的动作是什么？**

我给一个尽量实用的 checklist。

### 对 MCP Client / AI 编程平台

#### 1. 重做授权缓存模型
不要只按 provider 缓存 token，至少要按：

- authorization server
- resource URI
- scope / capability
- user / workspace / environment

做分层隔离。

#### 2. 把 resource server discovery 做成一等公民
不是手填一个 token endpoint 就算完。要支持：

- 401 中的 `WWW-Authenticate`
- Protected Resource Metadata 拉取
- Authorization Server Metadata 拉取
- 失败路径的可解释报错

#### 3. UI 上显式展示授权目标
用户应该知道：

- 正在授权哪个 MCP server
- 这个 server 的 canonical resource URI 是什么
- 请求了哪些 scope
- 哪些工具可能产生副作用

#### 4. 支持 structuredContent 的 typed pipeline
把结构化结果接进：

- planner
- verifier
- UI renderer
- 审计日志
- policy engine

别再把所有 tool output 都当纯文本处理。

#### 5. 对敏感工具调用做显式确认和日志
特别是 write / execute / external side effect 类操作。

### 对 MCP Server

#### 1. 不要做 token passthrough
严格只接受发给自己的 token。

#### 2. 把 Protected Resource Metadata 做完整
别让 client 靠文档猜你的 auth server。

#### 3. 为 tool output 提供 outputSchema
尤其是那些会被下游自动化消费的 tool。

#### 4. 把大结果拆成 structured summary + resource links
让 client 能按需展开，而不是一次性把上下文塞爆。

#### 5. 明确标注哪些工具有副作用
方便 client 做 HITL 保护。

### 对团队内部的 MCP Gateway / Aggregator

#### 1. 把自己当安全边界，不是透明管道
#### 2. 每个上游 client 都应有独立 consent 与审计
#### 3. redirect URI、state、cookie、session 都要按 OAuth 正规军标准来
#### 4. 不要为了“接得快”牺牲资源边界与审计边界

---

## 十一、我对未来 6~12 个月的判断

如果沿着这版规范继续演进，我对 MCP 的判断是：

### 1）生态竞争会逐渐让位给控制面竞争
前一阶段大家在比：

- 谁接了更多 server
- 谁支持更多工具
- 谁插件市场更热闹

下一阶段更关键的是：

- 谁的 auth plane 更稳
- 谁的 structured workflow 更强
- 谁的 runtime safety 更成熟
- 谁的 observability / audit / policy 更完整

### 2）typed workflow 会成为 AI 编程平台的分水岭
真正能把 agent 做深的平台，不会只让模型读大段文本，而会让：

- tool 有输入 schema
- result 有 output schema
- policy 有可判定字段
- UI 有可渲染结构
- verifier 有可复核证据

MCP 现在已经开始给这个方向提供底层协议支撑。

### 3）resource link + structured output 会改变上下文管理方式
未来更成熟的 agent 不是把所有材料一次塞进 prompt，而是：

- 先拿结构化摘要
- 再按需拉资源
- 最后把关键证据拼进有限上下文

这会明显影响 token 成本、推理稳定性与 UI 交互方式。

### 4）MCP 平台会越来越像“受治理的操作系统接口”
也就是说，MCP 的未来不只是“外设总线”，而是带着：

- 身份
- 权限
- 版本协商
- 结构化 I/O
- 资源寻址
- HITL
- 审计

的一层 agent runtime substrate。

---

## 十二、结语：别再只问“MCP 能接什么”，要开始问“MCP 如何承担边界”

如果你今天还停留在：

- “MCP 有多少工具？”
- “能不能接数据库？”
- “能不能接 GitHub？”

那你其实只看到了最外层。

真正决定一个 AI 编程平台能不能进到生产深水区的，不再只是它能不能“调到工具”，而是它能不能回答这些问题：

- token 边界清不清楚？
- 用户同意链是否真实有效？
- 敏感动作能不能被看见和拒绝？
- tool output 能不能稳定进入自动化流水线？
- 上下文是一次性灌爆，还是可按需拉取？
- 协议升级后，client 和 server 能不能继续稳定协商？

从这个角度看，MCP 2025-06-18 的意义非常明确：

**它把 MCP 从“会调工具的接口规范”，往“能承受真实 agent 系统复杂度的 runtime 协议”推了一大步。**

而对 AI 编程平台来说，下一轮真正的分水岭，也很可能就在这里：

不是谁先接 500 个工具，
而是谁先把 **安全、结构、协商、证据、人工闸门** 这些底层能力做完整。

这才是 MCP 进入下一个阶段后，最值得认真投入的地方。
