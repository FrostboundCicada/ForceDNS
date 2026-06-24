#!/system/bin/sh
# ForceDNS - 模块Action按钮脚本
# 在KernelSU/APatch管理器中点击模块的"执行"按钮时运行
# 功能: 切换开关并显示当前状态

MODDIR=/data/adb/modules/forcedns

sh "$MODDIR/forcedns-core.sh" toggle
