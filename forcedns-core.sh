#!/system/bin/sh
#=============================================
# ForceDNS 核心脚本 - DNS劫持引擎
#=============================================

MODDIR=${0%/*}
CONF_DIR="$MODDIR/data"
CONF_FILE="$CONF_DIR/forcedns.conf"
DNSMASQ_CONF="$CONF_DIR/dnsmasq.conf"
PID_FILE="$CONF_DIR/forcedns.pid"
DNSMASQ_PID="$CONF_DIR/dnsmasq.pid"
LOG_FILE="$CONF_DIR/forcedns.log"
PORT=5353
WEB_PORT=8953

# 预设DNS配置
PRESET_DNS="
AliDNS|223.5.5.5|223.6.6.6
TencentDNS|119.29.29.29|182.254.116.116
BaiduDNS|180.76.76.76|180.76.76.76
114DNS|114.114.114.114|114.114.115.115
GoogleDNS|8.8.8.8|8.8.4.4
CloudflareDNS|1.1.1.1|1.0.0.1
Quad9DNS|9.9.9.9|149.112.112.112
OpenDNS|208.67.222.222|208.67.220.220
NextDNS|45.90.28.0|45.90.30.0
AdGuardDNS|94.140.14.14|94.140.15.15
"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 读取配置
read_config() {
    if [ -f "$CONF_FILE" ]; then
        . "$CONF_FILE"
    else
        # 默认配置
        ENABLED=1
        DNS_PRIMARY="223.5.5.5"
        DNS_SECONDARY="223.6.6.6"
        PRESET_NAME="AliDNS"
        CUSTOM_DNS=""
        HIJACK_IPV6=1
        WHITELIST_UID=""
        LOG_ENABLED=1
        save_config
    fi
}

# 保存配置
save_config() {
    mkdir -p "$CONF_DIR"
    cat > "$CONF_FILE" << EOF
ENABLED=$ENABLED
DNS_PRIMARY=$DNS_PRIMARY
DNS_SECONDARY=$DNS_SECONDARY
PRESET_NAME=$PRESET_NAME
CUSTOM_DNS=$CUSTOM_DNS
HIJACK_IPV6=$HIJACK_IPV6
WHITELIST_UID=$WHITELIST_UID
LOG_ENABLED=$LOG_ENABLED
EOF
}

# 生成dnsmasq配置
gen_dnsmasq_conf() {
    mkdir -p "$CONF_DIR"
    cat > "$DNSMASQ_CONF" << EOF
# ForceDNS dnsmasq 配置
port=$PORT
no-resolv
server=$DNS_PRIMARY
server=$DNS_SECONDARY
cache-size=4096
min-cache-ttl=3600
dns-forward-max=1000
EOF

    # 如果有自定义DNS则追加
    if [ -n "$CUSTOM_DNS" ]; then
        for dns in $CUSTOM_DNS; do
            echo "server=$dns" >> "$DNSMASQ_CONF"
        done
    fi

    log_msg "dnsmasq配置已生成: 主DNS=$DNS_PRIMARY 备DNS=$DNS_SECONDARY"
}

# 启动dnsmasq
start_dnsmasq() {
    # 先停止已有的
    stop_dnsmasq

    gen_dnsmasq_conf

    # 查找dnsmasq二进制
    DNSMASQ_BIN=""
    if [ -x "$MODDIR/system/bin/dnsmasq" ]; then
        DNSMASQ_BIN="$MODDIR/system/bin/dnsmasq"
    elif command -v dnsmasq >/dev/null 2>&1; then
        DNSMASQ_BIN="dnsmasq"
    else
        log_msg "错误: 未找到dnsmasq"
        return 1
    fi

    $DNSMASQ_BIN -C "$DNSMASQ_CONF" -x "$DNSMASQ_PID" && {
        log_msg "dnsmasq已启动 (端口:$PORT)"
        return 0
    }

    log_msg "dnsmasq启动失败，尝试备用方式"
    # 备用: 不使用pid文件
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
        local pid=$(cat "$DNSMASQ_PID" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            log_msg "dnsmasq已停止 (PID:$pid)"
        fi
        rm -f "$DNSMASQ_PID"
    fi
    # 确保所有dnsmasq实例都停止
    killall dnsmasq 2>/dev/null
}

# 设置iptables规则 - 核心劫持逻辑
setup_iptables() {
    # 先清理旧规则
    cleanup_iptables

    # 创建自定义链
    iptables -t nat -N FORCEDNS 2>/dev/null
    ip6tables -t nat -N FORCEDNS 2>/dev/null

    # 白名单UID跳过（如系统关键服务）
    if [ -n "$WHITELIST_UID" ]; then
        for uid in $WHITELIST_UID; do
            iptables -t nat -A FORCEDNS -m owner --uid-owner "$uid" -j RETURN
        done
    fi

    # 劫持所有UDP 53端口的DNS请求到本地dnsmasq
    iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # 劫持TCP 53端口的DNS请求
    iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # 将自定义链挂载到OUTPUT链（本机发出的DNS请求）
    iptables -t nat -A OUTPUT -j FORCEDNS

    # 处理来自其他应用通过本机转发的DNS请求
    # 检查PREROUTING链是否存在（设备作为热点时）
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # IPv6支持
    if [ "$HIJACK_IPV6" = "1" ]; then
        ip6tables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT
        ip6tables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT
        ip6tables -t nat -A OUTPUT -j FORCEDNS
        ip6tables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT
        ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT
    fi

    # 阻止应用绕过DNS直接使用硬编码IP
    # 通过在mangle表标记DNS包
    iptables -t mangle -N FORCEDNS_MANGLE 2>/dev/null
    iptables -t mangle -A FORCEDNS_MANGLE -p udp --dport 53 -j MARK --set-mark 0x1fdns
    iptables -t mangle -A FORCEDNS_MANGLE -p tcp --dport 53 -j MARK --set-mark 0x1fdns
    iptables -t mangle -A OUTPUT -j FORCEDNS_MANGLE

    log_msg "iptables劫持规则已设置"
}

# 清理iptables规则
cleanup_iptables() {
    # 移除自定义链引用
    iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t mangle -D OUTPUT -j FORCEDNS_MANGLE 2>/dev/null

    # 清空并删除自定义链
    iptables -t nat -F FORCEDNS 2>/dev/null
    iptables -t nat -X FORCEDNS 2>/dev/null
    iptables -t mangle -F FORCEDNS_MANGLE 2>/dev/null
    iptables -t mangle -X FORCEDNS_MANGLE 2>/dev/null

    # IPv6
    ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -F FORCEDNS 2>/dev/null
    ip6tables -t nat -X FORCEDNS 2>/dev/null

    log_msg "iptables规则已清理"
}

# 修改系统DNS设置 - 防止系统使用运营商DNS
set_system_dns() {
    # 备份原始设置
    local dns_prop_file="/data/misc/net/dns.conf"
    local net_cfg="/data/misc/net/netstats.conf"

    # 通过setprop设置DNS
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

    # 修改/resolv.conf（通过Magisk overlay）
    mkdir -p "$MODDIR/system/etc"
    echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

    # 使用settings命令设置私有DNS为关闭（防止DoH绕过）
    settings put global private_dns_mode off 2>/dev/null

    log_msg "系统DNS设置已修改为本地"
}

# 恢复系统DNS设置
restore_system_dns() {
    # 恢复setprop
    setprop net.dns1 ""
    setprop net.dns2 ""
    setprop net.wlan0.dns1 ""
    setprop net.wlan0.dns2 ""
    setprop net.rmnet0.dns1 ""
    setprop net.rmnet0.dns2 ""

    # 恢复私有DNS
    settings put global private_dns_mode opportunistic 2>/dev/null

    log_msg "系统DNS设置已恢复"
}

# 启动ForceDNS
start_forcedns() {
    read_config

    if [ "$ENABLED" != "1" ]; then
        log_msg "ForceDNS已禁用，跳过启动"
        return 0
    fi

    log_msg "========== ForceDNS 启动 =========="

    # 启动dnsmasq
    if start_dnsmasq; then
        log_msg "dnsmasq启动成功"
    else
        log_msg "dnsmasq启动失败"
        return 1
    fi

    # 设置系统DNS
    set_system_dns

    # 设置iptables劫持
    setup_iptables

    # 记录PID
    echo $$ > "$PID_FILE"

    log_msg "ForceDNS启动完成 - DNS: $DNS_PRIMARY / $DNS_SECONDARY"
}

# 停止ForceDNS
stop_forcedns() {
    log_msg "========== ForceDNS 停止 =========="

    # 清理iptables
    cleanup_iptables

    # 停止dnsmasq
    stop_dnsmasq

    # 恢复系统DNS
    restore_system_dns

    # 清理PID
    rm -f "$PID_FILE"

    log_msg "ForceDNS已停止"
}

# 获取状态
get_status() {
    read_config

    local dnsmasq_running=0
    if [ -f "$DNSMASQ_PID" ] && kill -0 $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null; then
        dnsmasq_running=1
    fi

    local iptables_active=0
    if iptables -t nat -L FORCEDNS >/dev/null 2>&1; then
        iptables_active=1
    fi

    echo "{"
    echo "  \"enabled\": $ENABLED,"
    echo "  \"running\": $([ "$dnsmasq_running" = "1" ] && [ "$iptables_active" = "1" ] && echo 1 || echo 0),"
    echo "  \"dnsmasq_running\": $dnsmasq_running,"
    echo "  \"iptables_active\": $iptables_active,"
    echo "  \"dns_primary\": \"$DNS_PRIMARY\","
    echo "  \"dns_secondary\": \"$DNS_SECONDARY\","
    echo "  \"preset_name\": \"$PRESET_NAME\","
    echo "  \"custom_dns\": \"$CUSTOM_DNS\","
    echo "  \"hijack_ipv6\": $HIJACK_IPV6,"
    echo "  \"whitelist_uid\": \"$WHITELIST_UID\","
    echo "  \"log_enabled\": $LOG_ENABLED"
    echo "}"
}

# 获取预设DNS列表
get_presets() {
    echo "["
    local first=1
    echo "$PRESET_DNS" | while IFS='|' read -r name primary secondary; do
        [ -z "$name" ] && continue
        [ "$first" = "1" ] && first=0 || echo ","
        echo -n "  {\"name\": \"$name\", \"primary\": \"$primary\", \"secondary\": \"$secondary\"}"
    done
    echo ""
    echo "]"
}

# 应用预设
apply_preset() {
    local preset_name="$1"
    echo "$PRESET_DNS" | while IFS='|' read -r name primary secondary; do
        if [ "$name" = "$preset_name" ]; then
            DNS_PRIMARY="$primary"
            DNS_SECONDARY="$secondary"
            PRESET_NAME="$name"
            CUSTOM_DNS=""
            save_config
            # 重启服务
            stop_forcedns
            start_forcedns
            log_msg "已应用预设: $name"
            return 0
        fi
    done
}

# 应用自定义DNS
apply_custom() {
    local primary="$1"
    local secondary="$2"
    DNS_PRIMARY="$primary"
    DNS_SECONDARY="$secondary"
    PRESET_NAME="Custom"
    save_config
    stop_forcedns
    start_forcedns
    log_msg "已应用自定义DNS: $primary / $secondary"
}

# 根据命令行参数执行
case "$1" in
    start)
        start_forcedns
        ;;
    stop)
        stop_forcedns
        ;;
    restart)
        stop_forcedns
        sleep 1
        start_forcedns
        ;;
    status)
        get_status
        ;;
    presets)
        get_presets
        ;;
    apply_preset)
        apply_preset "$2"
        ;;
    apply_custom)
        apply_custom "$2" "$3"
        ;;
    set_config)
        read_config
        shift
        while [ $# -gt 0 ]; do
            case "$1" in
                enabled=*) ENABLED="${1#enabled=}" ;;
                dns_primary=*) DNS_PRIMARY="${1#dns_primary=}" ;;
                dns_secondary=*) DNS_SECONDARY="${1#dns_secondary=}" ;;
                hijack_ipv6=*) HIJACK_IPV6="${1#hijack_ipv6=}" ;;
                whitelist_uid=*) WHITELIST_UID="${1#whitelist_uid=}" ;;
                log_enabled=*) LOG_ENABLED="${1#log_enabled=}" ;;
            esac
            shift
        done
        save_config
        ;;
    reload)
        stop_forcedns
        sleep 1
        read_config
        start_forcedns
        ;;
    *)
        echo "用法: forcedns-core.sh {start|stop|restart|status|presets|apply_preset|apply_custom|set_config|reload}"
        ;;
esac
