#!/system/bin/sh
#=============================================
<<<<<<< HEAD
# ForceDNS 核心脚本 v5.0
# 架构: iptables → dnsmasq(5353) → 国内走114(明文) / 外网走dnsproxy(5354) → DoH
=======
# ForceDNS 核心脚本 v4.0
# 架构: iptables → dnsmasq(5353) → 国内走114(明文) / 外网走dnsproxy(5354) → DoT → 1.1.1.1:853
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
#=============================================

MODDIR=${0%/*}
CONF_DIR="$MODDIR/data"
CONF_FILE="$CONF_DIR/forcedns.conf"
DNSMASQ_CONF="$CONF_DIR/dnsmasq.conf"
DNSMASQ_PID="$CONF_DIR/dnsmasq.pid"
DNSPROXY_PID="$CONF_DIR/dnsproxy.pid"
LOG_FILE="$CONF_DIR/forcedns.log"
PORT_DNSMASQ=5353
PORT_DNSPROXY=5354

DNS_DOMESTIC="114.114.114.114"
<<<<<<< HEAD
DNS_FOREIGN="223.5.5.5"
=======
DNS_FOREIGN="1.1.1.1"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6

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

#=============================================
# dnsmasq配置: 国内域名→114, 其他→dnsproxy(5354)
#=============================================
gen_dnsmasq_conf() {
    mkdir -p "$CONF_DIR"
<<<<<<< HEAD
    cat > "$DNSMASQ_CONF" << 'EOF'
# ForceDNS dnsmasq 配置
port=5353
no-resolv
cache-size=8192

# 默认走dnsproxy(加密外网DNS)
server=127.0.0.1#5354

# ============ 国内顶级域名走114 ============
=======
    cat > "$DNSMASQ_CONF" << EOF
# ForceDNS dnsmasq 配置
port=$PORT_DNSMASQ
no-resolv
cache-size=4096
min-cache-ttl=600

# 默认走dnsproxy(加密外网DNS)
server=127.0.0.1#$PORT_DNSPROXY

# 国内域名走114.114.114.114(明文，国内不会被劫持)
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
server=/cn/114.114.114.114
server=/com.cn/114.114.114.114
server=/net.cn/114.114.114.114
server=/org.cn/114.114.114.114
server=/gov.cn/114.114.114.114
server=/edu.cn/114.114.114.114
server=/ac.cn/114.114.114.114
<<<<<<< HEAD
server=/mil.cn/114.114.114.114
=======
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
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

<<<<<<< HEAD
# ============ 常用国内域名走114（精简版，可按需增删）============
server=/baidu.com/114.114.114.114
server=/baidu.cn/114.114.114.114
server=/bdimg.com/114.114.114.114
server=/bdstatic.com/114.114.114.114
server=/hao123.com/114.114.114.114
server=/sogou.com/114.114.114.114
server=/so.com/114.114.114.114
server=/360.cn/114.114.114.114
server=/sm.cn/114.114.114.114
server=/alibaba.com/114.114.114.114
server=/taobao.com/114.114.114.114
server=/tmall.com/114.114.114.114
server=/alipay.com/114.114.114.114
server=/aliyun.com/114.114.114.114
server=/aliyuncs.com/114.114.114.114
server=/alicdn.com/114.114.114.114
server=/1688.com/114.114.114.114
server=/dingtalk.com/114.114.114.114
server=/youku.com/114.114.114.114
server=/tudou.com/114.114.114.114
server=/qq.com/114.114.114.114
server=/tencent.com/114.114.114.114
server=/tencentcloud.com/114.114.114.114
server=/weixin.qq.com/114.114.114.114
server=/wechat.com/114.114.114.114
server=/gtimg.cn/114.114.114.114
server=/qpic.cn/114.114.114.114
server=/qlogo.cn/114.114.114.114
server=/idqqimg.com/114.114.114.114
server=/myqcloud.com/114.114.114.114
server=/qcloud.com/114.114.114.114
server=/dns.pub/114.114.114.114
server=/qqmail.com/114.114.114.114
server=/foxmail.com/114.114.114.114
server=/qzone.com/114.114.114.114
server=/qqmusic.com/114.114.114.114
server=/qqgame.com/114.114.114.114
server=/qqlive.com/114.114.114.114
server=/tenpay.com/114.114.114.114
server=/weiyun.com/114.114.114.114
server=/soso.com/114.114.114.114
server=/wegame.com/114.114.114.114
server=/dnspod.com/114.114.114.114
server=/bytedance.com/114.114.114.114
server=/byteimg.com/114.114.114.114
server=/toutiao.com/114.114.114.114
server=/douyin.com/114.114.114.114
server=/iesdouyin.com/114.114.114.114
server=/snssdk.com/114.114.114.114
server=/ixigua.com/114.114.114.114
server=/volcengine.com/114.114.114.114
server=/feishu.cn/114.114.114.114
server=/lark.com/114.114.114.114
server=/xigua.com/114.114.114.114
server=/jd.com/114.114.114.114
server=/jdpay.com/114.114.114.114
server=/jcloud.com/114.114.114.114
server=/jdcloud.com/114.114.114.114
server=/163.com/114.114.114.114
server=/126.com/114.114.114.114
server=/netease.com/114.114.114.114
server=/yeah.net/114.114.114.114
server=/163yun.com/114.114.114.114
server=/163music.com/114.114.114.114
server=/kaola.com/114.114.114.114
server=/lofter.com/114.114.114.114
server=/sina.com.cn/114.114.114.114
server=/sina.cn/114.114.114.114
server=/weibo.com/114.114.114.114
server=/t.cn/114.114.114.114
server=/sinajs.cn/114.114.114.114
server=/sinaimg.cn/114.114.114.114
server=/mi.com/114.114.114.114
server=/xiaomi.com/114.114.114.114
server=/miui.com/114.114.114.114
server=/mipay.com/114.114.114.114
server=/wps.cn/114.114.114.114
server=/huawei.com/114.114.114.114
server=/huawei.cn/114.114.114.114
server=/hihonor.com/114.114.114.114
server=/honor.com/114.114.114.114
server=/huaweicloud.com/114.114.114.114
server=/oppo.com/114.114.114.114
server=/oppo.cn/114.114.114.114
server=/oneplus.com/114.114.114.114
server=/realme.com/114.114.114.114
server=/coloros.com/114.114.114.114
server=/heytap.com/114.114.114.114
server=/vivo.com/114.114.114.114
server=/vivo.cn/114.114.114.114
server=/pinduoduo.com/114.114.114.114
server=/pdd.com/114.114.114.114
server=/meituan.com/114.114.114.114
server=/dianping.com/114.114.114.114
server=/didichuxing.com/114.114.114.114
server=/didi.cn/114.114.114.114
server=/ctrip.com/114.114.114.114
server=/qunar.com/114.114.114.114
server=/tongcheng.com/114.114.114.114
server=/ly.com/114.114.114.114
server=/elong.com/114.114.114.114
server=/trip.com/114.114.114.114
server=/bilibili.com/114.114.114.114
server=/bilibili.tv/114.114.114.114
server=/biliimg.com/114.114.114.114
server=/zhihu.com/114.114.114.114
server=/zhihu.cn/114.114.114.114
server=/zhihuimg.com/114.114.114.114
server=/kuaishou.com/114.114.114.114
server=/ksapisrv.com/114.114.114.114
server=/ksyun.com/114.114.114.114
server=/sohu.com/114.114.114.114
server=/sohu.cn/114.114.114.114
server=/sohu-inc.com/114.114.114.114
server=/ifeng.com/114.114.114.114
server=/ifeng.cn/114.114.114.114
server=/csdn.net/114.114.114.114
server=/csdnimg.cn/114.114.114.114
server=/douban.com/114.114.114.114
server=/doubanio.com/114.114.114.114
server=/iqiyi.com/114.114.114.114
server=/iqiyi.cn/114.114.114.114
server=/qiyi.com/114.114.114.114
server=/v.qq.com/114.114.114.114
server=/qqvideo.com/114.114.114.114
server=/qqfilm.com/114.114.114.114
server=/mgtv.com/114.114.114.114
server=/mgtv.cn/114.114.114.114
server=/music.163.com/114.114.114.114
server=/y.qq.com/114.114.114.114
server=/kugou.com/114.114.114.114
server=/kuwo.cn/114.114.114.114
server=/douyu.com/114.114.114.114
server=/huya.com/114.114.114.114
server=/pan.baidu.com/114.114.114.114
server=/yun.baidu.com/114.114.114.114
server=/baiduyun.com/114.114.114.114
server=/aliyundrive.com/114.114.114.114
server=/aliyunpan.com/114.114.114.114
server=/teambition.com/114.114.114.114
server=/123pan.com/114.114.114.114
server=/123pan.cn/114.114.114.114
server=/map.baidu.com/114.114.114.114
server=/amap.com/114.114.114.114
server=/gaode.com/114.114.114.114
server=/autonavi.com/114.114.114.114
server=/map.qq.com/114.114.114.114
server=/wecom.qq.com/114.114.114.114
server=/work.weixin.qq.com/114.114.114.114
server=/12306.cn/114.114.114.114
server=/cnki.net/114.114.114.114
server=/acfun.cn/114.114.114.114
server=/52pojie.cn/114.114.114.114
server=/smzdm.com/114.114.114.114
server=/jianshu.com/114.114.114.114
server=/juejin.cn/114.114.114.114
server=/segmentfault.com/114.114.114.114
server=/v2ex.com/114.114.114.114
server=/github.com/114.114.114.114
server=/github.io/114.114.114.114
server=/githubusercontent.com/114.114.114.114
server=/githubassets.com/114.114.114.114
server=/githubstatus.com/114.114.114.114
server=/phei.com.cn/114.114.114.114
server=/tup.com.cn/114.114.114.114
server=/cmpbook.com/114.114.114.114
EOF

    log_msg "dnsmasq配置已生成: 国内→$DNS_DOMESTIC 外网→dnsproxy(DoH)"
}

#=============================================
# dnsproxy: DoH加密外网DNS查询
=======
# 国内常见服务走114
server=/baidu.com/114.114.114.114
server=/qq.com/114.114.114.114
server=/tencent.com/114.114.114.114
server=/weixin.qq.com/114.114.114.114
server=/wechat.com/114.114.114.114
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
server=/cnki.net/114.114.114.114
server=/doubanio.com/114.114.114.114
server=/aliyuncs.com/114.114.114.114
server=/aliyun.com/114.114.114.114
server=/tencentcloudapi.com/114.114.114.114
server=/qcloud.com/114.114.114.114
server=/meituan.net/114.114.114.114
server=/ksapisrv.com/114.114.114.114
server=/kuaishou.com/114.114.114.114
server=/ixigua.com/114.114.114.114
server=/bytedance.com/114.114.114.114
server=/byteimg.com/114.114.114.114
server=/feiliao.com/114.114.114.114
server=/pipix.com/114.114.114.114
server=/pipilong.com/114.114.114.114
server=/snssdk.com/114.114.114.114
server=/amemv.com/114.114.114.114
server=/musical.ly/114.114.114.114
server=/iesdouyin.com/114.114.114.114
server=/bdimg.com/114.114.114.114
server=/bdstatic.com/114.114.114.114
server=/bcebos.com/114.114.114.114
server=/baidubcr.com/114.114.114.114
server=/baidustatic.com/114.114.114.114
server=/bcebos.com/114.114.114.114
server=/qpic.cn/114.114.114.114
server=/gtimg.cn/114.114.114.114
server=/idqqimg.com/114.114.114.114
server=/qlogo.cn/114.114.114.114
server=/myqcloud.com/114.114.114.114
EOF

    log_msg "dnsmasq配置已生成: 国内→$DNS_DOMESTIC 外网→dnsproxy(DoT)"
}

#=============================================
# dnsproxy: DoT加密外网DNS查询
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
#=============================================
start_dnsproxy() {
    stop_dnsproxy

    local dnsproxy_bin=""
    if [ -x "$MODDIR/system/bin/dnsproxy" ]; then
        dnsproxy_bin="$MODDIR/system/bin/dnsproxy"
    elif command -v dnsproxy >/dev/null 2>&1; then
<<<<<<< HEAD
        dnsproxy_bin=$(command -v dnsproxy)
=======
        dnsproxy_bin=$(which dnsproxy)
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    else
        log_msg "dnsproxy未找到，外网DNS将使用明文(可能被劫持)"
        return 1
    fi

    log_msg "使用dnsproxy: $dnsproxy_bin"

<<<<<<< HEAD
    # 使用TCP明文查询（运营商难以篡改），多个上游
    # 混合上游：国内DoT + 国外DoH（备用）
$dnsproxy_bin \
    --insecure \
    -l 127.0.0.1 \
    -p $PORT_DNSPROXY \
    -u https://223.5.5.5/dns-query \
    -u https://119.29.29.29/dns-query \
    --upstream-mode=fastest_addr \
    --cache \
    --cache-size=4096 \
    --cache-min-ttl=300 \
    --timeout=15s \
    >> "$LOG_FILE" 2>&1 &
=======
    # dnsproxy: 监听5354, 上游用DoT到1.1.1.1:853
    # 注意: 部分版本dnsproxy用-l代替--listen-address
    $dnsproxy_bin \
        -l 127.0.0.1 \
        -p $PORT_DNSPROXY \
        -u tls://1.1.1.1 \
        -u tls://1.0.0.1 \
        --cache \
        --cache-size=4096 \
        --cache-min-ttl=300 \
        >> "$LOG_FILE" 2>&1 &
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6

    local pid=$!
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSPROXY_PID"
<<<<<<< HEAD
        log_msg "dnsproxy已启动 (TCP明文, PID=$pid)"
=======
        log_msg "dnsproxy已启动 (PID=$pid, DoT→1.1.1.1:853)"
        return 0
    fi

    # 备用: DoH
    $dnsproxy_bin \
        -l 127.0.0.1 \
        -p $PORT_DNSPROXY \
        -u https://1.1.1.1/dns-query \
        -u https://1.0.0.1/dns-query \
        --cache \
        --cache-size=4096 \
        >> "$LOG_FILE" 2>&1 &

    pid=$!
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSPROXY_PID"
        log_msg "dnsproxy已启动(备用, PID=$pid)"
        return 0
    fi

    # 备用2: DoH
    $dnsproxy_bin \
        -l 127.0.0.1 \
        -p $PORT_DNSPROXY \
        -u https://1.1.1.1/dns-query \
        -u https://1.0.0.1/dns-query \
        --cache \
        --cache-size=4096 \
        >> "$LOG_FILE" 2>&1 &

    pid=$!
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSPROXY_PID"
        log_msg "dnsproxy已启动(DoH备用, PID=$pid)"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        return 0
    fi

    log_msg "dnsproxy启动失败"
    return 1
}

stop_dnsproxy() {
    if [ -f "$DNSPROXY_PID" ]; then
<<<<<<< HEAD
        kill "$(cat "$DNSPROXY_PID" 2>/dev/null)" 2>/dev/null
=======
        kill $(cat "$DNSPROXY_PID" 2>/dev/null) 2>/dev/null
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        rm -f "$DNSPROXY_PID"
    fi
    killall dnsproxy 2>/dev/null
    sleep 0.5
}

#=============================================
<<<<<<< HEAD
# dnsmasq启动（优先使用模块目录下的新版）
=======
# dnsmasq启动
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
#=============================================
start_dnsmasq() {
    stop_dnsmasq
    gen_dnsmasq_conf

    local dnsmasq_bin=""
<<<<<<< HEAD
    # 优先使用模块目录下的 dnsmasq（新版）
    if [ -x "$MODDIR/system/bin/dnsmasq" ]; then
        dnsmasq_bin="$MODDIR/system/bin/dnsmasq"
    elif command -v dnsmasq >/dev/null 2>&1; then
        dnsmasq_bin=$(command -v dnsmasq)
=======
    if command -v dnsmasq >/dev/null 2>&1; then
        dnsmasq_bin=$(which dnsmasq)
    elif [ -x "$MODDIR/system/bin/dnsmasq" ]; then
        dnsmasq_bin="$MODDIR/system/bin/dnsmasq"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    else
        log_msg "错误: 未找到dnsmasq"
        echo "错误: 未找到dnsmasq"
        return 1
    fi

    log_msg "使用dnsmasq: $dnsmasq_bin"

<<<<<<< HEAD
    mkdir -p /var/run 2>/dev/null

    $dnsmasq_bin -C "$DNSMASQ_CONF" --user=root --pid-file="$DNSMASQ_PID" 2>>"$LOG_FILE"
    sleep 1
    if [ -f "$DNSMASQ_PID" ] || pgrep -f "dnsmasq.*$PORT_DNSMASQ" >/dev/null 2>&1; then
        log_msg "dnsmasq已启动"
        return 0
    fi

=======
    # 确保/var/run存在(旧版dnsmasq需要)
    mkdir -p /var/run 2>/dev/null

    # 方法1: 指定pid-file
    $dnsmasq_bin -C "$DNSMASQ_CONF" --user=root --pid-file="$DNSMASQ_PID" 2>>"$LOG_FILE"
    sleep 1
    if [ -f "$DNSMASQ_PID" ] || pgrep -f "dnsmasq.*$PORT_DNSMASQ" >/dev/null 2>&1; then
        log_msg "dnsmasq已启动(方法1)"
        return 0
    fi

    # 方法2: no-daemon后台
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    $dnsmasq_bin -C "$DNSMASQ_CONF" --user=root --no-daemon 2>>"$LOG_FILE" &
    local pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
<<<<<<< HEAD
        log_msg "dnsmasq已启动(no-daemon, PID=$pid)"
=======
        log_msg "dnsmasq已启动(方法2, PID=$pid)"
        return 0
    fi

    # 方法3: keep-in-foreground
    $dnsmasq_bin -k -C "$DNSMASQ_CONF" --user=root 2>>"$LOG_FILE" &
    pid=$!
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$DNSMASQ_PID"
        log_msg "dnsmasq已启动(方法3, PID=$pid)"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        return 0
    fi

    log_msg "dnsmasq启动失败"
    return 1
}

stop_dnsmasq() {
    if [ -f "$DNSMASQ_PID" ]; then
<<<<<<< HEAD
        kill "$(cat "$DNSMASQ_PID" 2>/dev/null)" 2>/dev/null
=======
        kill $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        rm -f "$DNSMASQ_PID"
    fi
    killall dnsmasq 2>/dev/null
    sleep 0.5
}

#=============================================
# iptables规则
#=============================================
setup_iptables() {
    cleanup_iptables

<<<<<<< HEAD
    iptables -t nat -N FORCEDNS 2>/dev/null

    iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
    iptables -t nat -A FORCEDNS -d 114.114.115.115 -j RETURN

=======
    # DNS劫持: 所有53端口 → 本地dnsmasq(5353)
    iptables -t nat -N FORCEDNS 2>/dev/null

    # 不劫持到授权DNS的出站(防止循环)
    iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
    iptables -t nat -A FORCEDNS -d 114.114.115.115 -j RETURN

    # 劫持所有DNS到本地dnsmasq
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ
    iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ

    iptables -t nat -A OUTPUT -j FORCEDNS
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ
    iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ

<<<<<<< HEAD
=======
    # IPv6
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    ip6tables -t nat -N FORCEDNS 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT_DNSMASQ 2>/dev/null
    ip6tables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT_DNSMASQ 2>/dev/null
    ip6tables -t nat -A OUTPUT -j FORCEDNS 2>/dev/null
    ip6tables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination [::1]:$PORT_DNSMASQ 2>/dev/null
    ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination [::1]:$PORT_DNSMASQ 2>/dev/null

<<<<<<< HEAD
=======
    # 防火墙: 阻止绕过
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    iptables -N FORCEDNS_FW 2>/dev/null
    iptables -A FORCEDNS_FW -o lo -j RETURN
    iptables -A FORCEDNS_FW -m state --state ESTABLISHED,RELATED -j RETURN

<<<<<<< HEAD
    iptables -A FORCEDNS_FW -d 114.114.114.114 -j RETURN
    iptables -A FORCEDNS_FW -d 114.114.115.115 -j RETURN

    iptables -A FORCEDNS_FW -d 223.5.5.5 -p tcp --dport 853 -j RETURN
    iptables -A FORCEDNS_FW -d 119.29.29.29 -p tcp --dport 853 -j RETURN
    iptables -A FORCEDNS_FW -d 223.5.5.5 -p tcp --dport 443 -j RETURN
    iptables -A FORCEDNS_FW -d 119.29.29.29 -p tcp --dport 443 -j RETURN

    for dns in 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 208.67.222.222 208.67.220.220 \
               180.76.76.76 94.140.14.14 94.140.15.15; do
=======
    # 允许授权DNS
    iptables -A FORCEDNS_FW -d 114.114.114.114 -j RETURN
    iptables -A FORCEDNS_FW -d 114.114.115.115 -j RETURN

    # 允许dnsproxy到1.1.1.1的TLS连接(853端口)
    iptables -A FORCEDNS_FW -d 1.1.1.1 -p tcp --dport 853 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -p tcp --dport 853 -j RETURN
    # DoH (443端口到1.1.1.1)
    iptables -A FORCEDNS_FW -d 1.1.1.1 -p tcp --dport 443 -j RETURN
    iptables -A FORCEDNS_FW -d 1.0.0.1 -p tcp --dport 443 -j RETURN

    # 阻止其他DNS
    for dns in 8.8.8.8 8.8.4.4 9.9.9.9 208.67.222.222 208.67.220.220 \
               223.5.5.5 223.6.6.6 119.29.29.29 180.76.76.76 \
               94.140.14.14 94.140.15.15; do
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        iptables -A FORCEDNS_FW -d $dns -p udp --dport 53 -j DROP
        iptables -A FORCEDNS_FW -d $dns -p tcp --dport 53 -j DROP
    done

<<<<<<< HEAD
=======
    # 阻止DoH到非授权服务器
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    iptables -A FORCEDNS_FW -d 8.8.8.8 -p tcp --dport 443 -j DROP
    iptables -A FORCEDNS_FW -d 8.8.4.4 -p tcp --dport 443 -j DROP

    iptables -A OUTPUT -j FORCEDNS_FW

    log_msg "iptables规则已设置"
}

cleanup_iptables() {
    iptables -t nat -D OUTPUT -j FORCEDNS 2>/dev/null
    iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:$PORT_DNSMASQ 2>/dev/null
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

#=============================================
# DNS配置覆盖
#=============================================
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

<<<<<<< HEAD
    mkdir -p "$MODDIR/system/etc"
    echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

=======
    # Magisk systemless覆盖
    mkdir -p "$MODDIR/system/etc"
    echo "nameserver 127.0.0.1" > "$MODDIR/system/etc/resolv.conf"

    # Termux
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    local termux_resolv="/data/data/com.termux/files/usr/etc/resolv.conf"
    if [ -d "/data/data/com.termux" ]; then
        mkdir -p "$(dirname "$termux_resolv")" 2>/dev/null
        echo "nameserver 127.0.0.1" > "$termux_resolv" 2>/dev/null
        chmod 644 "$termux_resolv" 2>/dev/null
    fi

<<<<<<< HEAD
=======
    # /data/misc/net
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    if [ -d "/data/misc/net" ]; then
        echo "nameserver 127.0.0.1" > /data/misc/net/resolv.conf 2>/dev/null
    fi

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

#=============================================
# 启动/停止
#=============================================
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

<<<<<<< HEAD
=======
    # 1. 启动dnsproxy(DoT加密外网DNS)
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    local dot_ok=1
    if ! start_dnsproxy; then
        dot_ok=0
        log_msg "dnsproxy启动失败，外网DNS将使用明文(可能被劫持)"
    fi

<<<<<<< HEAD
    if ! start_dnsmasq; then
        log_msg "dnsmasq启动失败，使用纯iptables模式"
        echo "dnsmasq启动失败，使用纯iptables备用模式"
=======
    # 2. 启动dnsmasq(分流)
    if ! start_dnsmasq; then
        log_msg "dnsmasq启动失败，使用纯iptables模式"
        echo "dnsmasq启动失败，使用纯iptables备用模式"
        # 备用: 直接DNAT到114
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        iptables -t nat -N FORCEDNS 2>/dev/null
        iptables -t nat -A FORCEDNS -d 114.114.114.114 -j RETURN
        iptables -t nat -A FORCEDNS -p udp --dport 53 -j DNAT --to-destination 114.114.114.114:53
        iptables -t nat -A FORCEDNS -p tcp --dport 53 -j DNAT --to-destination 114.114.114.114:53
        iptables -t nat -A OUTPUT -j FORCEDNS
        setprop net.dns1 "114.114.114.114"
        setprop net.dns2 "1.1.1.1"
        echo "ForceDNS 已启动(备用模式: 全部→114.114.114.114)"
        return 0
    fi

<<<<<<< HEAD
=======
    # 3. 覆盖DNS + 设置iptables
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    override_dns
    setup_iptables

    if [ "$dot_ok" = "1" ]; then
<<<<<<< HEAD
        log_msg "ForceDNS启动完成 - 国内: $DNS_DOMESTIC(明文) 外网: DoH加密"
        echo "ForceDNS 已启动 (国内→114明文, 外网→DoH加密)"
    else
        log_msg "ForceDNS启动完成(部分) - 国内: $DNS_DOMESTIC 外网: 明文(可能被劫持)"
        echo "ForceDNS 已启动 (国内→114, 外网→明文, dnsproxy未启动)"
=======
        log_msg "ForceDNS启动完成 - 国内: $DNS_DOMESTIC(明文) 外网: $DNS_FOREIGN(DoT加密)"
        echo "ForceDNS 已启动 (国内→114明文, 外网→1.1.1.1 DoT加密)"
    else
        log_msg "ForceDNS启动完成(部分) - 国内: $DNS_DOMESTIC 外网: $DNS_FOREIGN(明文,可能被劫持)"
        echo "ForceDNS 已启动 (国内→114, 外网→1.1.1.1 明文, dnsproxy未启动)"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
    fi
}

stop_forcedns() {
    log_msg "========== ForceDNS 停止 =========="
    cleanup_iptables
    stop_dnsmasq
    stop_dnsproxy
    restore_dns
    log_msg "ForceDNS已停止"
    echo "ForceDNS 已停止"
}

#=============================================
# 状态显示
#=============================================
show_status() {
    read_config
    local dnsmasq_running=0
    local dnsproxy_running=0
    local iptables_active=0

<<<<<<< HEAD
    if [ -f "$DNSMASQ_PID" ] && kill -0 "$(cat "$DNSMASQ_PID" 2>/dev/null)" 2>/dev/null; then
=======
    if [ -f "$DNSMASQ_PID" ] && kill -0 $(cat "$DNSMASQ_PID" 2>/dev/null) 2>/dev/null; then
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        dnsmasq_running=1
    fi
    [ "$dnsmasq_running" = "0" ] && pgrep -f "dnsmasq.*$PORT_DNSMASQ" >/dev/null 2>&1 && dnsmasq_running=1

<<<<<<< HEAD
    if [ -f "$DNSPROXY_PID" ] && kill -0 "$(cat "$DNSPROXY_PID" 2>/dev/null)" 2>/dev/null; then
=======
    if [ -f "$DNSPROXY_PID" ] && kill -0 $(cat "$DNSPROXY_PID" 2>/dev/null) 2>/dev/null; then
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
        dnsproxy_running=1
    fi
    [ "$dnsproxy_running" = "0" ] && pgrep -f "dnsproxy" >/dev/null 2>&1 && dnsproxy_running=1

    iptables -t nat -L FORCEDNS >/dev/null 2>&1 && iptables_active=1

    local running=0
    [ "$iptables_active" = "1" ] && running=1

    echo "========================================"
    echo "  ForceDNS 状态"
    echo "========================================"
    echo "  模块开关: $([ "$ENABLED" = "1" ] && echo "[开启]" || echo "[关闭]")"
    echo "  运行状态: $([ "$running" = "1" ] && echo "[运行中]" || echo "[已停止]")"
    echo "  国内DNS: $DNS_DOMESTIC (明文)"
<<<<<<< HEAD
    echo "  外网DNS: DoH $([ "$dnsproxy_running" = "1" ] && echo "(加密)" || echo "(未加密!)")"
    echo "  dnsmasq: $([ "$dnsmasq_running" = "1" ] && echo "运行中" || echo "未运行")"
    echo "  dnsproxy: $([ "$dnsproxy_running" = "1" ] && echo "运行中(DoH)" || echo "未运行")"
=======
    echo "  外网DNS: $DNS_FOREIGN $([ "$dnsproxy_running" = "1" ] && echo "(DoT加密)" || echo "(明文-未加密!)")"
    echo "  dnsmasq: $([ "$dnsmasq_running" = "1" ] && echo "运行中" || echo "未运行")"
    echo "  dnsproxy: $([ "$dnsproxy_running" = "1" ] && echo "运行中(DoT)" || echo "未运行")"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
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
                echo "  国内DNS(baidu.com): 127.0.0.1 → dnsmasq → 114 (OK)"
            elif [ "$ns_result" = "$DNS_DOMESTIC" ]; then
                echo "  国内DNS(baidu.com): $ns_result (直接模式)"
            else
                echo "  国内DNS(baidu.com): $ns_result (异常)"
            fi
        fi

        local ns2=$(nslookup github.com 2>&1 | grep -i "server" | head -1 | awk '{print $NF}')
        if [ -n "$ns2" ]; then
            if [ "$ns2" = "127.0.0.1" ]; then
                if [ "$dnsproxy_running" = "1" ]; then
<<<<<<< HEAD
                    echo "  外网DNS(github.com): 127.0.0.1 → dnsmasq → dnsproxy(DoH) (OK)"
                else
                    echo "  外网DNS(github.com): 127.0.0.1 → dnsmasq → 明文(可能被劫持)"
=======
                    echo "  外网DNS(github.com): 127.0.0.1 → dnsmasq → dnsproxy(DoT) → 1.1.1.1 (OK)"
                else
                    echo "  外网DNS(github.com): 127.0.0.1 → dnsmasq → 1.1.1.1 (明文,可能被劫持)"
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
                fi
            else
                echo "  外网DNS(github.com): $ns2 (异常)"
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
<<<<<<< HEAD
esac
=======
esac
>>>>>>> bd3b7ed707d100d2f2fbdbed6625df8db97fa5d6
