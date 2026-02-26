# Notion Calendar Skill

通过 Notion API 管理日历事件。

## 配置

在 `~/.openclaw/credentials/notion.json` 添加：
```json
{
  "token": "secret_xxx",
  "database_id": "xxx"
}
```

## 功能

### 创建事件
```bash
curl -X POST https://api.notion.com/v1/pages \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -d '{
    "parent": { "database_id": "'$DATABASE_ID'" },
    "properties": {
      "Name": { "title": [{ "text": { "content": "事件名称" } }] },
      "Date": { "date": { "start": "2026-02-25T14:00:00", "end": "2026-02-25T17:00:00" } },
      "Status": { "select": { "name": "待办" } },
      "Type": { "select": { "name": "工作" } }
    }
  }'
```

### 查询今日事件
```bash
curl -X POST https://api.notion.com/v1/databases/$DATABASE_ID/query \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -d '{
    "filter": {
      "and": [
        { "property": "Date", "date": { "on_or_after": "2026-02-25" } },
        { "property": "Date", "date": { "before": "2026-02-26" } }
      ]
    }
  }'
```

### 更新事件
```bash
curl -X PATCH https://api.notion.com/v1/pages/$PAGE_ID \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -d '{
    "properties": {
      "Status": { "select": { "name": "已完成" } }
    }
  }'
```

### 删除事件（归档）
```bash
curl -X PATCH https://api.notion.com/v1/pages/$PAGE_ID \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -d '{"archived": true}'
```

## 使用场景

- 日程管理：创建、修改、删除事件
- 任务追踪：状态更新、进度记录
- 知识库：会议笔记关联到日历事件

## 文档

- [Notion API 文档](https://developers.notion.com/)
