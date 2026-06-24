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

    # 检查iptables规则是否还在
    if ! iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        sh "$MODDIR/forcedns-core.sh" start
    fi

    # 重新设置DNS（防止被系统/DHCP覆盖）
    setprop net.dns1 "114.114.114.114" 2>/dev/null
    setprop net.dns2 "1.1.1.1" 2>/dev/null
    settings put global private_dns_mode off 2>/dev/null

    # 重新覆盖Termux resolv.conf
    if [ -d "/data/data/com.termux" ]; then
        printf "nameserver 114.114.114.114\nnameserver 1.1.1.1\n" > /data/data/com.termux/files/usr/etc/resolv.conf 2>/dev/null
    fi
done &
