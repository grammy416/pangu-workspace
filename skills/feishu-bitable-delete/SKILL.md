---
name: feishu-bitable-delete
description: 删除飞书多维表（Bitable）应用 - 当前需手动操作
---

# 飞书多维表删除工具

## ⚠️ 重要说明

**当前限制**：飞书开放平台暂未提供稳定的多维表删除 API，或需要特殊企业权限。

**建议操作**：使用飞书客户端手动删除。

---

## 手动删除步骤

### 步骤 1：打开多维表
访问链接：https://ucn9nqrs2gw7.feishu.cn/base/Vf0ebRTnfaEQiGswg5FcChytnNd

### 步骤 2：进入设置
1. 点击右上角 **「...」**（更多菜单）
2. 选择 **「设置」**

### 步骤 3：删除应用
1. 滚动到页面底部
2. 点击 **「删除应用」** 或 **「删除多维表」**
3. 输入确认码（如要求）
4. 点击确认删除

---

## API 尝试（如未来开放）

### 端点
```
DELETE https://open.feishu.cn/open-apis/bitable/v1/apps/{app_token}
```

### 权限要求
- `bitable:app` - 多维表应用管理权限

### 参数
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `app_token` | string | 是 | 多维表应用 Token |

---

## ⚠️ 注意事项

1. **不可恢复** - 删除后数据永久丢失，请谨慎操作
2. **权限检查** - 只有应用所有者或管理员可删除
3. **关联数据** - 删除应用会同时删除所有表格和数据
4. **协作者影响** - 其他协作者将失去访问权限

---

## 获取 App Token

从多维表 URL 中提取：
- URL: `https://xxx.feishu.cn/base/Vf0ebRTnfaEQiGswg5FcChytnNd`
- App Token: `Vf0ebRTnfaEQiGswg5FcChytnNd`

---

*此技能由盘古创建 - 当前版本建议手动删除*