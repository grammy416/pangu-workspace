#!/usr/bin/env python3
"""
🪓 盘古股票分析服务 - 替代 Dify 工作流
FastAPI + AkShare + Qwen3
"""

import os
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

import akshare as ak
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx

app = FastAPI(title="盘古股票分析服务", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置
QWEN_API_KEY = os.environ.get("QWEN_API_KEY", "")
QWEN_API_URL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

# 技术指标参数
PARAMS = {
    'ma_periods': {'short': 5, 'medium': 20, 'long': 60},
    'rsi_period': 14,
    'bollinger_period': 20,
    'bollinger_std': 2,
    'volume_ma_period': 20,
    'atr_period': 14
}

class StockRequest(BaseModel):
    stock_code: str  # 如: 000001 或 BILI
    market_type: str = "A"  # A/HK/US
    analysis_type: str = "full"  # full/technical/fundamental

class StockResponse(BaseModel):
    stock_code: str
    stock_name: str
    current_price: float
    daily_change: float
    analysis: str
    indicators: Dict[str, Any]
    timestamp: str


def calculate_ma(data: pd.Series, period: int) -> float:
    """计算移动平均线"""
    return data.rolling(window=period).mean().iloc[-1]

def calculate_rsi(data: pd.Series, period: int = 14) -> float:
    """计算 RSI 指标"""
    delta = data.diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi.iloc[-1]

def calculate_macd(data: pd.Series):
    """计算 MACD 指标"""
    exp1 = data.ewm(span=12, adjust=False).mean()
    exp2 = data.ewm(span=26, adjust=False).mean()
    macd = exp1 - exp2
    signal = macd.ewm(span=9, adjust=False).mean()
    histogram = macd - signal
    return macd.iloc[-1], signal.iloc[-1], histogram.iloc[-1]

def calculate_bollinger(data: pd.Series, period: int = 20, std: int = 2):
    """计算布林带"""
    ma = data.rolling(window=period).mean()
    std_dev = data.rolling(window=period).std()
    upper = ma + (std_dev * std)
    lower = ma - (std_dev * std)
    return upper.iloc[-1], ma.iloc[-1], lower.iloc[-1]

def get_stock_data_a(stock_code: str):
    """获取 A 股数据"""
    try:
        # 获取历史数据
        df = ak.stock_zh_a_hist(symbol=stock_code, period="daily", start_date=(datetime.now() - timedelta(days=90)).strftime("%Y%m%d"), end_date=datetime.now().strftime("%Y%m%d"), adjust="qfq")
        
        if df.empty:
            return None
        
        # 股票名称直接使用代码
        stock_name = f"A股{stock_code}"
        
        # 最新数据
        latest = df.iloc[-1]
        
        # 计算技术指标
        close = df["收盘"]
        high = df["最高"]
        low = df["最低"]
        volume = df["成交量"]
        
        indicators = {
            "current_price": float(latest["收盘"]),
            "open": float(latest["开盘"]),
            "high": float(latest["最高"]),
            "low": float(latest["最低"]),
            "volume": int(latest["成交量"]),
            "amount": float(latest["成交额"]),
            "change_pct": float(latest["涨跌幅"]) if "涨跌幅" in latest else 0,
            "ma5": float(calculate_ma(close, 5)),
            "ma20": float(calculate_ma(close, 20)),
            "ma60": float(calculate_ma(close, 60)),
            "rsi14": float(calculate_rsi(close, 14)),
            "macd": float(calculate_macd(close)[0]),
            "macd_signal": float(calculate_macd(close)[1]),
            "boll_upper": float(calculate_bollinger(close)[0]),
            "boll_middle": float(calculate_bollinger(close)[1]),
            "boll_lower": float(calculate_bollinger(close)[2]),
            "volume_ma20": float(calculate_ma(volume, 20))
        }
        
        return stock_name, indicators
    except Exception as e:
        print(f"Error getting A stock data: {e}")
        return None

def get_stock_data_hk(stock_code: str):
    """获取港股数据"""
    try:
        df = ak.stock_hk_hist(symbol=stock_code, period="daily", start_date=(datetime.now() - timedelta(days=90)).strftime("%Y%m%d"), end_date=datetime.now().strftime("%Y%m%d"))
        
        if df.empty:
            return None
        
        stock_name = f"港股{stock_code}"
        latest = df.iloc[-1]
        close = df["收盘"]
        volume = df["成交量"]
        
        indicators = {
            "current_price": float(latest["收盘"]),
            "open": float(latest["开盘"]),
            "high": float(latest["最高"]),
            "low": float(latest["最低"]),
            "volume": int(latest["成交量"]),
            "change_pct": float(latest["涨跌幅"]) if "涨跌幅" in latest else 0,
            "ma5": float(calculate_ma(close, 5)),
            "ma20": float(calculate_ma(close, 20)),
            "rsi14": float(calculate_rsi(close, 14))
        }
        
        return stock_name, indicators
    except Exception as e:
        print(f"Error getting HK stock data: {e}")
        return None

async def analyze_with_qwen(stock_name: str, indicators: dict, market_type: str) -> str:
    """使用 Qwen3 分析股票"""
    if not QWEN_API_KEY:
        return "⚠️ 未配置 Qwen3 API Key，仅返回技术指标数据"
    
    prompt = f"""你是一位专业股票分析师。请基于以下{market_type}股市场数据，提供专业的技术分析和投资建议。

股票名称: {stock_name}
当前价格: ¥{indicators['current_price']:.2f}
涨跌幅: {indicators.get('change_pct', 0):.2f}%

技术指标:
- MA5: ¥{indicators.get('ma5', 0):.2f}
- MA20: ¥{indicators.get('ma20', 0):.2f}
- MA60: ¥{indicators.get('ma60', 0):.2f}
- RSI14: {indicators.get('rsi14', 0):.2f}
- MACD: {indicators.get('macd', 0):.4f}
- 布林带: 上轨¥{indicators.get('boll_upper', 0):.2f} / 中轨¥{indicators.get('boll_middle', 0):.2f} / 下轨¥{indicators.get('boll_lower', 0):.2f}
- 成交量MA20: {indicators.get('volume_ma20', 0):.0f}

请提供:
1. 趋势分析（短期/中期/长期）
2. 关键技术位判断
3. 风险提示
4. 操作建议（观望/关注/谨慎）

保持客观专业， disclaimer: 仅供参考，不构成投资建议。"""

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                QWEN_API_URL,
                headers={
                    "Authorization": f"Bearer {QWEN_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "qwen-plus",
                    "input": {
                        "messages": [
                            {"role": "system", "content": "你是专业股票分析师"},
                            {"role": "user", "content": prompt}
                        ]
                    },
                    "parameters": {
                        "result_format": "message",
                        "max_tokens": 1500,
                        "temperature": 0.7
                    }
                },
                timeout=30.0
            )
            
            result = response.json()
            if "output" in result and "choices" in result["output"]:
                return result["output"]["choices"][0]["message"]["content"]
            return "⚠️ Qwen3 返回格式异常"
    except Exception as e:
        return f"⚠️ Qwen3 分析失败: {str(e)}"

