#!/bin/bash
# ============================================================
# 通用设置脚本 — IP / 主题 / 语言
# 验证状态：✅ WR30U 已验证
# ============================================================

WRT_IP="${WRT_IP:-192.168.1.1}"
WRT_THEME="${WRT_THEME:-argon}"
WRT_NAME="${WRT_NAME:-ImmortalWrt}"

echo "=== 设置 ==="
echo "LAN IP: $WRT_IP"
echo "主题: $WRT_THEME"
echo "主机名: $WRT_NAME"

# --- 修改默认 IP（系统 base-files） ---
CFG_FILE="./package/base-files/files/bin/config_generate"
if [ -f "$CFG_FILE" ]; then
  sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$CFG_FILE"
  echo "config_generate IP 已更新: $WRT_IP"
else
  echo "警告: 未找到 config_generate ($CFG_FILE)"
fi

# --- 修改 LuCI 刷机页面显示的 IP ---
FLASH_JS=$(find ./feeds/luci/modules/luci-mod-system/ -name "flash.js" 2>/dev/null | head -1)
if [ -z "$FLASH_JS" ]; then
  FLASH_JS=$(find ./package/ -path "*/luci-mod-system/*" -name "flash.js" 2>/dev/null | head -1)
fi
if [ -n "$FLASH_JS" ]; then
  sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$FLASH_JS"
  echo "luci flash.js IP 已更新: $WRT_IP"
else
  echo "警告: 未找到 flash.js"
fi

# --- 追加 LuCI 配置到 .config ---
echo "CONFIG_PACKAGE_luci=y" >> .config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> .config

echo "设置完成！"
