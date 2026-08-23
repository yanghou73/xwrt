#!/bin/bash
# ============================================================
# 通用后处理脚本
# 验证状态：⏳ 待验证
# ============================================================

echo "=== 后处理 ==="

# --- 主题修补（argon 颜色/字体） ---
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

# --- tailscale Makefile 冲突修复 ---
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile" 2>/dev/null | head -1)
if [ -f "$TS_FILE" ]; then
  sed -i '/\/files/d' "$TS_FILE" 2>/dev/null || true
  echo "tailscale Makefile 已修复"
fi

# --- rust ci-llvm 修复 ---
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile" 2>/dev/null | head -1)
if [ -f "$RUST_FILE" ]; then
  sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE" 2>/dev/null || true
  echo "rust ci-llvm 已修复"
fi

echo "后处理完成！"