@app.get("/")
def root():
    return {"message": "🪓 盘古股票分析服务", "version": "1.0.0", "docs": "/docs"}

@app.post("/analyze", response_model=StockResponse)
async def analyze_stock(request: StockRequest):
    """股票分析接口"""
    
    # 获取数据
    if request.market_type.upper() == "A":
        result = get_stock_data_a(request.stock_code)
    elif request.market_type.upper() in ["HK", "H"]:
        result = get_stock_data_hk(request.stock_code)
    else:
        raise HTTPException(status_code=400, detail=f"不支持的市场类型: {request.market_type}")
    
    if not result:
        raise HTTPException(status_code=404, detail=f"无法获取股票 {request.stock_code} 的数据")
    
    stock_name, indicators = result
    
    # AI 分析
    analysis = await analyze_with_qwen(stock_name, indicators, request.market_type)
    
    return StockResponse(
        stock_code=request.stock_code,
        stock_name=stock_name,
        current_price=indicators["current_price"],
        daily_change=indicators.get("change_pct", 0),
        analysis=analysis,
        indicators=indicators,
        timestamp=datetime.now().isoformat()
    )

@app.get("/health")
def health():
    """健康检查"""
    return {"status": "ok", "qwen_configured": bool(QWEN_API_KEY)}

@app.get("/hot-stocks")
def hot_stocks():
    """获取热门股票列表"""
    try:
        df = ak.stock_zh_a_spot_em()
        # 按成交额排序取前20
        hot = df.nlargest(20, "成交额")[["代码", "名称", "最新价", "涨跌幅", "成交额"]]
        return hot.to_dict(orient="records")
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
