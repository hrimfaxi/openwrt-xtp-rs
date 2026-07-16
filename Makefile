include $(TOPDIR)/rules.mk

PKG_NAME:=xtp-rs
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/hrimfaxi/xtp-rs
PKG_SOURCE_VERSION:=master

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

# OpenWrt 架构 → Rust target 映射
ifeq ($(ARCH),aarch64)
  RUST_TARGET:=aarch64-unknown-linux-musl
else ifeq ($(ARCH),x86_64)
  RUST_TARGET:=x86_64-unknown-linux-musl
else ifeq ($(ARCH),mips)
  RUST_TARGET:=mips-unknown-linux-musl
else ifeq ($(ARCH),mipsel)
  RUST_TARGET:=mipsel-unknown-linux-musl
else ifeq ($(ARCH),arm)
  ifneq ($(findstring v7,$(CPU_TYPE)),)
    RUST_TARGET:=armv7-unknown-linux-musleabihf
  else
    RUST_TARGET:=arm-unknown-linux-musleabi
  endif
else
  RUST_TARGET:=$(ARCH)-unknown-linux-musl
endif

CARGO_TARGET_ENV:=CARGO_TARGET_$(shell echo $(RUST_TARGET) | tr 'a-z-' 'A-Z_')_LINKER

define Package/xtp-rs
  SECTION:=net
  CATEGORY:=Network
  TITLE:=xtp-rs transparent proxy
  URL:=https://github.com/hrimfaxi/xtp-rs
  DEPENDS:=+kmod-nft-tproxy
endef

define Package/xtp-rs/description
  tproxy / port forward -> SOCKS5, with IP country-based direct switch
endef

define Build/Configure
	$(call Build/Configure/Default)
	mkdir -p $(PKG_BUILD_DIR)/.cargo
	printf '[target.$(RUST_TARGET)]\nlinker = "$(TARGET_CC)"\n' > $(PKG_BUILD_DIR)/.cargo/config.toml
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
	CARGO_HOME=$(PKG_BUILD_DIR)/.cargo_home \
	CARGO_TARGET_DIR=$(PKG_BUILD_DIR)/target \
	TARGET_CC=$(TARGET_CC) \
	TARGET_CXX=$(TARGET_CXX) \
	TARGET_AR=$(TARGET_AR) \
	$(CARGO_TARGET_ENV)=$(TARGET_CC) \
	RUSTFLAGS="-C target-feature=-crt-static" \
	cargo build --release --target $(RUST_TARGET)
endef

define Package/xtp-rs/install
	# 二进制
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/$(RUST_TARGET)/release/xtp-rs $(1)/usr/bin/

	# 配置文件 & MMDB
	$(INSTALL_DIR) $(1)/etc/xtp-rs
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/contrib/etc/xtp-rs/config.toml $(1)/etc/xtp-rs/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/contrib/etc/xtp-rs/Country-only-cn-private.mmdb $(1)/etc/xtp-rs/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/contrib/etc/xtp-rs/geosite.dat $(1)/etc/xtp-rs/

	# init 脚本
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/contrib/etc/init.d/xtp-rs $(1)/etc/init.d/

	# capabilities
	$(INSTALL_DIR) $(1)/etc/capabilities
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/contrib/etc/capabilities/xtp-rs.json $(1)/etc/capabilities/

	# libexec 脚本
	$(INSTALL_DIR) $(1)/usr/libexec/xtp-rs
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/contrib/usr/libexec/xtp-rs/common.sh $(1)/usr/libexec/xtp-rs/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/contrib/usr/libexec/xtp-rs/setup-xtp-rs.sh $(1)/usr/libexec/xtp-rs/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/contrib/usr/libexec/xtp-rs/unsetup-xtp-rs.sh $(1)/usr/libexec/xtp-rs/
endef

$(eval $(call BuildPackage,xtp-rs))
