#!/bin/bash
# 🪓 盘古工作空间备份脚本（GitHub 7日轮转版）
# 每天凌晨1点执行，GitHub 仅保留最近7个版本

set -e

WORKSPACE="/root/.openclaw/workspace"
COMMIT_MSG="🔄 $(date '+%m-%d %H:%M') 每日备份"
KEEP_VERSIONS=7
BACKUP_LOG="$WORKSPACE/BACKUP_LOG.md"

echo "🪓 盘古备份启动..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "策略: GitHub 保留最近 $KEEP_VERSIONS 个版本"

# 进入工作空间
cd "$WORKSPACE"

# 同步文件到 GitHub 工作目录
echo "📁 同步工作空间文件..."

for file in MEMORY.md USER.md SOUL.md IDENTITY.md AGENTS.md TOOLS.md HEARTBEAT.md; do
    [ -f "$file" ] && cp "$file" github-test/ 2>/dev/null && echo "  ✓ $file"
done

for dir in memory skills configs projects; do
    [ -d "$dir" ] && mkdir -p "github-test/$dir" && rsync -av --delete "$dir/" "github-test/$dir/" 2>/dev/null && echo "  ✓ $dir/"
done

# 进入 GitHub 仓库目录
cd github-test

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    echo "📭 无变更需要提交，跳过本次备份"
    
    # 即使无变更也更新备份日志时间
    cd "$WORKSPACE"
    echo "- $(date '+%Y-%m-%d %H:%M:%S') - 无变更，跳过" >> "$BACKUP_LOG"
    exit 0
fi

# 提交变更
echo "📤 提交变更..."
git add -A
git commit -m "$COMMIT_MSG"

# 🧹 七日轮转：只保留最近7个提交
echo "🧹 执行七日轮转清理..."

COMMIT_COUNT=$(git rev-list --count HEAD)
echo "当前共有 $COMMIT_COUNT 个提交"

if [ "$COMMIT_COUNT" -gt "$KEEP_VERSIONS" ]; then
    # 获取要保留的最近7个提交中的最旧一个
    KEEP_FROM=$(git rev-list --reverse HEAD | head -n $KEEP_VERSIONS | head -n 1)
    
    if [ -n "$KEEP_FROM" ]; then
        echo "保留从 $KEEP_FROM 开始的最近 $KEEP_VERSIONS 个提交"
        
        # 创建归档分支
        ARCHIVE_BRANCH="archive-$(date '+%Y%m%d')"
        git branch "$ARCHIVE_BRANCH" 2>/dev/null || true
        
        # 使用 git reset --soft 到第7个提交的父提交
        git reset --soft "HEAD~$((COMMIT_COUNT - KEEP_VERSIONS))"
        git commit -m "📦 归档 ($(date '+%Y-%m-%d') 之前的旧版本)"
        
        echo "✅ 已归档旧提交，保留最近 $KEEP_VERSIONS 个版本"
    fi
else
    echo "提交数 ($COMMIT_COUNT) 未超过限制 ($KEEP_VERSIONS)，无需清理"
fi

# 推送到 GitHub
echo "📤 推送到 GitHub..."
git push origin main --force

# 记录备份日志
cd "$WORKSPACE"
echo "- $(date '+%Y-%m-%d %H:%M:%S') - 备份成功 ($(git rev-list --count HEAD) 个版本)" >> "$BACKUP_LOG"

echo "✅ 备份完成！"
echo "提交时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "GitHub 版本数: 最多 $KEEP_VERSIONS 个"
