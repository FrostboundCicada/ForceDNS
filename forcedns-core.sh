#!/system/bin/sh
#=============================================
# ForceDNS 核心脚本 v3.1
# dnsmasq智能分流: 国内走114.114.114.114, 外网走1.1.1.1
# iptables劫持所有DNS到本地dnsmasq
#=============================================

MODDIR=${0%/*}
CONF_DIR="$MODDIR/data"
CONF_FILE="$CONF_DIR/forcedns.conf"
DNSMASQ_CONF="$CONF_DIR/dnsmasq.conf"
DNSMASQ_PID="$CONF_DIR/dnsmasq.pid"
LOG_FILE="$CONF_DIR/forcedns.log"
PORT=5353

DNS_DOMESTIC="114.114.114.114"
DNS_FOREIGN="1.1.1.1"

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

# 生成dnsmasq配置 - 国内域名走114, 其他走1.1.1.1
gen_dnsmasq_conf() {
    mkdir -p "$CONF_DIR"
    cat > "$DNSMASQ_CONF" << 'EOF'
# ForceDNS dnsmasq 配置
port=5353
no-resolv
cache-size=4096
min-cache-ttl=600
dns-forward-max=1000
all-servers

# 默认使用1.1.1.1(外网DNS)
server=1.1.1.1
server=1.0.0.1

# 国内域名走114.114.114.114
server=/cn/114.114.114.114
server=/com.cn/114.114.114.114
server=/net.cn/114.114.114.114
server=/org.cn/114.114.114.114
server=/gov.cn/114.114.114.114
server=/edu.cn/114.114.114.114
server=/ac.cn/114.114.114.114
server=/ah.cn/114.114.114.114
server=/bj.cn/114.114.114.114
server=/cq.cn/114.114.114.114
server=/fj.cn/114.114.114.114
server=/gd.cn/114.114.114.114
server=/gs.cn/114.114.114.114
server=/gz.cn/114.114.114.114
server=/gx.cn/114.114.114.114
server=/hb.cn/114.114.114.114
server=/he.cn/114.114.114.114
server=/hi.cn/114.114.114.114
server=/hk.cn/114.114.114.114
server=/hl.cn/114.114.114.114
server=/hn.cn/114.114.114.114
server=/jl.cn/114.114.114.114
server=/js.cn/114.114.114.114
server=/jx.cn/114.114.114.114
server=/ln.cn/114.114.114.114
server=/mo.cn/114.114.114.114
server=/nm.cn/114.114.114.114
server=/nx.cn/114.114.114.114
server=/qh.cn/114.114.114.114
server=/sc.cn/114.114.114.114
server=/sd.cn/114.114.114.114
server=/sh.cn/114.114.114.114
server=/sn.cn/114.114.114.114
server=/sx.cn/114.114.114.114
server=/tj.cn/114.114.114.114
server=/tw.cn/114.114.114.114
server=/xj.cn/114.114.114.114
server=/xz.cn/114.114.114.114
server=/yn.cn/114.114.114.114
server=/zj.cn/114.114.114.114

# 国内常见服务走114
server=/baidu.com/114.114.114.114
server=/qq.com/114.114.114.114
server=/tencent.com/114.114.114.114
server=/taobao.com/114.114.114.114
server=/tmall.com/114.114.114.114
server=/alibaba.com/114.114.114.114
server=/alicdn.com/114.114.114.114
server=/alipay.com/114.114.114.114
server=/jd.com/114.114.114.114
server=/163.com/114.114.114.114
server=/126.com/114.114.114.114
server=/netease.com/114.114.114.114
server=/sina.com.cn/114.114.114.114
server=/weibo.com/114.114.114.114
server=/zhihu.com/114.114.114.114
server=/bilibili.com/114.114.114.114
server=/douyin.com/114.114.114.114
server=/toutiao.com/114.114.114.114
server=/csdn.net/114.114.114.114
server=/douban.com/114.114.114.114
server=/meituan.com/114.114.114.114
server=/dianping.com/114.114.114.114
server=/mi.com/114.114.114.114
server=/xiaomi.com/114.114.114.114
server=/huawei.com/114.114.114.114
server=/oppo.com/114.114.114.114
server=/vivo.com/114.114.114.114
server=/360.cn/114.114.114.114
server=/sohu.com/114.114.114.114
server=/ifeng.com/114.114.114.114
server=/hao123.com/114.114.114.114
server=/ctrip.com/114.114.114.114
server=/12306.cn/114.114.114.114
server=/b站/114.114.114.114
server=/cnki.net/114.114.114.114
EOF

    log_msg "dnsmasq配置已生成: 国内→$DNS_DOMESTIC 外网→$DNS_FOREIGN"
}

# 启动dnsmasq
start_dnsmasq() {
    stop_dnsmasq
    gen_dnsmasq_conf

    # 查找dnsmasq
    local dnsmasq_bin=""
    if command -v dnsmasq >/dev/null 2>&1; then
        dnsmasq_bin=$(which dnsmasq)
    elif [ -x "$MODDIR/system/bin/dnsmasq" ]; then
        dnsmasq_bin="$MODDIR/system/bin/dnsmasq"
    else
        log_msg "错误: 未找到dnsmasq"
        echo "错误: 未找到dnsmasq"
        return 1
    fi

    log_msg "使用dnsmasq: $dnsmasq_bin"
    log_msg "$($dnsmasq_bin --version 2>&1 | head -1)"

    # 确保/var/run目录存在(部分旧版dnsmasq默认写/var/run/dnsmasq.pid)
    mkdir -p /var/run 2>/dev/null

    # 方法1: 指定pid-file路径(兼容旧版dnsmasq，避免找不到/var/run/)
    $dnsmasq_bin -C "$DNSMASQ_CONF" --user=root --pid-file="$DNSMASQ_PID" 2>>"$LOG_FILE"
    sleep 1
    if [ -f "$DNSMASQ_PID" ] || pgrep -f "dnsmasq.*5353" >/dev/null 2>&1; then
        log_msg "dnsmasq已启动(方法1: pid-file指定路径)"
        return 0
    fi

    # 方法2: 前台模式放后台(--no-daemon不写pidfile，最兼容)
    $dnsmasq_bin -C "$DNSMASQ_CONF" --user=root --no-daemon 2>>"$LOG_FILE" &
    local pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
        log_msg "dnsmasq已启动(方法2: no-daemon后台, PID=$pid)"
        return 0
    fi

    # 方法3: keep-in-foreground模式(-k，不写pidfile)
    $dnsmasq_bin -k -C "$DNSMASQ_CONF" --user=root 2>>"$LOG_FILE" &
    pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
        log_msg "dnsmasq已启动(方法3: keep-in-foreground, PID=$pid)"
        return 0
    fi

    # 方法4: 最简参数+no-daemon(不依赖配置文件)
    $dnsmasq_bin --port=5353 --no-resolv --server=114.114.114.114 --server=1.1.1.1 --user=root --no-daemon 2>>"$LOG_FILE" &
    pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
        log_msg "dnsmasq已启动(方法4: 最简no-daemon, PID=$pid)"
        return 0
    fi

    # 方法5: 绑定127.0.0.1 + no-daemon(避免绑定问题)
    $dnsmasq_bin -C "$DNSMASQ_CONF" --listen-address=127.0.0.1 --user=root --no-daemon 2>>"$LOG_FILE" &
    pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
        log_msg "dnsmasq已启动(方法5: 绑定127.0.0.1, PID=$pid)"
        return 0
    fi

    log_msg "dnsmasq所有启动方式均失败"
    echo "dnsmasq启动失败，查看日志: cat $LOG_FILE"
    return 1
}

# 停止dnsmasq
stop_dnsmasq() {
    if [ -f "$DNSMASQ_PID" ]; then
        kill $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null
        rm -f "$DNSMASQ_PID"
    fi
    # 杀死所有监听5353端口的dnsmasq
    killall dnsmasq 2>/dev/null
    sleep 0.5
}

# 设置iptables
setup_iptables() {
    cleanup_iptables

    # === DNS劫持: 所有53端口 → 本地5353 ===
    iptables -t nat -N FORCEDNS 2>/dev/null

    # 不劫持本地dnsmasq自身的出站请求(防止循环)
    iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
    iptables -t nat -A FORCEDNS -d 114.114.115.115 -j RETURN
    iptables -t nat -A FORCEDNS -d 1.1.1.1 -j RETURN
    iptables -t nat -A FORCEDNS -d 1.0.0.1 -j RETURN

    # 劫持所有DNS到本地dnsmasq
    iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT
    iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # 挂载
    iptables -t nat -A OUTPUT -j FORCEDNS
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT

    # IPv6
    ip6tables -t nat -N FORCEDNS 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -A OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null
    ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT 2>/dev/null

    # === 防火墙: 阻止绕过 ===
    iptables -N FORCEDNS_FW 2>/dev/null
    iptables -A FORCEDNS_FW -o lo -j RETURN
    iptables -A FORCEDNS_FW -m state --state ESTABLISHED,RELATED -j RETURN

    # 允许授权DNS
    iptables -A FORCEDNS_FW -d 114.114.114.114 -j RETURN
    iptables -A FORCEDNS_FW -d 114.114.115.115 -j RETURN
    iptables -A FORCEDNS_FW -d 1.1.1.1 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -j RETURN

    # 阻止其他DNS
    for dns in 8.8.8.8 8.8.4.4 9.9.9.9 208.67.222.222 208.67.220.220 \
               223.5.5.5 223.6.6.6 119.29.29.29 180.76.76.76 \
               94.140.14.14 94.140.15.15; do
        iptables -A FORCEDNS_FW -d $dns -p udp --dport 53 -j DROP
        iptables -A FORCEDNS_FW -d $dns -p tcp --dport 53 -j DROP
    done

    # 阻止DoH绕过
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p tcp --dport 443 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p tcp --dport 443 -j DROP

    iptables -A OUTPUT -j FORCEDNS_FW

    log_msg "iptables规则已设置"
}

cleanup_iptables() {
    iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT 2>/dev/null
    iptables -t nat -F FORCEDNS 2>/dev/null
    iptables -t nat -X FORCEDNS 2>/dev/null
    iptables -D OUTPUT -j FORCEDNS_FW 2>/dev/null
    iptables -F FORCEDNS_FW 2>/dev/null
    iptables -X FORCEDNS_FW 2>/dev/null
    ip6tables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -F FORCEDNS 2>/dev/null
    ip6tables -t nat -X FORCEDNS 2>/dev/null
    log_msg "iptables规则已清理"
}

# 覆盖DNS配置
override_dns() {
    setprop net.dns1 "127.0.0.1"
    setprop net.dns2 "127.0.0.1"
    setprop net.wlan0.dns1 "127.0.0.1"
    setprop net.wlan0.dns2 "127.0.0.1"
    setprop net.rmnet0.dns1 "127.0.0.1"
    setprop net.rmnet0.dns2 "127.0.0.1"
    setprop net.rmnet1.dns1 "127.0.0.1"
    setprop net.rmnet1.dns2 "127.0.0.1"

    settings put global private_dns_mode off 2>/dev/null
    settings put global private_dns_specifier "" 2>/dev/null

    # 系统resolv.conf
    mkdir -p "$MODDIR/system/etc"
    echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

    # Termux
    local termux_resolv="/data/data/com.termux/files/usr/etc/resolv.conf"
    if [ -d "/data/data/com.termux" ]; then
        mkdir -p "$(dirname "$termux_resolv")" 2>/dev/null
        echo "nameserver 127.0.0.1" > "$termux_resolv" 2>/dev/null
        chmod 644 "$termux_resolv" 2>/dev/null
    fi

    for f in /etc/resolv.conf /system/etc/resolv.conf /data/misc/net/resolv.conf; do
        echo "nameserver 127.0.0.1" > "$f" 2>/dev/null
    done

    log_msg "DNS配置已覆盖到127.0.0.1"
}

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

    if ! command -v iptables >/dev/null 2>&1; then
        log_msg "错误: iptables不可用"
        echo "错误: iptables不可用"
        return 1
    fi

    # 启动dnsmasq
    if ! start_dnsmasq; then
        log_msg "dnsmasq启动失败，尝试纯iptables模式"
        echo "dnsmasq启动失败，使用纯iptables备用模式"
        # 备用: 纯iptables直接DNAT到114
        iptables -t nat -N FORCEDNS 2>/dev/null
        iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
        iptables -t nat -A FORCEDNS -d 1.1.1.1 -j RETURN
        iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53
        iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53
        iptables -t nat -A OUTPUT -j FORCEDNS
        iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53
        iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53

        # 覆盖DNS到114(非本地)
        setprop net.dns1 "114.114.114.114"
        setprop net.dns2 "1.1.1.1"
        setprop net.wlan0.dns1 "114.114.114.114"
        setprop net.wlan0.dns2 "1.1.1.1"
        local termux_resolv="/data/data/com.termux/files/usr/etc/resolv.conf"
        if [ -d "/data/data/com.termux" ]; then
            printf "nameserver 114.114.114.114\nnameserver 1.1.1.1\n" > "$termux_resolv" 2>/dev/null
        fi
        echo "ForceDNS 已启动(备用模式: 全部→114.114.114.114)"
        return 0
    fi

    override_dns
    setup_iptables

    log_msg "ForceDNS启动完成 - 国内: $DNS_DOMESTIC 外网: $DNS_FOREIGN"
    echo "ForceDNS 已启动 (国内→114, 外网→1.1.1.1)"
}

# 停止
stop_forcedns() {
    log_msg "========== ForceDNS 停止 =========="
    cleanup_iptables
    stop_dnsmasq
    restore_dns
    log_msg "ForceDNS已停止"
    echo "ForceDNS 已停止"
}

# 显示状态
show_status() {
    read_config
    local dnsmasq_running=0
    local iptables_active=0

    if [ -f "$DNSMASQ_PID" ] && kill -0 $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null; then
        dnsmasq_running=1
    fi
    # 也检查进程
    if [ "$dnsmasq_running" = "0" ] && pgrep -f "dnsmasq.*5353" >/dev/null 2>&1; then
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
    echo "  模块开关: $([ "$ENABLED" = "1" ] && echo "[开启]" || echo "[关闭]")"
    echo "  运行状态: $([ "$running" = "1" ] && echo "[运行中]" || echo "[已停止]")"
    echo "  国内DNS: $DNS_DOMESTIC"
    echo "  外网DNS: $DNS_FOREIGN"
    echo "  dnsmasq: $([ "$dnsmasq_running" = "1" ] && echo "运行中" || echo "未运行")"
    echo "  iptables: $([ "$iptables_active" = "1" ] && echo "已设置" || echo "未设置")"
    echo "  私有DNS: $(settings get global private_dns_mode 2>/dev/null || echo "未知")"
    echo ""
    echo "  --- DNS验证 ---"

    local d1=$(getprop net.dns1 2>/dev/null)
    echo "  net.dns1: ${d1:-空}"

    if [ -f "/data/data/com.termux/files/usr/etc/resolv.conf" ]; then
        local tdns=$(grep "^nameserver" /data/data/com.termux/files/usr/etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}')
        echo "  Termux DNS: ${tdns:-未设置}"
    fi

    if command -v nslookup >/dev/null 2>&1; then
        local ns_result=$(nslookup baidu.com 2>&1 | grep -i "server" | head -1 | awk '{print $NF}')
        if [ -n "$ns_result" ]; then
            if [ "$ns_result" = "127.0.0.1" ]; then
                echo "  实际DNS: 127.0.0.1 (劫持→dnsmasq生效!)"
            elif [ "$ns_result" = "$DNS_DOMESTIC" ] || [ "$ns_result" = "$DNS_FOREIGN" ]; then
                echo "  实际DNS: $ns_result (备用模式生效)"
            else
                echo "  实际DNS: $ns_result (劫持未生效)"
            fi
        fi
    fi

    echo "========================================"
}

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
