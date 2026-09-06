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

# Nikki（暂不启用）
# nikki 主程序是闭源预编译的，无法从源码编译
# luci-app-nikki 依赖 nikki 包（不存在），会导致 Kconfig 递归依赖错误
# 后续可考虑用 ipk 方式安装，或改用其他面板
# if [ -f feeds.conf.default ]; then
#   if ! grep -q "nikkinikki" feeds.conf.default; then
#     echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
#     echo "已添加 nikki feed"
#   fi
# fi

# 注意：homeproxy 不使用 feed 方式
# immortalwrt/homeproxy 仓库根目录就是一个 luci-app-homeproxy 包，非标准 feed 结构
# 改为在 common-x64.sh 中直接 clone 到 package/ 目录

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
