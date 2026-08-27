#!/bin/bash
# ============================================================
# MT7981 平台预处理脚本
# 验证状态：✅ 6in4 移除已验证（参考 wr30u.yml）
# ============================================================

echo "=== MT7981 预处理 ==="

# --- 移除 6in4（IPv6 隧道，家庭环境不需要，可能导致问题）---
IPV6_HELPER="package/network/services/ipv6-helper/files/ipv6-helper.sh"
if [ -f "$IPV6_HELPER" ]; then
  sed -i '/6in4/d' "$IPV6_HELPER"
  echo "已移除 6in4（ipv6-helper.sh）"
else
  echo "警告：未找到 $IPV6_HELPER，跳过 6in4 移除"
fi

echo "MT7981 预处理完成！"
