#!/bin/bash
# 🪓 盘古股票分析服务启动脚本

cd /root/.openclaw/workspace/stock-analyzer

echo "🪓 盘古股票分析服务"
echo "===================="

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

# 创建虚拟环境（如果不存在）
if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
echo "📦 安装依赖..."
pip install -q -r requirements.txt

# 检查环境变量
if [ -z "$QWEN_API_KEY" ]; then
    echo "⚠️ 警告: 未设置 QWEN_API_KEY 环境变量"
    echo "   AI 分析功能将不可用"
    echo ""
    echo "   设置方式: export QWEN_API_KEY='sk-xxxxxx'"
fi

echo ""
echo "🚀 启动服务..."
echo "   API 地址: http://localhost:8000"
echo "   文档地址: http://localhost:8000/docs"
echo ""

# 启动服务
python3 pangu_stock_api.py
