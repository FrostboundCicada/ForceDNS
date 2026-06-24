#!/system/bin/sh
# ForceDNS - dnsmasq启动诊断脚本
# 在设备上运行: sh /data/adb/modules/forcedns/diag-dnsmasq.sh

echo "========================================"
echo "  dnsmasq 启动诊断"
echo "========================================"

# 1. 检查dnsmasq是否存在
echo ""
echo "[1] 检查dnsmasq位置..."
which dnsmasq 2>/dev/null && echo "  路径: $(which dnsmasq)" || echo "  which找不到dnsmasq"
ls -la /system/bin/dnsmasq 2>/dev/null && echo "  /system/bin/dnsmasq 存在" || echo "  /system/bin/dnsmasq 不存在"
ls -la /data/adb/modules/forcedns/system/bin/dnsmasq 2>/dev/null && echo "  模块内置dnsmasq 存在" || echo "  模块内置dnsmasq 不存在"

# 2. 版本信息
echo ""
echo "[2] dnsmasq版本..."
dnsmasq --version 2>&1 | head -3

# 3. 检查5353端口是否被占用
echo ""
echo "[3] 检查5353端口..."
netstat -tlnp 2>/dev/null | grep 5353 && echo "  5353端口已被占用!" || echo "  5353端口空闲"
ss -tlnp 2>/dev/null | grep 5353 && echo "  5353端口已被占用(ss)!" || echo "  5353端口空闲(ss)"

# 4. 检查53端口
echo ""
echo "[4] 检查53端口..."
netstat -tlnp 2>/dev/null | grep ":53 " | head -3
ss -tlnp 2>/dev/null | grep ":53 " | head -3

# 5. 杀掉残留dnsmasq
echo ""
echo "[5] 清理残留dnsmasq..."
killall dnsmasq 2>/dev/null && echo "  已杀掉残留进程" || echo "  无残留进程"
sleep 1

# 创建测试配置
CONF_DIR="/data/adb/modules/forcedns/data"
mkdir -p "$CONF_DIR"
cat > "$CONF_DIR/dnsmasq_test.conf" << 'EOF'
port=5353
no-resolv
server=114.114.114.114
server=1.1.1.1
cache-size=100
EOF

# 6. 测试方法1: 标准启动
echo ""
echo "[6] 方法1: 标准启动 (-C conf --user=root --pid-file)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --user=root --pid-file="$CONF_DIR/dnsmasq_test.pid" 2>&1
sleep 1
if pgrep -f "dnsmasq" >/dev/null 2>&1; then
    echo "  ✓ 方法1 成功! PID=$(cat "$CONF_DIR/dnsmasq_test.pid" 2>/dev/null || pgrep -f dnsmasq)"
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法1 失败"
fi

# 7. 测试方法2: 不用pid-file
echo ""
echo "[7] 方法2: 不用pid-file (-C conf --user=root)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --user=root 2>&1
sleep 1
if pgrep -f "dnsmasq" >/dev/null 2>&1; then
    echo "  ✓ 方法2 成功! PID=$(pgrep -f dnsmasq)"
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法2 失败"
fi

# 8. 测试方法3: 后台启动
echo ""
echo "[8] 方法3: 后台启动 (-C conf --user=root &)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --user=root &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法3 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法3 失败"
fi

# 9. 测试方法4: 前台模式后台运行
echo ""
echo "[9] 方法4: 前台模式后台运行 (--no-daemon &)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --user=root --no-daemon 2>&1 &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法4 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法4 失败"
fi

# 10. 测试方法5: 最简参数
echo ""
echo "[10] 方法5: 最简参数 (--port=5353 --no-resolv --server=...)..."
dnsmasq --port=5353 --no-resolv --server=114.114.114.114 --server=1.1.1.1 --user=root 2>&1 &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法5 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法5 失败"
fi

# 11. 测试方法6: 不指定user
echo ""
echo "[11] 方法6: 不指定user (-C conf)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" 2>&1 &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法6 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法6 失败"
fi

# 12. 测试方法7: 指定keep-in-foreground
echo ""
echo "[12] 方法7: keep-in-foreground (-k -C conf)..."
dnsmasq -k -C "$CONF_DIR/dnsmasq_test.conf" --user=root 2>&1 &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法7 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法7 失败"
fi

# 13. 测试方法8: 绑定到127.0.0.1
echo ""
echo "[13] 方法8: 绑定127.0.0.1 (-C conf --listen-address=127.0.0.1)..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --listen-address=127.0.0.1 --user=root 2>&1 &
local_pid=$!
sleep 1
if kill -0 $local_pid 2>/dev/null; then
    echo "  ✓ 方法8 成功! PID=$local_pid"
    kill $local_pid 2>/dev/null
    killall dnsmasq 2>/dev/null
    sleep 1
else
    echo "  ✗ 方法8 失败"
fi

# 14. 检查错误原因
echo ""
echo "[14] 最后一次启动看错误信息..."
dnsmasq -C "$CONF_DIR/dnsmasq_test.conf" --user=root --no-daemon 2>&1 &
local_pid=$!
sleep 2
kill $local_pid 2>/dev/null
killall dnsmasq 2>/dev/null

# 15. 检查SELinux
echo ""
echo "[15] SELinux状态..."
getenforce 2>/dev/null || echo "  getenforce不可用"

# 16. 检查dnsmasq运行权限
echo ""
echo "[16] 文件权限..."
ls -la $(which dnsmasq 2>/dev/null) 2>/dev/null || echo "  无法获取权限"
file $(which dnsmasq 2>/dev/null) 2>/dev/null || echo "  file命令不可用"

echo ""
echo "========================================"
echo "  诊断完成，请将以上输出发送给我"
echo "========================================"

# 清理
rm -f "$CONF_DIR/dnsmasq_test.conf" "$CONF_DIR/dnsmasq_test.pid"
