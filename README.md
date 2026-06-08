# xtp-rs

透明代理 / 端口转发 -> SOCKS5，支持基于 IP 国家/地区的直连切换

## 在 OpenWrt SDK 下编译

### 前置条件

1. 安装 Rust 工具链：
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. 安装目标平台的 Rust target（以 aarch64 为例）：
   ```bash
   rustup target add aarch64-unknown-linux-musl
   ```

3. 下载并解压 OpenWrt SDK：
   ```bash
   # 从 https://downloads.openwrt.org/releases/ 下载对应版本的 SDK
   tar xJf openwrt-sdk-*.tar.xz
   cd openwrt-sdk-*
   ```

### 添加包到 SDK

1. 将本仓库克隆到 SDK 的 `package/` 目录：
   ```bash
   cd openwrt-sdk-*
   git clone https://github.com/hrimfaxi/openwrt-xtp-rs.git package/xtp-rs
   ```

2. 更新并安装 feeds：
   ```bash
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```

### 编译

1. 配置目标平台：
   ```bash
   make menuconfig
   ```
   在 `Network` -> `xtp-rs` 下选中该包，保存退出。

2. 编译：
   ```bash
   make package/xtp-rs/compile V=s
   ```

3. 编译产物位于：
   ```
   bin/packages/<arch>/base/xtp-rs_*.ipk
   ```

### 支持的架构

| OpenWrt ARCH | Rust Target |
|--------------|-------------|
| aarch64 | aarch64-unknown-linux-musl |
| x86_64 | x86_64-unknown-linux-musl |
| mips | mips-unknown-linux-musl |
| mipsel | mipsel-unknown-linux-musl |
| arm (v7) | armv7-unknown-linux-musleabihf |
| arm | arm-unknown-linux-musleabi |

### 安装到路由器

```bash
scp bin/packages/<arch>/base/xtp-rs_*.ipk root@<router-ip>:/tmp/
ssh root@<router-ip> opkg install /tmp/xtp-rs_*.ipk
```

## 依赖

- `kmod-nft-tproxy`：内核模块，编译时自动处理

## 配置

配置文件位于 `/etc/xtp-rs/config.toml`，安装后根据实际情况修改。

## 许可证

GPL-v3
