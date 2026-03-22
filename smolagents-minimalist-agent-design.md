# 极简主义回归：smolagents 用 1000 行代码重新定义 Agent 框架

> HuggingFace 出品 | 26,199 Stars | 核心理念：Agents that think in code

---

## 核心洞察

当所有人都在把 Agent 框架做得越来越复杂的时候，HuggingFace 推出了 smolagents——一个核心理念只有 **~1000 行代码** 的 Agent 库。

这不是在秀技术，而是在回答一个根本问题：**Agent 框架的复杂度，真的需要那么高吗？**

mini-SWE-agent 的团队做过一个实验：把 Agent 框架简化到只剩 bash，没有任何 fancy 的工具调用接口，结果依然达到了 74% 的 SWE-bench 修复率。

smolagents 继承了同样的思路：用最少的抽象，做最有用的事。

---

## 一、smolagents 的核心理念

### "Think in Code" 而非 "Think in Text"

传统的 Agent 把所有动作都当成文本（tool_calls、JSON）来处理。smolagents 的 CodeAgent 不一样——**它的动作本身就是代码**。

```python
from smolagents import CodeAgent, WebSearchTool, InferenceClientModel

model = InferenceClientModel()
agent = CodeAgent(tools=[WebSearchTool()], model=model)

agent.run("How many seconds would it take for a leopard at full speed to run through Pont des Arts?")
```

Agent 生成的"动作"是真实的、可执行的 Python 代码，而不是 JSON 格式的 tool_call。这带来几个关键区别：

- **原生可执行**：代码直接通过 `exec()` 运行，不需要解析层
- **更自然的推理**：模型用代码思考，而不是用"调用工具"思考
- **更安全的沙箱**：代码在沙箱环境执行，不会影响宿主系统

### 最小化抽象

```
传统 Agent 框架：
模型 → 推理引擎 → 工具注册表 → 内存管理 → 状态机 → 工具执行

smolagents：
模型 → 代码生成 → exec() → 输出
```

smolagents 的 `agents.py` 核心文件只有约 1000 行。你可以在一个下午读完它的全部设计。

---

## 二、CodeAgent 的工作原理

### 执行流程

```
1. 用户输入问题
2. CodeAgent 生成 Python 代码片段
3. 代码在沙箱中执行
4. 执行结果返回给模型
5. 模型决定下一步（继续/结束）
```

### 代码动作示例

当 CodeAgent 需要搜索网页时，它生成的代码可能是：

```python
# CodeAgent 生成的代码
result = web_search("leopard speed Pont des Arts")
print(result)
```

当它需要计算时：

```python
# CodeAgent 生成的代码
speed_kmh = 58  # km/h
distance_m = 85.5  # meters
time_seconds = (distance_m / 1000) / speed_kmh * 3600
print(f"Approximately {time_seconds:.1f} seconds")
```

**关键点**：模型生成的是真实代码，可以直接运行，可以访问变量，可以调用函数。

### 工具系统的设计

smolagents 的工具系统极度精简：

```python
from smolagents import tool

@tool
def web_search(query: str) -> str:
    """Search the web for information."""
    # 实现...
    return results

# 添加到 agent
agent = CodeAgent(tools=[web_search])
```

工具就是一个带 `@tool` 装饰器的 Python 函数。没有任何复杂的注册表、schema 定义、权限系统。

---

## 三、沙箱执行：安全与灵活并存

### 为什么需要沙箱？

CodeAgent 生成的代码直接执行，必须隔离。smolagents 支持多种沙箱后端：

| 沙箱类型 | 适用场景 | 特点 |
|----------|----------|------|
| **E2B** | 云端沙箱，安全隔离 | 商业方案，开箱即用 |
| **Blaxel** | 去中心化计算 | 新兴方案 |
| **Modal** | Serverless 计算 | 支持 GPU |
| **Docker** | 本地容器化 | 最灵活 |
| **Pyodide** | 浏览器内执行 | WebAssembly |
| **本地 Bash** | 简单场景 | 无隔离，最快 |

### 配置示例

```python
from smolagents import CodeAgent, DockerExecutor

executor = DockerExecutor(
    image="python:3.11-slim",
    timeout=30,
)

agent = CodeAgent(
    model=model,
    tools=[web_search, file_reader],
    executor=DockerExecutor()
)
```

---

## 四、MCP 集成：工具无关的设计

smolagents 另一个亮点是对 MCP 的原生支持：

