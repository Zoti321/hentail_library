#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
SHA="${GITHUB_SHA}"
REQUIRED_CHECKS=("analyze" "test-unit")

if [[ ! "${GITHUB_REF}" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  echo "Tag must match vMAJOR.MINOR.PATCH (got: ${GITHUB_REF})"
  exit 1
fi

for check_name in "${REQUIRED_CHECKS[@]}"; do
  conclusion="$(gh api "repos/${REPO}/commits/${SHA}/check-runs" \
    --paginate \
    --jq "[.check_runs[] | select(.name == \"${check_name}\")] | sort_by(.started_at) | last | .conclusion // \"missing\"")"
  if [[ "${conclusion}" != "success" ]]; then
    echo "Required check '${check_name}' conclusion: '${conclusion}'"
    exit 1
  fi
  echo "Required check '${check_name}': success"
done

VERSION="${GITHUB_REF#refs/tags/v}"
echo "version=${VERSION}" >> "${GITHUB_OUTPUT}"
