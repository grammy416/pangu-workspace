# 🔧 使用示例

## 方式一：直接脚本调用

```bash
# 设置 Token
export FEISHU_ACCESS_TOKEN="your_feishu_token"

# 执行删除
./delete-bitable.sh Vf0ebRTnfaEQiGswg5FcChytnNd
```

## 方式二：通过 OpenClaw exec

```bash
# 在 OpenClaw 工作空间执行
export FEISHU_ACCESS_TOKEN=$(cat .secrets/feishu_token)

curl -X DELETE \
  "https://open.feishu.cn/open-apis/bitable/v1/apps/Vf0ebRTnfaEQiGswg5FcChytnNd" \
  -H "Authorization: Bearer $FEISHU_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

## 方式三：作为 OpenClaw 工具扩展

在 `config.yaml` 中添加：

```yaml
channels:
  feishu:
    tools:
      bitable_delete: true
```

---

## ⚠️ 重要提示

删除前请确认：
1. ✅ 已备份重要数据
2. ✅ 通知其他协作者
3. ✅ 确认 App Token 正确

---

## 获取 App Token

从多维表 URL 中提取：
- URL: `https://xxx.feishu.cn/base/Vf0ebRTnfaEQiGswg5FcChytnNd`
- App Token: `Vf0ebRTnfaEQiGswg5FcChytnNd`
