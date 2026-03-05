#!/bin/bash
# Star Office UI - 像素办公室完整部署脚本
# 自动处理所有依赖和配置

set -e

echo "🏢 Star Office UI - 像素办公室完整部署"
echo "=========================================="

# 配置
WORKSPACE="/root/.openclaw/workspace"
PROJECT_DIR="$WORKSPACE/pixel-office"
PORT=8000

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔧 步骤1: 安装系统依赖"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检测包管理器并安装依赖
install_dependencies() {
    echo "📦 正在安装 git, python3, python3-pip..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        echo "检测到 apt-get，正在安装..."
        apt-get update -qq
        apt-get install -y -qq git python3 python3-pip curl
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        echo "检测到 yum，正在安装..."
        yum install -y git python3 python3-pip curl
    elif command -v apk &> /dev/null; then
        # Alpine
        echo "检测到 apk，正在安装..."
        apk add --no-cache git python3 py3-pip curl
    else
        echo "⚠️  未检测到支持的包管理器"
        echo "请手动安装: git python3 python3-pip"
        exit 1
    fi
    
    echo "✅ 系统依赖安装完成"
}

# 检查并安装依赖
if ! command -v git &> /dev/null || ! command -v python3 &> /dev/null; then
    install_dependencies
else
    echo "✅ git 和 python3 已安装"
fi

# 确保 pip 可用
if ! command -v pip3 &> /dev/null; then
    echo "📦 安装 pip3..."
    python3 -m ensurepip --upgrade 2>/dev/null || true
    
    # 如果 ensurepip 失败，尝试其他方式
    if ! command -v pip3 &> /dev/null; then
        curl -sS https://bootstrap.pypa.io/get-pip.py | python3
    fi
fi

echo "✅ pip3 已就绪: $(pip3 --version)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 步骤2: 停止占用 8000 端口的服务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 查找并停止占用 8000 端口的进程
echo "🔎 检查端口 $PORT 占用情况..."

# 尝试多种方式查找进程
PID=""
if command -v lsof &> /dev/null; then
    PID=$(lsof -t -i:$PORT 2>/dev/null)
elif command -v fuser &> /dev/null; then
    PID=$(fuser $PORT/tcp 2>/dev/null | awk '{print $1}')
elif command -v netstat &> /dev/null; then
    PID=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1 | head -1)
elif command -v ss &> /dev/null; then
    PID=$(ss -tlnp 2>/dev/null | grep ":$PORT " | head -1 | grep -oP 'pid=\K[0-9]+')
fi

if [ -n "$PID" ]; then
    echo "⚠️  发现端口 $PORT 被进程 $PID 占用"
    echo "🛑 正在停止进程 $PID..."
    kill -9 $PID 2>/dev/null || true
    sleep 2
    echo "✅ 进程已停止"
else
    echo "✅ 端口 $PORT 未被占用"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📥 步骤3: 下载像素办公室项目"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 进入工作目录
cd "$WORKSPACE"

# 如果已存在，先备份
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  检测到已存在的 pixel-office 目录"
    BACKUP_NAME="pixel-office.backup.$(date +%Y%m%d%H%M%S)"
    echo "📦 备份为 $BACKUP_NAME"
    mv "$PROJECT_DIR" "$BACKUP_NAME"
fi

# 克隆仓库
echo "📥 克隆 Star Office UI 仓库..."
git clone --depth 1 https://github.com/ringhyacinth/Star-Office-UI.git pixel-office
cd "$PROJECT_DIR"

echo "✅ 项目下载完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🐍 步骤4: 安装 Python 依赖"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 安装依赖
echo "📦 安装 Python 包..."
pip3 install -q -r backend/requirements.txt

echo "✅ Python 依赖安装完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚙️ 步骤5: 修改端口配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 初始化状态文件
cp state.sample.json state.json

# 修改后端端口为 8000
echo "🔧 修改后端端口为 $PORT..."

# 修改 app.py
if [ -f "backend/app.py" ]; then
    sed -i "s/18791/$PORT/g" backend/app.py
    echo "✅ backend/app.py 端口已修改"
fi

# 修改 set_state.py
if [ -f "set_state.py" ]; then
    sed -i "s/18791/$PORT/g" set_state.py
    echo "✅ set_state.py 端口已修改"
fi

# 修改前端中的端口引用
if [ -d "frontend" ]; then
    find frontend -type f \( -name "*.js" -o -name "*.html" -o -name "*.json" \) -exec sed -i "s/18791/$PORT/g" {} \; 2>/dev/null || true
    echo "✅ 前端配置端口已修改"
fi

# 检查修改是否成功
if grep -q "$PORT" backend/app.py; then
    echo "✅ 端口配置验证通过"
else
    echo "⚠️  端口配置可能未成功，请手动检查"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔥 步骤6: 配置防火墙"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 配置防火墙
if command -v ufw &> /dev/null; then
    echo "🔥 配置 ufw 允许端口 $PORT..."
    ufw allow $PORT/tcp > /dev/null 2>&1 || true
    echo "✅ ufw 规则已添加"
