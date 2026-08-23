# WR30U 刷机指南：5.4 → 6.6 ubootmod 迁移手册

> 适用于：小米 WR30U 路由器，从 5.4 内核（hanwckf/112m）迁移到 6.6 内核（padavanonly/ubootmod）
> 状态：⏳ 待验证（设备不在身边，未实际操作）
> 日期：2026-08-21

---

## 一、为什么要刷 ubootmod

| 对比项 | 5.4 hanwckf/112m | 6.6 padavanonly/ubootmod |
|--------|-----------------|------------------------|
| 内核版本 | 5.4（较老） | 6.6（较新） |
| WiFi 驱动 | 闭源 mtk_drv | 主线开源 mt7921e |
| 固件格式 | factory.bin + sysupgrade.bin | 仅 sysupgrade.bin |
| U-Boot | 小米原厂/hanwckf uboot | 修改版 ubootmod |
| 救砖方式 | Breed / 原厂 TTL | U-Boot Web UI（按住 Reset 上电） |
| 功能完整度 | 稳定，功能全 | 持续更新，新特性多 |
| 编译支持 | ✅ 框架项目已支持 | ✅ 框架项目已支持 |

**核心差异**：ubootmod 是一个修改版 U-Boot，自带网页刷固件功能，变砖了进 U-Boot 网页就能救，不需要 factory.bin。

---

## 二、刷机路径总览

```
┌─────────────────┐
│   小米原厂固件   │
└────────┬────────┘
         │ 解锁 SSH
         ▼
┌─────────────────┐
│  5.4 hanwckf     │  ← 你当前可能在这里
│  (112m 布局)     │
└────────┬────────┘
         │ 刷 ubootmod fip
         ▼
┌─────────────────┐
│  ubootmod        │  ← 修改版 U-Boot（救砖工具）
│  (Web UI 刷固件)  │
└────────┬────────┘
         │ 上传 6.6 sysupgrade.bin
         ▼
┌─────────────────┐
│  6.6 padavanonly  │  ← 目标
│  (ubootmod)       │
└─────────────────┘
```

---

## 三、核心资源

### 3.1 源码仓库

| 仓库 | 地址 | 用途 |
|------|------|------|
| hanwckf/immortalwrt-mt798x | https://github.com/hanwckf/immortalwrt-mt798x | 5.4 内核源码 + uboot fip 文件 |
| padavanonly/immortalwrt-mt798x-6.6 | https://github.com/padavanonly/immortalwrt-mt798x-6.6 | 6.6 内核源码（ubootmod 固件） |
| Yuzhii0718/bl-mt798x-dhcpd | https://github.com/Yuzhii0718/bl-mt798x-dhcpd | 增强版 uboot（推荐） |

### 3.2 关键文件说明

**uboot 文件（刷入后替换原厂 U-Boot）**：

| 文件 | 来源 | 说明 |
|------|------|------|
| `mt7981_wr30u-fip-fixed-parts-multi-layout.bin` | hanwckf Releases | multi-layout uboot，支持多种分区布局切换 |
| `*-ubootmod-bl31-uboot.fip` | 6.6 固件包 | ubootmod 的 fip 文件（BL31 + U-Boot） |
| `*-ubootmod-preloader.bin` | 6.6 固件包 | 预加载器（preloader） |

**固件文件**：

| 文件 | 说明 |
|------|------|
| `*wr30u-112m-squashfs-factory.bin` | 5.4 版本，从原厂刷入 |
| `*wr30u-112m-squashfs-sysupgrade.bin` | 5.4 版本，系统内升级 |
| `*wr30u-ubootmod-squashfs-sysupgrade.bin` | 6.6 版本，ubootmod 下升级 |

### 3.3 推荐增强版 U-Boot

**Yuzhii0718/bl-mt798x-dhcpd** — hanwckf uboot 的增强版：

- ✅ 支持 DHCPD（自动分配 IP，不需要手动设静态 IP）
- ✅ 美化 Web UI
- ✅ 多语言支持
- ✅ GitHub Actions 自动构建
- ✅ 支持超频版本

地址：https://github.com/Yuzhii0718/bl-mt798x-dhcpd

---

## 四、详细刷机步骤

### 阶段 1：确认当前版本

在操作之前，先确认 WR30U 当前的固件版本：

1. 登录 LuCI → 系统 → 系统，查看内核版本
2. 或 SSH 登录后执行：
   ```bash
   uname -a
   cat /etc/openwrt_release
   ```
3. 查看固件文件名中是否包含 `112m` 或 `ubootmod`

**判断标准**：
- 内核 5.4 + 112m → 在 5.4 hanwckf 版本，需要刷 ubootmod
- 内核 6.x + ubootmod → 已经是 ubootmod，直接 sysupgrade 升级即可

### 阶段 2：准备工作

1. **下载 uboot 文件**
   - 从 hanwckf Releases 下载 `mt7981_wr30u-fip-fixed-parts-multi-layout.bin`
   - 或从 Yuzhii0718 下载增强版
   - 也可以从 6.6 固件包中提取 `*-ubootmod-bl31-uboot.fip`

2. **下载 6.6 固件**
   - 从 padavanonly/immortalwrt-mt798x-6.6 Releases 下载
   - 或用我们自己编译的：`*wr30u-ubootmod-squashfs-sysupgrade.bin`

3. **备份配置**
   - LuCI → 系统 → 备份/升级 → 生成备份
   - 下载备份文件到电脑

4. **确保 SSH 可用**
   - 确认能 SSH 登录路由器
   - 记录 root 密码

### 阶段 3：刷入 ubootmod

> ⚠️  **高风险操作**：刷 U-Boot 失败可能导致变砖，需要 TTL 救回。
> 确保电源稳定，操作过程中不要断电。

