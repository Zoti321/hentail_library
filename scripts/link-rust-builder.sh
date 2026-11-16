#!/usr/bin/env bash
# 将 app/rust_builder/rust 链接到 core/crates/flutter（Cargokit / FRB 构建所需）。
# Windows 使用目录 junction（无需管理员权限）；Unix 使用符号链接。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JUNCTION="$REPO_ROOT/app/rust_builder/rust"
TARGET="$REPO_ROOT/core/crates/flutter"

if [[ ! -f "$TARGET/Cargo.toml" ]]; then
  echo "error: 未找到 $TARGET/Cargo.toml" >&2
  exit 1
fi

if [[ -e "$JUNCTION" || -L "$JUNCTION" ]]; then
  if [[ "$JUNCTION" -ef "$TARGET" ]]; then
    echo "Rust 链接已就绪: $JUNCTION"
    exit 0
  fi
  echo "error: 路径已存在且不是目标链接，请人工核对: $JUNCTION" >&2
  exit 1
fi

is_windows() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
  esac
  [[ "${OS:-}" == "Windows_NT" ]]
}

if is_windows; then
  to_win() {
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -w "$1"
    else
      printf '%s' "$1" | sed -e 's|^/\([a-zA-Z]\)/|\1:\\|' -e 's|/|\\|g'
    fi
  }
  junction_win="$(to_win "$JUNCTION")"
  target_win="$(to_win "$TARGET")"
  # cmd mklink 在 Git Bash 下引号易被错误拆分；用 PowerShell 更稳妥。
  HENTAI_RUST_LINK_PATH="$junction_win" HENTAI_RUST_LINK_TARGET="$target_win" \
    powershell.exe -NoProfile -Command \
      '$ErrorActionPreference = "Stop"; New-Item -ItemType Junction -Path $env:HENTAI_RUST_LINK_PATH -Target $env:HENTAI_RUST_LINK_TARGET | Out-Null'
else
  ln -s ../../core/crates/flutter "$JUNCTION"
fi

echo "已链接 $JUNCTION -> core/crates/flutter"
