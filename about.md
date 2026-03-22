---
layout: page
title: 关于博客
permalink: /about/
---

<div class="about-page">
  <div class="about-hero">
    <svg class="about-icon" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="aboutGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#667eea"/>
          <stop offset="100%" style="stop-color:#764ba2"/>
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="12" fill="url(#aboutGrad)"/>
      <circle cx="32" cy="28" r="10" fill="none" stroke="white" stroke-width="2.5"/>
      <circle cx="32" cy="28" r="3" fill="white"/>
      <path d="M22 40 Q32 47 42 40" stroke="white" stroke-width="2.5" fill="none" stroke-linecap="round"/>
    </svg>
    <h1>关于 AI 编程实战笔记</h1>
  </div>

  <div class="about-section">
    <h2>🎯 博客定位</h2>
    <p>这是一个专注于 <strong>AI 辅助编程</strong>的实战博客。不是工具罗列，不是 API 手册，而是实打实的使用经验和技巧总结。</p>
  </div>

  <div class="about-section">
    <h2>📚 内容方向</h2>
    <ul>
      <li>🤖 <strong>AI 编程工具</strong>：Claude Code、Cursor、Copilot 的深度使用</li>
      <li>🔧 <strong>测试自动化</strong>：AI 生成测试、代码审查、安全扫描</li>
      <li>🧠 <strong>需求分析</strong>：如何让 AI 更好地理解需求</li>
      <li>🌐 <strong>MCP 生态</strong>：Model Context Protocol 插件系统</li>
      <li>⚙️ <strong>多 Agent</strong>：多 Agent 协作的设计与实现</li>
    </ul>
  </div>

  <div class="about-section">
    <h2>👤 关于作者</h2>
    <p>一名普通的后端开发者，正在探索 AI 辅助编程的无限可能。相信 AI 不是要取代程序员，而是让程序员变得更强大。</p>
  </div>

  <div class="about-section">
    <h2>🔗 关注我</h2>
    <div class="about-links">
      <a href="https://github.com/LuKaXiya" class="about-link" target="_blank">
        <span class="link-icon">🐙</span>
        <span class="link-text">GitHub</span>
      </a>
      <a href="https://github.com/LuKaXiya/coding-agent-blog" class="about-link" target="_blank">
        <span class="link-icon">📦</span>
        <span class="link-text">博客源码</span>
      </a>
    </div>
  </div>
</div>

<style>
  .about-page {
    max-width: 700px;
    margin: 0 auto;
    padding: 2rem;
  }
  .about-hero {
    text-align: center;
    padding: 2rem 0 3rem;
  }
  .about-icon {
    width: 80px;
    height: 80px;
    margin-bottom: 1rem;
  }
  .about-hero h1 {
    font-size: 1.8rem;
    color: #333;
  }
  .about-section {
    background: white;
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  }
  .about-section h2 {
    font-size: 1.1rem;
    color: #667eea;
    margin-bottom: 1rem;
  }
  .about-section p {
    color: #666;
    line-height: 1.7;
  }
  .about-section ul {
    list-style: none;
    padding: 0;
  }
  .about-section li {
    padding: 0.5rem 0;
    color: #666;
    border-bottom: 1px solid #f5f5f5;
  }
  .about-section li:last-child {
    border-bottom: none;
  }
  .about-links {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }
  .about-link {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-decoration: none;
    border-radius: 25px;
    transition: transform 0.2s;
  }
  .about-link:hover {
    transform: translateY(-2px);
  }
  .link-icon {
    font-size: 1.2rem;
  }
</style>
