#!/usr/bin/env bash
# 本地复现 Gate workflow（.github/workflows/ci.yml）的 gate-* 硬门禁。
# CI 各 job 直接调用本脚本对应子命令，保证本地与 CI 命令同源。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
CORE_MANIFEST="$REPO_ROOT/core/Cargo.toml"
GATE_MANIFEST="$APP_DIR/test/gate/manifest.txt"

usage() {
  cat <<'EOF'
用法: ./scripts/run-gate.sh [子命令...]

子命令（缺省为 all，按顺序执行）:
  rust-lint       cargo fmt --check + cargo clippy -D warnings
  rust-test       cargo test（core/ workspace）
  codegen-drift   FRB generate + build_runner，随后检查 git 工作区无漂移
  dart-static     dart format --set-exit-if-changed + flutter analyze
  dart-test       flutter test ← app/test/gate/manifest.txt
  all             以上全部

示例:
  ./scripts/run-gate.sh dart-static dart-test
EOF
}

gate_manifest_entries() {
  sed -e 's/\r$//' -e 's/#.*$//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' \
    "$GATE_MANIFEST" | sed '/^$/d'
}

run_rust_lint() {
  echo "==> gate-rust-lint"
  cargo fmt --manifest-path "$CORE_MANIFEST" --all -- --check
  cargo clippy --manifest-path "$CORE_MANIFEST" --workspace --all-targets -- -D warnings
}

run_rust_test() {
  echo "==> gate-rust-test"
  cargo test --manifest-path "$CORE_MANIFEST"
}

run_codegen_drift() {
  echo "==> gate-codegen-drift"
  (
    cd "$APP_DIR"
    flutter_rust_bridge_codegen generate
    dart run build_runner build --delete-conflicting-outputs
  )
  local drift
  drift="$(git -C "$REPO_ROOT" status --porcelain -- app core)"
  if [[ -n "$drift" ]]; then
    echo "$drift"
    git -C "$REPO_ROOT" --no-pager diff --stat -- app core
    echo "::error::Codegen drift: 重新运行 FRB generate / build_runner 并提交产物。" >&2
    return 1
  fi
}

run_dart_static() {
  echo "==> gate-dart-static"
  (
    cd "$APP_DIR"
    dart format --output=none --set-exit-if-changed lib test
    flutter analyze
  )
}

run_dart_test() {
  echo "==> gate-dart-test"
  local entries=()
  mapfile -t entries < <(gate_manifest_entries)
  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "gate manifest 为空: $GATE_MANIFEST" >&2
    return 1
  fi
  (cd "$APP_DIR" && flutter test "${entries[@]}")
}

run_step() {
  case "$1" in
    rust-lint) run_rust_lint ;;
    rust-test) run_rust_test ;;
    codegen-drift) run_codegen_drift ;;
    dart-static) run_dart_static ;;
    dart-test) run_dart_test ;;
    all)
      run_rust_lint
      run_rust_test
      run_codegen_drift
      run_dart_static
      run_dart_test
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "未知子命令: $1" >&2
      usage >&2
      return 1
      ;;
  esac
}

if [[ $# -eq 0 ]]; then
  set -- all
fi

for step in "$@"; do
  run_step "$step"
done
