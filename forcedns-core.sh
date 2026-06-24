#!/system/bin/sh
#=============================================
# ForceDNS 核心脚本
# 硬编码DNS: 114.114.114.114 + 1.1.1.1
# 强制关闭系统DNS + 防火墙阻止绕过
#=============================================

MODDIR=${0%/*}
CONF_DIR="$MODDIR/data"
CONF_FILE="$CONF_DIR/forcedns.conf"
DNSMASQ_CONF="$CONF_DIR/dnsmasq.conf"
PID_FILE="$CONF_DIR/forcedns.pid"
DNSMASQ_PID="$CONF_DIR/dnsmasq.pid"
LOG_FILE="$CONF_DIR/forcedns.log"
PORT=5353

# 硬编码DNS
DNS_PRIMARY="114.114.114.114"
DNS_SECONDARY="1.1.1.1"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 读取开关状态
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

# 生成dnsmasq配置
gen_dnsmasq_conf() {
    mkdir -p "$CONF_DIR"
    cat > "$DNSMASQ_CONF" << EOF
port=$PORT
no-resolv
server=$DNS_PRIMARY
server=$DNS_SECONDARY
cache-size=4096
min-cache-ttl=3600
dns-forward-max=1000
EOF
    log_msg "dnsmasq配置已生成: $DNS_PRIMARY / $DNS_SECONDARY"
}

# 启动dnsmasq
start_dnsmasq() {
    stop_dnsmasq
    gen_dnsmasq_conf

    DNSMASQ_BIN=""
    if command -v dnsmasq >/dev/null 2>&1; then
        DNSMASQ_BIN="dnsmasq"
    elif [ -x "$MODDIR/system/bin/dnsmasq" ]; then
        DNSMASQ_BIN="$MODDIR/system/bin/dnsmasq"
    else
        log_msg "错误: 未找到dnsmasq"
        return 1
    fi

    $DNSMASQ_BIN -C "$DNSMASQ_CONF" -x "$DNSMASQ_PID" 2>/dev/null && {
        log_msg "dnsmasq已启动 (端口:$PORT)"
        return 0
    }

    # 备用方式
    $DNSMASQ_BIN -C "$DNSMASQ_CONF" &
    echo $! > "$DNSMASQ_PID"
    sleep 1
    if kill -0 $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null; then
        log_msg "dnsmasq已启动(备用方式)"
        return 0
    fi
    return 1
}

# 停止dnsmasq
stop_dnsmasq() {
    if [ -f "$DNSMASQ_PID" ]; then
        kill $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null
        rm -f "$DNSMASQ_PID"
    fi
    killall dnsmasq 2>/dev/null
}

# 设置iptables - DNS劫持 + 防火墙
setup_iptables() {
    cleanup_iptables

    # === DNS劫持规则 ===
    iptables -t nat -N FORCEDNS 2>/dev/null

    # 劫持所有UDP/TCP 53端口到本地dnsmasq
    iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT
    iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # 挂载到OUTPUT和PREROUTING
    iptables -t nat -A OUTPUT -j FORCEDNS
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # IPv6
    ip6tables -t nat -N FORCEDNS 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT
    ip6tables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT
    ip6tables -t nat -A OUTPUT -j FORCEDNS
    ip6tables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT
    ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT

    # === 防火墙规则 - 阻止绕过DNS的直连 ===
    iptables -N FORCEDNS_FW 2>/dev/null

    # 允许本地回环
    iptables -A FORCEDNS_FW -o lo -j RETURN

    # 允许已建立的连接
    iptables -A FORCEDNS_FW -m state --state ESTABLISHED,RELATED -j RETURN

    # 允许到DNS服务器的连接(114.114.114.114 和 1.1.1.1)
    iptables -A FORCEDNS_FW -d 114.114.114.114 -j RETURN
    iptables -A FORCEDNS_FW -d 1.1.1.1 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -j RETURN

    # 允许本地DNS(dnsmasq)
    iptables -A FORCEDNS_FW -d 127.0.0.1 -j RETURN

    # 阻止其他应用直接向非授权DNS服务器发送请求
    # 常见运营商DNS和公共DNS黑名单(除我们指定的以外)
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 9.9.9.9 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 208.67.222.222 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 208.67.220.220 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 223.5.5.5 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 223.6.6.6 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 119.29.29.29 -p udp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 180.76.76.76 -p udp --dport 53 -j DROP
    # TCP也阻止
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 9.9.9.9 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 208.67.222.222 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 223.5.5.5 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 223.6.6.6 -p tcp --dport 53 -j DROP
    iptables -A FORCEDNS_FW -d 119.29.29.29 -p tcp --dport 53 -j DROP

    # 阻止DoH(HTTPS上的DNS)常用端口到已知DoH服务器
    iptables -A FORCEDNS_FW -d 1.1.1.1 -p tcp --dport 443 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -p tcp --dport 443 -j RETURN
    # 阻止Google DoH
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p tcp --dport 443 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p tcp --dport 443 -j DROP

    # 挂载防火墙链
    iptables -A OUTPUT -j FORCEDNS_FW

    log_msg "iptables规则已设置(DNS劫持+防火墙)"
}

# 清理iptables
cleanup_iptables() {
    # NAT链
    iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t nat -F FORCEDNS 2>/dev/null
    iptables -t nat -X FORCEDNS 2>/dev/null

    # 防火墙链
    iptables -D OUTPUT -j FORCEDNS_FW 2>/dev/null
    iptables -F FORCEDNS_FW 2>/dev/null
    iptables -X FORCEDNS_FW 2>/dev/null

    # IPv6
    ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -F FORCEDNS 2>/dev/null
    ip6tables -t nat -X FORCEDNS 2>/dev/null

    log_msg "iptables规则已清理"
}

# 强制关闭系统DNS
disable_system_dns() {
    # 覆盖所有net.dns属性
    setprop net.dns1 "127.0.0.1"
    setprop net.dns2 "127.0.0.1"
    setprop net.wlan0.dns1 "127.0.0.1"
    setprop net.wlan0.dns2 "127.0.0.1"
    setprop net.rmnet0.dns1 "127.0.0.1"
    setprop net.rmnet0.dns2 "127.0.0.1"
    setprop net.rmnet1.dns1 "127.0.0.1"
    setprop net.rmnet1.dns2 "127.0.0.1"
    setprop net.ppp0.dns1 "127.0.0.1"
    setprop net.ppp0.dns2 "127.0.0.1"

    # 关闭Android私有DNS(防止DoH绕过)
    settings put global private_dns_mode off 2>/dev/null
    settings put global private_dns_specifier "" 2>/dev/null

    # 覆盖resolv.conf
    mkdir -p "$MODDIR/system/etc"
    echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

    log_msg "系统DNS已强制关闭"
}

# 恢复系统DNS
restore_system_dns() {
    setprop net.dns1 "" 2>/dev/null
    setprop net.dns2 "" 2>/dev/null
    setprop net.wlan0.dns1 "" 2>/dev/null
    setprop net.wlan0.dns2 "" 2>/dev/null
    settings put global private_dns_mode opportunistic 2>/dev/null
    log_msg "系统DNS已恢复"
}

# 启动
start_forcedns() {
    read_config
    if [ "$ENABLED" != "1" ]; then
        log_msg "ForceDNS已禁用"
        return 0
    fi

    log_msg "========== ForceDNS 启动 =========="

    start_dnsmasq || { log_msg "dnsmasq启动失败"; return 1; }
    disable_system_dns
    setup_iptables

    echo $$ > "$PID_FILE"
    log_msg "ForceDNS启动完成 - DNS: $DNS_PRIMARY / $DNS_SECONDARY"
}

# 停止
stop_forcedns() {
    log_msg "========== ForceDNS 停止 =========="
    cleanup_iptables
    stop_dnsmasq
    restore_system_dns
    rm -f "$PID_FILE"
    log_msg "ForceDNS已停止"
}

# 显示状态
show_status() {
    read_config
    local dnsmasq_running=0
    local iptables_active=0

    if [ -f "$DNSMASQ_PID" ] && kill -0 $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null; then
        dnsmasq_running=1
    fi
    if iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        iptables_active=1
    fi

    local running=0
    [ "$dnsmasq_running" = "1" ] && [ "$iptables_active" = "1" ] && running=1

    echo "========================================"
    echo "  ForceDNS 状态"
    echo "========================================"
    if [ "$ENABLED" = "1" ]; then
        echo "  模块开关: [开启]"
    else
        echo "  模块开关: [关闭]"
    fi
    if [ "$running" = "1" ]; then
        echo "  运行状态: [运行中]"
    else
        echo "  运行状态: [已停止]"
    fi
    echo "  主DNS: $DNS_PRIMARY"
    echo "  副DNS: $DNS_SECONDARY"
    echo "  dnsmasq: $([ "$dnsmasq_running" = "1" ] && echo "运行中" || echo "未运行")"
    echo "  iptables: $([ "$iptables_active" = "1" ] && echo "已设置" || echo "未设置")"
    echo "  私有DNS: $(settings get global private_dns_mode 2>/dev/null || echo "未知")"
    echo "========================================"
}

# 切换开关
toggle() {
    read_config
    if [ "$ENABLED" = "1" ]; then
        ENABLED=0
        save_config
        stop_forcedns
        echo "ForceDNS 已关闭"
    else
        ENABLED=1
        save_config
        start_forcedns
        echo "ForceDNS 已开启"
    fi
    show_status
}

# 命令入口
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
