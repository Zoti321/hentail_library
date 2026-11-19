#!/usr/bin/env bash
# Local first-time / post-clone setup: Rust link + native deps.
# Linux / macOS / Windows (Git Bash, MSYS2).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

host_os() {
  uname -s 2>/dev/null || true
}

flutter_run_hint() {
  case "$(host_os)" in
    Darwin*) echo "flutter run -d macos" ;;
    Linux*) echo "flutter run -d linux" ;;
    MINGW* | MSYS* | CYGWIN*) echo "flutter run -d windows" ;;
    *)
      if [[ "${OS:-}" == "Windows_NT" ]]; then
        echo "flutter run -d windows"
      else
        echo "flutter run"
      fi
      ;;
  esac
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
  bash "$REPO_ROOT/core/vendor/fetch-native-deps.sh" --android
  # macOS: also fetch iOS pdfium for embed_pdfium.sh App-bundle embedding.
  if [[ "$(host_os)" == "Darwin" ]]; then
    bash "$REPO_ROOT/core/vendor/fetch-native-deps.sh" --ios
  fi
fi

echo "开发环境初始化完成。"
if command -v flutter >/dev/null 2>&1; then
  echo "当前 Flutter: $(flutter --version 2>/dev/null | head -n 1)"
  echo "工具链版本以 .github/workflows/gate.yml 为准。"
else
  echo "未检测到 flutter 命令；请按 .github/workflows/gate.yml 安装 SDK 后再进入 app/。"
fi
echo "下一步: cd app && flutter pub get && $(flutter_run_hint)"