fi

if command -v firewall-cmd &> /dev/null; then
    echo "🔥 配置 firewalld 允许端口 $PORT..."
    firewall-cmd --permanent --add-port=$PORT/tcp > /dev/null 2>&1 || true
    firewall-cmd --reload > /dev/null 2>&1 || true
    echo "✅ firewalld 规则已添加"
fi

if command -v iptables &> /dev/null; then
    echo "🔥 配置 iptables 允许端口 $PORT..."
    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true
    echo "✅ iptables 规则已添加"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 步骤7: 创建管理脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 创建前台启动脚本
cat > start.sh << EOF
#!/bin/bash
echo "🚀 启动 Pixel Office (前台模式)..."
echo "📝 按 Ctrl+C 停止"
echo "🌐 访问: http://\$(hostname -I | awk '{print \$1}'):$PORT"
echo ""
cd $PROJECT_DIR/backend
python3 app.py
EOF
chmod +x start.sh

# 创建后台启动脚本
cat > start-bg.sh << 'EOF'
#!/bin/bash
cd /root/.openclaw/workspace/pixel-office/backend
nohup python3 app.py > ../app.log 2>&1 &
sleep 2
PID=$(lsof -t -i:8000 2>/dev/null)
if [ -n "$PID" ]; then
    echo "🚀 Pixel Office 已后台启动 (PID: $PID)"
    echo "📝 日志: tail -f /root/.openclaw/workspace/pixel-office/app.log"
    echo "🌐 访问: http://$(hostname -I | awk '{print $1}'):8000"
else
    echo "❌ 启动失败，请检查日志"
fi
EOF
chmod +x start-bg.sh

# 创建停止脚本
cat > stop.sh << 'EOF'
#!/bin/bash
PID=$(lsof -t -i:8000 2>/dev/null)
if [ -n "$PID" ]; then
    kill -9 $PID 2>/dev/null
    echo "🛑 Pixel Office 已停止 (PID: $PID)"
else
    echo "ℹ️  Pixel Office 未运行"
fi
EOF
chmod +x stop.sh

# 创建状态更新脚本
cat > update-state.sh << 'EOF'
#!/bin/bash
# OpenClaw 状态更新脚本
# 用法: ./update-state.sh <状态> <消息>
# 状态选项: idle, writing, researching, executing, syncing, error

STATE=${1:-idle}
MESSAGE=${2:-"待命中"}

cd /root/.openclaw/workspace/pixel-office 2>/dev/null || exit 1
python3 set_state.py "$STATE" "$MESSAGE"
EOF
chmod +x update-state.sh

# 创建 systemd 服务文件
cat > pixel-office.service << EOF
[Unit]
Description=Star Office UI - Pixel Office for OpenClaw
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR/backend
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5
StandardOutput=append:$PROJECT_DIR/app.log
StandardError=append:$PROJECT_DIR/app.log

[Install]
WantedBy=multi-user.target
EOF

# 创建查看状态脚本
cat > status.sh << 'EOF'
#!/bin/bash
PID=$(lsof -t -i:8000 2>/dev/null)
if [ -n "$PID" ]; then
    echo "✅ Pixel Office 运行中 (PID: $PID)"
    echo "🌐 访问: http://$(hostname -I | awk '{print $1}'):8000"
    echo "📝 日志: tail -f /root/.openclaw/workspace/pixel-office/app.log"
else
    echo "❌ Pixel Office 未运行"
    echo "💡 启动命令: ./start-bg.sh"
fi
EOF
chmod +x status.sh

echo "✅ 管理脚本创建完成"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪 步骤8: 测试部署"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 测试 Python 依赖
echo "🧪 测试 Python 依赖..."
cd "$PROJECT_DIR/backend"
python3 -c "import flask; import flask_cors; print('✅ Flask 已安装')" 2>/dev/null || echo "⚠️  Flask 可能未正确安装"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 部署完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎮 Star Office UI 像素办公室"
echo ""

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')
echo "📁 项目目录: $PROJECT_DIR"
echo "🌐 访问地址: http://$SERVER_IP:$PORT"
echo ""
echo "🚀 启动命令:"
echo "   cd $PROJECT_DIR"
echo "   ./start-bg.sh    # 后台启动"
echo "   ./start.sh       # 前台启动（看日志）"
echo ""
echo "🛑 停止命令:"
echo "   ./stop.sh"
echo ""
echo "📊 查看状态:"
echo "   ./status.sh"
echo ""
echo "📝 更新状态:"
echo "   ./update-state.sh writing '正在整理文档'"
echo "   ./update-state.sh idle '待命中'"
echo ""
echo "🔧 系统服务安装（可选）:"
echo "   cp pixel-office.service /etc/systemd/system/"
echo "   systemctl daemon-reload"
echo "   systemctl enable pixel-office"
echo "   systemctl start pixel-office"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 现在运行: cd $PROJECT_DIR && ./start-bg.sh"
