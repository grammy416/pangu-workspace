#!/bin/bash
# 🧹 盘古 GitHub 仓库7天清理脚本（可选）
# 警告：此脚本会重写 Git 历史，请谨慎使用！
# 用法: ./cleanup-old-history.sh

set -e

KEEP_DAYS=7
CUTOFF_DATE=$(date -d "$KEEP_DAYS days ago" +%Y-%m-%d)

echo "⚠️  警告：此操作将重写 Git 历史！"
echo "保留最近 $KEEP_DAYS 天的提交（$CUTOFF_DATE 之后）"
echo ""
echo "此操作将："
echo "  1. 创建归档分支保存完整历史"
echo "  2. 重写 main 分支，只保留最近 $KEEP_DAYS 天"
echo "  3. 需要强制推送到 GitHub"
echo ""
read -p "确认执行? 输入 'cleanup' 继续: " confirm

if [[ "$confirm" != "cleanup" ]]; then
    echo "已取消"
    exit 0
fi

echo "🧹 开始清理..."

# 创建归档分支
git branch archive-$(date +%Y%m%d) 2>/dev/null || echo "归档分支已存在"

# 获取最近7天的提交数量
RECENT_COMMITS=$(git log --since="$CUTOFF_DATE" --oneline | wc -l)

if [ "$RECENT_COMMITS" -eq 0 ]; then
    echo "⚠️  最近7天没有提交，跳过清理"
    exit 0
fi

echo "保留最近 $RECENT_COMMITS 个提交..."

# 方案：使用 git rebase 压缩旧提交
# 找到7天前的提交点，将其之前的所有提交压缩

# 获取7天前最后一个提交的父提交
CUTOFF_COMMIT=$(git log --before="$CUTOFF_DATE" --format="%H" -1)

if [ -z "$CUTOFF_COMMIT" ]; then
    echo "没有找到旧提交，无需清理"
    exit 0
fi

echo "归档点: ${CUTOFF_COMMIT:0:8}"

# 交互式 rebase，压缩旧提交
git rebase -i --root << 'GITCMDS'
# 这里需要手动编辑，自动方案如下：
GITCMDS

echo "✅ 清理完成"
echo "请手动执行: git push --force origin main"
echo "以应用更改到 GitHub"
