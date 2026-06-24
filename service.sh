#!/system/bin/sh
# ForceDNS - 开机后服务启动 + 守护

MODDIR=${0%/*}

# 等待系统启动完成
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 5

# 启动
sh "$MODDIR/forcedns-core.sh" start &

# 守护
while true; do
    sleep 30

    . "$MODDIR/data/forcedns.conf" 2>/dev/null
    if [ "$ENABLED" != "1" ]; then
        continue
    fi

    # 检查dnsmasq
    if ! pgrep -f "dnsmasq.*5353" >/dev/null 2>&1; then
        if [ -f "$MODDIR/data/dnsmasq.pid" ]; then
            if ! kill -0 $(cat "$MODDIR/data/dnsmasq.pid" 2>/dev/null) 2>/dev/null; then
                sh "$MODDIR/forcedns-core.sh" start
            fi
        else
            sh "$MODDIR/forcedns-core.sh" start
        fi
    fi

    # 检查iptables
    if ! iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 重新设置DNS
    setprop net.dns1 "127.0.0.1" 2>/dev/null
    setprop net.dns2 "127.0.0.1" 2>/dev/null
    settings put global private_dns_mode off 2>/dev/null

    # 覆盖Termux
    if [ -d "/data/data/com.termux" ]; then
        echo "nameserver 127.0.0.1" > /data/data/com.termux/files/usr/etc/resolv.conf 2>/dev/null
    fi
done &
