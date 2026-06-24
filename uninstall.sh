#!/system/bin/sh
# ForceDNS - 卸载清理

MODDIR=${0%/*}

# 停止服务
sh "$MODDIR/forcedns-core.sh" stop 2>/dev/null

# 清理iptables
iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:5353 2>/dev/null
iptables -t nat -F FORCEDNS 2>/dev/null
iptables -t nat -X FORCEDNS 2>/dev/null
iptables -D OUTPUT -j FORCEDNS_FW 2>/dev/null
iptables -F FORCEDNS_FW 2>/dev/null
iptables -X FORCEDNS_FW 2>/dev/null
ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
ip6tables -t nat -F FORCEDNS 2>/dev/null
ip6tables -t nat -X FORCEDNS 2>/dev/null

killall dnsmasq 2>/dev/null
killall dnsproxy 2>/dev/null

# 恢复系统DNS
setprop net.dns1 "" 2>/dev/null
setprop net.dns2 "" 2>/dev/null
settings put global private_dns_mode opportunistic 2>/dev/null

rm -f "$MODDIR/data/"*.pid
