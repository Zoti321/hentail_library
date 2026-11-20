#!/usr/bin/env bash
# Extract one Keep a Changelog version section body from CHANGELOG.md.
# Usage: extract-changelog-section.sh <version> [CHANGELOG.md]
# Prints content under "## [<version>] ..." until the next "## [" heading
# (excluding the version heading). Empty stdout if the section is missing
# or only whitespace. Reads stdin when the file argument is omitted or "-".
set -euo pipefail

version="${1:?version required (e.g. 1.2.0 or Unreleased)}"
file="${2:-}"

awk -v ver="$version" '
  function section_id(line,    rest) {
    if (line !~ /^## \[/) return ""
    rest = line
    sub(/^## \[/, "", rest)
    sub(/\].*$/, "", rest)
    return rest
  }
  {
    # Keep a Changelog compare links sit after the last version section.
    if ($0 ~ /^\[[^]]+\]:/) {
      if (capturing) exit
      next
    }
    id = section_id($0)
    if (id != "") {
      if (capturing) exit
      if (id == ver) {
        capturing = 1
        next
      }
    }
    if (capturing) print
  }
' ${file:+"$file"} | awk '
  NF { seen = 1 }
  seen { print }
'
