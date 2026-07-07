#!/usr/bin/env bash
# 本地首次 / clone 后开发环境初始化（Rust 链接 + 原生依赖）。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKIP_RUST_LINK=0
SKIP_NATIVE_DEPS=0

usage() {
  cat <<'EOF'
用法: ./scripts/setup-dev.sh [选项]

选项:
  --skip-rust-link     跳过 app/rust_builder/rust 链接
  --skip-native-deps   跳过 pdfium 等原生依赖下载
  -h, --help           显示此帮助
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-rust-link) SKIP_RUST_LINK=1 ;;
    --skip-native-deps) SKIP_NATIVE_DEPS=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "未知选项: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ $SKIP_RUST_LINK -eq 0 ]]; then
  bash "$REPO_ROOT/scripts/link-rust-builder.sh"
fi

if [[ $SKIP_NATIVE_DEPS -eq 0 ]]; then
  bash "$REPO_ROOT/core/vendor/fetch-native-deps.sh"
fi

echo "开发环境初始化完成。"
echo "下一步: cd app && flutter pub get && flutter run -d windows"
