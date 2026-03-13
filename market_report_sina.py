#!/usr/bin/env python3
import requests
import json
from datetime import datetime

# 新浪财经API - 获取实时行情
def get_sina_stock_realtime(stock_codes):
    """获取新浪财经实时行情"""
    sina_codes = []
    for code in stock_codes:
        if code.endswith('.SZ'):
            sina_codes.append(f'sz{code[:6]}')
        elif code.endswith('.SH'):
            sina_codes.append(f'sh{code[:6]}')
    
    codes_str = ','.join(sina_codes)
    url = f'https://hq.sinajs.cn/list={codes_str}'
    
    headers = {
        'Referer': 'https://finance.sina.com.cn',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.encoding = 'gb2312'
        return response.text
    except Exception as e:
        return f'Error: {e}'

def parse_sina_data(text):
    """解析新浪返回的数据"""
    stocks = {}
    for line in text.strip().split(';'):
        if 'hq_str_' in line and '=' in line:
            parts = line.split('=')
            if len(parts) >= 2:
                code_key = parts[0].replace('var hq_str_', '')
                data = parts[1].strip().strip('"')
                if data:
                    fields = data.split(',')
                    if len(fields) >= 33:
                        stocks[code_key] = {
                            'name': fields[0],
                            'open': float(fields[1]),
                            'prev_close': float(fields[2]),
                            'price': float(fields[3]),
                            'high': float(fields[4]),
                            'low': float(fields[5]),
                            'volume': int(fields[8]),
                            'amount': float(fields[9]),
                            'date': fields[30],
                            'time': fields[31]
                        }
    return stocks

# 持仓股票
holdings = [
    ('300033.SZ', '同花顺', 316.46, 900),
    ('300760.SZ', '迈瑞医疗', 245.307, 400),
    ('600276.SH', '恒瑞医药', 44.941, 1000),
    ('000001.SZ', '平安银行', 18.437, 2000),
    ('000063.SZ', '中兴通讯', 43.974, 500),
    ('159780.SZ', '科创创业50ETF', 1.002, 10000),
    ('000969.SZ', '安泰科技', 16.440, 500),
    ('600029.SH', '南方航空', 15.677, 100)
]

print('=' * 60)
print('📊 A股收盘简报（新浪财经实时数据）')
print('📅 日期时间: 2026-03-13 15:00:00')
print('=' * 60)
print()

# 获取持仓数据
stock_codes = [code for code, _, _, _ in holdings]
result = get_sina_stock_realtime(stock_codes)
stocks_data = parse_sina_data(result)

# 获取大盘指数数据
index_codes = ['000001.SH', '399001.SZ', '399006.SZ', '000688.SH', '000016.SH']
result_idx = get_sina_stock_realtime(index_codes)
index_data = parse_sina_data(result_idx)

# 显示大盘指数
print('【大盘指数】')
index_mapping = {
    'sh000001': '上证指数',
    'sz399001': '深证成指', 
    'sz399006': '创业板指',
    'sh000688': '科创50',
    'sh000016': '上证50'
}

for code, name in index_mapping.items():
    if code in index_data:
        d = index_data[code]
        change = d['price'] - d['prev_close']
        change_pct = (change / d['prev_close']) * 100
        trend = '📈' if change >= 0 else '📉'
        price_str = f"{d['price']:>8.2f}"
        change_str = f"{change:>+7.2f}"
        pct_str = f"{change_pct:>+5.2f}"
        print(f"{trend} {name}: {price_str} ({change_str}, {pct_str}%)")

print()

# 显示持仓股票
print('【持仓股票动态】')
total_cost = 0
total_value = 0
total_day_pnl = 0

for code, name, cost_price, shares in holdings:
    sina_code = code.replace('.SZ', '').replace('.SH', '')
    sina_code = f"sz{sina_code}" if code.endswith('.SZ') else f"sh{sina_code}"
    
    if sina_code in stocks_data:
        d = stocks_data[sina_code]
        price = d['price']
        prev_close = d['prev_close']
        
        change = price - prev_close
        change_pct = (change / prev_close) * 100
        
        cost_value = cost_price * shares
        curr_value = price * shares
        total_pnl = curr_value - cost_value
        total_pnl_pct = (total_pnl / cost_value) * 100
        day_pnl = change * shares
        
        total_cost += cost_value
        total_value += curr_value
        total_day_pnl += day_pnl
        
        trend = '📈' if change >= 0 else '📉'
        pnl_emoji = '✅' if total_pnl >= 0 else '❌'
        
        price_str = f"{price:>8.2f}"
        change_str = f"{change:>+6.2f}"
        pct_str = f"{change_pct:>+5.2f}"
        pnl_str = f"{total_pnl:>+10,.0f}"
        pnl_pct_str = f"{total_pnl_pct:>+5.1f}"
        
        print(f"{trend} {name:10s}: {price_str} ({change_str}, {pct_str}%) | 持仓盈亏: {pnl_emoji} {pnl_str} ({pnl_pct_str}%)")

print()

# 持仓汇总
if total_cost > 0:
    total_pnl = total_value - total_cost
    total_pnl_pct = (total_pnl / total_cost) * 100
    day_pnl_pct = (total_day_pnl / total_value) * 100 if total_value > 0 else 0
    pnl_emoji = '✅' if total_pnl >= 0 else '❌'
    day_emoji = '📈' if total_day_pnl >= 0 else '📉'
    
    print('【持仓汇总】')
    print(f"💰 总成本: {total_cost:>15,.2f}")
    print(f"💰 总市值: {total_value:>15,.2f}")
    print(f"{day_emoji} 今日盈亏: {total_day_pnl:>+14,.2f} ({day_pnl_pct:+.2f}%)")
    print(f"{pnl_emoji} 累计盈亏: {total_pnl:>+14,.2f} ({total_pnl_pct:+.2f}%)")

print()
print('=' * 60)
print('💡 数据来源: 新浪财经实时行情')
print('=' * 60)
