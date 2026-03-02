#!/bin/bash
# 🪓 后台技能安装脚本
# 创建时间: 2026-03-02 19:52

set -e

WORKSPACE="/root/.openclaw/workspace"
LOG="$WORKSPACE/.install-log"

cd "$WORKSPACE"

echo "[$$(date '+%Y-%m-%d %H:%M:%S')] 开始后台安装..." >> "$LOG"

# 安装 skill-vetter
echo "[$$(date '+%H:%M:%S')] 尝试安装 skill-vetter..." >> "$LOG"
if clawhub install skill-vetter 2>&1 >> "$LOG"; then
    echo "[$$(date '+%H:%M:%S')] ✅ skill-vetter 安装成功" >> "$LOG"
    /usr/local/bin/openclaw message send --channel feishu --message "✅ skill-vetter 安装成功！"
else
    echo "[$$(date '+%H:%M:%S')] ❌ skill-vetter 失败，120秒后重试..." >> "$LOG"
    sleep 120
    if clawhub install skill-vetter 2>&1 >> "$LOG"; then
        echo "[$$(date '+%H:%M:%S')] ✅ skill-vetter 安装成功（重试）" >> "$LOG"
        /usr/local/bin/openclaw message send --channel feishu --message "✅ skill-vetter 安装成功（重试）！"
    else
        echo "[$$(date '+%H:%M:%S')] ❌ skill-vetter 最终失败" >> "$LOG"
    fi
fi

# 间隔 120 秒
sleep 120

# 安装 feishu-wiki
echo "[$$(date '+%H:%M:%S')] 尝试安装 feishu-wiki..." >> "$LOG"
if clawhub install feishu-wiki 2>&1 >> "$LOG"; then
    echo "[$$(date '+%H:%M:%S')] ✅ feishu-wiki 安装成功" >> "$LOG"
    /usr/local/bin/openclaw message send --channel feishu --message "✅ feishu-wiki 安装成功！"
else
    echo "[$$(date '+%H:%M:%S')] ❌ feishu-wiki 失败，120秒后重试..." >> "$LOG"
    sleep 120
    if clawhub install feishu-wiki 2>&1 >> "$LOG"; then
        echo "[$$(date '+%H:%M:%S')] ✅ feishu-wiki 安装成功（重试）" >> "$LOG"
        /usr/local/bin/openclaw message send --channel feishu --message "✅ feishu-wiki 安装成功（重试）！"
    else
        echo "[$$(date '+%H:%M:%S')] ❌ feishu-wiki 最终失败" >> "$LOG"
        /usr/local/bin/openclaw message send --channel feishu --message "⚠️ feishu-wiki 安装失败，请手动尝试"
    fi
fi

echo "[$$(date '+%H:%M:%S')] 后台安装任务完成" >> "$LOG"
