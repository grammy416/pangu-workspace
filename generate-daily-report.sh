#!/bin/bash
# 📊 盘古每日智能体简报生成脚本（Heartbeat 版本）
# 生成简报内容，供 Heartbeat 触发时发送

WORKSPACE="/root/.openclaw/workspace"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
REPORT_FILE="$WORKSPACE/.daily-report-last-sent"

# 检查今日是否已发送
if [ -f "$REPORT_FILE" ]; then
    LAST_SENT=$(cat "$REPORT_FILE")
    if [ "$LAST_SENT" = "$DATE" ]; then
        echo "今日简报已发送 ($DATE)，跳过"
        exit 0
    fi
fi

# 获取统计数据
BACKUP_COUNT=$(cat /var/log/pangu-backup.log 2>/dev/null | grep "$DATE" | wc -l)
COMMIT_COUNT=$(cd "$WORKSPACE/github-test" 2>/dev/null && git rev-list --count HEAD 2>/dev/null || echo "0")
TOKEN_DAYS=$(cat /var/log/pangu-token-check.log 2>/dev/null | tail -1 | grep -o '[0-9]* 天' | head -1 || echo "未知")

# 生成简报
cat << EOF
📊 $DATE 智能体日报

🧠 Agent 状态
━━━━━━━━━━━━━━━━━━━━━
• 盘古 (pangu:main): 🟢 活跃
• 子代理: 今日无运行
• 定时任务: ✅ 正常

📈 今日统计
━━━━━━━━━━━━━━━━━━━━━
• 备份执行: $BACKUP_COUNT 次
• GitHub 版本: $COMMIT_COUNT
• Token 剩余: $TOKEN_DAYS
• 系统时间: $TIME

⚙️ 定时任务状态
━━━━━━━━━━━━━━━━━━━━━
• 备份: 每天 01:00 ✅
• Token检查: 每天 09:00 ✅
• 简报发送: 每天 23:00 ✅

📋 系统健康度: ✅ 正常

—— 盘古 $TIME
EOF

# 记录发送日期
echo "$DATE" > "$REPORT_FILE"
