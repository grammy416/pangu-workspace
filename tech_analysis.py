#!/usr/bin/env python3
import urllib.request
import json
import sys

def get_kline_data(code, days=60):
    '''获取K线数据'''
    try:
        market = '0' if code.startswith('3') or code.startswith('0') else '1'
        url = f'https://quotes.sina.cn/cn/api/quotes.php?symbol={market}{code}&scale=240&ma=5&datalen={days}'
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = response.read().decode('utf-8')
            if 'data:' in data:
                json_str = data.split('data:')[1].strip()
                if json_str.endswith(')'):
                    json_str = json_str[:-1]
                if json_str.endswith(';'):
                    json_str = json_str[:-1]
                return json.loads(json_str)
    except Exception as e:
        return None
    return None

def calculate_ma(prices, period):
    '''计算移动平均线'''
    if len(prices) < period:
        return None
    return sum(prices[-period:]) / period

def calculate_macd(prices, fast=12, slow=26, signal=9):
    '''计算MACD指标'''
    if len(prices) < slow:
        return None, None, None
    
    ema_fast = [prices[0]]
    ema_slow = [prices[0]]
    
    for price in prices[1:]:
        ema_fast.append(price * (2/(fast+1)) + ema_fast[-1] * (1 - 2/(fast+1)))
        ema_slow.append(price * (2/(slow+1)) + ema_slow[-1] * (1 - 2/(slow+1)))
    
    macd_line = [f - s for f, s in zip(ema_fast, ema_slow)]
    
    signal_line = [macd_line[0]]
    for val in macd_line[1:]:
        signal_line.append(val * (2/(signal+1)) + signal_line[-1] * (1 - 2/(signal+1)))
    
    histogram = [m - s for m, s in zip(macd_line, signal_line)]
    
    return macd_line[-1], signal_line[-1], histogram[-1]

def analyze_stock(code, name):
    '''分析单只股票'''
    data = get_kline_data(code, 60)
    if not data:
        return None
    
    closes = [d['c'] for d in data]
    current_price = closes[-1]
    
    ma5 = calculate_ma(closes, 5)
    ma20 = calculate_ma(closes, 20)
    ma60 = calculate_ma(closes, 60)
    
    macd, signal, hist = calculate_macd(closes)
    
    return {
        'name': name,
        'code': code,
        'price': current_price,
        'ma5': ma5,
        'ma20': ma20,
        'ma60': ma60,
        'macd': macd,
        'signal': signal,
        'hist': hist
    }

stocks = [
    ('002594', '比亚迪'),
    ('300750', '宁德时代'),
    ('601127', '塞力斯'),
    ('601633', '长城汽车'),
    ('002709', '天赐材料'),
    ('002812', '恩捷股份'),
    ('300014', '亿纬锂能'),
    ('002466', '天齐锂业'),
    ('002460', '赣锋锂业'),
]

print('=== 新能源汽车股技术分析（双均线 + MACD）===\n')

results = []
for code, name in stocks:
    result = analyze_stock(code, name)
    if result:
        price = result['price']
        ma5, ma20, ma60 = result['ma5'], result['ma20'], result['ma60']
        macd, signal, hist = result['macd'], result['signal'], result['hist']
        
        # MACD信号
        if hist > 0.1:
            macd_signal = '金叉区'
        elif hist < -0.1:
            macd_signal = '死叉区'
        else:
            macd_signal = '零轴附近'
        
        # 双均线信号
        if ma5 > ma20:
            ma_signal = '短期多头'
        else:
            ma_signal = '短期空头'
        
        # 综合建议
        if ma5 > ma20 and hist > 0:
            suggestion = '买入'
        elif ma5 < ma20 and hist < 0:
            suggestion = '观望'
        else:
            suggestion = '持有观察'
        
        print(f"股票: {name} ({code})")
        print(f"  现价: {price:.2f}")
        print(f"  MA5: {ma5:.2f} | MA20: {ma20:.2f} | MA60: {ma60:.2f}")
        print(f"  MACD: {macd:.4f} | 信号: {macd_signal} | 柱状: {hist:.4f}")
        print(f"  均线信号: {ma_signal}")
        print(f"  建议: {suggestion}")
        print()
        results.append((result, suggestion))
    else:
        print(f"{name} ({code}): 数据获取失败\n")
