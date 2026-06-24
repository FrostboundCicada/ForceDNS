#!/system/bin/sh
#=============================================
# ForceDNS 核心脚本 v3
# 无需dnsmasq，纯iptables直接劫持DNS到目标服务器
# 主DNS: 114.114.114.114  副DNS: 1.1.1.1
#=============================================

MODDIR=${0%/*}
CONF_DIR="$MODDIR/data"
CONF_FILE="$CONF_DIR/forcedns.conf"
LOG_FILE="$CONF_DIR/forcedns.log"

# 硬编码DNS
DNS_PRIMARY="114.114.114.114"
DNS_SECONDARY="1.1.1.1"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

read_config() {
    if [ -f "$CONF_FILE" ]; then
        . "$CONF_FILE"
    else
        ENABLED=1
        save_config
    fi
}

save_config() {
    mkdir -p "$CONF_DIR"
    echo "ENABLED=$ENABLED" > "$CONF_FILE"
}

# 设置iptables - 直接劫持DNS到目标服务器
setup_iptables() {
    cleanup_iptables

    # === DNS劫持: 所有53端口流量直接重定向到114.114.114.114 ===
    iptables -t nat -N FORCEDNS 2>/dev/null

    # 不劫持到114.114.114.114和1.1.1.1自身的流量(防止循环)
    iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
    iptables -t nat -A FORCEDNS -d 1.1.1.1 -j RETURN
    iptables -t nat -A FORCEDNS -d 1.0.0.1 -j RETURN

    # 劫持所有其他DNS请求到114.114.114.114
    iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53
    iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53

    # 挂载到OUTPUT和PREROUTING
    iptables -t nat -A OUTPUT -j FORCEDNS
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53

    # IPv6 - 重定向到1.1.1.1的IPv6
    ip6tables -t nat -N FORCEDNS 2>/dev/null
    ip6tables -t nat -A FORCEDNS -d 2606:4700:4700::1111/128 -j RETURN 2>/dev/null
    ip6tables -t nat -A FORCEDNS -d 2606:4700:4700::1001/128 -j RETURN 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53 2>/dev/null
    ip6tables -t nat -A OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53 2>/dev/null
    ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53 2>/dev/null

    # === 防火墙: 阻止绕过 ===
    iptables -N FORCEDNS_FW 2>/dev/null

    # 允许本地回环和已建立连接
    iptables -A FORCEDNS_FW -o lo -j RETURN
    iptables -A FORCEDNS_FW -m state --state ESTABLISHED,RELATED -j RETURN

    # 允许到授权DNS服务器
    iptables -A FORCEDNS_FW -d 114.114.114.114 -j RETURN
    iptables -A FORCEDNS_FW -d 1.1.1.1 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -j RETURN
    # 114.114.115.115 (114备用)
    iptables -A FORCEDNS_FW -d 114.114.115.115 -j RETURN

    # 阻止直连其他DNS服务器(UDP+TCP 53)
    for dns in 8.8.8.8 8.8.4.4 9.9.9.9 208.67.222.222 208.67.220.220 \
               223.5.5.5 223.6.6.6 119.29.29.29 180.76.76.76 \
               94.140.14.14 94.140.15.15 45.90.28.0 45.90.30.0; do
        iptables -A FORCEDNS_FW -d $dns -p udp --dport 53 -j DROP
        iptables -A FORCEDNS_FW -d $dns -p tcp --dport 53 -j DROP
    done

    # 阻止DoH到非授权服务器
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p tcp --dport 443 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p tcp --dport 443 -j DROP
    iptables -A FORCEDNS_FW -d 9.9.9.9 -p tcp --dport 443 -j DROP

    # 挂载防火墙
    iptables -A OUTPUT -j FORCEDNS_FW

    log_msg "iptables规则已设置(直接DNAT到114.114.114.114+防火墙)"
}

# 清理iptables
cleanup_iptables() {
    # NAT链
    iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53 2>/dev/null
    iptables -t nat -F FORCEDNS 2>/dev/null
    iptables -t nat -X FORCEDNS 2>/dev/null

    # 防火墙链
    iptables -D OUTPUT -j FORCEDNS_FW 2>/dev/null
    iptables -F FORCEDNS_FW 2>/dev/null
    iptables -X FORCEDNS_FW 2>/dev/null

    # IPv6
    ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -F FORCEDNS 2>/dev/null
    ip6tables -t nat -X FORCEDNS 2>/dev/null

    log_msg "iptables规则已清理"
}

# 覆盖DNS配置
override_dns() {
    # setprop设置DNS到114
    setprop net.dns1 "$DNS_PRIMARY"
    setprop net.dns2 "$DNS_SECONDARY"
    setprop net.wlan0.dns1 "$DNS_PRIMARY"
    setprop net.wlan0.dns2 "$DNS_SECONDARY"
    setprop net.rmnet0.dns1 "$DNS_PRIMARY"
    setprop net.rmnet0.dns2 "$DNS_SECONDARY"
    setprop net.rmnet1.dns1 "$DNS_PRIMARY"
    setprop net.rmnet1.dns2 "$DNS_SECONDARY"
    setprop net.ppp0.dns1 "$DNS_PRIMARY"
    setprop net.ppp0.dns2 "$DNS_SECONDARY"

    # 关闭Android私有DNS
    settings put global private_dns_mode off 2>/dev/null
    settings put global private_dns_specifier "" 2>/dev/null

    # 覆盖系统resolv.conf
    mkdir -p "$MODDIR/system/etc"
    printf "nameserver %s\nnameserver %s\n" "$DNS_PRIMARY" "$DNS_SECONDARY" > "$MODDIR/system/etc/resolv.conf"

    # 覆盖Termux resolv.conf
    local termux_resolv="/data/data/com.termux/files/usr/etc/resolv.conf"
    if [ -d "/data/data/com.termux" ]; then
        mkdir -p "$(dirname "$termux_resolv")" 2>/dev/null
        printf "nameserver %s\nnameserver %s\n" "$DNS_PRIMARY" "$DNS_SECONDARY" > "$termux_resolv" 2>/dev/null
        chmod 644 "$termux_resolv" 2>/dev/null
        log_msg "Termux resolv.conf已覆盖"
    fi

    # 覆盖其他resolv.conf
    for f in /etc/resolv.conf /system/etc/resolv.conf /data/misc/net/resolv.conf; do
        printf "nameserver %s\nnameserver %s\n" "$DNS_PRIMARY" "$DNS_SECONDARY" > "$f" 2>/dev/null
    done

    log_msg "DNS配置已覆盖: $DNS_PRIMARY / $DNS_SECONDARY"
}

# 恢复DNS
restore_dns() {
    setprop net.dns1 "" 2>/dev/null
    setprop net.dns2 "" 2>/dev/null
    setprop net.wlan0.dns1 "" 2>/dev/null
    setprop net.wlan0.dns2 "" 2>/dev/null
    settings put global private_dns_mode opportunistic 2>/dev/null
    log_msg "DNS配置已恢复"
}

# 启动
start_forcedns() {
    read_config
    if [ "$ENABLED" != "1" ]; then
        log_msg "ForceDNS已禁用"
        return 0
    fi

    log_msg "========== ForceDNS 启动 =========="

    # 检查iptables
    if ! command -v iptables >/dev/null 2>&1; then
        log_msg "错误: iptables不可用"
        echo "错误: iptables不可用，无法启动"
        return 1
    fi

    override_dns
    setup_iptables

    log_msg "ForceDNS启动完成 - DNS: $DNS_PRIMARY / $DNS_SECONDARY"
    echo "ForceDNS 已启动"
}

# 停止
stop_forcedns() {
    log_msg "========== ForceDNS 停止 =========="
    cleanup_iptables
    restore_dns
    log_msg "ForceDNS已停止"
    echo "ForceDNS 已停止"
}

# 显示状态
show_status() {
    read_config
    local iptables_active=0
    if iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        iptables_active=1
    fi

    echo "========================================"
    echo "  ForceDNS 状态"
    echo "========================================"
    echo "  模块开关: $([ "$ENABLED" = "1" ] && echo "[开启]" || echo "[关闭]")"
    echo "  运行状态: $([ "$iptables_active" = "1" ] && echo "[运行中]" || echo "[已停止]")"
    echo "  主DNS: $DNS_PRIMARY"
    echo "  副DNS: $DNS_SECONDARY"
    echo "  iptables: $([ "$iptables_active" = "1" ] && echo "已设置" || echo "未设置")"
    echo "  私有DNS: $(settings get global private_dns_mode 2>/dev/null || echo "未知")"
    echo ""
    echo "  --- DNS验证 ---"

    # 检查setprop
    local d1=$(getprop net.dns1 2>/dev/null)
    local d2=$(getprop net.wlan0.dns1 2>/dev/null)
    echo "  net.dns1: ${d1:-空(系统自动分配)}"
    echo "  net.wlan0.dns1: ${d2:-空(系统自动分配)}"

    # Termux
    if [ -f "/data/data/com.termux/files/usr/etc/resolv.conf" ]; then
        local tdns=$(grep "^nameserver" /data/data/com.termux/files/usr/etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}')
        echo "  Termux DNS: ${tdns:-未设置}"
    fi

    # nslookup验证
    if command -v nslookup >/dev/null 2>&1; then
        local ns_result=$(nslookup baidu.com 2>&1 | grep -i "server" | head -1 | awk '{print $NF}')
        if [ -n "$ns_result" ]; then
            if [ "$ns_result" = "$DNS_PRIMARY" ] || [ "$ns_result" = "$DNS_SECONDARY" ]; then
                echo "  实际DNS: $ns_result (劫持生效!)"
            else
                echo "  实际DNS: $ns_result (劫持未生效)"
            fi
        else
            echo "  实际DNS: 无法检测"
        fi
    fi

    echo "========================================"
}

# 切换开关
toggle() {
    read_config
    if [ "$ENABLED" = "1" ]; then
        ENABLED=0
        save_config
        stop_forcedns
    else
        ENABLED=1
        save_config
        start_forcedns
    fi
    show_status
}

case "$1" in
    start)   start_forcedns ;;
    stop)    stop_forcedns ;;
    restart) stop_forcedns; sleep 1; start_forcedns ;;
    status)  show_status ;;
    toggle)  toggle ;;
    *)
        echo "用法: forcedns-core.sh {start|stop|restart|status|toggle}"
        ;;
esac
