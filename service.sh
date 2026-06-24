#!/system/bin/sh
# ForceDNS - 开机后服务启动 + 守护

MODDIR=${0%/*}

# 等待系统启动完成
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 5

# 启动DNS劫持服务
sh "$MODDIR/forcedns-core.sh" start &

# 守护：网络重连后重新应用
while true; do
    sleep 30

    . "$MODDIR/data/forcedns.conf" 2>/dev/null
    if [ "$ENABLED" != "1" ]; then
        continue
    fi

    # 检查dnsmasq
    if [ -f "$MODDIR/data/dnsmasq.pid" ]; then
        pid=$(cat "$MODDIR/data/dnsmasq.pid" 2>/dev/null)
        if ! kill -0 "$pid" 2>/dev/null; then
            sh "$MODDIR/forcedns-core.sh" start
        fi
    else
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 检查iptables规则
    if ! iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 重新设置系统DNS（防止被系统覆盖）
    setprop net.dns1 "127.0.0.1" 2>/dev/null
    setprop net.dns2 "127.0.0.1" 2>/dev/null
    settings put global private_dns_mode off 2>/dev/null
done &
