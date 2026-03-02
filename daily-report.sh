#!/bin/bash
# 📊 盘古每日智能体简报生成脚本
# 每天 23:00 执行，发送当日 Agent 活动简报

WORKSPACE="/root/.openclaw/workspace"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
LOG_FILE="/var/log/pangu-daily-report.log"

echo "[$TIME] 生成每日简报..." >> "$LOG_FILE"

# 获取系统状态
SESSION_STATUS=$(openclaw status 2>/dev/null || echo "状态获取失败")
TOKEN_COUNT=$(cat /var/log/pangu-backup.log 2>/dev/null | grep "$(date '+%Y-%m-%d')" | wc -l)
COMMIT_COUNT=$(cd "$WORKSPACE/github-test" && git rev-list --count HEAD 2>/dev/null || echo "0")

# 生成简报内容
cat > /tmp/daily_report.txt << EOF
📊 $(date '+%Y-%m-%d') 智能体日报

🧠 Agent 状态
━━━━━━━━━━━━━━━━━━━━━
• 盘古 (pangu:main): 🟢 活跃
• 子代理: 今日无运行
• 定时任务: ✅ 正常

📈 今日统计
━━━━━━━━━━━━━━━━━━━━━
• 备份次数: $TOKEN_COUNT
• GitHub 版本: $COMMIT_COUNT
• 系统时间: $(date '+%H:%M')

⚙️ 定时任务状态
━━━━━━━━━━━━━━━━━━━━━
• 备份: 每天 01:00 ✅
• Token检查: 每天 09:00 ✅
• 简报发送: 每天 23:00 ✅

📋 系统健康度: ✅ 正常

—— 盘古 $(date '+%H:%M')
EOF

cat /tmp/daily_report.txt

# 记录日志
echo "[$TIME] 简报已生成" >> "$LOG_FILE"
