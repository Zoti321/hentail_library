#!/usr/bin/env bash
# Extract list-item lines from generate-notes markdown and emit short "- " bullets.
set -euo pipefail

while IFS= read -r line || [ -n "$line" ]; do
  trimmed="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ ! "$trimmed" =~ ^[-\*][[:space:]] ]]; then
    continue
  fi

  bullet="$(printf '%s' "$trimmed" | sed -E 's/^[-*][[:space:]]*//')"
  bullet="$(printf '%s' "$bullet" | sed -E 's/ by @[^ ]+ in https:\/\/github\.com\/[^ ]+$//')"
  bullet="$(printf '%s' "$bullet" | sed -E 's/( \(@[^)]+\))+$//')"
  bullet="$(printf '%s' "$bullet" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  if [ -n "$bullet" ]; then
    printf -- '- %s\n' "$bullet"
  fi
done
