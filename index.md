---
layout: home
title: AI 编程实战笔记
---

# AI 编程实战笔记

> 后端程序员的 AI 协同开发实战指南

## 最新文章

{% for post in site.posts limit:10 %}
- *{{ post.date | date: "%Y-%m-%d" }}* [{{ post.title }}]({{ post.url }})
{% endfor %}

---

## 关于这个博客

本博客聚焦 AI 辅助编程的实战经验，涵盖：

- 🤖 **AI 编程工具**：Claude Code、Cursor、Copilot 等工具的深度使用
- 🔧 **测试自动化**：AI 生成测试、代码审查、安全扫描
- 🧠 **需求分析与任务分解**：如何让 AI 更好地理解需求
- 🌐 **MCP 生态**：Model Context Protocol 插件系统
- ⚙️ **多 Agent 协作**：多 Agent 系统的设计与实现

## 目录

{% for post in site.posts %}
1. [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%Y-%m-%d" }}
{% endfor %}
