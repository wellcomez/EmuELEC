# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="bl301"
PKG_VERSION="8eed09e9fb81337fa91bf40051ffd49e962d0d6e"
PKG_SHA256="5746c3e7b866bc69cc0702a32b060484c573a4137140e1b5272c0aa3fd288f34"
PKG_LICENSE="GPL"
PKG_SITE="https://coreelec.org"
PKG_URL="https://github.com/CoreELEC/bl301/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

pre_make_target() {
  sed -i "s|arm-none-eabi-|arm-eabi-|g" $PKG_BUILD/Makefile $PKG_BUILD/arch/arm/cpu/armv8/*/firmware/scp_task/Makefile 2>/dev/null || true
}

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-elf/bin/:$TOOLCHAIN/lib/gcc-linaro-arm-eabi/bin/:$PATH
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make mrproper

  for f in $(find ${PKG_BUILD}/configs -mindepth 1); do
    PKG_UBOOT_CONFIG=$(basename -- "$f")
    PKG_BL301_SUBDEVICE=${PKG_UBOOT_CONFIG%_defconfig}
    echo Building bl301 for ${PKG_BL301_SUBDEVICE}
    DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make ${PKG_UBOOT_CONFIG}
    DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make HOSTCC="${HOST_CC}" HOSTSTRIP="true" bl301.bin
    mv ${PKG_BUILD}/build/scp_task/bl301.bin ${PKG_BUILD}/build/${PKG_BL301_SUBDEVICE}_bl301.bin
    echo "moved blob to: " ${PKG_BUILD}/build/${PKG_BL301_SUBDEVICE}_bl301.bin
  done
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader/bl301

  for f in $(find ${PKG_BUILD}/configs -mindepth 1); do
    PKG_UBOOT_CONFIG=$(basename -- "$f")
    PKG_BL301_SUBDEVICE=${PKG_UBOOT_CONFIG%_defconfig}
    PKG_BIN=${PKG_BUILD}/build/${PKG_BL301_SUBDEVICE}_bl301.bin
    cp -av ${PKG_BIN} ${INSTALL}/usr/share/bootloader/bl301/${PKG_BL301_SUBDEVICE}_bl301.bin
  done
}
