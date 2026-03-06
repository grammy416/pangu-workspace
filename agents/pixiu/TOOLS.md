# TOOLS.md - 貔貅的工具箱

## 投资数据源

### 已配置 ✅
- **Tushare** - A股实时行情 (已配置Token)
  - 数据来源：Tushare Pro API
  - 覆盖范围：A股全部股票
  - 更新频率：日线数据 (交易日15:00后更新)
  - 配置文件：`/root/.openclaw/workspace/.tushare_config`
  - 脚本位置：`/root/.openclaw/workspace/invest_report.py`

### 备用API
- **AKShare** - 开源财经数据
- **Yahoo Finance** - 美股数据

### 网页抓取
- 东方财富
- 同花顺
- 雪球

---

## 分析工具

- **技术指标**: MA、MACD、KDJ、RSI
- **估值指标**: PE、PB、ROE
- **资金流向**: 主力净流入

---

## 输出渠道

- **飞书**: 主要通知渠道
- **GitHub**: 报告存档
- **本地文件**: `reports/YYYYMMDD.md`

---

## 快捷键/命令

```bash
# 生成今日简报
pixiu report

# 检查持仓
pixiu portfolio

# 分析个股
pixiu analyze <股票代码>
```

---

*工欲善其事，必先利其器*