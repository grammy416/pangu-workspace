#!/bin/bash
# 🪓 盘古工作空间恢复脚本
# 用法: ./restore.sh [备份仓库地址]

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
BACKUP_REPO="${1:-https://github.com/grammy416/pangu-workspace.git}"
RESTORE_DIR="/tmp/pangu-restore-$(date +%s)"

echo "🪓 盘古恢复启动..."
echo "目标工作空间: $WORKSPACE"
echo "备份仓库: $BACKUP_REPO"
echo ""

# 克隆备份仓库
echo "📥 下载备份..."
git clone "$BACKUP_REPO" "$RESTORE_DIR"

# 确认恢复
echo ""
echo "⚠️  即将恢复以下文件到: $WORKSPACE"
echo ""
ls -la "$RESTORE_DIR"
echo ""
read -p "确认恢复? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消"
    rm -rf "$RESTORE_DIR"
    exit 0
fi

# 创建工作空间目录
mkdir -p "$WORKSPACE"
cd "$RESTORE_DIR"

# 恢复核心文件
echo "📁 恢复核心文件..."
for file in MEMORY.md USER.md SOUL.md IDENTITY.md AGENTS.md TOOLS.md HEARTBEAT.md; do
    if [ -f "$file" ]; then
        cp "$file" "$WORKSPACE/"
        echo "  ✓ $file"
    fi
done

# 恢复目录
echo "📁 恢复目录..."
for dir in memory skills configs projects; do
    if [ -d "$dir" ]; then
        cp -r "$dir" "$WORKSPACE/"
        echo "  ✓ $dir/"
    fi
done

# 清理
rm -rf "$RESTORE_DIR"

echo ""
echo "✅ 恢复完成！"
echo ""
echo "🔐 注意: .secrets/ 目录包含敏感信息，需手动恢复:"
echo "   - GitHub Token"
echo "   - SSH 密钥"
echo ""
echo "请重新配置:"
echo "   1. GitHub SSH 密钥"
echo "   2. API Token"
echo ""
echo "工作空间已就绪，重启 OpenClaw 即可。"