```python
from smolagents import ToolCollection, McpServer

# 从 MCP 服务器加载工具
mcp_server = McpServer(
    command="npx",
    args=["-y", "@modelcontextprotocol/server-filesystem", "./data"]
)

tools = ToolCollection.from_mcp(mcp_server)

agent = CodeAgent(tools=tools)
```

这意味着：**smolagents 可以使用任何 MCP 服务器提供的工具**，不受语言限制。

同样，它也支持 LangChain 工具：

```python
from langchain.tools import DuckDuckGoSearchRun
from smolagents import Tool.from_langchain

search_tool = Tool.from_langchain(DuckDuckGoSearchRun())
agent = CodeAgent(tools=[search_tool])
```

---

## 五、Hub 集成：分享和复用 Agent

smolagents 让你可以把 Agent 分享到 HuggingFace Hub：

```python
# 分享 Agent
agent.push_to_hub("m-ric/my_agent")

# 从 Hub 加载 Agent
from smolagents import load_agent
agent = load_agent("m-ric/my_agent")
```

Agent 作为 Space 仓库存在，任何人都可以复用。这让 AI 编程工具的分享变得前所未有的简单。

---

## 六、模型无关：支持任何 LLM

smolagents 不绑定任何特定模型：

```python
# 使用 HuggingFace Inference API
from smolagents import InferenceClientModel
model = InferenceClientModel(model_id="deepseek-ai/DeepSeek-R1")

# 使用 LiteLLM（100+ 模型）
from smolagents import LiteLLMModel
model = LiteLLMModel(model_id="anthropic/claude-4-sonnet-latest")

# 使用 OpenAI 兼容接口
from smolagents import OpenAIModel
model = OpenAIModel(model_id="deepseek-ai/DeepSeek-R1", api_base="...")
```

同一套代码，换一个模型配置就能切换提供商。

---

## 七、与 mini-SWE-agent 的对比

| 维度 | smolagents | mini-SWE-agent |
|------|-----------|----------------|
| **代码量** | ~1000 行 | ~100 行 |
| **核心理念** | CodeAgent（代码动作）| 仅 bash（无工具接口）|
| **工具系统** | 有（@tool 装饰器）| 无（纯 bash）|
| **MCP 支持** | ✅ 原生 | ❌ |
| **沙箱支持** | Docker/E2B/Modal/Pyodide | Docker/Local/Singularity |
| **Hub 分享** | ✅ | ❌ |
| **定位** | 通用 Agent 框架 | 代码修复专项 Agent |

**共同点**：都相信"最小化抽象"的哲学，都认为模型能力 > 框架复杂度。

---

## 八、什么时候用 smolagents

### ✅ 适合

- 构建需要精确控制执行逻辑的 Agent
- 研究 Agent 内部机制（代码量少，易读）
- 需要 MCP 集成的复杂工作流
- 需要自定义工具和执行环境的场景

### ❌ 不适合

- 追求开箱即用的完整 Agent 解决方案
- 需要复杂记忆/状态管理的场景
- 不希望代码直接执行的环境

---

## 九、安装和快速开始

```bash
pip install "smolagents[toolkit]"
```

```python
from smolagents import CodeAgent, WebSearchTool, InferenceClientModel

model = InferenceClientModel(
    model_id="deepseek-ai/DeepSeek-R1",
    provider="together",
)

agent = CodeAgent(tools=[WebSearchTool()], model=model)
agent.run("Explain quantum entanglement in simple terms")
```

---

## 十、为什么这个项目值得关注

### 1. 极简主义是正确答案的一部分

mini-SWE-agent 用 100 行代码达到 74% 修复率，smolagents 用 1000 行代码提供完整框架。这不是说框架没用，而是说**框架应该服务于任务，而不是成为任务本身**。

### 2. "Think in Code" 是一个重要的范式转变

当模型用代码思考，而不是用"工具调用"思考时，它的推理链路更自然，表达能力更强。这可能是未来 Agent 设计的方向。

### 3. 工具无关是生态系统的关键

smolagents 能用 MCP、LangChain、HuggingFace Hub——它不试图成为一切，而是成为连接一切的桥梁。这才是健康的设计。

---

## 资源

- **GitHub**: https://github.com/huggingface/smolagents
- **文档**: https://huggingface.co/docs/smolagents
- **PyPI**: `pip install smolagents`

---

*本文基于 2026-03-22 的最新版本*
