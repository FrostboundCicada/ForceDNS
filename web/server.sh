#!/system/bin/sh
#=============================================
# ForceDNS Web服务器 - 轻量HTTP API
#=============================================

MODDIR=/data/adb/modules/forcedns
WEB_DIR="$MODDIR/web"
CORE="$MODDIR/forcedns-core.sh"
CONF_DIR="$MODDIR/data"
WEB_PID="$CONF_DIR/web.pid"
WEB_PORT=8953

# 解析HTTP请求
parse_request() {
    read -r METHOD URL PROTO
    # 读取headers
    CONTENT_LENGTH=0
    while IFS=': ' read -r KEY VALUE; do
        VALUE=$(echo "$VALUE" | tr -d '\r')
        case "$KEY" in
            Content-Length) CONTENT_LENGTH="$VALUE" ;;
        esac
        [ -z "$KEY" ] && break
    done
    # 读取body
    BODY=""
    if [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null; then
        BODY=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
    fi
}

# 发送HTTP响应
send_response() {
    local code="$1"
    local content_type="$2"
    local body="$3"
    local status_text="OK"
    [ "$code" = "200" ] && status_text="OK"
    [ "$code" = "400" ] && status_text="Bad Request"
    [ "$code" = "404" ] && status_text="Not Found"
    [ "$code" = "500" ] && status_text="Internal Server Error"

    printf "HTTP/1.1 %s %s\r\n" "$code" "$status_text"
    printf "Content-Type: %s\r\n" "$content_type"
    printf "Content-Length: %d\r\n" "$(echo -n "$body" | wc -c)"
    printf "Access-Control-Allow-Origin: *\r\n"
    printf "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
    printf "Access-Control-Allow-Headers: Content-Type\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    printf "%s" "$body"
}

# 发送JSON响应
send_json() {
    local code="$1"
    local json="$2"
    send_response "$code" "application/json" "$json"
}

# 处理API请求
handle_api() {
    local action=$(echo "$BODY" | grep -o '"action"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"action"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

    case "$action" in
        status)
            local status_output=$(sh "$CORE" status 2>/dev/null)
            send_json 200 "{\"success\":true,\"data\":$status_output}"
            ;;
        presets)
            local presets_output=$(sh "$CORE" presets 2>/dev/null)
            send_json 200 "{\"success\":true,\"data\":$presets_output}"
            ;;
        start)
            sh "$CORE" start >/dev/null 2>&1
            send_json 200 "{\"success\":true}"
            ;;
        stop)
            sh "$CORE" stop >/dev/null 2>&1
            send_json 200 "{\"success\":true}"
            ;;
        restart)
            sh "$CORE" restart >/dev/null 2>&1
            send_json 200 "{\"success\":true}"
            ;;
        apply_preset)
            local preset=$(echo "$BODY" | grep -o '"preset"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"preset"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -z "$preset" ]; then
                send_json 400 "{\"success\":false,\"error\":\"missing preset name\"}"
            else
                sh "$CORE" apply_preset "$preset" >/dev/null 2>&1
                send_json 200 "{\"success\":true}"
            fi
            ;;
        apply_custom)
            local primary=$(echo "$BODY" | grep -o '"primary"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"primary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            local secondary=$(echo "$BODY" | grep -o '"secondary"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"secondary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -z "$primary" ]; then
                send_json 400 "{\"success\":false,\"error\":\"missing primary DNS\"}"
            else
                sh "$CORE" apply_custom "$primary" "${secondary:-$primary}" >/dev/null 2>&1
                send_json 200 "{\"success\":true}"
            fi
            ;;
        set_config)
            local key=$(echo "$BODY" | grep -o '"key"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            local value=$(echo "$BODY" | grep -o '"value"[[:space:]]*:[[:space:]]*[^,}]*' | head -1 | sed 's/.*"value"[[:space:]]*:[[:space:]]*//;s/[",]//g')
            if [ -n "$key" ] && [ -n "$value" ]; then
                sh "$CORE" set_config "${key}=${value}" >/dev/null 2>&1
                send_json 200 "{\"success\":true}"
            else
                send_json 400 "{\"success\":false,\"error\":\"missing key or value\"}"
            fi
            ;;
        add_whitelist)
            local uid=$(echo "$BODY" | grep -o '"uid"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"uid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -n "$uid" ]; then
                # 读取当前白名单并追加
                . "$CONF_DIR/forcedns.conf" 2>/dev/null
                WHITELIST_UID="$WHITELIST_UID $uid"
                WHITELIST_UID=$(echo "$WHITELIST_UID" | tr -s ' ')
                sh "$CORE" set_config "whitelist_uid=$WHITELIST_UID" >/dev/null 2>&1
                send_json 200 "{\"success\":true}"
            else
                send_json 400 "{\"success\":false,\"error\":\"missing uid\"}"
            fi
            ;;
        remove_whitelist)
            local uid=$(echo "$BODY" | grep -o '"uid"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"uid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -n "$uid" ]; then
                . "$CONF_DIR/forcedns.conf" 2>/dev/null
                WHITELIST_UID=$(echo "$WHITELIST_UID" | sed "s/$uid//g;s/  */ /g;s/^ //;s/ $//")
                sh "$CORE" set_config "whitelist_uid=$WHITELIST_UID" >/dev/null 2>&1
                send_json 200 "{\"success\":true}"
            else
                send_json 400 "{\"success\":false,\"error\":\"missing uid\"}"
            fi
            ;;
        logs)
            local log_content=""
            if [ -f "$CONF_DIR/forcedns.log" ]; then
                log_content=$(tail -50 "$CONF_DIR/forcedns.log" 2>/dev/null)
                # 转义JSON特殊字符
                log_content=$(echo "$log_content" | sed 's/\\/\\\\/g;s/"/\\"/g;s/\t/\\t/g' | awk '{printf "%s\\n", $0}')
            fi
            send_json 200 "{\"success\":true,\"data\":\"$log_content\"}"
            ;;
        *)
            send_json 400 "{\"success\":false,\"error\":\"unknown action: $action\"}"
            ;;
    esac
}

