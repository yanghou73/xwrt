#!/bin/bash
# ============================================================
# x64 高大全包拉取脚本
# 基于 bleach1991/lede 的 50+ 包列表
# 验证状态：⏳ 待验证
# ============================================================

# 注：此脚本在 x64 平台使用，包量巨大
# 建议仅在 full 模式下调用

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

  git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

  if [[ "$PKG_SPECIAL" == "pkg" ]]; then
    find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
    rm -rf ./$REPO_NAME/
  elif [[ "$PKG_SPECIAL" == "name" ]]; then
    mv -f $REPO_NAME $PKG_NAME
  fi
}

# ============================================================
# 代理
# ============================================================
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git

# ============================================================
# DNS
# ============================================================
UPDATE_PACKAGE "smartdns" "pymumu/openwrt-smartdns" "master"
UPDATE_PACKAGE "luci-app-smartdns" "pymumu/luci-app-smartdns" "master"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "adguardhome" "rufengsuixing/luci-app-adguardhome" "master"

# ============================================================
# 主题（多主题）
# ============================================================
UPDATE_PACKAGE "design" "0x676e67/luci-theme-design" "main"
UPDATE_PACKAGE "edge" "garypang13/luci-theme-edge" "master"
UPDATE_PACKAGE "atmaterial" "openwrt-develop/luci-theme-atmaterial" "master"
UPDATE_PACKAGE "rosy" "rosywrt/luci-theme-rosy" "master"
UPDATE_PACKAGE "neobird" "thinktip/luci-theme-neobird" "master"
UPDATE_PACKAGE "opentopd" "sirpdboy/luci-theme-opentopd" "master"
UPDATE_PACKAGE "infinityfreedom" "xiaoqingfengATGH/luci-theme-infinityfreedom" "master"
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"

# ============================================================
# 系统工具
# ============================================================
UPDATE_PACKAGE "advanced" "sirpdboy/luci-app-advanced" "master"
UPDATE_PACKAGE "chatgpt-web" "sirpdboy/luci-app-chatgpt-web" "master"
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "master"
UPDATE_PACKAGE "cupsd" "sirpdboy/luci-app-cupsd" "master"
UPDATE_PACKAGE "eqosplus" "sirpdboy/luci-app-eqosplus" "master"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
UPDATE_PACKAGE "poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "bandwidthd" "AlexZhuo/luci-app-bandwidthd" "master"

# ============================================================
# 应用
# ============================================================
UPDATE_PACKAGE "alist" "sbwml/luci-app-alist" "master"
UPDATE_PACKAGE "onliner" "selfcan/luci-app-onliner" "master"
UPDATE_PACKAGE "homebox" "selfcan/luci-app-homebox" "master"
UPDATE_PACKAGE "serverchan" "tty228/luci-app-serverchan" "master"
UPDATE_PACKAGE "go-aliyundrive-webdav" "jerrykuku/luci-app-go-aliyundrive-webdav" "master"
UPDATE_PACKAGE "aliddns" "honwen/luci-app-aliddns" "master"
UPDATE_PACKAGE "dogcom" "mchome/luci-app-dogcom" "master"
UPDATE_PACKAGE "mentohust" "BoringCat/luci-app-mentohust" "master"
UPDATE_PACKAGE "minieap" "BoringCat/luci-app-minieap" "master"
UPDATE_PACKAGE "ikoolproxy" "iwrt/luci-app-ikoolproxy" "master"
UPDATE_PACKAGE "macvlan" "ParticleG/luci-app-macvlan" "master"
UPDATE_PACKAGE "ua2f" "lucikap/luci-app-ua2f" "master"
UPDATE_PACKAGE "msd_lite" "hejiadong0608/luci-app-msd_lite" "master"
UPDATE_PACKAGE "npc" "ghosthgytop/luci-app-npc" "master"
UPDATE_PACKAGE "bearDropper" "NateLol/luci-app-bearDropper" "master"
UPDATE_PACKAGE "athena-led" "NONGFAH/luci-app-athena-led" "master"
UPDATE_PACKAGE "leigod-acc" "miaoermua/luci-app-leigod-acc" "master"
UPDATE_PACKAGE "istore" "linkease/istore" "main"
UPDATE_PACKAGE "dnsfilter" "kiddin9/luci-app-dnsfilter" "master"
UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "master"

# ============================================================
# daed/dae
# ============================================================
UPDATE_PACKAGE "daed" "QiuSimons/luci-app-daed" "master"
UPDATE_PACKAGE "dae" "QiuSimons/luci-app-dae" "master"
UPDATE_PACKAGE "vmlinux-btf" "QiuSimons/vmlinux-btf" "main"

# ============================================================
# 其他
# ============================================================
UPDATE_PACKAGE "vssr" "MilesPoupart/luci-app-vssr" "master"
UPDATE_PACKAGE "clash" "frainzy1477/luci-app-clash" "master"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"

# 注意：不自动更新 sing-box，避免 Go 版本冲突
