#!/bin/bash
# 迁移博客到 GitHub Pages (_posts) 格式

POSTS_DIR="_posts"
mkdir -p $POSTS_DIR

migrate_file() {
    local src="$1"
    local date="$2"
    local newname="$3"
    
    if [ ! -f "$src" ]; then
        echo "跳过: $src (不存在)"
        return
    fi
    
    # 读取原文件内容
    content=$(cat "$src")
    
    # 提取标题（第一个 # 开头的内容）
    title=$(echo "$content" | head -1 | sed 's/^# //' | sed 's/\*$//')
    
    # 创建新文件（_posts格式）
    dest="$POSTS_DIR/${date}-${newname}.md"
    
    # 使用 Python 来处理，避免 shell 转义问题
    python3 << PYEOF
content = '''$content'''
title = content.split('\n')[0].replace('# ', '').replace('*', '')
date = '$date'
newname = '$newname'

frontmatter = f'''---
layout: post
title: "{title}"
date: {date}
---

'''

# Skip the first line (# title) since we have it in frontmatter
body = '\n'.join(content.split('\n')[1:])

with open('$POSTS_DIR/' + date + '-' + newname + '.md', 'w') as f:
    f.write(frontmatter + body)
PYEOF
    
    echo "迁移: $src -> $dest"
}

# 迁移所有博客文章（日期统一用 2026-03-22）
migrate_file "deep-insights.md" "2026-03-22" "ai-时代软件开发思维革命"
migrate_file "ai-testing-tools.md" "2026-03-22" "ai-testing-tools"
migrate_file "ai-code-review.md" "2026-03-22" "ai-code-review"
migrate_file "ai-requirements-analysis-advanced.md" "2026-03-22" "ai-requirements-analysis"
migrate_file "multi-agent-orchestration.md" "2026-03-22" "multi-agent-orchestration"
migrate_file "claude-code-plugins.md" "2026-03-22" "claude-code-plugins"
migrate_file "wshobson-agents-deep-dive.md" "2026-03-22" "wshobson-agents"
migrate_file "mcp-protocol-deep-dive.md" "2026-03-22" "mcp-protocol-deep-dive"
migrate_file "mcp-ecosystem-deep-dive.md" "2026-03-22" "mcp-ecosystem"
migrate_file "smolagents-minimalist-agent-design.md" "2026-03-22" "smolagents-minimalist"
migrate_file "mini-swe-agent-deep-dive.md" "2026-03-22" "mini-swe-agent"
migrate_file "ai-task-decomposition-deep-dive.md" "2026-03-22" "ai-task-decomposition"
migrate_file "ai-requirements-analysis.md" "2026-03-22" "ai-requirements-analysis-basic"

echo ""
echo "迁移完成！"
