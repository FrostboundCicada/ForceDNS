#!/system/bin/sh
# ForceDNS - 开机后服务启动
# 由Magisk在开机完成后调用

MODDIR=${0%/*}

# 等待系统启动完成
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# 额外等待确保网络就绪
sleep 5

# 启动DNS劫持服务
sh "$MODDIR/forcedns-core.sh" start &

# 仅在非KernelSU/APatch环境下启动独立Web服务器
# KernelSU/APatch通过webroot目录提供WebUI，无需额外服务器
if [ ! -d "$MODDIR/webroot" ] || [ ! -f "$MODDIR/webroot/index.html" ]; then
    sh "$MODDIR/web/server.sh" start &
fi

# 持续监控：如果网络重连则重新应用规则
while true; do
    sleep 30

    # 检查服务是否启用
    . "$MODDIR/data/forcedns.conf" 2>/dev/null
    if [ "$ENABLED" != "1" ]; then
        continue
    fi

    # 检查dnsmasq是否在运行
    if [ -f "$MODDIR/data/dnsmasq.pid" ]; then
        pid=$(cat "$MODDIR/data/dnsmasq.pid" 2>/dev/null)
        if ! kill -0 "$pid" 2>/dev/null; then
            # dnsmasq崩溃，重启
            sh "$MODDIR/forcedns-core.sh" start
        fi
    else
        # PID文件丢失，重启
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 检查iptables规则是否还在
    if ! iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 重新设置系统DNS（防止被系统覆盖）
    setprop net.dns1 "127.0.0.1" 2>/dev/null
    setprop net.dns2 "127.0.0.1" 2>/dev/null
done &
