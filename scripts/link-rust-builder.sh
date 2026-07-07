#!/usr/bin/env bash
# 将 app/rust_builder/rust 链接到 core/crates/flutter（Cargokit / FRB 构建所需）。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JUNCTION="$REPO_ROOT/app/rust_builder/rust"
TARGET="$REPO_ROOT/core/crates/flutter"

if [[ ! -f "$TARGET/Cargo.toml" ]]; then
  echo "error: 未找到 $TARGET/Cargo.toml" >&2
  exit 1
fi

rm -rf "$JUNCTION"
ln -s ../../core/crates/flutter "$JUNCTION"
echo "已链接 $JUNCTION -> core/crates/flutter"
