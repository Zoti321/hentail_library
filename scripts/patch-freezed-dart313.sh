#!/usr/bin/env bash
# freezed 3.2.x 在 Dart 3.13 下会在私有实现类构造函数生成非法的 `final` 形参修饰符。
# 在可升级到 freezed 4 + riverpod_generator 4 之前，build_runner 后执行本脚本。
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)"
shopt -s nullglob
files=("$APP_DIR"/lib/**/*.freezed.dart)

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

for f in "${files[@]}"; do
  perl -pi -e 's/, final  /, /g; s/required final  /required /g; s/\(\{final  /({/g' "$f"
done
