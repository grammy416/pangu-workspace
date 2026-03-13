#!/bin/bash
# 每天早上获取 Trello 今日待办并发送到飞书
# 需要设置环境变量: TRELLO_API_KEY, TRELLO_TOKEN

if [ -z "$TRELLO_API_KEY" ] || [ -z "$TRELLO_TOKEN" ]; then
    echo "错误: 请设置环境变量 TRELLO_API_KEY 和 TRELLO_TOKEN"
    exit 1
fi

BOARD_ID="64395dc243cb44e9c525a586"
DATE=$(date '+%Y-%m-%d %a')

# 获取今日待办列表ID
TODAY_LIST_ID=$(curl -s "https://api.trello.com/1/boards/$BOARD_ID/lists?key=$TRELLO_API_KEY&token=$TRELLO_TOKEN" | jq -r '.[] | select(.name | contains("今日待办")) | .id')

# 获取今日待办卡片
cards=$(curl -s "https://api.trello.com/1/lists/$TODAY_LIST_ID/cards?key=$TRELLO_API_KEY&token=$TRELLO_TOKEN&fields=name,labels,due,desc")

# 统计数量
count=$(echo "$cards" | jq 'length')

# 生成报告
report="📋 **今日待办 - $DATE**

**共 $count 项任务：**

"

if [ "$count" -eq 0 ]; then
  report="${report}✨ 今日暂无待办任务，可以休息一下！"
else
  # 格式化每个卡片
  while IFS= read -r card; do
    name=$(echo "$card" | jq -r '.name')
    labels=$(echo "$card" | jq -r '.labels | map(.name) | join(" ")')
    due=$(echo "$card" | jq -r '.due // "未设置"')
    
    if [ "$due" != "未设置" ] && [ "$due" != "null" ]; then
      due_time=$(echo "$due" | cut -d'T' -f2 | cut -d'.' -f1 | cut -d':' -f1,2)
      report="${report}• $name ⏰ $due_time"
    else
      report="${report}• $name"
    fi
    
    if [ "$labels" != "" ] && [ "$labels" != "null" ]; then
      report="${report} $labels"
    fi
    
    report="${report}
"
  done < <(echo "$cards" | jq -c '.[]')
fi

report="${report}

---
💡 **GTD 提示：**
• 早上从 📥 收件箱 筛选任务到 🔥 今日待办
• 执行时拖到 🎯 进行中
• 完成后拖到 ✅ 已完成

[查看看板](https://trello.com/b/LajVShqV)"

echo "$report"
