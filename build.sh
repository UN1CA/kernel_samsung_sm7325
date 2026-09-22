#!/usr/bin/env bash
#
# Build script for the UN1CA sm7325 kernel (Galaxy A52s 5G / A73 5G / M52 5G)
#
# Usage: ./build.sh <a52sxq|a73xq|m52xq>
#
# Environment:
#   KERNEL_DIR  Kernel source tree (default: ./kernel)
#   LLVM_DIR    Path to the clang toolchain root (default: ./llvm-aosp)
#   OUT_DIR     Kernel output directory (default: ./out)
#   DIST_DIR    Where the final images are copied (default: ./dist)
#

set -euo pipefail

case "${1:-}" in
    a52sxq|a73xq|m52xq)
        DEVICE="$1"
        ;;
    *)
        echo "Usage: $0 <a52sxq|a73xq|m52xq>" >&2
        exit 1
        ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL_DIR="$(cd "${KERNEL_DIR:-$ROOT_DIR/kernel}" && pwd)"
LLVM_DIR="${LLVM_DIR:-$ROOT_DIR/llvm-aosp}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/out}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"

DEFCONFIG="vendor/${DEVICE}_eur_open_defconfig"

log() {
    echo
    echo "-----------------------------------------------"
    echo "$1"
    echo "-----------------------------------------------"
}

if [ ! -f "$KERNEL_DIR/Makefile" ]; then
    echo "Kernel source not found in $KERNEL_DIR" >&2
    exit 1
fi

if [ ! -x "$LLVM_DIR/bin/clang" ]; then
    echo "clang not found in $LLVM_DIR/bin" >&2
    exit 1
fi

export PATH="$LLVM_DIR/bin:$PATH"

MAKE_ARGS=(
    -C "$KERNEL_DIR"
    O="$OUT_DIR"
    ARCH=arm64
    LLVM=1
    LLVM_IAS=1
)

build_kernel() {
    log "Building kernel for $DEVICE ($DEFCONFIG)..."
    clang --version | head -n 1

    mkdir -p "$OUT_DIR"
    make "${MAKE_ARGS[@]}" "$DEFCONFIG"

    make "${MAKE_ARGS[@]}" -j"$(nproc)"

    make "${MAKE_ARGS[@]}" \
        INSTALL_MOD_PATH="$OUT_DIR/modules_install" \
        INSTALL_MOD_STRIP=1 \
        modules_install
}

collect_dist() {
    log "Collecting build output..."

    local BOOT_DIR="$OUT_DIR/arch/arm64/boot"
    local DTB_DIR="$BOOT_DIR/dts/vendor/qcom"
    local MOD_DIR="$DIST_DIR/modules-$DEVICE"

    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR" "$MOD_DIR"

    cp "$BOOT_DIR/Image" "$DIST_DIR/Image-$DEVICE"
    cp "$BOOT_DIR/dtbo.img" "$DIST_DIR/dtbo-$DEVICE.img"
    cp "$DTB_DIR/yupik.dtb" "$DIST_DIR/dtb-$DEVICE"

    find "$OUT_DIR/modules_install/lib/modules" -name "*.ko" -exec cp {} "$MOD_DIR/" \;
    cp "$OUT_DIR/modules_install/lib/modules/$(cat "$OUT_DIR/include/config/kernel.release")/modules.alias" "$MOD_DIR/modules.alias"
    cp "$OUT_DIR/modules_install/lib/modules/$(cat "$OUT_DIR/include/config/kernel.release")/modules.dep" "$MOD_DIR/modules.dep"
    cp "$OUT_DIR/modules_install/lib/modules/$(cat "$OUT_DIR/include/config/kernel.release")/modules.softdep" "$MOD_DIR/modules.softdep"
    cp "$OUT_DIR/modules_install/lib/modules/$(cat "$OUT_DIR/include/config/kernel.release")/modules.order" "$MOD_DIR/modules.load"
    sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/lib\/modules\/\2/g' "$MOD_DIR/modules.dep"
    sed -i 's/.*\///g' "$MOD_DIR/modules.load"
    tar -C "$MOD_DIR" -czf "$DIST_DIR/modules-$DEVICE.tar.gz" .
    rm -rf "$MOD_DIR"

    cp "$OUT_DIR/include/config/kernel.release" "$DIST_DIR/kernel.release-$DEVICE"
    cp "$OUT_DIR/.config" "$DIST_DIR/config-$DEVICE"

    (cd "$DIST_DIR" && sha256sum Image-* dtbo-*.img dtb-* modules-*.tar.gz > "sha256sums-$DEVICE.txt")
}

build_kernel
collect_dist

log "Build completed successfully!"
ls -lh "$DIST_DIR"
