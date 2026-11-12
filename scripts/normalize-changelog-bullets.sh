#!/usr/bin/env bash
# Extract list-item lines from generate-notes markdown and emit short "- " bullets.
set -euo pipefail

awk '{
  gsub(/^[[:space:]]+|[[:space:]]+$/, "")
  if ($0 !~ /^[-*][[:space:]]/) next
  sub(/^[-*][[:space:]]*/, "")
  sub(/ by @[^ ]+ in https:\/\/github\.com\/[^ ]+$/, "")
  sub(/( \(@[^)]+\))+$/, "")
  gsub(/^[[:space:]]+|[[:space:]]+$/, "")
  if (length($0)) print "- " $0
}'
