#!/bin/bash
# SPDX-License-Identifier: MIT
# ============================================================
# 通用包拉取脚本 — AIROHA + MT7981 通用
# 执行位置：package/ 目录下（UPDATE_PACKAGE 用 ../feeds/ 佐证）
# 验证状态：✅ WR30U 已验证
# ============================================================

UPDATE_PACKAGE() {
  local PKG_NAME=$1
  local PKG_REPO=$2
  local PKG_BRANCH=$3
  local PKG_SPECIAL=$4
  local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
  local REPO_NAME=${PKG_REPO#*/}

  echo " "

  # 删除本地可能存在的不同名称的软件包
  for NAME in "${PKG_LIST[@]}"; do
    echo "Search directory: $NAME"
    local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

    if [ -n "$FOUND_DIRS" ]; then
      while read -r DIR; do
        rm -rf "$DIR"
        echo "Delete directory: $DIR"
      done <<< "$FOUND_DIRS"
    else
      echo "Not found directory: $NAME"
    fi
  done

  # 克隆 GitHub 仓库
  git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

  # 处理克隆的仓库
  if [[ "$PKG_SPECIAL" == "pkg" ]]; then
    find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
    rm -rf ./$REPO_NAME/
  elif [[ "$PKG_SPECIAL" == "name" ]]; then
    mv -f $REPO_NAME $PKG_NAME
  fi
}

# ============================================================
# 主题（仅保留 argon）
# ============================================================
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"

# ============================================================
# 代理插件
# ============================================================
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
# passwall2 已禁用：依赖 xray-core/geoview 等 Go 包，GitHub Actions 编译易失败
# UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

# passwall 依赖包（大量依赖在 kenzok8/small 中）
git clone --depth=1 https://github.com/kenzok8/small.git
# ⚠️  重要：删除有问题的包
# luci-app-fchomo: 递归依赖导致 make defconfig 失败
# luci-app-passwall2/xray-core/geoview/v2ray-geodata/sing-box: passwall2 相关 Go 包
rm -rfv small/luci-app-fchomo
rm -rfv small/luci-app-passwall2
rm -rfv small/xray-core
rm -rfv small/geoview
rm -rfv small/v2ray-geodata
rm -rfv small/sing-box

# ============================================================
# DNS
# ============================================================
# smartdns 使用 feeds 自带版本（与源码树完全兼容）
# AIROHA 平台注意：pymumu 最新版与 bingoguo93/immortalwrt 6.18 编译不兼容
# 如需更新 smartdns，请在各平台 pre 脚本中单独处理
# UPDATE_PACKAGE "smartdns" "pymumu/openwrt-smartdns" "master" ""
# UPDATE_PACKAGE "luci-app-smartdns" "pymumu/luci-app-smartdns" "master" ""

# ============================================================
# 网络测速
# ============================================================
if [ "$SLIM" != "true" ]; then
  UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
fi

# ============================================================
# Lucky（端口转发/DDNS/定时重启等）
# 注意：tty228/luci-app-lucky 已删除，改用 gdy666 仓库
# ============================================================
UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main"

# ============================================================
# iStore 应用商店
# ============================================================
if [ "$SLIM" != "true" ]; then
  UPDATE_PACKAGE "istore" "linkease/istore" "main"
fi

# ============================================================
# Tailscale（远程访问/虚拟组网）
# LuCI 面板已在 OpenWrt 官方 luci feeds 中，无需 clone
# ============================================================

# ============================================================
# 踩坑记录：
# 1. kenzok8/small 中的 luci-app-fchomo 有递归依赖，必须删除
# 2. AIROHA 平台 smartdns 用 feeds 版本，不用 pymumu 最新版
# 3. 脚本在 package/ 目录下执行，路径用 ../feeds/
# 4. 不自动更新 sing-box 版本，避免 Go 版本冲突
# 5. lucky 和 istore 需要手动 clone，feeds 中没有
# 6. SLIM=true 时跳过 netspeedtest/istore 克隆，减少编译时间和固件体积
# ============================================================
