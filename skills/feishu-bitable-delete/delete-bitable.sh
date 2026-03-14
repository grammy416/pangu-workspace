#!/bin/bash
# 🗑️ 飞书多维表删除工具
# 用法: ./delete-bitable.sh <app_token>

set -e

APP_TOKEN="${1:-}"
FEISHU_TOKEN="${FEISHU_ACCESS_TOKEN:-$(cat ~/.openclaw/workspace/.secrets/feishu_token 2>/dev/null || echo '')}"

if [ -z "$APP_TOKEN" ]; then
    echo "❌ 错误: 请提供 app_token"
    echo "用法: $0 <app_token>"
    echo ""
    echo "示例:"
    echo "  $0 Vf0ebRTnfaEQiGswg5FcChytnNd"
    exit 1
fi

if [ -z "$FEISHU_TOKEN" ]; then
    echo "❌ 错误: 未设置飞书 Token"
    echo "请设置环境变量 FEISHU_ACCESS_TOKEN"
    exit 1
fi

echo "⚠️  警告: 即将删除多维表应用"
echo "App Token: $APP_TOKEN"
echo ""
echo "此操作不可恢复！"
echo ""
read -p "确认删除? 输入 'DELETE' 继续: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "已取消删除"
    exit 0
fi

echo ""
echo "🗑️  正在删除多维表..."

response=$(curl -s -X DELETE \
    "https://open.feishu.cn/open-apis/bitable/v1/apps/$APP_TOKEN" \
    -H "Authorization: Bearer $FEISHU_TOKEN" \
    -H "Content-Type: application/json")

echo "响应: $response"

# 解析响应
if echo "$response" | grep -q '"code":0'; then
    echo ""
    echo "✅ 多维表删除成功！"
    exit 0
else
    echo ""
    echo "❌ 删除失败"
    echo "请检查:"
    echo "  1. Token 是否有 bitable:app 权限"
    echo "  2. 是否为应用所有者或管理员"
    echo "  3. App Token 是否正确"
    exit 1
fi
