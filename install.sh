#!/bin/bash
# ===================================================
# 🚀 Shadowsocks-libev 纯净部署脚本（for Shadowrocket）
# 适配系统：Debian 11/12 / Ubuntu 20.04+
# 作者：ChatGPT 定制版 for guuu ge
# ===================================================

set -e

# 检查 root 权限
if [ "$(id -u)" != "0" ]; then
    echo "❌ 请以 root 权限运行：sudo -i"
    exit 1
fi

echo "🚀 开始安装 Shadowsocks-libev ..."

# 1️⃣ 安装 Shadowsocks-libev 与常用工具
apt update -y
apt install -y shadowsocks-libev curl jq net-tools

# 2️⃣ 创建配置文件
mkdir -p /etc/shadowsocks-libev
cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server": "0.0.0.0",
    "server_port": 8388,
    "password": "sspassword123",
    "timeout": 60,
    "method": "aes-256-gcm",
    "fast_open": true,
    "reuse_port": true,
    "mode": "tcp_and_udp"
}
EOF

# 3️⃣ 启动并设置开机自启
systemctl enable shadowsocks-libev
systemctl restart shadowsocks-libev
sleep 2

# 4️⃣ 检查运行状态
if ss -tuln | grep -q ":8388"; then
    echo "✅ Shadowsocks-libev 已启动并监听端口 8388"
else
    echo "❌ Shadowsocks 启动失败，请检查：journalctl -u shadowsocks-libev -e"
    exit 1
fi

# 5️⃣ 启用 BBR 拥塞控制加速
if ! sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "⚙️ 开启 BBR 拥塞控制..."
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 6️⃣ 防火墙放行（如存在 UFW）
if command -v ufw >/dev/null 2>&1; then
    echo "🧱 放行防火墙端口 8388 ..."
    ufw allow 8388/tcp >/dev/null 2>&1
    ufw allow 8388/udp >/dev/null 2>&1
    echo "✅ 防火墙已放行端口 8388"
else
    echo "ℹ️ 未安装 UFW，请确保云防火墙允许 8388 端口。"
fi

# 7️⃣ 生成 Shadowrocket 链接
IP=$(curl -s ifconfig.me || curl -s ipv4.ip.sb)
SS_LINK="ss://$(echo -n aes-256-gcm:sspassword123@$IP:8388 | base64 -w0)#GCP-SS"
echo -e "\n🌐 你的 Shadowrocket 节点：\n$SS_LINK\n"

# 8️⃣ 输出状态总结
echo "✅ 安装完成，节点已启动！"
echo "=========================================="
echo "服务器 IP: $IP"
echo "端口: 8388"
echo "密码: sspassword123"
echo "加密: aes-256-gcm"
echo "链接: $SS_LINK"
echo "=========================================="
echo "📱 在 Shadowrocket 中添加节点即可上网。"
