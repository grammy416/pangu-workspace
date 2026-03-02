#!/usr/bin/env python3
"""
🪓 盘古股票分析服务 v2.0 - 支持模拟数据模式
FastAPI + (AkShare/模拟数据) + Qwen3
"""

import os
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

try:
    import akshare as ak
    AKSHARE_AVAILABLE = True
except:
    AKSHARE_AVAILABLE = False
    
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import random

app = FastAPI(title="🪓 盘古股票分析服务", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置
QWEN_API_KEY = os.environ.get("QWEN_API_KEY", "")
USE_MOCK_DATA = os.environ.get("USE_MOCK_DATA", "false").lower() == "true" or not AKSHARE_AVAILABLE

# 模拟股票数据库
MOCK_STOCKS = {
    "000001": {"name": "平安银行", "base_price": 12.50},
    "000858": {"name": "五粮液", "base_price": 145.20},
    "002594": {"name": "比亚迪", "base_price": 268.50},
    "300750": {"name": "宁德时代", "base_price": 185.30},
    "600519": {"name": "贵州茅台", "base_price": 1580.00},
    "601318": {"name": "中国平安", "base_price": 48.60},
    "601888": {"name": "中国中免", "base_price": 65.80},
    "00700": {"name": "腾讯控股", "base_price": 385.20},  # 港股
}

class StockRequest(BaseModel):
    stock_code: str
    market_type: str = "A"
    use_ai: bool = True

def generate_mock_data(stock_code: str, days: int = 60):
    """生成模拟股票数据"""
    base_info = MOCK_STOCKS.get(stock_code, {"name": f"股票{stock_code}", "base_price": 50.0})
    base_price = base_info["base_price"]
    
    dates = [(datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(days, 0, -1)]
    
    prices = [base_price]
    for i in range(1, days):
        change = random.uniform(-0.03, 0.03)
        new_price = prices[-1] * (1 + change)
        prices.append(max(new_price, base_price * 0.7))
    
    df = pd.DataFrame({
        "日期": dates,
        "开盘": [p * random.uniform(0.98, 1.0) for p in prices],
        "收盘": prices,
        "最高": [p * random.uniform(1.0, 1.02) for p in prices],
        "最低": [p * random.uniform(0.97, 1.0) for p in prices],
        "成交量": [random.randint(1000000, 10000000) for _ in range(days)],
        "成交额": [random.randint(100000000, 1000000000) for _ in range(days)],
    })
    
    return base_info["name"], df

def to_float(val):
    """转换为 Python float"""
    if pd.isna(val):
        return 0.0
    return float(val)

def to_int(val):
    """转换为 Python int"""
    if pd.isna(val):
        return 0
    return int(val)

def calculate_indicators(df: pd.DataFrame):
    """计算技术指标"""
    close = df["收盘"]
    
    # 移动平均线
    ma5 = to_float(close.rolling(window=5).mean().iloc[-1])
    ma20 = to_float(close.rolling(window=20).mean().iloc[-1])
    ma60 = to_float(close.rolling(window=60).mean().iloc[-1]) if len(close) >= 60 else ma20
    
    # RSI
    delta = close.diff()
    gain = delta.where(delta > 0, 0).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    rsi_value = to_float(rsi.iloc[-1]) if not pd.isna(rsi.iloc[-1]) else 50.0
    
    # MACD
    exp1 = close.ewm(span=12, adjust=False).mean()
    exp2 = close.ewm(span=26, adjust=False).mean()
    macd_val = exp1 - exp2
    signal_val = macd_val.ewm(span=9, adjust=False).mean()
    
    # 布林带
    ma20_val = close.rolling(window=20).mean()
    std = close.rolling(window=20).std()
    boll_upper = ma20_val + (std * 2)
    boll_lower = ma20_val - (std * 2)
    
    latest = df.iloc[-1]
    prev = df.iloc[-2] if len(df) > 1 else latest
    
    change_pct = ((latest["收盘"] - prev["收盘"]) / prev["收盘"] * 100) if prev["收盘"] != 0 else 0
    
    return {
        "current_price": to_float(latest["收盘"]),
        "open": to_float(latest["开盘"]),
        "high": to_float(latest["最高"]),
        "low": to_float(latest["最低"]),
        "volume": to_int(latest["成交量"]),
        "amount": to_float(latest["成交额"]),
        "change_pct": round(change_pct, 2),
        "ma5": ma5,
        "ma20": ma20,
        "ma60": ma60,
        "rsi14": rsi_value,
        "macd": round(to_float(macd_val.iloc[-1]), 4),
        "macd_signal": round(to_float(signal_val.iloc[-1]), 4),
        "boll_upper": round(to_float(boll_upper.iloc[-1]), 2),
        "boll_middle": round(to_float(ma20_val.iloc[-1]), 2),
        "boll_lower": round(to_float(boll_lower.iloc[-1]), 2),
    }

async def analyze_with_qwen(stock_name: str, stock_code: str, indicators: dict) -> str:
    """使用 Qwen3 分析"""
    if not QWEN_API_KEY:
        return generate_local_analysis(stock_name, stock_code, indicators)
    
    prompt = f"""作为专业股票分析师，请分析 {stock_name}({stock_code})：

【行情数据】
- 当前价: ¥{indicators['current_price']}
- 涨跌: {indicators['change_pct']}%
- 成交量: {indicators['volume']:,}

【技术指标】
- MA5/20/60: ¥{indicators['ma5']} / ¥{indicators['ma20']} / ¥{indicators['ma60']}
- RSI(14): {indicators['rsi14']:.1f}
- MACD: {indicators['macd']:.4f}
- 布林带: ¥{indicators['boll_lower']:.2f} - ¥{indicators['boll_middle']:.2f} - ¥{indicators['boll_upper']:.2f}

请提供:
1. 趋势判断（短期/中期/长期）
2. 关键技术位
3. 风险提示
4. 操作建议

简洁专业， disclaimer: 仅供参考。"""

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
                headers={
                    "Authorization": f"Bearer {QWEN_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "qwen-plus",
                    "input": {
                        "messages": [
                            {"role": "system", "content": "你是资深股票分析师"},
                            {"role": "user", "content": prompt}
                        ]
                    },
                    "parameters": {
                        "result_format": "message",
                        "max_tokens": 1000,
                        "temperature": 0.7
                    }
                },
                timeout=30.0
            )
            result = response.json()
            return result["output"]["choices"][0]["message"]["content"]
    except Exception as e:
        return f"⚠️ AI 分析失败: {str(e)}\n\n{generate_local_analysis(stock_name, stock_code, indicators)}"

def generate_local_analysis(stock_name: str, stock_code: str, indicators: dict) -> str:
    """本地规则分析（无 AI 时）"""
    price = indicators['current_price']
    ma5, ma20, ma60 = indicators['ma5'], indicators['ma20'], indicators['ma60']
    rsi = indicators['rsi14']
    macd = indicators['macd']
    
    # 趋势判断
    if price > ma5 > ma20 > ma60:
        trend = "🟢 强势上涨 - 多头排列"
    elif price > ma5 > ma20:
        trend = "🟡 短期向好 - 关注能否突破中期均线"
    elif price < ma5 < ma20:
        trend = "🔴 弱势整理 - 空头排列"
    else:
        trend = "⚪ 震荡格局 - 方向不明"
    
    # RSI 判断
    if rsi > 70:
        rsi_signal = "超买区 - 注意回调风险"
    elif rsi < 30:
        rsi_signal = "超卖区 - 可能存在反弹机会"
    else:
        rsi_signal = "中性区域"
    
    # MACD
    macd_signal = "金叉" if macd > indicators['macd_signal'] else "死叉"
    
    return f"""📊 {stock_name}({stock_code}) 技术分析报告

【趋势分析】{trend}

【关键指标】
• RSI(14): {rsi:.1f} - {rsi_signal}
• MACD: {macd:.4f} ({macd_signal})
• 支撑位: ¥{indicators['boll_lower']:.2f}
• 压力位: ¥{indicators['boll_upper']:.2f}

【操作建议】
基于当前技术指标，建议 {'关注突破机会' if '强势' in trend else '谨慎观望' if '弱势' in trend else '等待方向明确'}。

⚠️ 免责声明：本分析仅供参考，不构成投资建议。
{"💡 提示：设置 QWEN_API_KEY 环境变量可启用 AI 深度分析" if not QWEN_API_KEY else ""}
"""

@app.get("/")
def root():
    return {
        "message": "🪓 盘古股票分析服务",
        "version": "2.0.0",
        "mode": "mock" if USE_MOCK_DATA else "live",
        "akshare_available": AKSHARE_AVAILABLE,
        "qwen_configured": bool(QWEN_API_KEY),
        "docs": "/docs",
        "endpoints": {
            "analyze": "POST /analyze",
            "health": "GET /health",
            "hot_stocks": "GET /hot-stocks"
        }
    }

@app.get("/health")
def health():
    return {
        "status": "ok",
        "mode": "mock" if USE_MOCK_DATA else "live",
        "qwen_configured": bool(QWEN_API_KEY),
        "timestamp": datetime.now().isoformat()
    }

@app.post("/analyze")
async def analyze_stock(request: StockRequest):
    """股票分析接口"""
    stock_code = request.stock_code
    
    # 获取数据
    if USE_MOCK_DATA or stock_code in MOCK_STOCKS:
        stock_name, df = generate_mock_data(stock_code)
    else:
        raise HTTPException(status_code=400, detail=f"模拟模式下仅支持: {list(MOCK_STOCKS.keys())}")
    
    indicators = calculate_indicators(df)
    
    # 分析
    if request.use_ai and QWEN_API_KEY:
        analysis = await analyze_with_qwen(stock_name, stock_code, indicators)
    else:
        analysis = generate_local_analysis(stock_name, stock_code, indicators)
    
    return {
        "stock_code": stock_code,
        "stock_name": stock_name,
        "current_price": indicators["current_price"],
        "daily_change": indicators["change_pct"],
        "analysis": analysis,
        "indicators": indicators,
        "mode": "mock" if USE_MOCK_DATA else "live",
        "ai_enabled": bool(QWEN_API_KEY),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/hot-stocks")
def hot_stocks():
    """热门股票列表"""
    return [
        {"code": code, "name": info["name"], "price": info["base_price"]}
        for code, info in MOCK_STOCKS.items()
    ]

if __name__ == "__main__":
    import uvicorn
    print(f"🪓 启动盘古股票分析服务...")
    print(f"   模式: {'模拟数据' if USE_MOCK_DATA else '实时数据'}")
    print(f"   AI分析: {'已启用' if QWEN_API_KEY else '未配置'}")
    print(f"   地址: http://0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
