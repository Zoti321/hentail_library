#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
SHA="${COMMIT_SHA:-${GITHUB_SHA}}"
REQUIRED_CHECKS=("analyze" "test-unit" "test-rust")

if [[ -n "${RELEASE_TAG:-}" ]]; then
  TAG="${RELEASE_TAG}"
elif [[ "${GITHUB_REF}" =~ ^refs/tags/ ]]; then
  TAG="${GITHUB_REF#refs/tags/}"
else
  echo "RELEASE_TAG must be set when not triggered by tag push"
  exit 1
fi

STABLE_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+$'
PRERELEASE_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+-.+$'

if [[ "${TAG}" =~ ${STABLE_PATTERN} ]]; then
  PRERELEASE="false"
elif [[ "${TAG}" =~ ${PRERELEASE_PATTERN} ]]; then
  PRERELEASE="true"
else
  echo "Tag must match vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-PRERELEASE (got: ${TAG})"
  exit 1
fi

if [[ "${DISPATCH_PRERELEASE:-}" == "true" ]]; then
  PRERELEASE="true"
fi

if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
  if ! gh api "repos/${REPO}/git/ref/tags/${TAG}" &>/dev/null; then
    echo "Tag '${TAG}' does not exist on remote"
    exit 1
  fi
fi

compare_status="$(gh api "repos/${REPO}/compare/${SHA}...main" --jq '.status // "unknown"')"
if [[ "${compare_status}" != "ahead" && "${compare_status}" != "identical" ]]; then
  echo "Commit ${SHA} is not on main branch (compare status: ${compare_status})"
  exit 1
fi
echo "Commit ${SHA} is on main (${compare_status})"

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

VERSION="${TAG#v}"
{
  echo "version=${VERSION}"
  echo "prerelease=${PRERELEASE}"
  echo "tag=${TAG}"
  echo "sha=${SHA}"
} >> "${GITHUB_OUTPUT}"
