#!/usr/bin/env bash
# CI-only filtered Miri run for hentai-core lib tests (Nightly).
# Native FFI (pdfium / unrar / SQLite via sqlx) is out of Miri's interpreter.
# Lib tests that open SQLite/FFI use `#[cfg_attr(miri, ignore = "sqlite/FFI unavailable under miri")]`.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CORE_MANIFEST="$REPO_ROOT/core/Cargo.toml"
export MIRIFLAGS="${MIRIFLAGS:--Zmiri-disable-isolation -Zmiri-ignore-leaks}"

usage() {
  cat <<'EOF'
用法: bash .github/scripts/run-rust-miri.sh

环境变量:
  MIRIFLAGS  传给 Miri（默认 -Zmiri-disable-isolation -Zmiri-ignore-leaks）

仅跑 -p hentai-core --lib；集成测与 FFI 路径不在范围内。
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! rustup run nightly miri --version >/dev/null 2>&1; then
  echo "nightly miri 不可用。运行: rustup toolchain install nightly --component miri rust-src" >&2
  exit 1
fi

echo "==> rust-miri (hentai-core --lib)"
# build.rs may be skipped under miri; pdf.rs uses option_env! + cfg(miri) so missing
# HENTAI_PDFIUM_LIB_DIR does not fail compilation. FFI-heavy tests use cfg(miri) ignore.
cargo +nightly miri test \
  --manifest-path "$CORE_MANIFEST" \
  -p hentai-core \
  --lib