**方法 A：SSH 命令行刷写（推荐，在 5.4 immortalwrt 下操作）**

1. SCP 上传 fip 文件到路由器 `/tmp/`：
   ```bash
   scp mt7981_wr30u-fip-fixed-parts-multi-layout.bin root@192.168.1.1:/tmp/
   ```

2. SSH 登录路由器：
   ```bash
   ssh root@192.168.1.1
   ```

3. 确认 fip 分区（不同版本分区名可能不同）：
   ```bash
   cat /proc/mtd
   # 查找 fip 或 uboot 分区
   ```

4. 写入 fip（**确认分区名后再操作！**）：
   ```bash
   # 示例，具体分区名需确认
   mtd write /tmp/mt7981_wr30u-fip-fixed-parts-multi-layout.bin fip
   ```

5. 重启：
   ```bash
   reboot
   ```

**方法 B：U-Boot Web UI 刷写（如果已进入 ubootmod）**

1. 按住 Reset 键，插上电源
2. 等待 3-5 秒后松开 Reset
3. 电脑设静态 IP：`192.168.1.2`，子网掩码 `255.255.255.0`
4. 浏览器访问 `http://192.168.1.1`
5. 在 Web UI 中上传固件刷入

### 阶段 4：刷入 6.6 固件

1. 确认已进入 ubootmod Web UI（按住 Reset 上电）
2. 选择 `immortalwrt` 或 `ubootmod` 分区布局
3. 上传 6.6 ubootmod 的 `sysupgrade.bin`
4. 点击刷入，等待完成
5. 自动重启后，访问 `192.168.1.1`（或你设置的 IP）

---

## 五、救砖方法

### 5.1 U-Boot Web UI 救砖（ubootmod 时）

这是 ubootmod 最大的优势——变砖了也能救：

1. 拔掉电源
2. 按住 Reset 键不放
3. 插上电源，保持按住 Reset 约 5 秒
4. 电脑设静态 IP：`192.168.1.2 / 255.255.255.0`
5. 浏览器访问 `http://192.168.1.1`
6. 上传 sysupgrade.bin 重新刷入

### 5.2 TTL 救砖（最坏情况）

如果 U-Boot 也刷挂了，需要 TTL 串口：

1. 拆开路由器，找到 TTL 针脚
2. 连接 USB-TTL 模块（波特率 115200）
3. 上电后打断启动，进入 U-Boot 命令行
4. 通过 TFTP 或 Kermit 传输固件刷入

参考：https://www.router-recovery.com/en/xiaomi-wr30u-router-ttl

---

## 六、常见问题

### Q1: 不刷 ubootmod，直接 sysupgrade 行不行？

不行。5.4（112m 布局）和 6.6 ubootmod 的分区布局不同，直接刷会导致无法启动。必须先刷 ubootmod。

### Q2: ubootmod 和 stock 有什么区别？

| 特性 | ubootmod | stock |
|------|----------|-------|
| U-Boot | 修改版（Web UI） | 原厂兼容 |
| 固件格式 | 仅 sysupgrade.bin | 仅 sysupgrade.bin（6.6 无 factory） |
| 救砖方式 | Web UI 方便 | 需要 Breed/TTL |
| 分区布局 | ubootmod 专用 | 兼容原厂分区 |
| 推荐场景 | 日常使用 + 折腾 | 从原厂过渡 |

### Q3: multi-layout 是什么？

multi-layout uboot 支持在 Web UI 中切换多种分区布局（原厂/112m/immortalwrt 等），灵活性更高。

### Q4: 6.6 的 WiFi 驱动怎么样？

6.6 用主线开源驱动 `mt7921e`，5.4 用闭源 mtk 驱动。功能上主线驱动持续更新，但某些特殊功能（如硬件加速、某些加密模式）可能闭源驱动更完善。日常使用差别不大。

### Q5: 刷完 ubootmod 还能刷回 5.4 吗？

可以。ubootmod Web UI 中选择对应分区布局，上传 5.4 固件即可。但建议确认兼容性后再操作。

---

## 七、参考教程

| 教程 | 地址 | 说明 |
|------|------|------|
| CSDN：小米 WR30U 解锁并刷机 | https://blog.csdn.net/CoolBoySilverBullet/article/details/132484099 | 完整图文教程：解锁 SSH → 刷 uboot → 刷 ImmortalWrt |
| 落寒陌墨博客：WR30U 刷入 OpenWRT | https://lotusmomo.cn/2025/02/19/WR30U/ | 详细步骤，命令行操作 |
| 虚拟世界的懒猫：WR30U 解锁ssh刷uboot | https://pidan.dev/20250809/mirouter-wr30u-openwrt-kwrt/ | SSH 解锁 + uboot + passwall 配置 |
| ImmortalWrt 官方讨论：WR30U 23.05 升 24.10 | https://github.com/immortalwrt/immortalwrt/discussions/1716 | 从老版本升级到新版本的讨论 |

---

## 八、操作前检查清单

- [ ] 确认当前固件版本（5.4 / 6.6，112m / ubootmod）
- [ ] 下载 ubootmod fip 文件（hanwckf 或 Yuzhii 增强版）
- [ ] 下载 6.6 ubootmod sysupgrade.bin
- [ ] 备份路由器配置
- [ ] 确认 SSH 可登录
- [ ] 电脑有网线接口（WiFi 刷机不稳定）
- [ ] 准备好 TTL 模块（以防万一）
- [ ] 电源稳定，不会中途断电

---

> ⚠️  **免责声明**：刷机有风险，操作需谨慎。本指南仅供参考，因刷机造成的设备损坏请自行承担责任。
> 建议设备在身边时操作，操作前仔细阅读参考教程，确认每一步的命令和文件。
