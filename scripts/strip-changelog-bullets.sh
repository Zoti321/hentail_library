#!/usr/bin/env bash
# Drop list-item lines from generate-notes markdown; keep headings and Full Changelog.
set -euo pipefail

while IFS= read -r line || [ -n "$line" ]; do
  trimmed="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ "$trimmed" =~ ^[-\*][[:space:]] ]]; then
    continue
  fi
  printf '%s\n' "$line"
done
