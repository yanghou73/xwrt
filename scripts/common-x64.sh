#!/bin/bash
# ============================================================
# x64 包拉取脚本
# standard 模式：iStore + 核心代理（OpenClash/PassWall/PassWall2）
# full 模式：精简实用包（DNS过滤/系统工具/打印/网络应用/安全）
# 验证状态：⏳ 待验证
# 注意：部分仓库可能因作者删除/改名而 clone 失败，失败不中断编译
# ============================================================

# 由 core.yml 传入，默认 full
X64_VARIANT="${X64_VARIANT:-full}"

UPDATE_PACKAGE() {
  local PKG_NAME=$1
  local PKG_REPO=$2
  local PKG_BRANCH=$3
  local PKG_SPECIAL=$4
  local PKG_LIST=("$PKG_NAME" $5)
  local REPO_NAME=${PKG_REPO#*/}

  echo " "
  for NAME in "${PKG_LIST[@]}"; do
    echo "Search directory: $NAME"
    local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
    if [ -n "$FOUND_DIRS" ]; then
      while read -r DIR; do
        rm -rf "$DIR"
        echo "Delete directory: $DIR"
      done <<< "$FOUND_DIRS"
    fi
  done

  # clone 失败不中断（部分仓库可能已删除/改名），超时 2 分钟
  timeout 120 git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" || {
    echo "警告：克隆失败 $PKG_REPO ($PKG_BRANCH)，跳过"
    return 0
  }

  if [[ "$PKG_SPECIAL" == "pkg" ]]; then
    find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
    rm -rf ./$REPO_NAME/
  elif [[ "$PKG_SPECIAL" == "name" ]]; then
    mv -f $REPO_NAME $PKG_NAME
  fi
}

# ============================================================
# 核心代理（standard + full 都执行）
# ============================================================
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
timeout 120 git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git || true

# ============================================================
# iStore 应用商店（standard + full 都执行）
# ============================================================
UPDATE_PACKAGE "istore" "linkease/istore" "main"

# ============================================================
# 以下为 full 模式专属
# ============================================================
if [ "$X64_VARIANT" != "full" ]; then
  echo "standard 模式：核心代理 + iStore 拉取完成"
  exit 0
fi

echo "full 模式：继续拉取精简实用包..."

# ============================================================
# DNS / 过滤
# ============================================================
UPDATE_PACKAGE "adguardhome" "rufengsuixing/luci-app-adguardhome" "master"

# ============================================================
# 系统工具
# ============================================================
UPDATE_PACKAGE "advanced" "sirpdboy/luci-app-advanced" "main"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
# bandwidthd 是 lede 内置包，只 clone LuCI 面板，不删官方源
timeout 120 git clone --depth=1 --single-branch --branch master "https://github.com/AlexZhuo/luci-app-bandwidthd.git" || {
  echo "警告：克隆失败 AlexZhuo/luci-app-bandwidthd (master)，跳过"
}

# ============================================================
# 打印（cupsd 为 lede 内置，无需 clone）
# ============================================================

# ============================================================
# 安全
# ============================================================
UPDATE_PACKAGE "bearDropper" "NateLol/luci-app-bearDropper" "master"

# ============================================================
# 网络应用
# ============================================================
UPDATE_PACKAGE "onliner" "selfcan/luci-app-onliner" "main"
UPDATE_PACKAGE "serverchan" "tty228/luci-app-serverchan" "master"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "npc" "ghosthgytop/luci-app-npc" "master"

echo "full 模式：精简实用包拉取完成"
