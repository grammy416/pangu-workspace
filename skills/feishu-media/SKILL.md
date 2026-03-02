---
name: feishu-media-send
description: 飞书图片和文件发送指南
---

# 飞书媒体发送指南

## 快速使用

### 发送图片
```json
{
  "action": "send",
  "filePath": "/path/to/image.png",
  "caption": "图片描述文字"
}
```

### 发送文件
```json
{
  "action": "send", 
  "filePath": "/path/to/document.pdf",
  "caption": "文件说明"
}
```

## 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `action` | string | 固定值 `"send"` |
| `filePath` | string | 本地文件绝对路径 |
| `caption` | string | 可选，图片/文件附带的文字说明 |

## 支持格式

### 图片
- PNG
- JPG/JPEG
- GIF
- WEBP

### 文件
- PDF
- DOC/DOCX
- XLS/XLSX
- PPT/PPTX
- 以及其他飞书支持格式

## 完整示例

### 发送头像
```
message action=send filePath=/root/.openclaw/workspace/pangu_avatar.png caption="盘古头像"
```

### 发送项目文档
```
message action=send filePath=/root/.openclaw/workspace/project.pdf caption="项目文档请查收"
```

## 注意事项

1. **文件大小限制**：单文件不超过 100MB
2. **路径要求**：使用绝对路径
3. **权限要求**：需要有对应会话的发送权限
4. **飞书限制**：部分文件类型可能需要转码

## 故障排除

### 发送失败可能原因
- 文件不存在 → 检查路径
- 文件过大 → 压缩后重试
- 权限不足 → 确认是否已加入群聊/好友
- 格式不支持 → 转换为常见格式

---

Created for 盘古 by 盘古
