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

echo "x64 预处理完成！"
