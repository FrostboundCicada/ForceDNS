#!/system/bin/sh
# ForceDNS - 卸载清理脚本

MODDIR=${0%/*}

# 停止Web服务器
sh "$MODDIR/web/server.sh" stop 2>/dev/null

# 停止DNS劫持
sh "$MODDIR/forcedns-core.sh" stop 2>/dev/null

# 清理iptables规则（确保干净卸载）
iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -F FORCEDNS 2>/dev/null
iptables -t nat -X FORCEDNS 2>/dev/null
iptables -t mangle -D OUTPUT -j FORCEDNS_MANGLE 2>/dev/null
iptables -t mangle -F FORCEDNS_MANGLE 2>/dev/null
iptables -t mangle -X FORCEDNS_MANGLE 2>/dev/null

ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
ip6tables -t nat -F FORCEDNS 2>/dev/null
ip6tables -t nat -X FORCEDNS 2>/dev/null

# 停止所有dnsmasq
killall dnsmasq 2>/dev/null

# 恢复系统DNS
setprop net.dns1 "" 2>/dev/null
setprop net.dns2 "" 2>/dev/null
setprop net.wlan0.dns1 "" 2>/dev/null
setprop net.wlan0.dns2 "" 2>/dev/null
settings put global private_dns_mode opportunistic 2>/dev/null

# 清理PID文件
rm -f "$MODDIR/data/forcedns.pid"
rm -f "$MODDIR/data/dnsmasq.pid"
rm -f "$MODDIR/data/web.pid"
