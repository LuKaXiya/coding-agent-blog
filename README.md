# 🧠 CCG 模式：用 AI 协同提升编程效率

> 从需求分析到代码生成：后端程序员的 AI 协同开发实战

[![Stars](https://img.shields.io/github/stars/LuKaXiya/coding-agent-blog?style=social)](https://github.com/LuKaXiya/coding-agent-blog)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 目录

- [🎯 CCG 是什么？](#-ccg-是什么)
- [🤖 三剑客分工](#-三剑客分工)
- [⚡ 快速上手](#-快速上手)
- [📋 后端开发全流程实战](#-后端开发全流程实战)
- [💻 完整代码示例](#-完整代码示例)
- [🛡️ 安全与最佳实践](#-安全与最佳实践)
- [🚀 进阶技巧](#-进阶技巧)

---

## 🎯 CCG 是什么？

**CCG = Claude + Gemini + Codex**

三种 AI 工具协同，覆盖**从需求到代码**的全流程：

```
┌────────────────────────────────────────────────────────────────┐
│                 🧠 Opus（Claude Code）                          │
│  需求分析 → 技术方案 → 任务分解 → 代码审核 → 最终把关            │
└────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
    ┌─────────┐         ┌─────────┐         ┌─────────┐
    │  Gemini │         │ Claude  │         │  Codex  │
    │  (前端)  │         │  (后端)  │         │ (测试)  │
    └─────────┘         └─────────┘         └─────────┘
```

### 传统开发 vs CCG 模式

| 阶段 | 传统开发 | CCG 模式 |
|------|----------|----------|
| 需求分析 | 产品写 PRD，开发自己理解 | AI 辅助解析，自动生成结构化需求 |
| 技术方案 | 架构师设计，开发评审 | AI 生成多方案对比，开发决策 |
| 任务分解 | 技术 leader 拆解 | AI 自动 WBS 分解，产出甘特图 |
| 数据库设计 | DBA 或开发自己设计 | AI 辅助 ER 图生成、SQL 优化 |
| API 设计 | 手写 OpenAPI/YAPI | AI 生成完整 API 文档 + Mock |
| 代码编写 | 手工编码 | AI 生成 + 开发审核 |
| 测试用例 | 测试手写 | AI 自动生成测试用例 |
| 代码审查 | Code Review 人工看 | AI 辅助审查 + 安全扫描 |

---

## 🤖 三剑客分工

### 1. 🧠 Claude Opus — 指挥官兼后端主力

**定位**：理解需求、制定计划、架构设计、数据库建模、API 设计、代码审查

```bash
# 示例：让 Opus 分析需求并产出技术方案
claude --print --permission-mode bypassPermissions << 'EOF'
我需要为一个「用户积分系统」设计技术方案，需求如下：

## 需求描述
1. 用户通过签到、消费、活动获取积分
2. 积分可抵扣订单金额（100积分=1元）
3. 积分有有效期（默认1年）
4. 支持积分明细查询
5. 风控：同一用户每天最多获取积分上限

## 请产出以下内容

### 1. 数据库设计
- 表结构（SQL）
- ER 图描述
- 索引设计
- 分库分表建议（如需要）

### 2. API 接口设计
- 接口列表（RESTful）
- 请求/响应格式
- 错误码规范

### 3. 核心业务流程
- 积分获取流程（含风控校验）
- 积分扣减流程（幂等设计）
- 过期积分回收（定时任务）

### 4. 任务分解（WBS）
- 分解为 1-2 小时的最小可执行单元
- 标注依赖关系

### 5. 技术选型建议
- Redis 缓存策略
- MQ 解耦方案
- 事务一致性方案
EOF
```

### 2. ✨ Gemini Flash — 前端专家

**定位**：React/Vue 组件、页面布局、数据可视化、样式优化

```bash
# Gemini 生成前端组件
gemini "用 React + TailwindCSS 实现积分明细页面，包含：
- 日期范围筛选器
- 积分变动类型筛选（获取/消耗/过期）
- 表格展示（时间、类型、积分数量、备注）
- 分页组件
- 底部统计（当前积分、统计周期内总计）
- 深色模式适配"
```

### 3. ⚡ Codex — 效率助手

**定位**：脚本生成、测试用例、代码补全、快速重构

```bash
# Codex 生成测试用例
codex exec "为积分系统生成完整的测试用例：

1. 单元测试（Jest）：
   - PointService.addPoints() - 正常加分
   - PointService.addPoints() - 风控拦截
   - PointService.deductPoints() - 正常扣减
   - PointService.deductPoints() - 余额不足
   - PointService.deductPoints() - 幂等校验
   - PointService.expirePoints() - 过期处理

2. 集成测试：
   - 签到积分完整流程
   - 消费抵扣完整流程
   - 积分过期定时任务

3. 测试覆盖率要求：核心业务 > 90%"
```

---

## ⚡ 快速上手

### 环境准备

```bash
# 1. Claude Code（Opus 载体）
npm install -g @anthropic-ai/claude-code

# 2. 配置环境变量
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="..."

# 3. 验证安装
claude --version
```

### Workspace 隔离（关键！）

```
~/.openclaw/workspace/
├── MEMORY.md              ← Opus 的记忆（我）
├── projects/              ← 编程专用目录
│   ├── backend/           ← 后端代码（Opus/Codex）
│   ├── frontend/          ← 前端代码（Gemini）
│   ├── docs/              ← 技术文档
│   │   ├── prd/           ← 需求文档
│   │   ├── design/        ← 设计文档
│   │   └── api/           ← API 文档
│   └── tests/             ← 测试代码（Codex）
└── blog/                  ← 博客
```

> ⚠️ **重要**：每个 AI 只在自己的目录工作，不跨越边界，避免上下文污染。

---

## 📋 后端开发全流程实战

下面用一个**真实的订单系统**完整演示 CCG 模式的每个环节。

### 需求描述（产品原始需求）

```
我们需要开发一个「限时折扣订单系统」，需求如下：

1. 用户可以查看正在进行的限时折扣活动
2. 用户在折扣有效期内下单，享受折扣价格
3. 每个活动有库存限制，先到先得
4. 订单支付成功后扣减库存
5. 支持订单退款（退回库存）
6. 活动结束后未使用的库存自动释放
7. 需要记录完整的订单日志
```

---

### 第一步：Opus 分析需求，生成 PRD

```markdown
## 📋 PRD：限时折扣订单系统

### 一、业务规则

#### 1.1 折扣活动规则
| 规则 | 说明 |
|------|------|
| 活动时间 | 精确到秒，超时不可下单 |
| 折扣类型 | 固定金额折扣 / 百分比折扣 |
| 库存类型 | 总量库存（先到先得）|
| 每人限购 | 可配置（默认不限）|

#### 1.2 订单规则
| 规则 | 说明 |
|------|------|
| 下单流程 | 创建订单 → 锁定库存 → 支付 → 确认 |
| 支付超时 | 15分钟未支付自动取消，释放库存 |
| 退款规则 | 支付后7天内可退款，退回库存 |
| 幂等设计 | 同一商户订单号不可重复下单 |

#### 1.3 库存规则
| 场景 | 库存变化 |
|------|---------|
| 下单（锁定）| 总库存不变，锁定库存 +1 |
| 支付成功 | 锁定库存 -1，总库存 -1 |
| 取消/超时 | 锁定库存 -1 |
| 退款成功 | 总库存 +1 |
| 活动结束 | 未使用总库存释放 |

---

### 二、用户故事

#### US-1: 查看折扣活动
```
作为: 买家
我想要: 查看当前可用的限时折扣活动
以便: 了解有哪些优惠

验收标准:
- [ ] 显示活动名称、时间、折扣力度
- [ ] 显示剩余库存
- [ ] 显示已购数量（如已登录）
- [ ] 活动未开始显示倒计时
- [ ] 活动已结束不显示
```

#### US-2: 下单享受折扣
```
作为: 买家
我想要: 在折扣有效期内下单
以便: 享受折扣价格

验收标准:
- [ ] 折扣价格正确显示
- [ ] 库存不足时提示
- [ ] 订单创建后库存立即锁定
- [ ] 支付页面显示折扣信息
```

#### US-3: 退款退回库存
```
作为: 客服
我想要: 为用户办理退款
以便: 用户享受退款权益

验收标准:
- [ ] 退款后库存立即恢复
- [ ] 退款金额正确计算
- [ ] 记录退款日志
- [ ] 退款后不可二次退款
```

---

### 三、度量指标

| 指标 | 计算方式 | 目标 |
|------|---------|------|
| 折扣使用率 | 已售出 / 总库存 | > 80% |
| 下单转化率 | 支付订单 / 创建订单 | > 60% |
| 退款率 | 退款订单 / 支付订单 | < 5% |
| 超时取消率 | 取消订单 / 创建订单 | < 15% |
```

---

### 第二步：Opus 设计数据库

```sql
-- ============================================
-- 限时折扣订单系统 - 数据库设计
-- ============================================

-- 1. 折扣活动表
CREATE TABLE discount_activity (
    id            BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '活动ID',
    name          VARCHAR(100) NOT NULL COMMENT '活动名称',
    start_time    DATETIME NOT NULL COMMENT '开始时间',
    end_time      DATETIME NOT NULL COMMENT '结束时间',
    discount_type ENUM('FIXED', 'PERCENT') NOT NULL COMMENT '折扣类型',
    discount_value DECIMAL(10,2) NOT NULL COMMENT '折扣值',
    total_stock   INT NOT NULL COMMENT '总库存',
    stock_left    INT NOT NULL COMMENT '剩余库存',
    stock_locked  INT NOT NULL DEFAULT 0 COMMENT '锁定库存',
    max_per_user  INT DEFAULT 0 COMMENT '每人限购，0表示不限',
    status        ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'ENDED') DEFAULT 'DRAFT' COMMENT '状态',
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_time (start_time, end_time),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='折扣活动表';

-- 2. 折扣订单表
CREATE TABLE discount_order (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单ID',
    order_no        VARCHAR(64) UNIQUE NOT NULL COMMENT '订单号',
    merchant_order_no VARCHAR(64) UNIQUE NOT NULL COMMENT '商户订单号',
    user_id         BIGINT NOT NULL COMMENT '用户ID',
    activity_id     BIGINT NOT NULL COMMENT '活动ID',
    original_price  DECIMAL(10,2) NOT NULL COMMENT '原价',
    discount_amount DECIMAL(10,2) NOT NULL COMMENT '折扣金额',
    final_price     DECIMAL(10,2) NOT NULL COMMENT '最终价格',
    quantity        INT NOT NULL DEFAULT 1 COMMENT '数量',
    status          ENUM('CREATED', 'PAID', 'CANCELLED', 'REFUNDED') DEFAULT 'CREATED' COMMENT '订单状态',
    pay_deadline    DATETIME NOT NULL COMMENT '支付截止时间',
    paid_at         DATETIME COMMENT '支付时间',
    refunded_at     DATETIME COMMENT '退款时间',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_activity (activity_id),
    INDEX idx_status (status),
    INDEX idx_pay_deadline (pay_deadline),
    FOREIGN KEY (activity_id) REFERENCES discount_activity(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='折扣订单表';

-- 3. 库存变动日志表
CREATE TABLE stock_log (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    activity_id BIGINT NOT NULL,
    order_id    BIGINT COMMENT '关联订单，为空表示非订单变动',
    change_type ENUM('LOCK', 'UNLOCK', 'CONFIRM', 'REFUND', 'RELEASE') NOT NULL COMMENT '变动类型',
    quantity    INT NOT NULL COMMENT '变动数量',
    stock_before INT NOT NULL COMMENT '变动前库存',
    stock_after  INT NOT NULL COMMENT '变动后库存',
    reason      VARCHAR(255) COMMENT '变动原因',
    operator    VARCHAR(50) COMMENT '操作人（系统/用户/管理员）',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_activity (activity_id),
    INDEX idx_order (order_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='库存变动日志';

-- 4. 订单操作日志表
CREATE TABLE order_log (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id   BIGINT NOT NULL,
    action     VARCHAR(50) NOT NULL COMMENT '操作类型',
    before_status VARCHAR(20) COMMENT '操作前状态',
    after_status VARCHAR(20) COMMENT '操作后状态',
    detail     JSON COMMENT '操作详情',
    operator   VARCHAR(50) NOT NULL COMMENT '操作人',
    ip         VARCHAR(50) COMMENT 'IP地址',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单操作日志';
```

---

### 第三步：Opus 设计 API 接口

```yaml
# openapi: 3.0.3
info:
  title: 限时折扣订单系统 API
  version: 1.0.0

paths:
  # ============ 活动接口 ============
  /api/v1/discount/activities:
    get:
      summary: 获取折扣活动列表
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [ACTIVE, UPCOMING]
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: pageSize
          in: query
          schema:
            type: integer
            default: 20
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  data:
                    type: object
                    properties:
                      items:
                        type: array
                        items:
                          $ref: '#/components/schemas/Activity'
                      pagination:
                        $ref: '#/components/schemas/Pagination'

  /api/v1/discount/activities/{id}:
    get:
      summary: 获取活动详情
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  data:
                    $ref: '#/components/schemas/ActivityDetail'

  # ============ 订单接口 ============
  /api/v1/discount/orders:
    post:
      summary: 创建折扣订单
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [activityId, merchantOrderNo, quantity]
              properties:
                activityId:
                  type: integer
                  description: 活动ID
                merchantOrderNo:
                  type: string
                  description: 商户订单号（用于幂等）
                quantity:
                  type: integer
                  minimum: 1
                  description: 购买数量
      responses:
        200:
          description: 创建成功，返回订单信息
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  data:
                    $ref: '#/components/schemas/OrderCreated'

  /api/v1/discount/orders/{orderNo}:
    get:
      summary: 查询订单详情
      parameters:
        - name: orderNo
          in: path
          required: true
          schema:
            type: string
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  data:
                    $ref: '#/components/schemas/OrderDetail'

  /api/v1/discount/orders/{orderNo}/cancel:
    post:
      summary: 取消订单
      description: 支付超时或用户主动取消
      parameters:
        - name: orderNo
          in: path
          required: true
          schema:
            type: string
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  message: { type: string }

  /api/v1/discount/orders/{orderNo}/refund:
    post:
      summary: 退款
      description: 管理员或客服退款
      parameters:
        - name: orderNo
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                reason:
                  type: string
                  description: 退款原因
      responses:
        200:
          content:
            application/json:
              schema:
                type: object
                properties:
                  code: { type: integer, example: 0 }
                  message: { type: string }

components:
  schemas:
    Activity:
      type: object
      properties:
        id: { type: integer }
        name: { type: string }
        startTime: { type: string, format: date-time }
        endTime: { type: string, format: date-time }
        discountType: { type: string }
        discountValue: { type: number }
        originalPrice: { type: number }
        finalPrice: { type: number }
        stockLeft: { type: integer }
        status: { type: string }

    OrderCreated:
      type: object
      properties:
        orderNo: { type: string }
        finalPrice: { type: number }
        payDeadline: { type: string, format: date-time }
        qrCode: { type: string }

    Error:
      type: object
      properties:
        code: { type: integer }
        message: { type: string }
        details: { type: object }
```

---

### 第四步：Opus 生成核心代码

```java
// ==================== DiscountOrderService.java ====================
package com.example.discount.service;

@Service
@RequiredArgsConstructor
@Slf4j
public class DiscountOrderService {

    private final DiscountActivityRepository activityRepository;
    private final DiscountOrderRepository orderRepository;
    private final StockLogRepository stockLogRepository;
    private final OrderLogRepository orderLogRepository;
    private final RedisTemplate<String, String> redisTemplate;

    private static final String STOCK_LOCK_KEY = "discount:stock:lock:%d:%d";
    private static final int PAY_TIMEOUT_MINUTES = 15;

    /**
     * 创建折扣订单
     * 核心流程：校验活动 → 校验库存 → 锁定库存 → 创建订单 → 发送延迟消息
     */
    @Transactional(rollbackFor = Exception.class)
    public OrderCreatedDTO createOrder(Long userId, CreateOrderRequest request) {
        // 1. 幂等校验
        String idempotentKey = "order:idempotent:" + request.getMerchantOrderNo();
        if (Boolean.TRUE.equals(redisTemplate.hasKey(idempotentKey))) {
            throw new BusinessException("订单已存在，请勿重复提交");
        }

        // 2. 查询活动
        DiscountActivity activity = activityRepository
            .findById(request.getActivityId())
            .orElseThrow(() -> new BusinessException("活动不存在"));

        // 3. 校验活动时间
        validateActivityTime(activity);

        // 4. 校验用户购买数量
        validatePurchaseLimit(userId, activity, request.getQuantity());

        // 5. 锁定库存（Redis + 数据库双写）
        boolean locked = lockStock(activity.getId(), request.getQuantity());
        if (!locked) {
            throw new BusinessException("库存不足");
        }

        try {
            // 6. 创建订单
            DiscountOrder order = DiscountOrder.builder()
                .orderNo(generateOrderNo())
                .merchantOrderNo(request.getMerchantOrderNo())
                .userId(userId)
                .activityId(activity.getId())
                .originalPrice(activity.getOriginalPrice())
                .discountAmount(activity.getDiscountAmount())
                .finalPrice(activity.getFinalPrice().multiply(request.getQuantity()))
                .quantity(request.getQuantity())
                .status(OrderStatus.CREATED)
                .payDeadline(LocalDateTime.now().plusMinutes(PAY_TIMEOUT_MINUTES))
                .build();
            orderRepository.save(order);

            // 7. 记录库存变动日志
            saveStockLog(activity.getId(), order.getId(), StockChangeType.LOCK,
                request.getQuantity(), activity.getStockLeft(),
                activity.getStockLeft() - request.getQuantity(), "下单锁定");

            // 8. 记录订单日志
            saveOrderLog(order.getId(), "CREATE", null, OrderStatus.CREATED,
                request, String.valueOf(userId));

            // 9. 发送延迟消息（超时取消）
            sendDelayCancelMessage(order.getId(), PAY_TIMEOUT_MINUTES);

            // 10. 标记幂等
            redisTemplate.opsForValue().set(idempotentKey, String.valueOf(order.getId()),
                Duration.ofHours(2));

            return OrderCreatedDTO.builder()
                .orderNo(order.getOrderNo())
                .finalPrice(order.getFinalPrice())
                .payDeadline(order.getPayDeadline())
                .build();

        } catch (Exception e) {
            // 库存锁定失败，回滚
            unlockStock(activity.getId(), request.getQuantity());
            throw e;
        }
    }

    /**
     * 锁定库存
     * 使用 Redis 实现分布式锁，保证并发安全
     */
    private boolean lockStock(Long activityId, Integer quantity) {
        String lockKey = String.format(STOCK_LOCK_KEY, activityId, quantity);
        Boolean acquired = redisTemplate.opsForValue()
            .setIfAbsent(lockKey, "1", Duration.ofSeconds(5));

        if (!Boolean.TRUE.equals(acquired)) {
            return false;
        }

        try {
            // 数据库更新（乐观锁）
            int updated = activityRepository.decreaseStockWithOptimisticLock(
                activityId, quantity);
            if (updated == 0) {
                return false;
            }

            // 更新锁定库存
            activityRepository.incrementLockedStock(activityId, quantity);
            return true;
        } finally {
            redisTemplate.delete(lockKey);
        }
    }

    /**
     * 支付成功回调
     */
    @Transactional(rollbackFor = Exception.class)
    public void confirmPayment(String orderNo, String paymentNo) {
        DiscountOrder order = orderRepository.findByOrderNo(orderNo)
            .orElseThrow(() -> new BusinessException("订单不存在"));

        if (order.getStatus() != OrderStatus.CREATED) {
            throw new BusinessException("订单状态不允许支付");
        }

        // 更新库存（锁定 → 确认）
        DiscountActivity activity = order.getActivity();
        activityRepository.confirmStock(activity.getId(), order.getQuantity());

        // 更新订单状态
        order.setStatus(OrderStatus.PAID);
        order.setPaidAt(LocalDateTime.now());
        order.setPaymentNo(paymentNo);
        orderRepository.save(order);

        // 记录日志
        saveStockLog(activity.getId(), order.getId(), StockChangeType.CONFIRM,
            order.getQuantity(), activity.getStockLocked(),
            activity.getStockLocked() - order.getQuantity(), "支付成功");
        saveOrderLog(order.getId(), "PAY", OrderStatus.CREATED, OrderStatus.PAID,
            Map.of("paymentNo", paymentNo), "system");
    }

    /**
     * 退款
     */
    @Transactional(rollbackFor = Exception.class)
    public void refundOrder(String orderNo, String reason, String operator) {
        DiscountOrder order = orderRepository.findByOrderNo(orderNo)
            .orElseThrow(() -> new BusinessException("订单不存在"));

        if (order.getStatus() != OrderStatus.PAID) {
            throw new BusinessException("只有已支付订单可以退款");
        }

        // 恢复库存
        activityRepository.refundStock(order.getActivityId(), order.getQuantity());

        // 更新订单状态
        order.setStatus(OrderStatus.REFUNDED);
        order.setRefundedAt(LocalDateTime.now());
        orderRepository.save(order);

        // 记录日志
        DiscountActivity activity = order.getActivity();
        saveStockLog(activity.getId(), order.getId(), StockChangeType.REFUND,
            order.getQuantity(), activity.getStockLeft(),
            activity.getStockLeft() + order.getQuantity(), reason);
        saveOrderLog(order.getId(), "REFUND", OrderStatus.PAID, OrderStatus.REFUNDED,
            Map.of("reason", reason), operator);
    }

    private void validateActivityTime(DiscountActivity activity) {
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(activity.getStartTime())) {
            throw new BusinessException("活动尚未开始");
        }
        if (now.isAfter(activity.getEndTime())) {
            throw new BusinessException("活动已结束");
        }
        if (activity.getStatus() != ActivityStatus.ACTIVE) {
            throw new BusinessException("活动未激活");
        }
    }

    private void validatePurchaseLimit(Long userId, DiscountActivity activity, Integer quantity) {
        if (activity.getMaxPerUser() <= 0) {
            return; // 不限制
        }

        Integer userPurchased = orderRepository.countUserPurchased(
            userId, activity.getId(), OrderStatus.PAID);
        if (userPurchased + quantity > activity.getMaxPerUser()) {
            throw new BusinessException("购买数量超过限制");
        }
    }

    private String generateOrderNo() {
        return "DS" + System.currentTimeMillis() +
               String.format("%04d", new Random().nextInt(10000));
    }
}
```

---

### 第五步：Codex 生成测试用例

```java
// ==================== DiscountOrderServiceTest.java ====================
@ExtendWith(MockitoExtension.class)
class DiscountOrderServiceTest {

    @Mock
    private DiscountActivityRepository activityRepository;
    @Mock
    private DiscountOrderRepository orderRepository;
    @Mock
    private StockLogRepository stockLogRepository;
    @Mock
    private OrderLogRepository orderLogRepository;
    @Mock
    private RedisTemplate<String, String> redisTemplate;

    @InjectMocks
    private DiscountOrderService service;

    private DiscountActivity testActivity;
    private CreateOrderRequest testRequest;

    @BeforeEach
    void setUp() {
        testActivity = DiscountActivity.builder()
            .id(1L)
            .name("测试活动")
            .startTime(LocalDateTime.now().minusHours(1))
            .endTime(LocalDateTime.now().plusHours(1))
            .discountType(DiscountType.FIXED)
            .discountValue(BigDecimal.valueOf(10))
            .originalPrice(BigDecimal.valueOf(100))
            .finalPrice(BigDecimal.valueOf(90))
            .totalStock(100)
            .stockLeft(50)
            .stockLocked(0)
            .maxPerUser(2)
            .status(ActivityStatus.ACTIVE)
            .build();

        testRequest = CreateOrderRequest.builder()
            .activityId(1L)
            .merchantOrderNo("M20260322001")
            .quantity(1)
            .build();
    }

    // ============ 创建订单测试 ============

    @Test
    @DisplayName("正常创建订单成功")
    void createOrder_Success() {
        // given
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.of(testActivity));
        given(redisTemplate.opsForValue()).willReturn(mock(ValueOperations.class));
        given(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any(Duration.class)))
            .willReturn(true);
        given(activityRepository.decreaseStockWithOptimisticLock(eq(1L), eq(1)))
            .willReturn(1);
        given(orderRepository.save(any(DiscountOrder.class)))
            .willAnswer(inv -> {
                DiscountOrder order = inv.getArgument(0);
                order.setId(100L);
                return order;
            });

        // when
        OrderCreatedDTO result = service.createOrder(1L, testRequest);

        // then
        assertNotNull(result);
        assertNotNull(result.getOrderNo());
        assertEquals(BigDecimal.valueOf(90), result.getFinalPrice());
        verify(activityRepository).incrementLockedStock(eq(1L), eq(1));
        verify(stockLogRepository).save(any(StockLog.class));
        verify(orderLogRepository).save(any(OrderLog.class));
    }

    @Test
    @DisplayName("订单重复提交，抛出业务异常")
    void createOrder_Idempotent_ThrowsException() {
        // given
        given(redisTemplate.hasKey("order:idempotent:M20260322001")).willReturn(true);

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("订单已存在，请勿重复提交", ex.getMessage());
    }

    @Test
    @DisplayName("活动不存在，抛出业务异常")
    void createOrder_ActivityNotFound_ThrowsException() {
        // given
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.empty());

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("活动不存在", ex.getMessage());
    }

    @Test
    @DisplayName("活动未开始，抛出业务异常")
    void createOrder_ActivityNotStarted_ThrowsException() {
        // given
        testActivity.setStartTime(LocalDateTime.now().plusHours(1));
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.of(testActivity));

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("活动尚未开始", ex.getMessage());
    }

    @Test
    @DisplayName("活动已结束，抛出业务异常")
    void createOrder_ActivityEnded_ThrowsException() {
        // given
        testActivity.setEndTime(LocalDateTime.now().minusHours(1));
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.of(testActivity));

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("活动已结束", ex.getMessage());
    }

    @Test
    @DisplayName("库存不足，抛出业务异常")
    void createOrder_StockNotEnough_ThrowsException() {
        // given
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.of(testActivity));
        given(redisTemplate.opsForValue()).willReturn(mock(ValueOperations.class));
        given(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any(Duration.class)))
            .willReturn(true);
        given(activityRepository.decreaseStockWithOptimisticLock(eq(1L), eq(1)))
            .willReturn(0); // 库存不足

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("库存不足", ex.getMessage());
    }

    @Test
    @DisplayName("超出用户购买限制，抛出业务异常")
    void createOrder_ExceedPurchaseLimit_ThrowsException() {
        // given
        given(redisTemplate.hasKey(anyString())).willReturn(false);
        given(activityRepository.findById(1L)).willReturn(Optional.of(testActivity));
        // 用户已购买1件，限购2件，本次购买2件，应该超限
        given(orderRepository.countUserPurchased(eq(1L), eq(1L), eq(OrderStatus.PAID)))
            .willReturn(2);
        testRequest.setQuantity(2);

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.createOrder(1L, testRequest), BusinessException.class);
        assertEquals("购买数量超过限制", ex.getMessage());
    }

    // ============ 支付确认测试 ============

    @Test
    @DisplayName("支付成功，库存确认")
    void confirmPayment_Success() {
        // given
        DiscountOrder order = DiscountOrder.builder()
            .id(1L)
            .orderNo("DS123456")
            .status(OrderStatus.CREATED)
            .activity(testActivity)
            .quantity(2)
            .build();
        given(orderRepository.findByOrderNo("DS123456")).willReturn(Optional.of(order));

        // when
        service.confirmPayment("DS123456", "PAY123");

        // then
        assertEquals(OrderStatus.PAID, order.getStatus());
        assertEquals("PAY123", order.getPaymentNo());
        assertNotNull(order.getPaidAt());
        verify(activityRepository).confirmStock(eq(1L), eq(2));
    }

    @Test
    @DisplayName("订单状态非CREATED，不允许支付")
    void confirmPayment_InvalidStatus_ThrowsException() {
        // given
        DiscountOrder order = DiscountOrder.builder()
            .status(OrderStatus.PAID) // 已经是PAID
            .build();
        given(orderRepository.findByOrderNo(anyString())).willReturn(Optional.of(order));

        // when & then
        BusinessException ex = catchThrowableOfType(
            () -> service.confirmPayment("DS123456", "PAY123"),
            BusinessException.class);
        assertEquals("订单状态不允许支付", ex.getMessage());
    }

    // ============ 退款测试 ============

    @Test
    @DisplayName("退款成功，库存恢复")
    void refundOrder_Success() {
        // given
        DiscountOrder order = DiscountOrder.builder()
            .id(1L)
            .orderNo("DS123456")
            .status(OrderStatus.PAID)
            .activityId(1L)
            .quantity(2)
            .finalPrice(BigDecimal.valueOf(180))
            .build();
        given(orderRepository.findByOrderNo("DS123456")).willReturn(Optional.of(order));

        // when
        service.refundOrder("DS123456", "用户申请退款", "admin");

        // then
        assertEquals(OrderStatus.REFUNDED, order.getStatus());
        assertNotNull(order.getRefundedAt());
        verify(activityRepository).refundStock(eq(1L), eq(2));
        verify(stockLogRepository).save(any(StockLog.class));
    }

    @Test
    @DisplayName("未支付订单不能退款")
