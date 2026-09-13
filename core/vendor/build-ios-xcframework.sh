#!/usr/bin/env bash
# 将 vendored 的三份 iOS pdfium 动态库打包为 XCFramework，供 CocoaPods 以
# vendored_frameworks 嵌入 Flutter iOS App（真机 arm64 + 模拟器 arm64/x64）。
#
# 仅可在 macOS 上运行（依赖 lipo / xcodebuild / install_name_tool）。
# 先运行 `./core/vendor/fetch-native-deps.sh --ios` 下载三份 dylib。
set -euo pipefail

VENDOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$VENDOR_ROOT/../.." && pwd)"
OUT_XCFRAMEWORK="$REPO_ROOT/app/rust_builder/ios/pdfium.xcframework"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "此脚本仅可在 macOS 上运行（需要 lipo / xcodebuild / install_name_tool）。" >&2
  exit 1
fi

DEVICE_DYLIB="$VENDOR_ROOT/ios-device-arm64/libpdfium.dylib"
SIM_ARM64_DYLIB="$VENDOR_ROOT/ios-simulator-arm64/libpdfium.dylib"
SIM_X64_DYLIB="$VENDOR_ROOT/ios-simulator-x64/libpdfium.dylib"

for f in "$DEVICE_DYLIB" "$SIM_ARM64_DYLIB" "$SIM_X64_DYLIB"; do
  if [[ ! -f "$f" ]]; then
    echo "缺少 $f。请先运行: ./core/vendor/fetch-native-deps.sh --ios" >&2
    exit 1
  fi
done

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

device_lib="$WORK_DIR/device/libpdfium.dylib"
sim_lib="$WORK_DIR/simulator/libpdfium.dylib"
mkdir -p "$WORK_DIR/device" "$WORK_DIR/simulator"

cp "$DEVICE_DYLIB" "$device_lib"
# 模拟器：合并 arm64 + x64 为单个 fat dylib。
lipo -create "$SIM_ARM64_DYLIB" "$SIM_X64_DYLIB" -output "$sim_lib"

# 统一 install_name 为 @rpath/libpdfium.dylib，便于嵌入 App bundle 后由 dyld/@rpath 解析。
install_name_tool -id "@rpath/libpdfium.dylib" "$device_lib"
install_name_tool -id "@rpath/libpdfium.dylib" "$sim_lib"

rm -rf "$OUT_XCFRAMEWORK"
xcodebuild -create-xcframework \
  -library "$device_lib" \
  -library "$sim_lib" \
  -output "$OUT_XCFRAMEWORK"

echo "已生成 $OUT_XCFRAMEWORK"
