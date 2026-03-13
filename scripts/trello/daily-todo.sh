#!/bin/bash
# 每天早上获取 Trello 今日待办并发送到飞书
# 需要设置环境变量: TRELLO_API_KEY, TRELLO_TOKEN

if [ -z "$TRELLO_API_KEY" ] || [ -z "$TRELLO_TOKEN" ]; then
    echo "错误: 请设置环境变量 TRELLO_API_KEY 和 TRELLO_TOKEN"
    exit 1
fi

BOARD_ID="64395dc243cb44e9c525a586"

# 获取今日待办列表ID
TODAY_LIST_ID=$(curl -s "https://api.trello.com/1/boards/$BOARD_ID/lists?key=$TRELLO_API_KEY&token=$TRELLO_TOKEN" | jq -r '.[] | select(.name | contains("今日待办")) | .id')

# 获取今日待办卡片
cards=$(curl -s "https://api.trello.com/1/lists/$TODAY_LIST_ID/cards?key=$TRELLO_API_KEY&token=$TRELLO_TOKEN&fields=name,labels,due")

# 格式化输出
echo "📋 今日待办 ($(date '+%Y-%m-%d'))"
echo ""
echo "$cards" | jq -r '.[] | "• " + .name'
