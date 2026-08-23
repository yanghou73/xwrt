# 多平台 OpenWrt 固件编译框架

统一编译 XG-040G-MD (AIROHA) / WR30U (MT7981) / Intel x64 三平台固件。

## 支持平台

| 平台 | 设备 | 源码 | 状态 |
|------|------|------|------|
| AIROHA | XG-040G-MD (EN7581) | bingoguo93/immortalwrt 6.18 | ✅ 已验证可刷入 |
| MT7981 | WR30U (MT7981B) | padavanonly/immortalwrt-mt798x-6.6 | ✅ 已验证编译 |
| x64 | Generic x86_64 | coolsnowwolf/lede master | ⏳ 待验证 |

## 快速开始

1. Fork 或复制本仓库到 GitHub
2. 进入 Actions → 选择 **Build Firmware** → Run workflow
3. 选择平台、代理插件、开发工具等选项
4. 等待编译完成（约 1-4 小时）
5. 在 Releases 页面下载固件

## 目录结构

```
xwrt/
├── .github/workflows/
│   ├── build.yml              # 入口：用户选择参数
│   ├── core.yml               # 核心：统一编译流程
│   ├── clean-build.yml        # 清理 Release + Workflow
│   └── clean-cache.yml        # 清理 Actions Cache
├── configs/
│   ├── airoha.txt             # XG-040G-MD 基础配置
│   ├── mt7981-66.txt          # WR30U 内核 6.6 配置
│   ├── mt7981-54.txt          # WR30U 内核 5.4 配置（预留）
│   └── x64.txt                # Intel x64 基础配置
├── fragments/
│   ├── general.txt            # 通用包（所有平台共享）
│   ├── proxy-openclash.txt    # 仅 OpenClash
│   ├── proxy-passwall.txt     # PassWall + PassWall2
│   ├── proxy-both.txt         # OpenClash + PassWall
│   ├── devtools.txt           # 开发工具包
│   ├── x64-docker.txt         # x64 Docker 支持
│   ├── x64-lxc.txt            # x64 LXC 支持
│   └── x64-full.txt           # x64 高大全包
├── scripts/
│   ├── common.sh              # AIROHA + MT7981 通用包拉取
│   ├── common-x64.sh          # x64 高大全包拉取
│   ├── airoha-pre.sh          # AIROHA 预处理
│   ├── mt7981-pre.sh          # MT7981 预处理
│   ├── x64-pre.sh             # x64 预处理
│   ├── settings.sh            # 通用设置（IP/主题/语言）
│   └── post.sh                # 通用后处理
├── docs/
│   └── wr30u-ubootmod-guide.md # WR30U ubootmod 刷机指南
├── .gitignore
└── README.md
```

## 设计思路

- **配置分片**：平台基础配置 + 功能片段动态拼接，`make defconfig` 自动补全
- **脚本分离**：通用逻辑与平台专属逻辑分离
- **缓存策略**：toolchain cache 可开关，首次编译或报错时关闭
- **测试模式**：TEST=true 只生成 .config，快速验证配置正确性

## 踩坑记录

详细记录见 `action固件编译方案.md` 第 2.3 节和第 14 节。

### 关键避坑点

1. **AIROHA 必须用 bingoguo93/immortalwrt 6.18**（master 输出 .itb 设备不认）
2. **MT7981 6.6 子目标是 filogic**，不是 mt7981；设备名是 wr30u-ubootmod/stock
3. **kenzok8/small 中的 luci-app-fchomo 必须删除**（递归依赖导致 make defconfig 失败）
4. **openssh-server 不要装**（与 dropbear 端口 22 冲突）
5. **mtr 包名是 mtr-nojson**，不是 mtr
6. **AIROHA smartdns 用 feeds 版本**（pymumu 最新版编译不兼容）
7. **设备目标丢失 = 无固件输出**，检查 make defconfig 是否有 recursive dependency

## Workflow 说明

### Build Firmware

| 参数 | 说明 |
|------|------|
| platform | 目标平台：airoha / mt7981 / x64 |
| kernel | 内核版本（仅 mt7981）：6.6 / 5.4 |
| device_variant | 设备变体（仅 mt7981）：ubootmod / stock |
| proxy | 代理插件：openclash / passwall / both / none |
| devtools | 开发工具：true / false |
| x64_variant | x64 固件规模（仅 x64）：minimal / standard / full |
| x64_docker | x64 Docker 支持（仅 x64）：true / false |
| x64_lxc | x64 LXC 支持（仅 x64）：true / false |
| x64_filesystem | x64 文件系统（仅 x64）：ext4 / squashfs / both |
| wrt_ip | LAN IP 地址，默认 192.168.1.1 |
| theme | 主题：argon |
| cache | 使用缓存：true / false |
| test_only | 仅测试模式：true / false |

### Clean Build

清理旧的 Release 和 Workflow 运行记录。

### Clean Cache

清理 Actions 缓存（缓存损坏时使用）。

## 固件输出

| 平台 | 输出文件 | 说明 |
|------|---------|------|
| AIROHA | factory.bin + sysupgrade.bin | bingoguo93/6.18 已验证 |
| MT7981 6.6 (ubootmod) | 仅 sysupgrade.bin | ✅ 已验证 |
| MT7981 6.6 (stock) | 仅 sysupgrade.bin | ⚠️ 无 factory.bin（无小米格式签名） |
| MT7981 5.4 (112m) | factory.bin + sysupgrade.bin | ⏳ 待验证（需切换到 hanwckf 源码） |
| x64 | combined-*.img.gz + vdi/vmdk/vhdx/qcow2 | ⏳ 待验证 |

## 已知问题 / TODO

### MT7981 (WR30U)

- **6.6 stock 变体无 factory.bin**：padavanonly/immortalwrt-mt798x-6.6 的 wr30u-stock 变体不生成小米原厂格式的 factory.bin（需要特殊签名）。救砖用 U-Boot 网页模式（ubootmod）或 Breed。
- **5.4 内核待适配**：5.4 内核需切换到 hanwckf/immortalwrt-mt798x 源码仓库，子目标为 mt7981，设备名为 wr30u-112m。当前框架中 5.4 配置是占位符。
- **ubootmod 与 5.4 不互通**：ubootmod 的 sysupgrade.bin 不能直接升级 5.4 版本的设备（U-Boot 和分区布局不同）。

### AIROHA (XG-040G-MD)

- **smartdns 用 feeds 版本**：pymumu/openwrt-smartdns 最新版与 bingoguo93/immortalwrt 6.18 编译环境不兼容，改用 feeds 自带版本。

### 通用

- **kenzok8/small 中的 fchomo 必须删除**：luci-app-fchomo 有递归依赖，会导致 make defconfig 失败，设备目标丢失。

## 调试技巧

1. **先跑 TEST=true** 验证配置，检查设备目标是否正确
2. **编译失败时**：关闭 Cache 重跑，或查看 V=s 详细输出
3. **无固件输出**：检查 build.config 中是否有 `CONFIG_TARGET_DEVICE_*=y`
4. **依赖错误**：搜索 `recursive dependency detected` 定位问题包
