#!/usr/bin/env bash
# 将 vendored libpdfium.dylib 复制到 App bundle 的 Frameworks/，供 core/pdf.rs dlopen。
# 由 ios/Podfile post_install 注入 Runner 构建阶段；CI 需先 fetch-native-deps --ios。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="${SCRIPT_DIR}/../../../core/vendor"

if [[ "${EFFECTIVE_PLATFORM_NAME:-}" == "-iphonesimulator" ]]; then
  if [[ "${ARCHS:-}" == *"x86_64"* ]]; then
    SRC="${VENDOR}/ios-simulator-x64/libpdfium.dylib"
  else
    SRC="${VENDOR}/ios-simulator-arm64/libpdfium.dylib"
  fi
else
  SRC="${VENDOR}/ios-device-arm64/libpdfium.dylib"
fi

if [[ ! -f "${SRC}" ]]; then
  echo "error: 缺少 ${SRC}，请先运行 ./core/vendor/fetch-native-deps.sh --ios" >&2
  exit 1
fi

DEST="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${DEST}"
cp "${SRC}" "${DEST}/libpdfium.dylib"
echo "已嵌入 ${DEST}/libpdfium.dylib"
