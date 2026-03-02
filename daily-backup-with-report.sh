#!/bin/bash
# 🪓 盘古工作空间每日备份脚本
# 由盘古自动执行 - 每天凌晨 1:00

set -e

WORKSPACE="/root/.openclaw/workspace"
BACKUP_LOG="$WORKSPACE/BACKUP_LOG.md"
DATE_STR=$(date '+%Y-%m-%d %H:%M:%S')
DATE_SHORT=$(date '+%Y-%m-%d')

cd "$WORKSPACE"

echo "🪓 [$DATE_STR] 盘古备份启动..."

# 检查变更
if git diff --quiet && git diff --cached --quiet; then
    echo "📭 无变更需要提交"
    echo "- $DATE_STR - 无变更" >> "$BACKUP_LOG"
    
    # 发送汇报（即使无变更）
    /usr/local/bin/openclaw message send --channel feishu --message "📦 盘古备份报告 ($DATE_SHORT)

状态: ⚪ 无变更
时间: $DATE_STR
仓库: https://github.com/grammy416/pangu-workspace

无需备份。"
    exit 0
fi

# 提交变更
git add -A
git commit -m "🔄 $DATE_SHORT 每日备份"
git push origin master

# 记录日志
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "- $DATE_STR - 备份成功 (commit: $COMMIT_HASH)" >> "$BACKUP_LOG"

echo "✅ 备份完成: $COMMIT_HASH"

# 发送成功汇报
/usr/local/bin/openclaw message send --channel feishu --message "📦 盘古备份报告 ($DATE_SHORT)

状态: ✅ 成功
时间: $DATE_STR
Commit: \`$COMMIT_HASH\`
仓库: https://github.com/grammy416/pangu-workspace

备份内容:
- MEMORY.md / AGENTS.md / SOUL.md 等核心配置
- memory/ 历史记录
- skills/ 技能目录

已推送至 GitHub。"
