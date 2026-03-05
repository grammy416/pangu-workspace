#!/usr/bin/env python3
"""
投资简报数据获取脚本
用于定时任务获取持仓和市场数据
"""

import os
import json
from datetime import datetime, timedelta

def get_token():
    """获取 Tushare Token"""
    token = os.environ.get('TUSHARE_TOKEN')
    if token:
        return token
    
    config_path = os.path.expanduser('~/.openclaw/workspace/.tushare_config')
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            for line in f:
                if line.startswith('TUSHARE_TOKEN='):
                    return line.split('=', 1)[1].strip()
    return None

def init_tushare():
    """初始化 Tushare"""
    import tushare as ts
    token = get_token()
    if not token:
        raise ValueError("未找到 TUSHARE_TOKEN")
    ts.set_token(token)
    return ts.pro_api()

def get_portfolio_data(pro, portfolio_file='portfolio/portfolio.json'):
    """获取投资组合数据并更新实时行情"""
    portfolio_path = os.path.expanduser(f'~/.openclaw/workspace/{portfolio_file}')
    
    if not os.path.exists(portfolio_path):
        return None
    
    with open(portfolio_path, 'r', encoding='utf-8') as f:
        portfolio = json.load(f)
    
    # 获取今日日期
    today = datetime.now().strftime('%Y%m%d')
    
    # 更新持仓实时价格
    for holding in portfolio.get('holdings', []):
        ts_code = holding.get('code')
        if ts_code:
            try:
                # 获取最新日线数据
                df = pro.daily(ts_code=ts_code, trade_date=today)
                if not df.empty:
                    holding['current_price'] = float(df.iloc[0]['close'])
                    holding['change_pct'] = float(df.iloc[0]['pct_chg'])
                    
                    # 计算盈亏
                    cost = holding.get('cost_price', 0)
                    qty = holding.get('quantity', 0)
                    current = holding['current_price']
                    holding['profit'] = (current - cost) * qty
                    holding['profit_pct'] = ((current - cost) / cost * 100) if cost > 0 else 0
            except Exception as e:
                print(f"获取 {ts_code} 数据失败: {e}")
                continue
    
    return portfolio

def get_market_indices(pro):
    """获取主要指数行情"""
    today = datetime.now().strftime('%Y%m%d')
    indices = {}
    
    index_map = {
        '000001.SH': '上证指数',
        '399001.SZ': '深证成指',
        '399006.SZ': '创业板指',
        '000300.SH': '沪深300',
        '000016.SH': '上证50',
        '399675.SZ': '创业板50'
    }
    
    for code, name in index_map.items():
        try:
            df = pro.index_daily(ts_code=code, trade_date=today)
            if not df.empty:
                indices[name] = {
                    'close': float(df.iloc[0]['close']),
                    'change': float(df.iloc[0]['change']),
                    'change_pct': float(df.iloc[0]['pct_chg'])
                }
        except Exception as e:
            print(f"获取 {name} 失败: {e}")
            continue
    
    return indices

def format_report(portfolio, indices):
    """格式化投资简报"""
    lines = []
    lines.append("📊 **投资市场简报** | " + datetime.now().strftime('%Y年%m月%d日'))
    lines.append("")
    
    # 大盘指数
    lines.append("**📈 大盘指数**")
    for name, data in indices.items():
        emoji = "📈" if data['change_pct'] >= 0 else "📉"
        lines.append(f"{emoji} {name}: {data['close']:.2f} ({data['change']:+.2f}, {data['change_pct']:+.2f}%)")
    lines.append("")
    
    # 持仓概览
    if portfolio:
        lines.append("**💼 持仓概览**")
        total_value = portfolio.get('total_value', 0)
        cash = portfolio.get('cash', 0)
        total_assets = portfolio.get('total_assets', total_value + cash)
        
        lines.append(f"总资产: ¥{total_assets:,.2f}")
        lines.append(f"持仓市值: ¥{total_value:,.2f}")
        lines.append(f"现金: ¥{cash:,.2f}")
        lines.append("")
        
        # 持仓明细
        lines.append("**📋 持仓明细**")
        for h in portfolio.get('holdings', []):
            name = h.get('name', '未知')
            code = h.get('code', '')
            qty = h.get('quantity', 0)
            cost = h.get('cost_price', 0)
            current = h.get('current_price', cost)
            profit_pct = h.get('profit_pct', 0)
            
            emoji = "📈" if profit_pct >= 0 else "📉"
            lines.append(f"{emoji} {name}({code}): {current:.2f} | 盈亏: {profit_pct:+.2f}%")
    
    return '\n'.join(lines)

if __name__ == '__main__':
    try:
        pro = init_tushare()
        print("✅ Tushare 连接成功")
        
        # 获取数据
        indices = get_market_indices(pro)
        portfolio = get_portfolio_data(pro)
        
        # 输出简报
        report = format_report(portfolio, indices)
        print(report)
        
        # 保存简报到文件（供其他脚本使用）
        report_file = os.path.expanduser('~/.openclaw/workspace/latest_market_report.txt')
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n📄 简报已保存至: {report_file}")
        
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
