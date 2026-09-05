#!/bin/bash
# ============================================================
# x64 平台预处理脚本
# 验证状态：⏳ 待验证
# 注意：此脚本在 config 组装之前执行，仅修改源码和 feeds
# 不要在此脚本中直接 echo 到 .config（会被后续 cat 覆盖）
# ============================================================

echo "=== x64 预处理 ==="

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

echo "x64 预处理完成！"
