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

rm -rf "$JUNCTION"

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
  powershell.exe -NoProfile -Command \
    "New-Item -ItemType Junction -Path '$junction_win' -Target '$target_win' | Out-Null"
else
  ln -s ../../core/crates/flutter "$JUNCTION"
fi

echo "已链接 $JUNCTION -> core/crates/flutter"