# 处理静态文件请求
handle_static() {
    local url="$1"
    local file_path="$WEB_DIR"
    local content_type="text/html"

    case "$url" in
        /|/index.html)
            file_path="$WEB_DIR/index.html"
            content_type="text/html; charset=utf-8"
            ;;
        *)
            send_json 404 "{\"success\":false,\"error\":\"not found\"}"
            return
            ;;
    esac

    if [ -f "$file_path" ]; then
        local body=$(cat "$file_path")
        send_response 200 "$content_type" "$body"
    else
        send_json 404 "{\"success\":false,\"error\":\"file not found\"}"
    fi
}

# 处理单个连接
handle_connection() {
    parse_request

    # 处理OPTIONS预检
    if [ "$METHOD" = "OPTIONS" ]; then
        printf "HTTP/1.1 204 No Content\r\n"
        printf "Access-Control-Allow-Origin: *\r\n"
        printf "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
        printf "Access-Control-Allow-Headers: Content-Type\r\n"
        printf "Connection: close\r\n"
        printf "\r\n"
        return
    fi

    case "$URL" in
        /api)
            handle_api
            ;;
        *)
            handle_static "$URL"
            ;;
    esac
}

# 启动Web服务器
start_web() {
    # 检查是否已在运行
    if [ -f "$WEB_PID" ] && kill -0 $(cat "$WEB_PID" 2>/dev/null) 2>/dev/null; then
        echo "Web服务器已在运行 (PID: $(cat $WEB_PID))"
        return 0
    fi

    echo "启动ForceDNS Web服务器 (端口: $WEB_PORT)..."

    # 使用while循环处理连接
    while true; do
        # 监听端口，每次接受一个连接
        nc -l -p $WEB_PORT -q 0 2>/dev/null | (
            handle_connection
        ) 2>/dev/null
    done &

    local pid=$!
    echo $pid > "$WEB_PID"

    # 验证启动
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        echo "Web服务器已启动 (PID: $pid)"
    else
        echo "Web服务器启动失败，尝试使用busybox httpd..."

        # 备用方案: 使用busybox httpd
        if command -v busybox >/dev/null 2>&1 && busybox --list 2>/dev/null | grep -q httpd; then
            mkdir -p "$WEB_DIR/cgi-bin"
            # 创建CGI脚本
            cat > "$WEB_DIR/cgi-bin/api" << 'CGIEOF'
#!/system/bin/sh
echo "Content-Type: application/json"
echo ""
MODDIR=/data/adb/modules/forcedns
# 读取POST数据
if [ "$REQUEST_METHOD" = "POST" ]; then
    BODY=$(cat)
    ACTION=$(echo "$BODY" | grep -o '"action"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    sh "$MODDIR/forcedns-core.sh" "$ACTION" 2>/dev/null
else
    echo '{"success":false,"error":"method not allowed"}'
fi
CGIEOF
            chmod 755 "$WEB_DIR/cgi-bin/api"
            busybox httpd -p $WEB_PORT -h "$WEB_DIR" -f &
            echo $! > "$WEB_PID"
            echo "busybox httpd已启动"
        else
            echo "无可用的Web服务器"
            return 1
        fi
    fi
}

# 停止Web服务器
stop_web() {
    if [ -f "$WEB_PID" ]; then
        local pid=$(cat "$WEB_PID" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo "Web服务器已停止"
        fi
        rm -f "$WEB_PID"
    fi
    # 确保清理
    killall nc 2>/dev/null
    killall busybox 2>/dev/null
}

# 命令行入口
case "$1" in
    start) start_web ;;
    stop) stop_web ;;
    restart) stop_web; sleep 1; start_web ;;
    *) echo "用法: server.sh {start|stop|restart}" ;;
esac
