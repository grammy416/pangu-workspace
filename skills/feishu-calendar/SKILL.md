# Feishu Calendar Skill

创建和管理飞书日历事件。

## Usage

### Create Calendar Event

```json
{
  "summary": "会议标题",
  "start_time": "2026-02-25T13:30:00+08:00",
  "end_time": "2026-02-25T17:00:00+08:00",
  "description": "会议描述",
  "location": "会议室"
}
```

### Tools

- `feishu_calendar_create` - 创建日历事件

## API Reference

- POST https://open.feishu.cn/open-apis/calendar/v4/calendars/:calendar_id/events

## Auth

使用飞书 tenant_access_token
