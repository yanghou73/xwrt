#!/bin/bash
# ============================================================
# MT7981 平台预处理脚本
# 验证状态：✅ 6.6 内核 6in4 移除已验证
#           ⏳ 5.4 内核 6in4 移除 + mt_wifi 补丁 + DEV_PATH_MTK_WDMA 修复 + 999-2708 上下文修复待验证
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

# ============================================================
# 修复 DEV_PATH_MTK_WDMA 枚举定义缺失（仅 5.4 内核，hanwckf 源码）
# 问题：v6.6 nft hw offload 补丁在 nft_flow_offload.c 中引用了
#       DEV_PATH_MTK_WDMA，但 v5.15 补丁在 netdevice.h 中定义
#       enum net_device_path_type 时只到 DEV_PATH_DSA，缺少该值
# 修复：在 v5.15 补丁的枚举定义中添加 DEV_PATH_MTK_WDMA
# ============================================================
HW_OFFLOAD_PATCH="target/linux/mediatek/patches-5.4/999-1718-v5.15-net-netfilter-add-nf-hw-offload.patch"
if [ -f "$HW_OFFLOAD_PATCH" ]; then
  if ! grep -q 'DEV_PATH_MTK_WDMA' "$HW_OFFLOAD_PATCH"; then
    sed -i 's/^\(\+\tDEV_PATH_DSA,\)$/\1\n+\tDEV_PATH_MTK_WDMA,/' "$HW_OFFLOAD_PATCH"
    sed -i 's/@@ -843,6 +843,59 @@/@@ -843,6 +843,60 @@/' "$HW_OFFLOAD_PATCH"
    echo "已修复 DEV_PATH_MTK_WDMA 枚举定义缺失"
  else
    echo "DEV_PATH_MTK_WDMA 已存在，跳过修复"
  fi
else
  echo "提示：未找到 hw offload 补丁（非 5.4 内核，跳过）"
fi

# ============================================================
# 修复 999-2708 补丁上下文不匹配（仅 5.4 内核，hanwckf 源码）
# 问题：999-1718 修复添加了 DEV_PATH_MTK_WDMA，导致 999-2708 补丁
#       期望的上下文 DEV_PATH_DSA → }; 变为 DEV_PATH_DSA → DEV_PATH_MTK_WDMA → };
# 修复：在 999-2708 补丁中添加 DEV_PATH_MTK_WDMA 作为上下文行
# ============================================================
PATCH_2708="target/linux/mediatek/patches-5.4/999-2708-mtkhnat-add-support-for-virtual-interface-acceleration.patch"
if [ -f "$PATCH_2708" ]; then
  if ! grep -q 'DEV_PATH_MTK_WDMA' "$PATCH_2708"; then
    sed -i 's/@@ -849,6 +849,8 @@/@@ -849,7 +849,9 @@/' "$PATCH_2708"
    sed -i 's/\(^ \tDEV_PATH_DSA,$\)/\1\n \tDEV_PATH_MTK_WDMA,/' "$PATCH_2708"
    echo "已修复 999-2708 补丁上下文（添加 DEV_PATH_MTK_WDMA 上下文行）"
  else
    echo "999-2708 补丁已包含 DEV_PATH_MTK_WDMA，跳过修复"
  fi
else
  echo "提示：未找到 999-2708 补丁（非 5.4 内核，跳过）"
fi

echo "MT7981 预处理完成！"
