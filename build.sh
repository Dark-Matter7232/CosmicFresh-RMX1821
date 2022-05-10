#!/bin/bash

echo "Cloning dependencies"

git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r437112.git clang
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
# git clone --depth=1 https://github.com/Subash2001/AnyKernel3.git AnyKernel

echo "Done"

export ARCH=arm64
export KBUILD_BUILD_USER=Const
export KBUILD_BUILD_HOST=Coccinelle
ZIPNAME="Const_KERNEL-RMX1821-$(date '+%Y%m%d-%H%M').zip"
PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \

# Compile plox

make -j$(nproc) O=out ARCH=arm64 RMX1821_defconfig
make -j$(nproc) O=out \
                ARCH=arm64 \
                CC=clang \
                CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE="${PWD}/los-4.9-64/bin/aarch64-linux-android-" \
                CROSS_COMPILE_ARM32="${PWD}/los-4.9-32/bin/arm-linux-androideabi-" \
                CONFIG_NO_ERROR_ON_MISMATCH=y

# Zipping

cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
cd AnyKernel
zip -r9 $ZIPNAME *
