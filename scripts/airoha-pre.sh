#!/bin/bash
# ============================================================
# AIROHA 平台预处理脚本
# 验证状态：⏳ 待验证
# ============================================================

echo "=== AIROHA 预处理 ==="

cd package/

# ============================================================
# 克隆 AIROHA 专属包（feeds 中无，需手动拉取）
# ============================================================

# luci-app-airoha-npu（NPU 状态监控）
if [ ! -d "luci-app-airoha-npu" ]; then
  git clone --depth=1 --single-branch --branch main "https://github.com/bingoguo93/luci-app-airoha-npu.git"
fi

# viking 综合包（gecoosac 账号认证 / luci-app-timewol 定时唤醒 / luci-app-wolplus 网络唤醒）
if [ ! -d "viking" ]; then
  git clone --depth=1 --single-branch --branch main "https://github.com/VIKINGYFY/packages.git" viking
fi

# qmodem（4G/5G modem 管理，USB 上行场景）
if [ ! -d "qmodem" ]; then
  git clone --depth=1 --single-branch --branch main "https://github.com/FUjr/QModem.git" qmodem
fi

# ddns-go（DDNS 动态域名，通过 Go 实现轻量级 DDNS）
if [ ! -d "luci-app-ddns-go" ]; then
  git clone --depth=1 --single-branch --branch main "https://github.com/sirpdboy/luci-app-ddns-go.git"
fi

cd ..

echo "AIROHA 预处理完成！"
