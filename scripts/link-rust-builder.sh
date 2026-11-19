#!/usr/bin/env bash
# Link app/rust_builder/rust -> core/crates/flutter (Cargokit / FRB).
# Unix: symlink. Windows (Git Bash/MSYS/Cygwin): directory junction.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINK_PATH="$REPO_ROOT/app/rust_builder/rust"
TARGET="$REPO_ROOT/core/crates/flutter"

die() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$TARGET/Cargo.toml" ]] || die "未找到 $TARGET/Cargo.toml"

if [[ -e "$LINK_PATH" || -L "$LINK_PATH" ]]; then
  if [[ "$LINK_PATH" -ef "$TARGET" ]]; then
    echo "Rust 链接已就绪: $LINK_PATH"
    exit 0
  fi
  die "路径已存在且不是目标链接，请人工核对: $LINK_PATH"
fi

is_windows() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
  esac
  [[ "${OS:-}" == "Windows_NT" ]]
}

to_win_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    # Fallback: /e/foo -> E:\foo
    printf '%s' "$1" | sed -e 's|^/\([a-zA-Z]\)/|\1:\\|' -e 's|/|\\|g'
  fi
}

create_windows_junction() {
  local link_win target_win
  link_win="$(to_win_path "$LINK_PATH")"
  target_win="$(to_win_path "$TARGET")"

  if command -v powershell.exe >/dev/null 2>&1 || command -v pwsh.exe >/dev/null 2>&1; then
    local ps
    if command -v powershell.exe >/dev/null 2>&1; then
      ps=powershell.exe
    else
      ps=pwsh.exe
    fi
    # Env vars avoid Git Bash mangling quoted paths for PowerShell.
    HENTAI_RUST_LINK_PATH="$link_win" HENTAI_RUST_LINK_TARGET="$target_win" \
      "$ps" -NoProfile -Command \
      '$ErrorActionPreference = "Stop"; New-Item -ItemType Junction -Path $env:HENTAI_RUST_LINK_PATH -Target $env:HENTAI_RUST_LINK_TARGET | Out-Null'
    return
  fi

  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe //c mklink /J "$link_win" "$target_win" >/dev/null
    return
  fi

  die "Windows 上需要 powershell.exe/pwsh.exe 或 cmd.exe 以创建 junction"
}

mkdir -p "$(dirname "$LINK_PATH")"

if is_windows; then
  create_windows_junction
else
  ln -s ../../core/crates/flutter "$LINK_PATH"
fi

echo "已链接 $LINK_PATH -> core/crates/flutter"
