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
# ============================================================
PCAT_FW_DIR=$(find package feeds -maxdepth 4 -type d -name "pcat-firmware" 2>/dev/null | head -1)
if [ -n "$PCAT_FW_DIR" ]; then
  rm -rf "$PCAT_FW_DIR"
  echo "已删除 pcat-firmware（修复递归依赖）"
fi

# 启用 helloworld feed
if [ -f feeds.conf.default ]; then
  sed -i 's/#src-git helloworld/src-git helloworld/g' feeds.conf.default
  echo "已启用 helloworld feed"
fi

# 添加 Nikki feed
if [ -f feeds.conf.default ]; then
  if ! grep -q "nikkinikki" feeds.conf.default; then
    echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
    echo "已添加 nikki feed"
  fi
fi

# 添加 HomeProxy feed
if [ -f feeds.conf.default ]; then
  if ! grep -q "immortalwrt/homeproxy" feeds.conf.default; then
    echo "src-git homeproxy https://github.com/immortalwrt/homeproxy.git" >> feeds.conf.default
    echo "已添加 homeproxy feed"
  fi
fi

# Docker 菜单自定义 overlay
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-docker-menu <<'EOFSCRIPT'
#!/bin/sh
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

echo "x64 预处理（第一阶段）完成"
echo "注：feeds 级修复将在 feeds update 后由 post.sh 执行"
