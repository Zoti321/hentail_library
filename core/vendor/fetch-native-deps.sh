#!/usr/bin/env bash
# Download vendored pdfium binaries into core/vendor/<platform>/.
# Linux / macOS / Windows (Git Bash, MSYS2, Cygwin). Requires curl + tar;
# jq preferred for manifest.json, else python3/python.
set -euo pipefail

VENDOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$VENDOR_ROOT/manifest.json"

die() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$MANIFEST" ]] || die "missing $MANIFEST"

# Run Python with cwd=VENDOR_ROOT so relative open() works under Git Bash
# (Windows Python cannot open MSYS paths like /e/...).
py_manifest() {
  local code="$1"
  shift
  local py
  for py in python3 python; do
    if command -v "$py" >/dev/null 2>&1; then
      (cd "$VENDOR_ROOT" && "$py" -c "$code" "$@")
      return
    fi
  done
  die "need jq or python3/python to read manifest.json"
}

pdfium_version_encoded() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '.pdfium.version' "$MANIFEST" | sed 's|/|%2F|g'
    return
  fi
  py_manifest 'import json; print(json.load(open("manifest.json", encoding="utf-8"))["pdfium"]["version"].replace("/", "%2F"))'
}

pdfium_artifact() {
  local platform="$1"
  local artifact
  if command -v jq >/dev/null 2>&1; then
    artifact="$(jq -r --arg p "$platform" '.pdfium.artifacts[$p] // empty' "$MANIFEST")"
  else
    artifact="$(py_manifest 'import json,sys; print(json.load(open("manifest.json", encoding="utf-8"))["pdfium"]["artifacts"].get(sys.argv[1], ""))' "$platform")"
  fi
  [[ -n "$artifact" ]] || die "manifest.json has no artifact for platform: $platform"
  printf '%s\n' "$artifact"
}

detect_platform() {
  local os arch
  os="$(uname -s 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"
  case "${os}-${arch}" in
    Linux-x86_64) echo "linux-x86_64" ;;
    Linux-aarch64 | Linux-arm64) echo "linux-aarch64" ;;
    Darwin-x86_64) echo "macos-x86_64" ;;
    Darwin-arm64) echo "macos-aarch64" ;;
    MINGW*-x86_64 | MSYS*-x86_64 | CYGWIN*-x86_64) echo "windows-x86_64" ;;
    MINGW*-aarch64 | MSYS*-aarch64 | CYGWIN*-aarch64 | MINGW*-arm64 | MSYS*-arm64) echo "windows-aarch64" ;;
    *)
      if [[ "${OS:-}" == "Windows_NT" ]]; then
        case "${PROCESSOR_ARCHITECTURE:-}${PROCESSOR_ARCHITEW6432:-}" in
          *ARM64* | *arm64*) echo "windows-aarch64" ;;
          *) echo "windows-x86_64" ;;
        esac
        return
      fi
      die "unsupported host: ${os}-${arch}"
      ;;
  esac
}

pdfium_lib_name() {
  local platform="$1"
  case "$platform" in
    windows-*) echo "pdfium.dll" ;;
    macos-* | ios-*) echo "libpdfium.dylib" ;;
    *) echo "libpdfium.so" ;;
  esac
}

find_named_file() {
  local root="$1" name="$2"
  # Avoid GNU-only find -quit; first match is enough.
  find "$root" -type f -name "$name" 2>/dev/null | head -n 1
}

fetch_pdfium_for_platform() {
  local platform="$1"
  local artifact out_dir url tmp_archive tmp_extract want lib_path
  artifact="$(pdfium_artifact "$platform")"
  out_dir="$VENDOR_ROOT/$platform"
  mkdir -p "$out_dir"

  url="https://github.com/bblanchon/pdfium-binaries/releases/download/${pdfium_version}/${artifact}"
  tmp_archive="$(mktemp "${TMPDIR:-/tmp}/hentai-pdfium.XXXXXX")"
  tmp_extract="$(mktemp -d "${TMPDIR:-/tmp}/hentai-pdfium-extract.XXXXXX")"

  cleanup() {
    rm -f "$tmp_archive"
    rm -rf "$tmp_extract"
  }
  trap cleanup RETURN

  echo "下载 $url ..."
  curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 "$url" -o "$tmp_archive"

  if [[ "$artifact" == *.tgz || "$artifact" == *.tar.gz ]]; then
    tar -xzf "$tmp_archive" -C "$tmp_extract"
  else
    command -v unzip >/dev/null 2>&1 || die "unzip required for $artifact"
    unzip -q "$tmp_archive" -d "$tmp_extract"
  fi

  want="$(pdfium_lib_name "$platform")"
  lib_path="$(find_named_file "$tmp_extract" "$want")"
  if [[ -z "$lib_path" ]]; then
    die "解压后未找到 $want ($platform)"
  fi

  cp "$lib_path" "$out_dir/$want"
  echo "已写入 $out_dir/$want"
}

usage() {
  cat <<'EOF'
用法: ./core/vendor/fetch-native-deps.sh [选项...]

无参数时下载当前 host 平台（macOS 为双架构）。

选项:
  --host                 当前 host 平台
  --android              Android ABI（arm / arm64 / x86 / x64）
  --ios                  iOS（device arm64 + simulator arm64/x64）
  --platform=key[,key]   精确平台键（见 manifest.json）
  -h, --help             显示此帮助
EOF
}

platforms=()
if [[ $# -eq 0 ]]; then
  if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
    platforms=("macos-aarch64" "macos-x86_64")
  else
    platforms=("$(detect_platform)")
  fi
else
  for arg in "$@"; do
    case "$arg" in
      -h | --help)
        usage
        exit 0
        ;;
      --host)
        platforms+=("$(detect_platform)")
        ;;
      --android)
        platforms+=("android-arm" "android-arm64" "android-x86" "android-x64")
        ;;
      --ios)
        platforms+=("ios-device-arm64" "ios-simulator-arm64" "ios-simulator-x64")
        ;;
      --platform=*)
        IFS=',' read -r -a keys <<< "${arg#--platform=}"
        for key in "${keys[@]}"; do
          [[ -n "$key" ]] && platforms+=("$key")
        done
        ;;
      *)
        echo "未知参数: $arg" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
fi

# Deduplicate while preserving order (bash 3 compatible).
unique_platforms=()
for key in "${platforms[@]}"; do
  [[ -z "$key" ]] && continue
  already=0
  if ((${#unique_platforms[@]} > 0)); then
    for existing in "${unique_platforms[@]}"; do
      if [[ "$existing" == "$key" ]]; then
        already=1
        break
      fi
    done
  fi
  if [[ "$already" -eq 0 ]]; then
    unique_platforms+=("$key")
  fi
done
platforms=("${unique_platforms[@]}")
((${#platforms[@]} > 0)) || die "no platforms selected"

pdfium_version="$(pdfium_version_encoded)"
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

for platform in "${platforms[@]}"; do
  fetch_pdfium_for_platform "$platform"
done
