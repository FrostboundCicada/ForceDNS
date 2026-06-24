#!/system/bin/sh
# ForceDNS - 开机早期初始化

MODDIR=${0%/*}
mkdir -p "$MODDIR/data"

# 初始化默认配置
if [ ! -f "$MODDIR/data/forcedns.conf" ]; then
    echo "ENABLED=1" > "$MODDIR/data/forcedns.conf"
fi

# 覆盖resolv.conf
mkdir -p "$MODDIR/system/etc"
echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"
