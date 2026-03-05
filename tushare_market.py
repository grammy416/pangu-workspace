#!/usr/bin/env python3
"""
Tushare 市场数据获取脚本
用于定时任务获取 A 股实时行情
"""

import os
import sys
import json
from datetime import datetime, timedelta

# 配置 Token
def get_token():
    """从环境变量或配置文件获取 Token"""
    token = os.environ.get('TUSHARE_TOKEN')
    if token:
        return token
    
    # 尝试从配置文件读取
    config_path = os.path.expanduser('~/.tushare_config')
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            for line in f:
                if line.startswith('TUSHARE_TOKEN='):
                    return line.split('=', 1)[1].strip()
    
    return None

def init_tushare():
    """初始化 Tushare API"""
    import tushare as ts
    token = get_token()
    if not token:
        raise ValueError("未找到 TUSHARE_TOKEN，请配置环境变量或 ~/.tushare_config")
    
    ts.set_token(token)
    return ts.pro_api()

def get_market_overview(pro):
    """获取大盘指数行情"""
    today = datetime.now().strftime('%Y%m%d')
    
    # 获取主要指数
    index_codes = ['000001.SH', '399001.SZ', '399006.SZ', '000300.SH', '000016.SH']
    
    try:
        df = pro.index_daily(ts_code=','.join(index_codes), trade_date=today)
        return df.to_dict('records')
    except Exception as e:
        print(f"获取指数数据失败: {e}")
        return None

def get_stock_snapshot(pro, ts_code):
    """获取个股实时快照"""
    try:
        df = pro.daily(ts_code=ts_code, trade_date=datetime.now().strftime('%Y%m%d'))
        return df.to_dict('records')[0] if not df.empty else None
    except Exception as e:
        print(f"获取个股数据失败: {e}")
        return None

def get_stock_basic(pro):
    """获取股票基础信息"""
    try:
        df = pro.stock_basic(exchange='', list_status='L')
        return df[['ts_code', 'name', 'industry', 'market']].to_dict('records')
    except Exception as e:
        print(f"获取股票列表失败: {e}")
        return None

def format_market_report(data):
    """格式化市场报告"""
    if not data:
        return "暂无数据"
    
    report = []
    report.append("📊 A股大盘行情")
    report.append("-" * 40)
    
    index_names = {
        '000001.SH': '上证指数',
        '399001.SZ': '深证成指', 
        '399006.SZ': '创业板指',
        '000300.SH': '沪深300',
        '000016.SH': '上证50'
    }
    
    for item in data:
        name = index_names.get(item['ts_code'], item['ts_code'])
        close = item.get('close', 0)
        pct_change = item.get('pct_change', 0)
        change = item.get('change', 0)
        
        emoji = "📈" if pct_change >= 0 else "📉"
        report.append(f"{emoji} {name}: {close:.2f} ({change:+.2f}, {pct_change:+.2f}%)")
    
    return '\n'.join(report)

if __name__ == '__main__':
    # 测试连接
    try:
        pro = init_tushare()
        print("✅ Tushare 连接成功！")
        
        # 获取今日日期
        today = datetime.now().strftime('%Y%m%d')
        print(f"\n当前日期: {today}")
        
        # 获取股票列表（仅前5条）
        stocks = pro.stock_basic(exchange='', list_status='L')
        print(f"\n📋 A股总数: {len(stocks)} 只")
        print("\n示例股票:")
        for _, row in stocks.head(5).iterrows():
            print(f"  {row['ts_code']} - {row['name']} ({row['industry']})")
        
        # 获取今日大盘数据
        print("\n" + "="*40)
        market_data = get_market_overview(pro)
        if market_data:
            print(format_market_report(market_data))
        else:
            print("⏳ 今日数据可能尚未更新，请稍后重试")
            
    except Exception as e:
        print(f"❌ 错误: {e}")
        sys.exit(1)
