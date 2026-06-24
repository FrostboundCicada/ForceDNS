#!/system/bin/sh
# ForceDNS - 文件系统挂载后执行
# 由Magisk在post-fs-data阶段调用

MODDIR=${0%/*}

# 创建数据目录
mkdir -p "$MODDIR/data"

# 初始化默认配置（如果不存在）
if [ ! -f "$MODDIR/data/forcedns.conf" ]; then
    cat > "$MODDIR/data/forcedns.conf" << EOF
ENABLED=1
DNS_PRIMARY=223.5.5.5
DNS_SECONDARY=223.6.6.6
PRESET_NAME=AliDNS
CUSTOM_DNS=
HIJACK_IPV6=1
WHITELIST_UID=
LOG_ENABLED=1
EOF
fi

# 创建resolv.conf覆盖（通过Magisk模块systemless方式）
mkdir -p "$MODDIR/system/etc"
echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

# 确保dnsmasq可执行
if [ -f "$MODDIR/system/bin/dnsmasq" ]; then
    chmod 0755 "$MODDIR/system/bin/dnsmasq"
fi
