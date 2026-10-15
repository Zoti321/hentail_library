#!/usr/bin/env bash
# Canonical hentai-core line coverage via cargo-llvm-cov (Nightly + Gate + local rust-coverage).
# Same package scope and ignore rules as gate-rust-test product code; see docs/agents/testing.md.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE_MANIFEST="$REPO_ROOT/core/Cargo.toml"
OUTPUT_DIR="${RUST_COVERAGE_OUTPUT_DIR:-$REPO_ROOT/target/rust-coverage}"
LCOV_PATH="$OUTPUT_DIR/lcov.info"
HTML_DIR="$OUTPUT_DIR/html"

# Exclude vendored natives and integration-test harness trees from the denominator.
RUST_COVERAGE_IGNORE_REGEX="${RUST_COVERAGE_IGNORE_REGEX:-(/vendor/|/crates/core/tests/)}"

usage() {
  cat <<'EOF'
用法: ./scripts/run-rust-coverage.sh [选项]

环境变量:
  RUST_COVERAGE_OUTPUT_DIR     输出目录（默认 target/rust-coverage）
  RUST_COVERAGE_FAIL_UNDER_LINES  若设置，行覆盖率低于该整数百分比时非零退出（Gate）
  RUST_COVERAGE_HTML           设为 1 时额外生成 HTML（Nightly）；Gate 不设
  RUST_COVERAGE_IGNORE_REGEX   覆盖默认 --ignore-filename-regex

与 gate-rust-test 同 workspace 测试范围，指标仅 -p hentai-core 产品源码。
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mkdir -p "$OUTPUT_DIR"

llvm_cov_args=(
  llvm-cov
  --manifest-path "$CORE_MANIFEST"
  -p hentai-core
  --ignore-filename-regex "$RUST_COVERAGE_IGNORE_REGEX"
  --lcov
  --output-path "$LCOV_PATH"
)

if [[ "${RUST_COVERAGE_HTML:-0}" == "1" ]]; then
  mkdir -p "$HTML_DIR"
  llvm_cov_args+=(--html --output-dir "$HTML_DIR")
fi

if [[ -n "${RUST_COVERAGE_FAIL_UNDER_LINES:-}" ]]; then
  llvm_cov_args+=(--fail-under-lines "$RUST_COVERAGE_FAIL_UNDER_LINES")
fi

echo "==> rust-coverage (hentai-core, ignore=$RUST_COVERAGE_IGNORE_REGEX)"
cargo "${llvm_cov_args[@]}"

if [[ -f "$LCOV_PATH" ]]; then
  summary_line="$(
    awk -F: '/^LF:/{found+=$2} /^LH:/{hit+=$2} END {
      pct = found ? hit * 100 / found : 0
      printf "Rust line coverage: %.1f%% (%d / %d lines)\n", pct, hit, found
    }' "$LCOV_PATH"
  )"
  echo "$summary_line"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "$summary_line" >>"$GITHUB_STEP_SUMMARY"
  fi
else
  echo "missing lcov: $LCOV_PATH" >&2
  exit 1
fi
