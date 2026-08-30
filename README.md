# 多平台 OpenWrt 固件编译框架

统一编译 XG-040G-MD (AIROHA) / WR30U (MT7981) / Intel x64 三平台固件，支持精简模式。

## 支持平台

| 平台 | 设备 | 源码仓库 | 分支 | 内核版本 | ImmortalWrt/OpenWrt 版本 | 验证状态 |
|------|------|----------|------|----------|--------------------------|----------|
| AIROHA | Nokia XG-040G-MD (EN7581) | [bingoguo93/immortalwrt](https://github.com/bingoguo93/immortalwrt) | `6.18` | 6.18 | ImmortalWrt SNAPSHOT | ✅ 已验证刷入+运行 |
| MT7981 5.4 | Xiaomi WR30U (112m 布局) | [Yuzhii0718/immortalwrt-mt798x-hanwckf](https://github.com/Yuzhii0718/immortalwrt-mt798x-hanwckf) | `openwrt-21.02` | 5.4 | ImmortalWrt 21.02-SNAPSHOT | ✅ 已验证刷入+运行 |
| MT7981 6.6 | Xiaomi WR30U (ubootmod/stock) | [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) | `openwrt-24.10-6.6` | 6.6 | ImmortalWrt 24.10-SNAPSHOT | ⏳ 待验证 |
| x64 | Generic x86_64 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) | `master` | 6.12（稳定）/ 6.18（测试） | LEDE SNAPSHOT | ⏳ 待验证 |

### 各平台编译目标

| 平台 | target | subtarget | devicetype | 固件输出 |
|------|--------|-----------|------------|----------|
| AIROHA | `airoha` | `an7581` | `nokia_xg-040g-md` | factory.bin + sysupgrade.bin |
| MT7981 5.4 | `mediatek` | `mt7981` | `wr30u-112m` | factory.bin + sysupgrade.bin |
| MT7981 6.6 | `mediatek` | `filogic` | `wr30u-ubootmod` / `wr30u-stock` | sysupgrade.bin（stock 无 factory.bin） |
| x64 | `x86` | `64` | `generic` | combined-*.img.gz + vdi/vmdk/vhdx/qcow2 |

### MT7981 设备变体说明

| 变体 | 说明 | 分区布局 | 固件格式 |
|------|------|----------|----------|
| `stock` (5.4) | 小米原厂分区，112m 布局 | FIP/Factory/BL2/ubi | factory.bin + sysupgrade.bin |
| `ubootmod` (6.6) | 改造 U-Boot，支持 Web UI 救砖 | ubootmod 布局 | 仅 sysupgrade.bin |
| `stock` (6.6) | 原厂分区，无小米签名 | 原厂布局 | 仅 sysupgrade.bin（无 factory.bin） |

> **WR30U 刷机注意**：5.4 与 6.6 ubootmod 不互通（U-Boot 和分区布局不同），首次从原厂系统刷机用 5.4 factory.bin。

## 快速开始

1. Fork 本仓库到自己的 GitHub
2. 进入 Actions → 选择 **Build Firmware** → Run workflow
3. 选择平台、代理插件、精简模式等选项
4. 等待编译完成（约 60-90 分钟）
5. 在 Releases 页面下载固件

## Workflow 参数详解

### Build Firmware

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `platform` | choice | `mt7981` | 目标平台：`airoha` / `mt7981` / `x64` |
| `kernel` | choice | `6.6` | 内核版本（仅 mt7981）：`6.6` / `5.4` |
| `device_variant` | choice | `ubootmod` | 设备变体（仅 mt7981）：`ubootmod` / `stock`（5.4 自动用 `112m`） |
| `proxy` | choice | `both` | 代理插件：`openclash` / `passwall` / `both` / `none` |
| `devtools` | boolean | `true` | 开发工具（bash/ssh/curl/nano/htop 等） |
| `slim` | boolean | `false` | 精简模式（禁用非必要服务，提升运行速度） |
| `x64_variant` | choice | `standard` | x64 固件规模（仅 x64）：`minimal` / `standard` / `full` |
| `x64_docker` | boolean | `false` | x64 Docker 支持（仅 x64） |
| `x64_lxc` | boolean | `false` | x64 LXC 支持（仅 x64） |
| `x64_nikki` | boolean | `false` | x64 Nikki 代理（仅 x64） |
| `x64_homeproxy` | boolean | `false` | x64 HomeProxy 代理（仅 x64） |
| `x64_filesystem` | choice | `ext4` | x64 文件系统（仅 x64）：`ext4` / `squashfs` / `both` |
| `wrt_ip` | string | `192.168.1.1` | LAN IP 地址 |
| `theme` | choice | `argon` | LuCI 主题 |
| `cache` | boolean | `true` | 使用工具链缓存（首次或报错时关闭） |
| `test_only` | boolean | `false` | 测试模式（只生成 .config，不编译） |

### Clean Build

清理旧的 Release 和 Workflow 运行记录。

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `releases_keep` | `5` | 保留最近 N 个 Release |
| `workflows_keep_day` | `7` | 保留最近 N 天的 Workflow 记录 |
| `delete_releases` | `true` | 是否删除 Release |
| `delete_workflows` | `true` | 是否删除 Workflow 记录 |

### Clean Cache

清理 Actions 缓存（缓存损坏时使用），需要输入 `yes` 确认。

## 目录结构

```
xwrt/
├── .github/workflows/
│   ├── build.yml              # 入口：用户选择参数，解析平台配置
│   ├── core.yml               # 核心：编译流程（克隆→预处理→配置→编译→发布）
│   ├── clean-build.yml        # 清理 Release + Workflow
│   └── clean-cache.yml        # 清理 Actions Cache
├── configs/
│   ├── airoha.txt             # AIROHA (EN7581) 基础配置
│   ├── mt7981-54.txt          # WR30U 内核 5.4 配置（hanwckf/21.02）
│   ├── mt7981-66.txt          # WR30U 内核 6.6 配置（padavanonly/24.10）
│   └── x64.txt                # Intel x64 基础配置（lede/master）
├── fragments/
│   ├── general.txt            # 通用配置（所有平台共享）
│   ├── proxy-openclash.txt    # 代理：仅 OpenClash
│   ├── proxy-passwall.txt     # 代理：仅 PassWall
│   ├── proxy-both.txt         # 代理：OpenClash + PassWall + PassWall2
│   ├── devtools.txt           # 开发工具
│   ├── slim.txt               # 精简覆盖（禁用非必要服务）
│   ├── x64-slim.txt            # x64 精简恢复（恢复 USB/SATA/磁盘/文件系统）
│   ├── x64-docker.txt         # x64 Docker 内核选项 + 管理工具
│   ├── x64-lxc.txt            # x64 LXC 容器支持
│   ├── x64-full.txt           # x64 高大全插件包
│   ├── x64-nikki.txt          # x64 Nikki 代理（基于 Mihomo）
│   └── x64-homeproxy.txt      # x64 HomeProxy 代理（基于 sing-box）
├── scripts/
│   ├── common.sh              # AIROHA + MT7981 通用包拉取
│   ├── common-x64.sh          # x64 包拉取（支持 minimal/standard/full）
│   ├── airoha-pre.sh          # AIROHA 预处理（克隆 NPU/4G/DDNS-go）
│   ├── mt7981-pre.sh          # MT7981 预处理（内核补丁/6in4 移除）
│   ├── x64-pre.sh             # x64 预处理（feeds 配置）
│   ├── settings.sh            # 通用设置（IP/主题/语言）
│   └── post.sh                # 通用后处理（主题补丁/Tailscale 修复）
├── docs/
│   └── wr30u-ubootmod-guide.md # WR30U 刷机指南（5.4 → 6.6 迁移）
├── .gitignore
└── README.md
```

## 配置拼接机制

### 拼接顺序（后拼接覆盖先拼接）

```
1. configs/平台配置.txt        ← 平台基础（airoha/mt7981-54/mt7981-66/x64）
2. fragments/general.txt       ← 通用配置（所有平台共享）
3. fragments/proxy-*.txt       ← 代理插件（openclash/passwall/both/none）
4. fragments/devtools.txt      ← 开发工具（devtools=true 时）
5. fragments/slim.txt          ← 精简覆盖（slim=true 时）
6. fragments/x64-*.txt         ← x64 专属（docker/lxc/nikki/homeproxy/full）
7. fragments/x64-slim.txt      ← x64 精简恢复（slim=true 且 platform=x64 时，最后拼接）
```

> 后拼接的 `=n` 会覆盖先拼接的 `=y`，`make defconfig` 自动补全依赖。

### 精简模式覆盖关系

#### slim.txt 禁用的内容

| 类别 | 禁用项 | 原因 |
|------|--------|------|
| DNS 服务 | smartdns | OpenClash 内置 DNS 处理 |
| 端口转发 | lucky | 运行不稳定 |
| 应用商店 | istore | 后台守护进程占用 RAM |
| 网络测速 | netspeedtest | 依赖 Python3，占用存储 |
| 文件共享 | samba4 | 路由器不做 NAS |
| CPU 基准 | coremark | 持续占用 CPU |
| Web 终端 | ttyd | SSH 替代 |
| 其他插件 | gecoosac, wolplus | 非必要 |
| WireGuard | kmod-wireguard | 无应用场景 |
| 磁盘工具 | blkid, fdisk, smartmontools 等 17 个 | ARM 平台无 SATA/USB |
| USB 工具 | kmod-usb3, usbutils, usb-modeswitch | ARM 平台无 USB 接口 |
| iOS 工具 | libimobiledevice, usbmuxd | 无 iOS 设备连接需求 |
| 文件系统 | kmod-fs-btrfs/autofs4/vfat/ksmbd/fuse | 无 NAS/USB 需求 |
| SATA/ATA | kmod-ata-ahci/core | ARM 平台无 SATA |
| 重型工具 | strace/tcpdump/iperf3/screen/rsync/coreutils 等 20 个 | busybox 内置替代 |

#### x64-slim.txt 恢复的内容（仅 x64 平台）

x64 有 USB/SATA 接口，slim.txt 中禁用的相关配置需要恢复：

| 类别 | 恢复项 |
|------|--------|
| USB 驱动 | kmod-usb3, usbutils, usb-modeswitch, kmod-scsi-core |
| 磁盘工具 | blkid, lsblk, fdisk, cfdisk, sfdisk, smartmontools |
| 文件系统 | kmod-fs-btrfs/autofs4/vfat/ksmbd/fuse |
| SATA/ATA | kmod-ata-ahci/core |
| iOS 工具 | libimobiledevice, usbmuxd |
| 自动挂载 | automount |

> x64 精简模式仍禁用 SmartDNS、Lucky、iStore、Samba4、Coremark、ttyd、WireGuard 及重型开发工具。

## 插件与包来源

### 通用包（common.sh，AIROHA + MT7981）

| 包名 | 仓库 | 分支 | 说明 |
|------|------|------|------|
| luci-theme-argon | sbwml/luci-theme-argon | openwrt-25.12 | 主题 |
| OpenClash | vernesong/OpenClash | dev | 代理插件 |
| PassWall | Openwrt-Passwall/openwrt-passwall | main | 代理插件 |
| PassWall 依赖 | kenzok8/small | - | PassWall 运行依赖 |
| netspeedtest | sirpdboy/netspeedtest | main | 网络测速（SLIM=true 时跳过） |
| istore | linkease/istore | main | 应用商店（SLIM=true 时跳过） |

**已禁用的包**（从 kenzok8/small 中删除）：
- `luci-app-fchomo`：递归依赖导致 `make defconfig` 失败
- `luci-app-passwall2` / `xray-core` / `geoview` / `v2ray-geodata` / `sing-box`：Go 语言包，GitHub Actions 编译易失败

### AIROHA 专属包（airoha-pre.sh）

| 包名 | 仓库 | 说明 |
|------|------|------|
| luci-app-airoha-npu | bingoguo93/luci-app-airoha-npu | NPU 硬件加速管理 |
| gecoosac / luci-app-timewol / luci-app-wolplus | VIKINGYFY/packages | 网络唤醒等 |
| qmodem | FUjr/QModem | 4G/5G modem 管理 |
| luci-app-ddns-go | sirpdboy/luci-app-ddns-go | DDNS 动态域名 |

### x64 专属包（common-x64.sh）

| 模式 | 包含内容 |
|------|----------|
| `minimal` | OpenClash + PassWall + PassWall2 + 依赖包 |
| `standard` | minimal + iStore |
| `full` | standard + AdGuardHome / Advanced / Bandwidthd / Netspeedtest / BearDropper / ServerChan / EasyTier / NPC / Onliner |

### MT7981 5.4 内核预处理（mt7981-pre.sh）

| 修复项 | 说明 |
|--------|------|
| DEV_PATH_MTK_WDMA 枚举 | 在 v5.15 补丁中添加枚举值，同步更新 999-2708 补丁上下文 |
| mt_wifi token_rx_cnt | 5.4 专属性能补丁，4592 → 6144 |
| 6in4 移除 | 移除 IPv6 6in4 隧道依赖 |
| 无用包清理 | 删除 v2ray-geodata / v2ray-core / xray-core |

## 平台配置详解

### AIROHA (XG-040G-MD)

- **源码**：bingoguo93/immortalwrt 6.18 分支
- **内核**：6.18
- **NPU 固件**：airoha-en7581-npu-firmware + airoha-en7581-mt7996-npu-firmware
- **PON 固件**：airoha-en8811h-firmware
- **DNS**：使用 feeds 自带 smartdns（pymumu 最新版不兼容 6.18）
- **包管理器**：同时支持 apk 和 opkg
- **刷机方式**：sysupgrade 或 factory.bin
- **典型场景**：旁路由

### MT7981 5.4 (WR30U)

- **源码**：Yuzhii0718/immortalwrt-mt798x-hanwckf，openwrt-21.02 分支
- **内核**：5.4
- **WiFi 驱动**：闭源 mtk_drv（功能完整，稳定）
- **分区布局**：112m（小米原厂布局，含 FIP/Factory/BL2）
- **刷机方式**：首次用 factory.bin（U-Boot Web UI），后续用 sysupgrade.bin
- **DNS**：DNS 指向 127.0.0.1 但 OpenClash 未启动时需手动修复 `/etc/resolv.conf`
- **OpenClash 内核**：需手动安装 Mihomo（`/etc/openclash/core/clash_meta`）

### MT7981 6.6 (WR30U)

- **源码**：padavanonly/immortalwrt-mt798x-6.6，openwrt-24.10-6.6 分支
- **内核**：6.6
- **WiFi 驱动**：主线开源 mt7921e（持续更新，新特性多）
- **分区布局**：ubootmod（改造 U-Boot，支持 Web UI 救砖）
- **刷机方式**：仅 sysupgrade.bin（ubootmod 变体）

### x64 (Generic)

- **源码**：coolsnowwolf/lede，master 分支
- **内核**：默认 6.12（稳定），可选 6.18（测试版，`CONFIG_TESTING_KERNEL=y`）
- **引导**：GRUB（BIOS），可选 EFI
- **虚拟机镜像**：VDI / VMDK / VHDX / QCOW2
- **分区大小**：kernel 64MB / rootfs 800MB
- **文件系统**：ext4（默认）/ squashfs / both
- **扩展功能**：Docker / LXC / Nikki / HomeProxy

## 固件输出

| 平台 | 输出文件 | 格式 | 验证状态 |
|------|---------|------|----------|
| AIROHA | factory.bin + sysupgrade.bin | squashfs | ✅ 已验证 |
| MT7981 5.4 (112m) | factory.bin + sysupgrade.bin | squashfs | ✅ 已验证 |
| MT7981 6.6 (ubootmod) | sysupgrade.bin | squashfs | ⏳ 待验证 |
| MT7981 6.6 (stock) | sysupgrade.bin | squashfs | ⚠️ 无 factory.bin |
| x64 | combined-*.img.gz + vdi/vmdk/vhdx/qcow2 | ext4/squashfs | ⏳ 待验证 |

## 精简模式使用建议

| 平台 | 建议 | 说明 |
|------|------|------|
| WR30U (256MB RAM) | ✅ 推荐启用 | 精简后 Web 界面流畅，运行稳定 |
| AIROHA | ✅ 推荐启用 | 旁路由场景，精简非必要服务 |
| x64 | 🔶 按需启用 | 有 USB/SATA 需求时仍可启用，x64-slim.txt 自动恢复 |

## 设计思路

- **配置分片**：平台基础配置 + 功能片段动态拼接，`make defconfig` 自动补全
- **脚本分离**：通用逻辑（common.sh）与平台专属逻辑（airoha-pre.sh 等）分离
- **精简覆盖**：slim.txt 在最后拼接确保覆盖，x64-slim.txt 恢复 x64 专属配置
- **缓存策略**：toolchain cache 可开关，首次编译或报错时关闭
- **测试模式**：test_only=true 只生成 .config，快速验证配置正确性

## 踩坑记录

1. **AIROHA 必须用 bingoguo93/immortalwrt 6.18**：master 分支输出 .itb 设备不认
2. **MT7981 5.4 补丁冲突**：hanwckf 仓库回移植 v5.15 和 v6.6 补丁有 DEV_PATH_MTK_WDMA 枚举不一致，需在 mt7981-pre.sh 中修复
3. **kenzok8/small 中的 luci-app-fchomo 必须删除**：递归依赖导致 make defconfig 失败，设备目标丢失
4. **openssh-server 不要装**：与 dropbear 端口 22 冲突，仅保留 openssh-client + openssh-sftp-server
5. **passwall2 相关 Go 包必须删除**：xray-core/geoview/v2ray-geodata/sing-box 在 GitHub Actions 编译易失败
6. **AIROHA smartdns 用 feeds 版本**：pymumu 最新版与 bingoguo93/immortalwrt 6.18 编译不兼容
7. **MT7981 6.6 子目标是 filogic**：不是 mt7981；设备名是 wr30u-ubootmod/stock
8. **mtr 包名是 mtr-nojson**：不是 mtr
9. **WR30U 5.4 OpenClash 内核需手动安装**：页面下载成功但更新失败，需手动下载 Mihomo 并放置到 `/etc/openclash/core/clash_meta`
10. **AIROHA DNS 修复**：resolv.conf 指向 127.0.0.1 但 OpenClash 未启动时，需手动改为实际 DNS 服务器
11. **设备目标丢失 = 无固件输出**：检查 make defconfig 是否有 recursive dependency

## 调试技巧

1. **先跑 test_only=true** 验证配置，下载 artifact 检查 .config 是否正确
2. **编译失败时**：关闭 Cache 重跑，或查看 V=s 详细输出
3. **无固件输出**：检查 build.config 中是否有 `CONFIG_TARGET_DEVICE_*=y`
4. **依赖错误**：搜索 `recursive dependency detected` 定位问题包
5. **下载失败**：搜索 `failed to build` 或 `ERROR:` 定位失败包

## OpenClash Meta 内核手动安装

WR30U (aarch64) OpenClash 页面更新内核失败时，手动安装：

```bash
# 下载 Mihomo（Clash.Meta 内核）
cd /tmp
curl -L -o mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.18.10/mihomo-linux-arm64-v1.18.10.gz
gunzip mihomo.gz
mv mihomo /etc/openclash/core/clash_meta
chmod +x /etc/openclash/core/clash_meta
/etc/openclash/core/clash_meta -v  # 验证版本
/etc/init.d/openclash restart
```

Mihomo 项目地址：https://github.com/MetaCubeX/mihomo

## 升级机制

- **每次编译都拉取最新源码**：`git clone --depth=1` 不使用旧版本
- **不会自动触发编译**：需要手动到 GitHub Actions 页面运行
- **缓存只缓存工具链**（ccache/staging_dir），源码和包每次都是新的
- **OpenClash 内核可在线更新**：不影响固件编译版本

| 场景 | 需要重新编译？ |
|------|---------------|
| 上游源码有安全补丁/新内核 | 是 |
| OpenClash 发布新版本 | 否（页面在线更新） |
| 官方 feeds 有新插件 | 是（需要新插件时） |
| 修改了 fragments/configs | 是 |
| 固件运行稳定，无新需求 | 否 |
