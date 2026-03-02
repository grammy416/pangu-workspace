#!/bin/bash
# 🪓 盘古股票分析服务 - 后台守护进程启动

cd /root/.openclaw/workspace/stock-analyzer

# 加载环境变量
if [ -f ".env" ]; then
    export $(cat .env | xargs)
fi

# 激活虚拟环境
source venv/bin/activate

# 后台启动
nohup python3 pangu_stock_api.py > server.log 2>&1 &
echo $! > server.pid

echo "✅ 服务已后台启动"
echo "   PID: $(cat server.pid)"
echo "   日志: /root/.openclaw/workspace/stock-analyzer/server.log"
echo "   API: http://localhost:8000"
