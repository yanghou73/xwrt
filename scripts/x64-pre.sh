#!/bin/bash
# ============================================================
# x64 平台预处理脚本
# 验证状态：⏳ 待验证
# 注意：此脚本在 config 组装之前执行，仅修改源码和 feeds
# 不要在此脚本中直接 echo 到 .config（会被后续 cat 覆盖）
# ============================================================

echo "=== x64 预处理 ==="

# ============================================================
# 修复 pcat-firmware 递归依赖错误
# 问题：pcat-firmware select ath10k-board-qca9377-sdio
#       而 ath10k-board-qca9377-sdio 又 depends on pcat-firmware
#       形成循环依赖，导致 make defconfig 失败，设备目标丢失
# 修复：直接删除 pcat-firmware 包（x64 平台不需要）
# ============================================================
PCAT_FW_DIR=$(find package feeds -maxdepth 4 -type d -name "pcat-firmware" 2>/dev/null | head -1)
if [ -n "$PCAT_FW_DIR" ]; then
  rm -rf "$PCAT_FW_DIR"
  echo "已删除 pcat-firmware（修复递归依赖）"
else
  echo "未找到 pcat-firmware，跳过"
fi

# 启用 helloworld feed（SSR+ / VSSR 等代理插件）
if [ -f feeds.conf.default ]; then
  sed -i 's/#src-git helloworld/src-git helloworld/g' feeds.conf.default
  echo "已启用 helloworld feed"
else
  echo "警告：feeds.conf.default 未找到"
fi

# 添加 Nikki feed（Mihomo 代理面板）
if [ -f feeds.conf.default ]; then
  if ! grep -q "nikkinikki" feeds.conf.default; then
    echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
    echo "已添加 nikki feed"
  fi
fi

# 添加 HomeProxy feed（ImmortalWrt 官方代理面板，依赖 sing-box）
if [ -f feeds.conf.default ]; then
  if ! grep -q "immortalwrt/homeproxy" feeds.conf.default; then
    echo "src-git homeproxy https://github.com/immortalwrt/homeproxy.git" >> feeds.conf.default
    echo "已添加 homeproxy feed"
  fi
fi

# 创建 files/ overlay：将 Docker 菜单从「服务」子菜单移至侧边栏顶级菜单
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-docker-menu <<'EOFSCRIPT'
#!/bin/sh
# 将 dockerman 菜单从 admin/services/dockerman 改为 admin/docker（侧边栏顶级菜单）
MENU_FILE="/usr/share/luci/menu.d/luci-app-dockerman.json"
if [ -f "$MENU_FILE" ]; then
  sed -i 's|admin/services/dockerman|admin/docker|g' "$MENU_FILE"
  sed -i 's|"Dockerman JS"|"Docker"|' "$MENU_FILE"
  rm -rf /tmp/luci-* 2>/dev/null
fi
exit 0
EOFSCRIPT
chmod +x files/etc/uci-defaults/99-docker-menu
echo "已创建 Docker 菜单自定义 overlay"

# ============================================================
# 回退 jsonfilter 到 2025-04-18 版本
# 问题：lede 2026-08-30 更新 jsonfilter 到 2026-03-16 版本后编译失败
# 修复：回退到上一个已知可编译的版本
# ============================================================
JF_MAKEFILE="package/utils/jsonfilter/Makefile"
if [ -f "$JF_MAKEFILE" ]; then
  if grep -q "PKG_SOURCE_DATE:=2026-03-16" "$JF_MAKEFILE"; then
    sed -i 's/PKG_SOURCE_DATE:=2026-03-16/PKG_SOURCE_DATE:=2025-04-18/' "$JF_MAKEFILE"
    sed -i 's/PKG_SOURCE_VERSION:=b9034210bd331749673416c6bf389cccd4e23610/PKG_SOURCE_VERSION:=8a86fb78235b5d7925b762b7b0934517890cc034/' "$JF_MAKEFILE"
    sed -i 's/PKG_MIRROR_HASH:=e8616b3eee53c6dd3420a7d800337e13a61e1333dfbd8551b50ab15bafd94a0e/PKG_MIRROR_HASH:=59b78647914855284960630f8e9d716bf09f00ab007cf1e2c1570ae5c55cc64a/' "$JF_MAKEFILE"
    echo "已回退 jsonfilter 到 2025-04-18（修复编译失败）"
  else
    echo "jsonfilter 版本不是 2026-03-16，跳过回退"
  fi
fi

echo "x64 预处理完成！"
