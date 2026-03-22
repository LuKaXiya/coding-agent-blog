# 🧪 AI 测试工具大全：让测试工程师效率翻倍的实战指南

> 从单元测试到自动化测试：用 AI 工具链打造高效测试体系

[![Testing](https://img.shields.io/badge/AI-Testing-blue?style=social)](https://github.com/LuKaXiya/coding-agent-blog)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 目录

- [🤔 为什么测试需要 AI？](#-为什么测试需要-ai)
- [🧬 AI 测试工具全景图](#-ai-测试工具全景图)
- [⚡ 快速上手：Codex 生成测试](#-快速上手codex-生成测试)
- [💻 Java/JUnit 深度实战](#-java-junit-深度实战)
- [🔗 API 接口测试 AI 化](#-api-接口测试-ai-化)
- [📊 性能测试 AI 辅助](#-性能测试-ai-辅助)
- [🔄 持续集成与自动化](#-持续集成与自动化)
- [🎯 测试用例设计prompt库](#-测试用例设计prompt库)
- [⚠️ AI 测试的局限与注意](#-ai-测试的局限与注意)

---

## 🤔 为什么测试需要 AI？

### 传统测试 vs AI 测试

| 环节 | 传统方式 | AI 辅助 |
|------|----------|---------|
| 写单元测试 | 手工编写，速度慢 | AI 自动生成覆盖率高的测试 |
| 构造测试数据 | 手动准备，容易遗漏 | AI 智能生成多样化边界数据 |
| 接口测试 | Postman 手动点 | AI 自动生成用例 + Mock |
| 回归测试 | 全量回归耗时 | AI 智能识别变更影响范围 |
| 性能测试 | JMeter 手工配 | AI 生成场景 + 分析报告 |
| 测试报告 | 手工整理 | AI 自动生成 + 问题定位 |

### AI 测试的价值

```
传统：1人1天 → 写50个用例
AI辅助：1人1天 → 生成200个用例 + AI审查 → 人工审核50个核心用例
效率提升：4-5倍
```

---

## 🧬 AI 测试工具全景图

### 按测试类型分类

```
┌─────────────────────────────────────────────────────────────┐
│                      AI 测试工具生态                           │
├─────────────┬─────────────┬─────────────┬───────────────────┤
│  单元测试    │  接口测试    │  性能测试    │   测试管理        │
├─────────────┼─────────────┼─────────────┼───────────────────┤
│ Codex       │ Codex       │ k6 + AI    │ TestRail AI      │
│ Diffblue    │ Thunder Client│ AI 分析    │ Qase.io         │
│ Mokkato     │ Postman AI  │ JMeter AI  │ Zephyr AI        │
│ EvoSuite    │ Apifox AI   │ Grafana AI │                  │
│            │             │            │                   │
└─────────────┴─────────────┴─────────────┴───────────────────┘
```

### 工具推荐矩阵

| 场景 | 推荐工具 | 语言 | 收费 |
|------|---------|------|------|
| Java 单元测试 | **Diffblue / EvoSuite / Codex** | Java | Diffblue 商业/EvoSuite免费 |
| Python 测试 | **Codex /pytest-aio** | Python | 免费 |
| API 测试 | **Thunder Client + Codex** | 通用 | 免费 |
| 前端测试 | **Playwright + Codex** | TS/JS | 免费 |
| 性能测试 | **k6 + AI 分析** | JS | 免费 |
| 测试数据 | **Codex 数据生成器** | 通用 | 免费 |

---

## ⚡ 快速上手：Codex 生成测试

### 1. 安装配置

```bash
# 安装
pip install openai

# 环境变量
export OPENAI_API_KEY="sk-..."

# 快速生成测试（单文件）
codex exec "为这个文件里的所有public方法生成单元测试"
```

### 2. 基础用法

```bash
# 为 Java Service 生成测试
codex exec "为 DiscountOrderService.java 生成完整的单元测试，
要求：
1. 使用 JUnit 5 + Mockito
2. 每个 public 方法至少3个测试用例（正常/异常/边界）
3. 覆盖所有分支路径
4. 使用 @ParameterizedTest 测试多边界值
5. 测试覆盖率目标：核心方法 > 95%"

# 为 Python 函数生成测试
codex exec "为 calculate_discount() 函数生成 pytest 测试用例，
覆盖：
1. 正常折扣计算
2. 折扣超过100%异常
3. 折扣为负数异常
4. 金额为0
5. 金额为负数异常
6. null输入处理"
```

### 3. 测试数据生成

```bash
# Codex 生成多样化测试数据
codex exec "为用户注册接口生成20条测试数据：
- 正常数据：5条
- 手机号格式错误：3条
- 邮箱格式错误：3条
- 密码强度不足：3条（短密码、无数字、无特殊字符）
- 用户名长度边界：3条（1字符、50字符、51字符）
- 已存在用户：2条
- SQL注入尝试：1条

输出格式：JSON数组，每条包含 name, phone, email, password, expected_status"
```

---

## 💻 Java/JUnit 深度实战

### 场景：电商订单服务测试

#### 被测代码

```java
// OrderService.java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final StockService stockService;
    private final PaymentService paymentService;

    /**
     * 创建订单
     * @throws BusinessException 业务异常
     */
    @Transactional
    public Order createOrder(Long userId, CreateOrderRequest request) {
        // 1. 参数校验
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new BusinessException("ORDER_001", "订单商品不能为空");
        }

        // 2. 查询商品
        List<Product> products = productRepository.findByIds(
            request.getItems().stream()
                .map(OrderItem::getProductId)
                .collect(Collectors.toList())
        );

        if (products.size() != request.getItems().size()) {
            throw new BusinessException("ORDER_002", "部分商品不存在");
        }

        // 3. 校验库存并扣减
        for (OrderItem item : request.getItems()) {
            Product product = products.stream()
                .filter(p -> p.getId().equals(item.getProductId()))
                .findFirst()
                .orElseThrow();

            if (product.getStock() < item.getQuantity()) {
                throw new BusinessException("ORDER_003",
                    String.format("商品[%s]库存不足", product.getName()));
            }
        }

        // 4. 计算总价
        BigDecimal totalAmount = calculateTotal(products, request.getItems());

        // 5. 创建订单
        Order order = Order.builder()
            .orderNo(generateOrderNo())
            .userId(userId)
            .status(OrderStatus.CREATED)
            .totalAmount(totalAmount)
            .items(request.getItems())
            .build();

        return orderRepository.save(order);
    }

    /**
     * 支付订单
     */
    @Transactional
    public void payOrder(String orderNo, PayMethod method, String paymentData) {
        Order order = orderRepository.findByOrderNo(orderNo)
            .orElseThrow(() -> new BusinessException("ORDER_404", "订单不存在"));

        if (order.getStatus() != OrderStatus.CREATED) {
            throw new BusinessException("ORDER_401", "订单状态不允许支付");
        }

        if (order.getCreatedAt().plusMinutes(30).isBefore(LocalDateTime.now())) {
            throw new BusinessException("ORDER_402", "订单已超时");
        }

        // 调用支付服务
        PaymentResult result = paymentService.pay(order, method, paymentData);

        if (result.isSuccess()) {
            order.setStatus(OrderStatus.PAID);
            order.setPaidAt(LocalDateTime.now());
            order.setPaymentNo(result.getPaymentNo());
            orderRepository.save(order);
        } else {
            throw new BusinessException("ORDER_403", "支付失败：" + result.getMessage());
        }
    }

    /**
     * 取消订单
     */
    @Transactional
    public void cancelOrder(String orderNo, String reason) {
        Order order = orderRepository.findByOrderNo(orderNo)
            .orElseThrow(() -> new BusinessException("ORDER_404", "订单不存在"));

        if (order.getStatus() != OrderStatus.CREATED) {
            throw new BusinessException("ORDER_405", "只有待支付订单可以取消");
        }

        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelReason(reason);
        orderRepository.save(order);
    }
}
```

#### AI 生成的完整测试

```java
// OrderServiceTest.java
@ExtendWith(MockitoExtension.class)
@DisplayName("订单服务测试")
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private ProductRepository productRepository;
    @Mock
    private StockService stockService;
    @Mock
    private PaymentService paymentService;

    @InjectMocks
    private OrderService orderService;

    // ============ createOrder 测试 ============

    @Nested
    @DisplayName("创建订单测试")
    class CreateOrderTests {

        @Test
        @DisplayName("商品列表为空，抛出 ORDER_001 异常")
        void createOrder_WithEmptyItems_ThrowsException() {
            // given
            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(Collections.emptyList())
                .build();

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.createOrder(1L, request));

            assertEquals("ORDER_001", ex.getCode());
            assertEquals("订单商品不能为空", ex.getMessage());
        }

        @Test
        @DisplayName("商品列表为null，抛出 ORDER_001 异常")
        void createOrder_WithNullItems_ThrowsException() {
            // given
            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(null)
                .build();

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.createOrder(1L, request));

            assertEquals("ORDER_001", ex.getCode());
        }

        @Test
        @DisplayName("商品不存在，抛出 ORDER_002 异常")
        void createOrder_WithNonExistentProduct_ThrowsException() {
            // given
            Product existingProduct = Product.builder()
                .id(1L)
                .name("商品A")
                .price(BigDecimal.valueOf(100))
                .stock(50)
                .build();

            OrderItem item = OrderItem.builder()
                .productId(1L)
                .quantity(1)
                .build();
            OrderItem nonExistentItem = OrderItem.builder()
                .productId(999L) // 不存在
                .quantity(1)
                .build();

            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(Arrays.asList(item, nonExistentItem))
                .build();

            given(productRepository.findByIds(anyList()))
                .willReturn(List.of(existingProduct)); // 只返回1个

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.createOrder(1L, request));

            assertEquals("ORDER_002", ex.getCode());
            assertTrue(ex.getMessage().contains("部分商品不存在"));
        }

        @Test
        @DisplayName("商品库存不足，抛出 ORDER_003 异常")
        void createOrder_WithInsufficientStock_ThrowsException() {
            // given
            Product product = Product.builder()
                .id(1L)
                .name("商品A")
                .price(BigDecimal.valueOf(100))
                .stock(5) // 库存5件
                .build();

            OrderItem item = OrderItem.builder()
                .productId(1L)
                .quantity(10) // 购买10件
                .build();

            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(List.of(item))
                .build();

            given(productRepository.findByIds(anyList()))
                .willReturn(List.of(product));

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.createOrder(1L, request));

            assertEquals("ORDER_003", ex.getCode());
            assertTrue(ex.getMessage().contains("库存不足"));
        }

        @Test
        @DisplayName("多商品订单，计算总价正确")
        void createOrder_WithMultipleItems_CalculatesTotalCorrectly() {
            // given
            Product productA = Product.builder()
                .id(1L).name("商品A").price(BigDecimal.valueOf(100)).stock(100).build();
            Product productB = Product.builder()
                .id(2L).name("商品B").price(BigDecimal.valueOf(50)).stock(100).build();

            List<OrderItem> items = Arrays.asList(
                OrderItem.builder().productId(1L).quantity(2).build(),  // 2 * 100 = 200
                OrderItem.builder().productId(2L).quantity(4).build()   // 4 * 50 = 200
            ); // 总计 = 400

            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(items)
                .build();

            given(productRepository.findByIds(anyList()))
                .willReturn(Arrays.asList(productA, productB));
            given(orderRepository.save(any(Order.class)))
                .willAnswer(inv -> {
                    Order o = inv.getArgument(0);
                    o.setId(1L);
                    return o;
                });

            // when
            Order result = orderService.createOrder(1L, request);

            // then
            assertNotNull(result);
            assertEquals(BigDecimal.valueOf(400), result.getTotalAmount());
            assertEquals(OrderStatus.CREATED, result.getStatus());
            assertEquals(1L, result.getUserId());
            assertNotNull(result.getOrderNo());
            assertTrue(result.getOrderNo().startsWith("ORD"));
        }

        @ParameterizedTest
        @DisplayName("边界值测试：单商品单数量")
        @CsvSource({
            "1, 1, 100.00",
            "1, 100, 10000.00",
            "1, 0, 0.00"
        })
        void createOrder_BoundaryValues(long productId, int qty, BigDecimal expected) {
            // given
            Product product = Product.builder()
                .id(productId)
                .name("商品")
                .price(BigDecimal.valueOf(100))
                .stock(1000)
                .build();

            OrderItem item = OrderItem.builder()
                .productId(productId)
                .quantity(qty)
                .build();

            CreateOrderRequest request = CreateOrderRequest.builder()
                .items(List.of(item))
                .build();

            given(productRepository.findByIds(anyList())).willReturn(List.of(product));
            given(orderRepository.save(any())).willAnswer(inv -> inv.getArgument(0));

            // when
            Order result = orderService.createOrder(1L, request);

            // then
            assertEquals(expected, result.getTotalAmount());
        }
    }

    // ============ payOrder 测试 ============

    @Nested
    @DisplayName("支付订单测试")
    class PayOrderTests {

        @Test
        @DisplayName("订单不存在，抛出 ORDER_404")
        void payOrder_OrderNotFound_ThrowsException() {
            // given
            given(orderRepository.findByOrderNo("NOT_EXIST"))
                .willReturn(Optional.empty());

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.payOrder("NOT_EXIST", PayMethod.WECHAT, "{}"));

            assertEquals("ORDER_404", ex.getCode());
        }

        @Test
        @DisplayName("订单状态非CREATED，抛出 ORDER_401")
        void payOrder_InvalidStatus_ThrowsException() {
            // given
            Order order = Order.builder()
                .orderNo("ORD123")
                .status(OrderStatus.PAID) // 已支付
                .createdAt(LocalDateTime.now())
                .build();
            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.payOrder("ORD123", PayMethod.WECHAT, "{}"));

            assertEquals("ORDER_401", ex.getCode());
        }

        @Test
        @DisplayName("订单超时30分钟，抛出 ORDER_402")
        void payOrder_OrderTimeout_ThrowsException() {
            // given
            Order order = Order.builder()
                .orderNo("ORD123")
                .status(OrderStatus.CREATED)
                .createdAt(LocalDateTime.now().minusMinutes(31)) // 31分钟前
                .build();
            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.payOrder("ORD123", PayMethod.WECHAT, "{}"));

            assertEquals("ORDER_402", ex.getCode());
            assertTrue(ex.getMessage().contains("超时"));
        }

        @Test
        @DisplayName("支付成功，订单状态更新为PAID")
        void payOrder_Success_UpdatesStatusToPaid() {
            // given
            Order order = Order.builder()
                .id(1L)
                .orderNo("ORD123")
                .status(OrderStatus.CREATED)
                .totalAmount(BigDecimal.valueOf(100))
                .createdAt(LocalDateTime.now())
                .build();

            PaymentResult successResult = PaymentResult.builder()
                .success(true)
                .paymentNo("PAY123")
                .build();

            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));
            given(paymentService.pay(any(), eq(PayMethod.WECHAT), eq("{}")))
                .willReturn(successResult);

            // when
            orderService.payOrder("ORD123", PayMethod.WECHAT, "{}");

            // then
            assertEquals(OrderStatus.PAID, order.getStatus());
            assertNotNull(order.getPaidAt());
            assertEquals("PAY123", order.getPaymentNo());
            verify(orderRepository).save(order);
        }

        @Test
        @DisplayName("支付失败，抛出 ORDER_403")
        void payOrder_PaymentFailed_ThrowsException() {
            // given
            Order order = Order.builder()
                .orderNo("ORD123")
                .status(OrderStatus.CREATED)
                .createdAt(LocalDateTime.now())
                .build();

            PaymentResult failedResult = PaymentResult.builder()
                .success(false)
                .message("余额不足")
                .build();

            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));
            given(paymentService.pay(any(), any(), any())).willReturn(failedResult);

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.payOrder("ORD123", PayMethod.WECHAT, "{}"));

            assertEquals("ORDER_403", ex.getCode());
            assertTrue(ex.getMessage().contains("余额不足"));
        }
    }

    // ============ cancelOrder 测试 ============

    @Nested
    @DisplayName("取消订单测试")
    class CancelOrderTests {

        @Test
        @DisplayName("待支付订单取消成功")
        void cancelOrder_Success() {
            // given
            Order order = Order.builder()
                .orderNo("ORD123")
                .status(OrderStatus.CREATED)
                .build();
            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));

            // when
            orderService.cancelOrder("ORD123", "用户主动取消");

            // then
            assertEquals(OrderStatus.CANCELLED, order.getStatus());
            assertEquals("用户主动取消", order.getCancelReason());
            verify(orderRepository).save(order);
        }

        @Test
        @DisplayName("已支付订单不能取消，抛出 ORDER_405")
        void cancelOrder_PaidOrder_ThrowsException() {
            // given
            Order order = Order.builder()
                .orderNo("ORD123")
                .status(OrderStatus.PAID) // 已支付
                .build();
            given(orderRepository.findByOrderNo("ORD123")).willReturn(Optional.of(order));

            // when & then
            BusinessException ex = assertThrows(BusinessException.class,
                () -> orderService.cancelOrder("ORD123", "用户要求"));

            assertEquals("ORDER_405", ex.getCode());
        }
    }
}
```

---

## 🔗 API 接口测试 AI 化

### Thunder Client + Codex 工作流

Thunder Client 是 VS Code 插件，配合 Codex 可以实现：

```
1. 手动请求 → 2. Codex 分析响应 → 3. 自动生成测试用例 → 4. 批量回归
```

### Codex 生成 API 测试用例

```bash
# 生成完整的接口测试集
codex exec "基于以下 OpenAPI 文档，生成 Thunder Client 测试集合：

## 接口列表
POST /api/v1/orders - 创建订单
GET /api/v1/orders/{orderNo} - 查询订单
POST /api/v1/orders/{orderNo}/pay - 支付订单
POST /api/v1/orders/{orderNo}/cancel - 取消订单

## 生成的测试要求
1. 每个接口生成5-10个测试用例
2. 覆盖：正常、参数错误、权限不足、并发、边界值
3. 添加前置条件（登录获取token）
4. 添加响应断言（status code、关键字段）
5. 输出 Thunder Client Collection JSON 格式
6. 生成 Newman CLI 命令（可集成CI/CD）
"
```

### 生成的测试用例示例

```json
{
  "info": {
    "name": "订单系统 API 测试集",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "创建订单 - 正常流程",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('状态码为200', function() {",
              "  pm.response.to.have.status(200);",
              "});",
              "pm.test('返回订单号', function() {",
              "  const jsonData = pm.response.json();",
              "  pm.expect(jsonData.data.orderNo).to.be.a('string');",
              "  pm.expect(jsonData.data.orderNo).to.match(/^ORD\\d+$/);",
              "});",
              "pm.test('金额计算正确', function() {",
              "  const jsonData = pm.response.json();",
              "  pm.expect(jsonData.data.totalAmount).to.greaterThan(0);",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "{{token}}" },
          { "key": "Content-Type", "value": "application/json" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"items\": [\n    {\"productId\": 1, \"quantity\": 2}\n  ]\n}"
        },
        "url": "{{baseUrl}}/api/v1/orders"
      }
    },
    {
      "name": "创建订单 - 商品不存在",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('状态码为400', function() {",
              "  pm.response.to.have.status(400);",
              "});",
              "pm.test('错误码ORDER_002', function() {",
              "  const jsonData = pm.response.json();",
              "  pm.expect(jsonData.code).to.eql('ORDER_002');",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "{{token}}" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"items\": [\n    {\"productId\": 99999, \"quantity\": 1}\n  ]\n}"
        },
        "url": "{{baseUrl}}/api/v1/orders"
      }
    },
    {
      "name": "创建订单 - 库存不足",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('状态码为400', function() {",
              "  pm.response.to.have.status(400);",
              "});",
              "pm.test('错误码ORDER_003', function() {",
              "  const jsonData = pm.response.json();",
              "  pm.expect(jsonData.code).to.eql('ORDER_003');",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "{{token}}" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"items\": [\n    {\"productId\": 1, \"quantity\": 99999}\n  ]\n}"
        },
        "url": "{{baseUrl}}/api/v1/orders"
      }
    },
    {
      "name": "创建订单 - 未登录(401)",
      "request": {
        "method": "POST",
        "header": [],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"items\": [\n    {\"productId\": 1, \"quantity\": 1}\n  ]\n}"
        },
        "url": "{{baseUrl}}/api/v1/orders"
      }
    },
    {
      "name": "支付订单 - 订单不存在",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('状态码为404', function() {",
              "  pm.response.to.have.status(404);",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "header": [
          { "key": "Authorization", "value": "{{token}}" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"method\": \"WECHAT\",\n  \"paymentData\": \"{}\"\n}"
        },
        "url": "{{baseUrl}}/api/v1/orders/NOT_EXIST/pay"
      }
    }
  ]
}
```

### Newman CLI 集成 CI/CD

```yaml
# .github/workflows/api-test.yml
name: API Regression Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Newman
        run: npm install -g newman

      - name: Run API Tests
        run: |
          newman run tests/orders-api.json \
            --environment tests/env.json \
            --reporters cli,junit \
            --reporter-junit-export results/test-results.xml

      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: api-test-results
          path: results/test-results.xml

      - name: Upload Reports on Failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: api-test-report
          path: newman/*.html
```

---

## 📊 性能测试 AI 辅助

### k6 + AI 分析

```javascript
// load-test.js
// AI 生成的 k6 性能测试脚本
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const orderCreationTime = new Trend('order_creation_time');

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // 预热
    { duration: '5m', target: 100 },   // 稳态
    { duration: '2m', target: 200 },   // 阶梯加压
    { duration: '5m', target: 200 },   // 高负载
    { duration: '2m', target: 0 },     // 冷却
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95%请求在500ms内
    http_req_failed: ['rate<0.01'],    // 错误率<1%
    'order_creation_time': ['p(99)<1000'], // 创建订单p99<1s
  },
};

export default function () {
  // 1. 创建订单
  const createRes = http.post(
    `${__ENV.BASE_URL}/api/v1/orders`,
    JSON.stringify({
      items: [{ productId: 1, quantity: Math.floor(Math.random() * 5) + 1 }]
    }),
    {
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    }
  );

  orderCreationTime.add(createRes.timings.duration);
  check(createRes, {
    'create order: status 200': (r) => r.status === 200,
    'create order: has orderNo': (r) => r.json('data.orderNo'),
  }) || errorRate.add(1);

  sleep(1);
}
```

### AI 性能问题分析

```bash
# k6 输出后，AI 分析报告
codex exec "分析以下 k6 性能测试结果，找出性能瓶颈：

## 测试环境
- 并发用户: 200
- 测试时长: 15分钟
- 总请求数: 1,234,567

## 测试结果摘要
http_req_duration:
  avg: 320ms
  p(50): 280ms
  p(90): 450ms
  p(95): 520ms
  p(99): 890ms
  max: 3200ms

http_req_failed: 2.3%

## 失败的请求分布
/api/v1/orders POST: 1.8% 失败率
/api/v1/orders/{orderNo} GET: 0.3% 失败率
/api/v1/products GET: 0.2% 失败率

## 具体问题
1. 95%请求在520ms，但有部分请求超过2s
2. 订单创建接口失败率最高
3. 峰值期响应时间明显上升

请分析：
1. 主要性能瓶颈在哪里
2. 失败原因推断
3. 优化建议（从应用到数据库到缓存）
4. 需要收集哪些指标进一步定位"
```

---

## 🔄 持续集成与自动化

### GitHub Actions + AI 测试

```yaml
# .github/workflows/ci.yml
name: CI with AI Testing

on:
  push:
    branches: [main, develop]
    paths:
      - '**.java'
      - '**.js'
      - '**.py'
  pull_request:

jobs:
  # 1. 代码质量检查
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
      - run: mvn compile
      - run: mvn checkstyle:check

  # 2. AI 生成单元测试（Codex）
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
      - name: Install Codex
        run: pip install openai
      - name: Generate Tests with Codex
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          codex exec "为 src/main/java 下的每个 service 类生成测试，
          使用 JUnit 5 + Mockito，
          目标覆盖率：核心方法 > 80%"
      - name: Upload Generated Tests
        uses: actions/upload-artifact@v3
        with:
          name: generated-tests
          path: src/test/java/

  # 3. 运行所有测试
  test:
    runs-on: ubuntu-latest
    needs: generate-tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
      - name: Download Generated Tests
        uses: actions/download-artifact@v3
        with:
          name: generated-tests
          path: src/test/java/
      - run: mvn test
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: target/site/jacoco/jacoco.xml

  # 4. AI 代码审查
  ai-review:
    runs-on: ubuntu-latest
    needs: [code-quality, test]
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run AI Code Review
        uses: actions/github-script@v6
        with:
          script: |
            const { execSync } = require('child_process');
            const diff = execSync('git diff main...HEAD -- "*.java"').toString();
            
            // 调用 Codex 审查
            const review = execSync(`codex exec "审查以下代码变更，给出安全和逻辑问题：
            ${diff.slice(0, 5000)}"`, { env: { ...process.env, OPENAI_API_KEY: process.env.OPENAI_API_KEY }});
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## AI Code Review\\n\\n' + review.toString()
            });
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

---

## 🎯 测试用例设计 Prompt 库

### 通用测试用例 Prompt

```
## Prompt 模板：边界值测试生成

请为 [{函数/方法名}] 生成边界值测试用例：

### 输入参数规格
{参数列表及其类型、范围、约束}

### 请覆盖以下边界
1. 最小值 / 最大值
2. 最小值-1 / 最大值+1
3. 空值（null, "", []）
4. 零值（0, 0.0, false）
5. 负数（-1, -100）
6. 极大值（超出范围）
7. 正常值（中间值）
8. 特殊字符（SQL注入、XSS、Unicode）

### 输出格式
| 用例ID | 输入 | 预期输出 | 测试类型 |
|--------|------|---------|---------|
| TC001 | ... | ... | ... |

---

## Prompt 模板：业务流程测试生成

请为 [{业务场景}] 设计完整的业务流程测试用例：

### 业务流程描述
{步骤1 → 步骤2 → 步骤3...}

### 参与者
{用户、管理员、系统}

### 请覆盖
1. 正常流程（Happy Path）
2. 异常流程（每个步骤失败）
3. 并发场景
4. 权限场景
5. 数据状态一致性

### 输出
1. 测试场景矩阵
2. 每个场景的测试步骤
3. 预期结果
4. 前置条件
5. 测试数据需求
```

---

## ⚠️ AI 测试的局限与注意

### AI 测试不能替代的

| 场景 | 原因 | 建议 |
|------|------|------|
| 业务逻辑理解 | AI 不懂公司业务规则 | 人工补充业务规则测试 |
| 探索性测试 | 需要人类直觉和经验 | 人工执行 |
| UI/UX 测试 | 主观感受无法量化 | 人工评审 |
| 安全性渗透 | 需要专业安全知识 | 安全团队介入 |
| 复杂场景编排 | 涉及多方系统交互 | 人工设计 + AI 辅助 |

### AI 测试注意事项

```markdown
## 安全注意
1. 不要把真实用户数据发给 AI
2. 测试数据要脱敏后再给 AI
3. API Key 等敏感信息用环境变量

## 质量注意
1. AI 生成的测试用例必须人工审核
2. 不要100%依赖 AI 的断言
3. 复杂业务逻辑的测试还是要人工写

## 维护注意
1. 定期清理无效测试用例
2. AI 生成的代码要保持可读性
3. 建立测试用例评审机制
```

---

## 🔗 相关资源

- [Diffblue](https://www.diffblue.com/) - Java AI 测试生成