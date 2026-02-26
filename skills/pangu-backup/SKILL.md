---
name: pangu-backup
description: 盘古工作空间备份与恢复指南
---

# 🪓 盘古备份与恢复系统

## 快速使用

### 备份（日常使用）

```bash
# 在工作空间执行
./backup.sh "提交信息"
```

### 恢复（重新安装后）

```bash
# 方式一：使用恢复脚本
curl -O https://raw.githubusercontent.com/grammy416/pangu-workspace/main/restore.sh
chmod +x restore.sh
./restore.sh

# 方式二：手动克隆
git clone https://github.com/grammy416/pangu-workspace.git
rsync -av pangu-workspace/ ~/.openclaw/workspace/
```

---

## 📋 备份内容清单

### ✅ 自动备份
- MEMORY.md - 长期记忆
- USER.md - 用户档案
- SOUL.md - 人格设定
- IDENTITY.md - 身份信息
- AGENTS.md - 代理配置
- TOOLS.md - 工具笔记
- HEARTBEAT.md - 心跳任务
- memory/ - 每日记忆
- skills/ - 自定义技能
- projects/ - 项目文件

### ⚠️ 需手动处理
- .secrets/github_token - GitHub API Token
- .secrets/github_pangu - SSH 私钥
- 其他敏感凭证

---

## 🔐 重新配置敏感信息

### 1. GitHub SSH 密钥

```bash
# 生成新密钥对
ssh-keygen -t ed25519 -C "pangu@openclaw.local" -f ~/.openclaw/workspace/.secrets/github_pangu

# 添加公钥到 GitHub
# 复制 ~/.openclaw/workspace/.secrets/github_pangu.pub 到
# GitHub -> Settings -> SSH and GPG keys -> New SSH key
```

### 2. GitHub API Token

1. 访问 https://github.com/settings/tokens
2. 生成 Personal access token (classic)
3. 选择权限: repo, workflow, delete_repo
4. 保存到文件:
```bash
echo 'ghp_xxxxx' > ~/.openclaw/workspace/.secrets/github_token
chmod 600 ~/.openclaw/workspace/.secrets/github_token
```

---

## 🛠️ 完整恢复流程

### 步骤 1: 安装 OpenClaw
```bash
npm install -g openclaw
openclaw setup
```

### 步骤 2: 恢复工作空间
```bash
mkdir -p ~/.openclaw/workspace
cd ~/.openclaw/workspace

# 下载并运行恢复脚本
curl -O https://raw.githubusercontent.com/grammy416/pangu-workspace/main/restore.sh
chmod +x restore.sh
./restore.sh
```

### 步骤 3: 配置 Git
```bash
git config --global user.name "盘古 (Pangu)"
git config --global user.email "pangu@openclaw.local"
```

### 步骤 4: 恢复敏感信息
```bash
# 创建 secrets 目录
mkdir -p ~/.openclaw/workspace/.secrets

# 按上文「重新配置敏感信息」添加 SSH 密钥和 Token
```

### 步骤 5: 验证连接
```bash
ssh -T git@github.com
```

### 步骤 6: 启动 OpenClaw
```bash
openclaw
```

---

## 💡 自动化建议

### 设置定时备份

```bash
# 添加 crontab 任务（每天凌晨 3 点备份）
0 3 * * * cd ~/.openclaw/workspace && ./backup.sh "🌙 夜间自动备份"
```

### 重要操作后备份

完成以下操作后建议立即备份：
- 新增重要技能
- 修改核心记忆
- 完成里程碑任务
- 修改用户配置

---

## 🆘 故障排除

### 问题：恢复后 Token 失效
**解决**: Token 有有效期，需重新生成

### 问题：SSH 连接失败
**解决**: 
1. 确认已添加公钥到 GitHub
2. 检查私钥权限: `chmod 600 ~/.ssh/github_pangu`
3. 测试连接: `ssh -T git@github.com`

### 问题：部分文件未恢复
**解决**: 检查 .backup-manifest 确认备份范围

---

## 📦 仓库地址

**主仓库**: https://github.com/grammy416/pangu-workspace

---

*此技能由 盘古 维护*