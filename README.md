# 🧠 CCG 模式：用 AI 协同提升编程效率

> 一个让 Claude Opus 做指挥官、Gemini 做前端、Codex 做助手的编程工作流

[![Stars](https://img.shields.io/github/stars/LuKaXiya/coding-agent-blog?style=social)](https://github.com/LuKaXiya/coding-agent-blog)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 目录

- [🎯 CCG 是什么？](#-ccg-是什么)
- [🤖 三剑客分工](#-三剑客分工)
- [⚡ 快速上手](#-快速上手)
- [📋 实战流程](#-实战流程)
- [💻 完整代码示例](#-完整代码示例)
- [🎨 效果展示](#-效果展示)
- [🛡️ 安全与最佳实践](#-安全与最佳实践)
- [🚀 进阶技巧](#-进阶技巧)

---

## 🎯 CCG 是什么？

**CCG = Claude + Cursor/Gemini + Codex**

这是一种 AI 协同编程模式，每个 AI 做自己最擅长的事：

```
┌─────────────────────────────────────────────────────────┐
│                    🧠 Opus (指挥官)                      │
│         理解任务 → 制定计划 → 审核代码 → 最终把关          │
└──────────────────────┬──────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │  Gemini │   │ Claude  │   │  Codex  │
   │  (前端)  │   │  (后端)  │   │ (辅助)  │
   └─────────┘   └─────────┘   └─────────┘
```

### 为什么需要 CCG？

| 痛点 | 传统方案 | CCG 方案 |
|------|----------|----------|
| AI 上下文污染 | 一个 AI 干所有事，记忆混乱 | 各 Agent 独立 workspace，互不干扰 |
| AI 生成代码质量参差 | 盲目信任 AI | Opus 最终审核，严格把关 |
| 前端开发效率低 | 手工写 HTML/CSS | Gemini 快速生成 UI |
| 测试覆盖不足 | 懒得写测试 | Codex 自动生成测试用例 |

---

## 🤖 三剑客分工

### 1. 🧠 Claude Opus — 指挥官

**定位**：理解需求、制定计划、架构设计、代码审查

```bash
# Opus 的工作方式
claude --print --permission-mode bypassPermissions << 'EOF'
我需要你分析这个需求并制定开发计划：
用户想要一个任务管理应用，支持：
1. 用户注册登录
2. CRUD 任务
3. 任务分类和标签
4. 截止日期提醒

请产出：
1. 技术方案文档
2. 数据库设计
3. API 接口规划
4. 任务分解（WBS）
EOF
```

### 2. ✨ Gemini Flash — 前端专家

**定位**：React/Vue 组件、UI/UX 设计、页面布局、样式优化

```bash
# Gemini 的工作方式
gemini "用 React + TailwindCSS 实现任务卡片组件，包含：
- 任务标题和描述
- 截止日期显示
- 优先级标签（高/中/低用不同颜色）
- 完成checkbox动画
要求：深色模式适配，移动端友好"
```

### 3. ⚡ Codex — 效率助手

**定位**：脚本生成、测试用例、代码补全、快速重构

```bash
# Codex 的工作方式
codex exec "为 tasks 表编写完整的单元测试和集成测试，
覆盖：增删改查、分页、排序、标签过滤"
```

---

## ⚡ 快速上手

### 环境准备

```bash
# 1. 安装 Claude Code
npm install -g @anthropic-ai/claude-code

# 2. 安装 Codex
# pip install openai Codex 已内置于 OpenAI API

# 3. 配置环境变量
export ANTHROPIC_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
```

### Workspace 隔离（关键！）

```
~/.openclaw/workspace/
├── MEMORY.md              ← Opus 的记忆
├── projects/              ← 编程专用目录
│   ├── backend/           ← 后端代码
│   ├── frontend/          ← 前端代码
│   └── tests/             ← 测试代码
└── blog/                  ← 本博客源码
```

> ⚠️ **重要**：每个 AI 只在自己的目录工作，不跨越边界，避免上下文污染。

---

## 📋 实战流程

### 第一步：Opus 分析任务

```
用户：我想做一个股票行情看板

Opus 思考：
1. 需求理解：实时行情、K线图、数据筛选
2. 技术选型：React + D3.js + WebSocket
3. 任务分解：
   - 数据层：WebSocket 接入 / REST API
   - 业务层：数据处理、状态管理
   - 展示层：K线图、行情列表、技术指标
4. 产出文档：PRD + 技术方案
```

### 第二步：Gemini 生成前端

```tsx
// Gemini 生成的股票卡片组件
import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface StockCardProps {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
}

export const StockCard: React.FC<StockCardProps> = ({
  symbol, name, price, change, changePercent
}) => {
  const isPositive = change >= 0;
  
  return (
    <div className="bg-gray-800 rounded-xl p-4 hover:bg-gray-750 transition-colors">
      <div className="flex justify-between items-start mb-2">
        <div>
          <span className="text-lg font-bold text-white">{symbol}</span>
          <span className="ml-2 text-gray-400 text-sm">{name}</span>
        </div>
        {isPositive ? (
          <TrendingUp className="text-green-500" size={20} />
        ) : (
          <TrendingDown className="text-red-500" size={20} />
        )}
      </div>
      
      <div className="flex items-end gap-2">
        <span className="text-2xl font-mono font-bold text-white">
          ${price.toFixed(2)}
        </span>
        <span className={`text-sm font-medium ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
          {isPositive ? '+' : ''}{change.toFixed(2)} ({changePercent.toFixed(2)}%)
        </span>
      </div>
    </div>
  );
};
```

### 第三步：Codex 生成测试

```typescript
// Codex 生成的测试用例
import { render, screen } from '@testing-library/react';
import { StockCard } from '../components/StockCard';

describe('StockCard', () => {
  it('renders positive stock data correctly', () => {
    const { container } = render(
      <StockCard
        symbol="AAPL"
        name="Apple Inc."
        price={178.50}
        change={2.35}
        changePercent={1.33}
      />
    );
    
    expect(screen.getByText('AAPL')).toBeInTheDocument();
    expect(screen.getByText('Apple Inc.')).toBeInTheDocument();
    expect(container.querySelector('.text-green-400')).toHaveTextContent('+2.35 (1.33%)');
  });

  it('renders negative stock data with red color', () => {
    const { container } = render(
      <StockCard
        symbol="TSLA"
        name="Tesla Inc."
        price={245.80}
        change={-5.20}
        changePercent={-2.07}
      />
    );
    
    expect(container.querySelector('.text-red-400')).toHaveTextContent('-5.20 (-2.07%)');
  });
});
```

### 第四步：Opus 最终审核

```bash
claude --print << 'EOF'
请审查以下代码变更：
1. StockCard.tsx - 股票卡片组件
2. StockCard.test.tsx - 测试文件

检查项：
✅ 组件是否完整处理了涨跌情况
✅ 是否有 XSS 风险
✅ TypeScript 类型是否正确
✅ 测试覆盖率是否充分
✅ 样式是否符合设计规范
EOF
```

---

## 💻 完整代码示例

### 项目结构

```
stock-dashboard/
├── src/
│   ├── components/
│   │   ├── StockCard.tsx        # 股票卡片
│   │   ├── StockList.tsx        # 股票列表
│   │   ├── StockChart.tsx      # K线图
│   │   └── SearchBar.tsx       # 搜索栏
│   ├── hooks/
│   │   ├── useStockData.ts     # 数据Hook
│   │   └── useWebSocket.ts     # 实时数据
│   ├── services/
│   │   └── api.ts              # API服务
│   ├── types/
│   │   └── stock.ts            # 类型定义
│   └── App.tsx
├── tests/
│   └── components/
│       ├── StockCard.test.tsx
│       └── StockList.test.tsx
└── package.json
```

### 核心类型定义

```typescript
// types/stock.ts
export interface Stock {
  symbol: string;           // 股票代码，如 "AAPL"
  name: string;             // 公司名称
  price: number;             // 当前价格
  change: number;            // 涨跌额
  changePercent: number;     // 涨跌幅 %
  volume: number;            // 成交量
  marketCap: string;         // 市值
  lastUpdated: Date;         // 最后更新时间
}

export interface StockQuote {
  symbol: string;
  open: number;
  high: number;
  low: number;
  close: number;
  timestamp: number;
}

export type TimeRange = '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL';

export interface StockFilters {
  search?: string;
  sortBy: 'symbol' | 'price' | 'change' | 'volume';
  sortOrder: 'asc' | 'desc';
  timeRange: TimeRange;
}
```

### 股票列表组件

```tsx
// components/StockList.tsx
import React, { useState, useMemo } from 'react';
import { StockCard } from './StockCard';
import { SearchBar } from './SearchBar';
import { Stock, StockFilters } from '../types/stock';

interface StockListProps {
  stocks: Stock[];
  onSelect: (symbol: string) => void;
}

export const StockList: React.FC<StockListProps> = ({ stocks, onSelect }) => {
  const [filters, setFilters] = useState<StockFilters>({
    sortBy: 'symbol',
    sortOrder: 'asc',
    timeRange: '1D',
  });

  const filteredStocks = useMemo(() => {
    let result = [...stocks];
    
    // 搜索过滤
    if (filters.search) {
      const query = filters.search.toLowerCase();
      result = result.filter(
        s => s.symbol.toLowerCase().includes(query) ||
             s.name.toLowerCase().includes(query)
      );
    }
    
    // 排序
    result.sort((a, b) => {
      const aVal = a[filters.sortBy];
      const bVal = b[filters.sortBy];
      return filters.sortOrder === 'asc' 
        ? (aVal > bVal ? 1 : -1)
        : (aVal < bVal ? 1 : -1);
    });
    
    return result;
  }, [stocks, filters]);

  return (
    <div className="space-y-4">
      <SearchBar
        value={filters.search || ''}
        onChange={search => setFilters(f => ({ ...f, search }))}
      />
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filteredStocks.map(stock => (
          <div 
            key={stock.symbol} 
            onClick={() => onSelect(stock.symbol)}
            className="cursor-pointer"
          >
            <StockCard {...stock} />
          </div>
        ))}
      </div>
      
      {filteredStocks.length === 0 && (
        <div className="text-center py-12 text-gray-400">
          未找到匹配的股票
        </div>
      )}
    </div>
  );
};
```

---

## 🎨 效果展示

### 股票卡片（深色主题）

![Stock Card Dark](https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80)

### 实时行情界面

```
┌─────────────────────────────────────────────────────────┐
│  🔍 搜索股票...                              [时间:1D▼] │
├─────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ AAPL     │  │ GOOGL    │  │ MSFT      │  │ AMZN   │ │
│  │ Apple    │  │ Google   │  │ Microsoft │  │Amazon  │ │
│  │ $178.50  │  │ $142.30  │  │ $378.90   │  │$156.20 │ │
│  │ +1.33% 🟢│  │ +0.85% 🟢│  │ -0.32% 🔴 │  │+2.15%🟢│ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │              📈 AAPL 苹果公司                      │ │
│  │                     K线图区域                       │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 响应式设计

| 断点 | 列数 | 描述 |
|------|------|------|
| `< 640px` | 1列 | 手机端 |
| `640px - 768px` | 2列 | 大手机 |
| `768px - 1024px` | 3列 | 平板 |
| `> 1024px` | 4列 | 桌面端 |

---

## 🛡️ 安全与最佳实践

### 1. API 密钥管理

```typescript
// ✅ 正确：使用环境变量
const apiKey = process.env.ANTHROPIC_API_KEY;

// ❌ 错误：硬编码密钥
const apiKey = "sk-ant-xxx-xxx";
```

### 2. 用户输入校验

```typescript
// Gemini 生成的代码需要审核
const sanitizeInput = (input: string): string => {
  return input
    .replace(/[<>]/g, '')  // 移除 HTML 标签
    .trim()
    .slice(0, 200);         // 限制长度
};

// 股票代码格式验证
const isValidSymbol = (symbol: string): boolean => {
  return /^[A-Z]{1,5}$/.test(symbol.toUpperCase());
};
```

### 3. AI 生成代码审查清单

```markdown
- [ ] 逻辑正确性
- [ ] 边界条件处理
- [ ] 错误处理
- [ ] 安全性（XSS、SQL注入）
- [ ] 性能（大数据量渲染）
- [ ]  accessibility（无障碍）
- [ ] TypeScript 类型安全
```

---

## 🚀 进阶技巧

### 1. Opus 自动任务分配

```typescript
// Opus 的任务分发逻辑
const assignTask = (task: Task): AIAgent => {
  if (task.type === 'frontend') return 'gemini';
  if (task.type === 'test') return 'codex';
  if (task.type === 'critical') return 'opus';
  return 'codex';
};
```

### 2. 并行任务处理

```bash
# 同时启动多个 AI
claude --print "实现后端API" &
gemini "实现前端组件" &
codex "编写测试" &
wait
```

### 3. 上下文隔离技巧

```bash
# 每个 AI 在独立目录工作
mkdir -p projects/{opus,gemini,codex}

# Opus 在主目录
cd projects/opus && claude --print "协调全局"

# Gemini 在前端目录
cd projects/gemini && gemini "实现UI"

# Codex 在测试目录
cd projects/codex && codex "写测试"
```

---

## 📚 相关资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)
- [Gemini API](https://ai.google.dev/)
- [Codex API](https://platform.openai.com/docs/guides/code)
- [TailwindCSS](https://tailwindcss.com/)
- [React](https://react.dev/)

---

## 🤝 贡献

欢迎提交 Issue 和 PR！

---

## 📄 License

MIT © [LuKaXiya](https://github.com/LuKaXiya)
