#!/bin/bash
# ============================================================
# 通用后处理脚本（feeds update 之后执行）
# 验证状态：⏳ 待验证
# 执行位置：SOURCE_DIR/package/
# ============================================================

echo "=== 后处理 ==="

cd ..  # 回到 SOURCE_DIR 根目录

# ============================================================
# 1. 回退 jsonfilter 到 2025-04-18（lede 8月更新导致编译失败）
# ============================================================
JF_MAKEFILE="package/utils/jsonfilter/Makefile"
if [ -f "$JF_MAKEFILE" ]; then
  if grep -q "PKG_SOURCE_DATE:=2026-03-16" "$JF_MAKEFILE"; then
    sed -i 's/PKG_SOURCE_DATE:=2026-03-16/PKG_SOURCE_DATE:=2025-04-18/' "$JF_MAKEFILE"
    sed -i 's/PKG_SOURCE_VERSION:=b9034210bd331749673416c6bf389cccd4e23610/PKG_SOURCE_VERSION:=8a86fb78235b5d7925b762b7b0934517890cc034/' "$JF_MAKEFILE"
    sed -i 's/PKG_MIRROR_HASH:=e8616b3eee53c6dd3420a7d800337e13a61e1333dfbd8551b50ab15bafd94a0e/PKG_MIRROR_HASH:=59b78647914855284960630f8e9d716bf09f00ab007cf1e2c1570ae5c55cc64a/' "$JF_MAKEFILE"
    echo "已回退 jsonfilter 到 2025-04-18"
  fi
fi

# ============================================================
# 2. 修复 mihomo-alpha / mihomo-meta 递归依赖（nikki feed）
# 两个包都 PROVIDES:=mihomo 且互相 CONFLICTS，导致 Kconfig 死循环
# 修复：删除 mihomo-alpha，只保留 mihomo-meta
# ============================================================
MIHOMO_ALPHA=$(find feeds -maxdepth 4 -type d -name "mihomo-alpha" 2>/dev/null | head -1)
if [ -n "$MIHOMO_ALPHA" ]; then
  rm -rf "$MIHOMO_ALPHA"
  echo "已删除 mihomo-alpha（修复 mihomo 递归依赖）"
fi

# ============================================================
# 3. 清理 helloworld 中有问题的 Rust 包（编译耗内存，GitHub Actions 易 OOM）
# ============================================================
if [ -d "feeds/helloworld/shadowsocks-rust" ]; then
  rm -rf feeds/helloworld/shadowsocks-rust
  echo "已清理 helloworld/shadowsocks-rust"
fi

# ============================================================
# 4. 清理 passwall-packages 中有问题的 Go/Rust 包
# ============================================================
PW_DIR=$(find package -maxdepth 2 -type d -name "openwrt-passwall-packages" 2>/dev/null | head -1)
if [ -n "$PW_DIR" ]; then
  rm -rf "$PW_DIR/xray-core" 2>/dev/null || true
  rm -rf "$PW_DIR/geoview" 2>/dev/null || true
  rm -rf "$PW_DIR/sing-box" 2>/dev/null || true
  rm -rf "$PW_DIR/shadowsocks-rust" 2>/dev/null || true
  rm -rf "$PW_DIR/v2ray-geodata" 2>/dev/null || true
  echo "已清理 passwall-packages 中有问题的 Go/Rust 包"
fi

# ============================================================
# 5. 修复 netspeedtest 依赖 python3-pkg-resources
# ============================================================
NSTS_MAKEFILE=$(find package/ -path "*/luci-app-netspeedtest/Makefile" 2>/dev/null | head -1)
if [ -n "$NSTS_MAKEFILE" ]; then
  sed -i 's/python3-pkg-resources/python3-setuptools/g' "$NSTS_MAKEFILE"
  echo "已修复 netspeedtest 依赖名"
fi

# ============================================================
# 6. tailscale Makefile 冲突修复
# ============================================================
TS_FILE=$(find feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile" 2>/dev/null | head -1)
if [ -f "$TS_FILE" ]; then
  sed -i '/\/files/d' "$TS_FILE" 2>/dev/null || true
  echo "tailscale Makefile 已修复"
fi

# ============================================================
# 7. rust ci-llvm 修复
# ============================================================
RUST_FILE=$(find feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile" 2>/dev/null | head -1)
if [ -f "$RUST_FILE" ]; then
  sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE" 2>/dev/null || true
  echo "rust ci-llvm 已修复"
fi

# ============================================================
# 8. 主题修补（argon 颜色/字体）
# ============================================================
cd package/
if ls -d *luci-theme-argon* 1>/dev/null 2>&1; then
  ARGON_DIR=$(ls -d *luci-theme-argon* | head -1)
  if [ -d "$ARGON_DIR/luci-app-argon-config" ]; then
    cd "$ARGON_DIR/luci-app-argon-config/"
    if [ -f root/etc/config/argon ]; then
      sed -i "s/primary '.*'/primary '#31a1a1'/g" root/etc/config/argon 2>/dev/null || true
      sed -i "s/'0.2'/'0.5'/g" root/etc/config/argon 2>/dev/null || true
      sed -i "s/'none'/'bing'/g" root/etc/config/argon 2>/dev/null || true
      sed -i "s/'600'/'normal'/g" root/etc/config/argon 2>/dev/null || true
      echo "argon 主题颜色已调整"
    fi
    cd ../../
  fi
fi
cd ..

echo "后处理完成！"
