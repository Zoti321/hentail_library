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

pdfium_lib_name() {
  local platform="$1"
  case "$platform" in
    windows-*) echo "pdfium.dll" ;;
    macos-*) echo "libpdfium.dylib" ;;
    *) echo "libpdfium.so" ;;
  esac
}

fetch_pdfium_for_platform() {
  local platform="$1"
  local artifact
  artifact="$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(m['pdfium']['artifacts']['$platform'])")"
  local out_dir="$VENDOR_ROOT/$platform"
  mkdir -p "$out_dir"

  local url="https://github.com/bblanchon/pdfium-binaries/releases/download/${pdfium_version}/${artifact}"
  local tmp_archive tmp_extract
  tmp_archive="$(mktemp)"
  tmp_extract="$(mktemp -d)"

  cleanup() {
    rm -f "$tmp_archive"
    rm -rf "$tmp_extract"
  }
  trap cleanup RETURN

  echo "下载 $url ..."
  curl -fsSL "$url" -o "$tmp_archive"

  if [[ "$artifact" == *.tgz ]]; then
    tar -xzf "$tmp_archive" -C "$tmp_extract"
  else
    unzip -q "$tmp_archive" -d "$tmp_extract"
  fi

  local want lib_path
  want="$(pdfium_lib_name "$platform")"
  lib_path="$(find "$tmp_extract" -name "$want" -print -quit)"
  if [[ -z "$lib_path" ]]; then
    echo "解压后未找到 $want ($platform)" >&2
    exit 1
  fi

  cp "$lib_path" "$out_dir/$want"
  echo "已写入 $out_dir/$want"
}

platforms=()
if [[ $# -eq 0 ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    platforms=("macos-aarch64" "macos-x86_64")
  else
    platforms=("$(detect_platform)")
  fi
else
  for arg in "$@"; do
    case "$arg" in
      --host)
        platforms+=("$(detect_platform)")
        ;;
      --android)
        platforms+=("android-arm" "android-arm64" "android-x86" "android-x64")
        ;;
      --platform=*)
        IFS=',' read -r -a keys <<< "${arg#--platform=}"
        for key in "${keys[@]}"; do
          [[ -n "$key" ]] && platforms+=("$key")
        done
        ;;
      *)
        echo "未知参数: $arg（支持 --host、--android、--platform=key[,key...]）" >&2
        exit 1
        ;;
    esac
  done
fi

# unique
mapfile -t platforms < <(printf '%s\n' "${platforms[@]}" | awk 'NF && !seen[$0]++')

for platform in "${platforms[@]}"; do
  fetch_pdfium_for_platform "$platform"
done
