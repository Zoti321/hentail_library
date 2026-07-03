#!/usr/bin/env bash
set -euo pipefail

VENDOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$VENDOR_ROOT/manifest.json"

pdfium_version="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['pdfium']['version'].replace('/', '%2F'))")"

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}-${arch}" in
    Linux-x86_64) echo "linux-x86_64" ;;
    Linux-aarch64 | Linux-arm64) echo "linux-aarch64" ;;
    Darwin-x86_64) echo "macos-x86_64" ;;
    Darwin-arm64) echo "macos-aarch64" ;;
    MINGW*-x86_64 | MSYS*-x86_64) echo "windows-x86_64" ;;
    MINGW*-aarch64 | MSYS*-aarch64) echo "windows-aarch64" ;;
    *) echo "unsupported: ${os}-${arch}" >&2; exit 1 ;;
  esac
}

platform="$(detect_platform)"
artifact="$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(m['pdfium']['artifacts']['$platform'])")"
out_dir="$VENDOR_ROOT/$platform"
mkdir -p "$out_dir"

url="https://github.com/bblanchon/pdfium-binaries/releases/download/${pdfium_version}/${artifact}"
tmp_archive="$(mktemp)"
tmp_extract="$(mktemp -d)"

cleanup() {
  rm -f "$tmp_archive"
  rm -rf "$tmp_extract"
}
trap cleanup EXIT

echo "下载 $url ..."
curl -fsSL "$url" -o "$tmp_archive"

if [[ "$artifact" == *.tgz ]]; then
  tar -xzf "$tmp_archive" -C "$tmp_extract"
else
  unzip -q "$tmp_archive" -d "$tmp_extract"
fi

lib_path="$(find "$tmp_extract" \( -name 'libpdfium.so' -o -name 'libpdfium.dylib' -o -name 'pdfium.dll' \) -print -quit)"
if [[ -z "$lib_path" ]]; then
  echo "解压后未找到 pdfium 动态库" >&2
  exit 1
fi

case "$(basename "$lib_path")" in
  libpdfium.so) cp "$lib_path" "$out_dir/libpdfium.so" ;;
  libpdfium.dylib) cp "$lib_path" "$out_dir/libpdfium.dylib" ;;
  pdfium.dll) cp "$lib_path" "$out_dir/pdfium.dll" ;;
esac

echo "已写入 $out_dir/$(basename "$lib_path")"
