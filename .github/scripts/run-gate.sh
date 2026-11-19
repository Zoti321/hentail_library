#!/usr/bin/env bash
# CI-only Gate entry for .github/workflows/gate.yml and release-verify.
# Not a local developer entrypoint.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/app"
CORE_MANIFEST="$REPO_ROOT/core/Cargo.toml"
GATE_MANIFEST="$APP_DIR/test/gate/manifest.txt"

usage() {
  cat <<'EOF'
用法: bash .github/scripts/run-gate.sh [子命令...]

子命令（缺省为 all，按顺序执行）:
  rust-lint       cargo fmt --check + cargo clippy -D warnings
  rust-test       cargo nextest run（core/ workspace，--profile ci）
  codegen-drift   FRB generate + build_runner，随后检查 git 工作区无漂移
  dart-static     dart format --set-exit-if-changed + flutter analyze
  dart-lint       dart_code_linter 规则门禁（app/lib + app/test，硬失败）
  dart-test       cargo build hentai_flutter（FRB 线缝用）+ flutter test ← app/test/gate/manifest.txt
  all             以上全部
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
  if ! cargo nextest --version >/dev/null 2>&1; then
    echo "cargo-nextest 未安装。运行: cargo install cargo-nextest --locked" >&2
    return 1
  fi
  cargo nextest run --manifest-path "$CORE_MANIFEST" --workspace --profile ci
}

run_codegen_drift() {
  echo "==> gate-codegen-drift"
  (
    cd "$APP_DIR"
    flutter_rust_bridge_codegen generate
    dart run build_runner build --delete-conflicting-outputs
    # FRB 生成末尾的 `dart format` 是 warn_only（失败只 warning），失败时
    # frb_generated.dart 会以未格式化模板落盘并造成假漂移；这里显式兜底。
    dart format lib/src/rust >/dev/null
  )
  local drift
  # 按内容判定，不用 `git status --porcelain`：本机 core.autocrlf=true 时，
  # 生成器写出的 LF 文件会被 status 标成 M，但 blob 与 HEAD 完全相同（diff 为空），
  # 属于 EOL 假阳性。这里只看真实内容差异 + 未跟踪文件。
  drift="$(git -C "$REPO_ROOT" diff HEAD --name-only -- app core)"
  local untracked
  untracked="$(git -C "$REPO_ROOT" ls-files --others --exclude-standard -- app core)"
  if [[ -n "$untracked" ]]; then
    drift="${drift}${drift:+$'\n'}${untracked}"
  fi
  if [[ -n "$drift" ]]; then
    echo "$drift"
    git -C "$REPO_ROOT" --no-pager diff HEAD --stat -- app core
    echo "::error::Codegen drift: 重新运行 FRB generate / build_runner 并提交产物。" >&2
    return 1
  fi
}

run_dart_static() {
  echo "==> gate-dart-static"
  (
    cd "$APP_DIR"
    dart format --output=none --set-exit-if-changed lib test widgetbook
    flutter analyze --fatal-infos
  )
}

run_dart_lint() {
  echo "==> gate-dart-lint"
  # One package options file scopes production and test rules with include.
  # Every diagnostic severity fails, including style and performance.
  (cd "$APP_DIR" &&
    dart run dart_code_linter:metrics analyze lib test \
      --no-congratulate \
      --fatal-style \
      --fatal-performance \
      --exclude="{/**.g.dart,/**.freezed.dart,/**/src/rust/**}")
}

run_dart_test() {
  echo "==> gate-dart-test"
  local entries=()
  mapfile -t entries < <(gate_manifest_entries)
  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "gate manifest 为空: $GATE_MANIFEST" >&2
    return 1
  fi
  cargo build --manifest-path "$CORE_MANIFEST" -p hentai_flutter
  if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == mingw* || "${OSTYPE:-}" == cygwin* ]]; then
    # Keep the Flutter subprocess command line below Windows' CreateProcess limit.
    local offset=0
    local batch_size=25
    while (( offset < ${#entries[@]} )); do
      local batch=("${entries[@]:offset:batch_size}")
      (cd "$APP_DIR" && flutter test "${batch[@]}")
      offset=$((offset + batch_size))
    done
  else
    (cd "$APP_DIR" && flutter test "${entries[@]}")
  fi
}

run_step() {
  case "$1" in
    rust-lint) run_rust_lint ;;
    rust-test) run_rust_test ;;
    codegen-drift) run_codegen_drift ;;
    dart-static) run_dart_static ;;
    dart-lint) run_dart_lint ;;
    dart-test) run_dart_test ;;
    all)
      run_rust_lint
      run_rust_test
      run_codegen_drift
      run_dart_static
      run_dart_lint
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
