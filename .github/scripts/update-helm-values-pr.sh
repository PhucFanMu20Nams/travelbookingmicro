#!/usr/bin/env bash
set -euo pipefail

required_vars=(SERVICE_NAME HELM_REPO HELM_REPO_PAT)
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required env var: ${var_name}" >&2
    exit 1
  fi
done

GHCR_ORG="${GHCR_ORG:-${GITHUB_REPOSITORY_OWNER:-}}"
if [[ -z "${GHCR_ORG}" ]]; then
  echo "Missing GHCR_ORG and GITHUB_REPOSITORY_OWNER is empty." >&2
  exit 1
fi

IMAGE_TAG="${IMAGE_TAG:-${GITHUB_SHA:-}}"
if [[ -z "${IMAGE_TAG}" ]]; then
  echo "Missing IMAGE_TAG and GITHUB_SHA is empty." >&2
  exit 1
fi

HELM_BASE_BRANCH="${HELM_BASE_BRANCH:-main}"
HELM_VALUES_PATH="${HELM_VALUES_PATH:-microservices-chart/values.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  YQ_BIN="/tmp/yq"
  curl -sSL "https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_linux_amd64" -o "${YQ_BIN}"
  chmod +x "${YQ_BIN}"
  export PATH="/tmp:${PATH}"
fi

repo_owner="${HELM_REPO%%/*}"
repo_name="${HELM_REPO##*/}"
short_sha="${IMAGE_TAG:0:7}"
branch_name="ci/${SERVICE_NAME}/${short_sha}"

workdir="$(mktemp -d)"
cleanup() {
  rm -rf "${workdir}"
}
trap cleanup EXIT

echo "Cloning ${HELM_REPO}..."
git clone "https://x-access-token:${HELM_REPO_PAT}@github.com/${HELM_REPO}.git" "${workdir}/helm-repo"
cd "${workdir}/helm-repo"

git checkout -b "${branch_name}" "origin/${HELM_BASE_BRANCH}"

if [[ ! -f "${HELM_VALUES_PATH}" ]]; then
  echo "Could not find values file: ${HELM_VALUES_PATH}" >&2
  exit 1
fi

yq eval ".services.${SERVICE_NAME}.image.repository = \"ghcr.io/${GHCR_ORG}/${SERVICE_NAME}\"" -i "${HELM_VALUES_PATH}"
yq eval ".services.${SERVICE_NAME}.image.tag = \"${IMAGE_TAG}\"" -i "${HELM_VALUES_PATH}"

if git diff --quiet -- "${HELM_VALUES_PATH}"; then
  echo "No changes detected in ${HELM_VALUES_PATH}; skipping push/PR."
  exit 0
fi

git config user.email "${GIT_AUTHOR_EMAIL:-github-actions[bot]@users.noreply.github.com}"
git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"

git add "${HELM_VALUES_PATH}"
git commit -m "Update ${SERVICE_NAME} image to ${IMAGE_TAG}"
git push -u origin "${branch_name}"

pr_title="chore(ci): update ${SERVICE_NAME} image to ${short_sha}"
pr_body="Automated update from ${GITHUB_REPOSITORY:-online-boutique}.\n\n- Service: ${SERVICE_NAME}\n- Image: ghcr.io/${GHCR_ORG}/${SERVICE_NAME}:${IMAGE_TAG}\n- Source commit: ${GITHUB_SHA:-unknown}"

api_url="https://api.github.com/repos/${HELM_REPO}/pulls"
auth_header="Authorization: Bearer ${HELM_REPO_PAT}"
accept_header="Accept: application/vnd.github+json"

existing_pr_count="$(
  curl -fsSL -H "${auth_header}" -H "${accept_header}" \
    "${api_url}?state=open&head=${repo_owner}:${branch_name}" \
  | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))'
)"

if [[ "${existing_pr_count}" -gt 0 ]]; then
  echo "Open PR already exists for branch ${branch_name}."
  exit 0
fi

payload="$(python3 - <<PY
import json
print(json.dumps({
  "title": "${pr_title}",
  "head": "${branch_name}",
  "base": "${HELM_BASE_BRANCH}",
  "body": """${pr_body}"""
}))
PY
)"

response="$(curl -sS -w "\n%{http_code}" -X POST \
  -H "${auth_header}" \
  -H "${accept_header}" \
  "${api_url}" \
  -d "${payload}")"

http_status="${response##*$'\n'}"
response_body="${response%$'\n'*}"

if [[ "${http_status}" != "201" ]]; then
  echo "Failed to create pull request (HTTP ${http_status})." >&2
  echo "${response_body}" >&2
  exit 1
fi

echo "Pull request created successfully for ${branch_name}."
