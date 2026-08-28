#!/bin/bash
# ============================================================
# MT7981 平台预处理脚本
# 验证状态：✅ 6.6 内核 6in4 移除已验证
#           ⏳ 5.4 内核 6in4 移除 + mt_wifi 补丁待验证
# 参考：Ljzkirito/Actions-ImmortalWrt diy-part1.sh
# ============================================================

echo "=== MT7981 预处理 ==="

# ============================================================
# 移除 6in4（IPv6 隧道，家庭环境不需要）
# 5.4 和 6.6 内核路径不同：
#   5.4: package/emortal/ipv6-helper/Makefile
#   6.6: package/network/services/ipv6-helper/files/ipv6-helper.sh
# ============================================================

# --- 5.4 内核路径（hanwckf 源码）---
IPV6_HELPER_54="package/emortal/ipv6-helper/Makefile"
if [ -f "$IPV6_HELPER_54" ]; then
  sed -i 's/ +6in4//g' "$IPV6_HELPER_54"
  sed -i '/hotplug.d/d' "$IPV6_HELPER_54"
  rm -fv package/emortal/ipv6-helper/files/60-6in4
  echo "已移除 6in4（5.4 内核路径: $IPV6_HELPER_54）"
fi

# --- 6.6 内核路径（padavanonly 源码）---
IPV6_HELPER_66="package/network/services/ipv6-helper/files/ipv6-helper.sh"
if [ -f "$IPV6_HELPER_66" ]; then
  sed -i '/6in4/d' "$IPV6_HELPER_66"
  echo "已移除 6in4（6.6 内核路径: $IPV6_HELPER_66）"
fi

# 两个路径都不存在时提示
if [ ! -f "$IPV6_HELPER_54" ] && [ ! -f "$IPV6_HELPER_66" ]; then
  echo "警告：未找到 ipv6-helper，跳过 6in4 移除"
fi

# ============================================================
# mt_wifi 性能补丁（仅 5.4 内核，hanwckf 源码）
# token_rx_cnt: 4592 → 6144（MEMORY_SHRINK_AGGRESS 模式下提升吞吐）
# 参考：Ljzkirito diy-part1.sh
# ============================================================
MT_WIFI_PATCH_DIR="package/mtk/drivers/mt_wifi/patches-7673"
if [ -d "$MT_WIFI_PATCH_DIR" ]; then
  cat > "$MT_WIFI_PATCH_DIR/999-Increase-token-rx-cnt.patch" <<'PATCH_EOF'
--- a/mt_wifi/chips/mt7981.c
+++ b/mt_wifi/chips/mt7981.c
@@ -11711,7 +11711,7 @@
 	chip_cap->tkn_info.hw_tx_token_cnt = 8192;
 #ifdef MEMORY_SHRINK
 #ifdef MEMORY_SHRINK_AGGRESS
-	chip_cap->tkn_info.token_rx_cnt = 4592;
+	chip_cap->tkn_info.token_rx_cnt = 6144;
 #else
 	chip_cap->tkn_info.token_rx_cnt = 12288;
 #endif	/* MEMORY_SHRINK_AGGRESS */
PATCH_EOF
  echo "已应用 mt_wifi 性能补丁（token_rx_cnt: 4592→6144）"
else
  echo "提示：未找到 mt_wifi 补丁目录（非 5.4 内核，跳过）"
fi

echo "MT7981 预处理完成！"
