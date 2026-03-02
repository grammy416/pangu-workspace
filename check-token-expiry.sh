#!/bin/bash
# 🔔 GitHub Token 到期提醒检查脚本

TOKEN_INFO="/root/.openclaw/workspace/.secrets/TOKEN_INFO.md"
LOG_FILE="/var/log/pangu-token-check.log"

# 获取到期日期（从 TOKEN_INFO.md 中提取）
EXPIRY_DATE=$(grep "到期日期" "$TOKEN_INFO" 2>/dev/null | awk -F'|' '{print $3}' | xargs)

if [ -z "$EXPIRY_DATE" ]; then
    echo "$(date) - 无法获取到期日期" >> "$LOG_FILE"
    exit 1
fi

# 计算剩余天数
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || echo "0")
TODAY_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - TODAY_EPOCH) / 86400 ))

echo "$(date) - Token 剩余有效期: $DAYS_LEFT 天" >> "$LOG_FILE"

# 提前7天提醒
if [ "$DAYS_LEFT" -le 7 ] && [ "$DAYS_LEFT" -ge 0 ]; then
    echo "⚠️  ALERT: GitHub Token 将在 $DAYS_LEFT 天后到期！($EXPIRY_DATE)" >> "$LOG_FILE"
    # 这里可以添加通知逻辑，如发送消息到飞书等
    echo "到期提醒: $DAYS_LEFT 天"
fi

# 已过期提醒
if [ "$DAYS_LEFT" -lt 0 ]; then
    echo "🚨 CRITICAL: GitHub Token 已过期 $(( -DAYS_LEFT )) 天！请立即更新！" >> "$LOG_FILE"
    echo "Token 已过期！"
fi
