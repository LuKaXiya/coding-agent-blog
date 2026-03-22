#!/bin/bash
# 博客同步脚本
# 用法: bash _scripts/sync-post.sh <源文件.md> [标题]
# 
# 这个脚本会把博客文章同步到两个位置：
# 1. _posts/YYYY-MM-DD-title.md (GitHub Pages)
# 2. <title>.md (根目录，仓库视图)
#
# 示例：
#   bash _scripts/sync-post.sh my-blog-draft.md "我的新博客"

set -e

SRC="$1"
TITLE="$2"
DATE=$(date +%Y-%m-%d)

if [ -z "$SRC" ] || [ -z "$TITLE" ]; then
    echo "用法: bash _scripts/sync-post.sh <源文件> <标题>"
    echo "示例: bash _scripts/sync-post.sh draft.md \"我的第一篇博客\""
    exit 1
fi

# 生成 slug（用于文件名）
SLUG=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5]/-/g' | tr '[:upper:]' '[:lower:]')

# 转换标题中的特殊字符
ESCAPED_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')

# 创建 _posts 版本（带 front matter）
python3 << PYEOF
import re

with open('$SRC', 'r') as f:
    content = f.read()

# 提取标题（第一个 # 开头）
lines = content.strip().split('\n')
title_line = None
body_lines = []
for i, line in enumerate(lines):
    if line.startswith('# '):
        title_line = line[2:].replace('*', '').strip()
        body_lines = lines[i+1:]
        break

if not title_line:
    title_line = '$TITLE'

# 生成 front matter
frontmatter = f'''---
layout: post
title: "{title_line}"
date: $DATE
---

'''

# 写入 _posts
with open('_posts/$DATE-$SLUG.md', 'w') as f:
    f.write(frontmatter + '\n'.join(body_lines))

print(f"✓ 写入 _posts/$DATE-$SLUG.md")

# 写入根目录版本（无 front matter，保持原样）
with open(f'$SLUG.md', 'w') as f:
    f.write('# ' + title_line + '\n\n' + '\n'.join(body_lines))

print(f"✓ 写入 $SLUG.md")
PYEOF

echo ""
echo "完成！"
echo "- GitHub Pages: https://luKaXiya.github.io/coding-agent-blog/posts/$DATE-$SLUG/"
echo "- 仓库文件: https://github.com/LuKaXiya/coding-agent-blog/blob/main/$SLUG.md"
