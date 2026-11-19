#!/usr/bin/env bash
# CI-only timed cargo-fuzz runs for pure-Rust parsers (Nightly).
# Requires: rustup toolchain nightly, cargo-fuzz, C++ toolchain for libFuzzer.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FUZZ_DIR="$REPO_ROOT/core/fuzz"
MAX_TOTAL_TIME="${RUST_FUZZ_MAX_TOTAL_TIME:-120}"
TARGETS=(comic_info epub_opf normalize_and_sort)

usage() {
  cat <<'EOF'
用法: bash .github/scripts/run-rust-fuzz.sh [target...]

环境变量:
  RUST_FUZZ_MAX_TOTAL_TIME  每个 target 的 libFuzzer 秒数（默认 120）

默认 target: comic_info epub_opf normalize_and_sort
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
fi

if ! command -v cargo-fuzz >/dev/null 2>&1 && ! cargo fuzz -h >/dev/null 2>&1; then
  echo "cargo-fuzz 未安装。运行: cargo install cargo-fuzz" >&2
  exit 1
fi

cd "$FUZZ_DIR"
echo "==> rust-fuzz (max_total_time=${MAX_TOTAL_TIME}s)"
for target in "${TARGETS[@]}"; do
  echo "==> fuzz $target"
  cargo +nightly fuzz run "$target" -- -max_total_time="$MAX_TOTAL_TIME"
done
