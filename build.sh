#!/bin/bash

# Initialize variables

GRN='\033[01;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[01;31m'
RST='\033[0m'
ORIGIN_DIR=$(pwd)
BUILD_PREF_COMPILER='clang'
TOOLCHAIN=$ORIGIN_DIR/build-shit/toolchain
IMAGE=$ORIGIN_DIR/out/arch/arm64/boot/Image
DEVICE=RMX1821
CONFIG="${DEVICE}_defconfig"

# export environment variables
export_env_vars() {
    export KBUILD_BUILD_USER=Const
    export KBUILD_BUILD_HOST=Coccinelle

    export ARCH=arm64
    export SUBARCH=arm64
    export ANDROID_MAJOR_VERSION=r
    export PLATFORM_VERSION=11.0.0

    # CCACHE
    export USE_CCACHE=1
    export PATH="/usr/lib/ccache/bin/:$PATH"
    export CCACHE_SLOPPINESS="file_macro,locale,time_macros"
    export CCACHE_NOHASHDIR="true"
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    export CC=${BUILD_PREF_COMPILER}
}

script_echo() {
    echo "  $1"
}
exit_script() {
    kill -INT $$
}
add_deps() {
    echo -e "${CYAN}"
    if [ ! -d "$ORIGIN_DIR/build-shit" ]
    then
        script_echo "Create build-shit folder"
        mkdir "$ORIGIN_DIR/build-shit"
    fi

    if [ ! -d "$ORIGIN_DIR/build-shit/toolchain" ]
    then
        script_echo "Downloading proton-clang...."
        cd "$ORIGIN_DIR/build-shit" || exit
        script_echo $(wget -q https://github.com/kdrag0n/proton-clang/archive/refs/tags/20201212.tar.gz -O clang.tar.gz);
        bsdtar xf clang.tar.gz
        rm -rf clang.tar.gz
        mv proton-clang* toolchain
        cd ../
    fi
    verify_toolchain_install
}
verify_toolchain_install() {
    script_echo " "
    if [[ -d "${TOOLCHAIN}" ]]; then
        script_echo "I: Toolchain found at default location"
        export PATH="${TOOLCHAIN}/bin:$PATH"
        export LD_LIBRARY_PATH="${TOOLCHAIN}/lib:$LD_LIBRARY_PATH"
    else
        script_echo "I: Toolchain not found"
        script_echo "   Downloading recommended toolchain at ${TOOLCHAIN}..."
        add_deps
    fi
}
build_kernel_image() {
    cleanup
    script_echo " "
    echo -e "${GRN}"
    read -p "Write the Kernel version: " KV
    echo -e "${YELLOW}"
    script_echo "Building CosmicFresh Kernel For $DEVICE"
    make -C "$ORIGIN_DIR" CC=${BUILD_PREF_COMPILER} -j$(($(nproc)+1)) LOCALVERSION="—CosmicFresh-R$KV" $CONFIG 2>&1 | sed 's/^/     /'
    make -C "$ORIGIN_DIR" CC=${BUILD_PREF_COMPILER} -j$(($(nproc)+1)) LOCALVERSION="—CosmicFresh-R$KV" 2>&1 | sed 's/^/     /'
    SUCCESS=$?
    echo -e "${RST}"

    if [ $SUCCESS -eq 0 ] && [ -f "$IMAGE" ]
    then
        echo -e "${GRN}"
        script_echo "------------------------------------------------------------"
        script_echo "Compilation successful..."
        script_echo "Image can be found at out/arch/arm64/boot/Image"
        script_echo  "------------------------------------------------------------"
    elif [ $SUCCESS -eq 130 ]
    then
        echo -e "${RED}"
        script_echo "------------------------------------------------------------"
        script_echo "Build force stopped by the user."
        script_echo "------------------------------------------------------------"
        echo -e "${RST}"
    elif [ $SUCCESS -eq 1 ]
    then
        echo -e "${RED}"
        script_echo "------------------------------------------------------------"
        script_echo "Compilation failed..check build logs for errors"
        script_echo "------------------------------------------------------------"
        echo -e "${RST}"
        cleanup
    fi
}

cleanup() {
    rm -rf "$ORIGIN_DIR"/out/arch/arm64/boot/{Image,dt*}
}
add_deps
export_env_vars
build_kernel_image
