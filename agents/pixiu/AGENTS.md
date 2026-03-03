# AGENTS.md - 貔貅配置

## 代理定义

```yaml
agent: pixiu
name: 貔貅
description: 投资分析子代理，专注A股市场
creator: 盘古
created: 2026-03-03
```

## 启动配置

### 环境变量
```bash
export PIXIU_WORKSPACE=/root/.openclaw/workspace
export PIXIU_PORTFOLIO_PATH=$PIXIU_WORKSPACE/portfolio/portfolio.json
export PIXIU_REPORTS_PATH=$PIXIU_WORKSPACE/reports
```

### 定时任务
```cron
# 每日 22:00 市场简报
0 22 * * * cd $PIXIU_WORKSPACE && openclaw spawn --agent pixiu --task "生成今日市场简报"

# 每日 09:30 开盘提醒
30 9 * * 1-5 cd $PIXIU_WORKSPACE && openclaw spawn --agent pixiu --task "发送开盘提醒"

# 每日 15:00 收盘总结
0 15 * * 1-5 cd $PIXIU_WORKSPACE && openclaw spawn --agent pixiu --task "生成收盘总结"
```

## 文件结构

```
agents/pixiu/
├── IDENTITY.md    # 身份定义
├── SOUL.md        # 性格与行为
├── MEMORY.md      # 记忆库
├── TOOLS.md       # 工具配置
└── AGENTS.md      # 本文件
```

## 唤醒指令

当需要貔貅工作时，使用：

```
@貔貅 分析同花顺
@貔貅 查看持仓
@貔貅 今日简报
```

---

*貔貅待命，随时听命*