#!/usr/bin/env bash
# Drop list-item lines from generate-notes markdown; keep headings and Full Changelog.
set -euo pipefail

# Preserve original CRLF lines under Git Bash as well as LF on Unix.
awk -v BINMODE=3 '{
  trimmed = $0
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed)
  if (trimmed !~ /^[-*][[:space:]]/) print
}'
