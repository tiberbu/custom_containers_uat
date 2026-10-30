#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -z "${GITHUB_BUILD_TOKEN:-}" ]]; then
  echo "GITHUB_BUILD_TOKEN must have read access to tiberbu/crm and tiberbu/openmeter_mediator" >&2
  exit 2
fi

python3 -B ci/validate_crm_uat_apps.py ci/apps-crm-uat.json

docker buildx build \
  --platform linux/amd64 \
  --file images/custom/Containerfile.buildkit \
  --tag crm-openmeter:local-test \
  --load \
  --build-arg FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg FRAPPE_BRANCH=version-15 \
  --secret type=file,id=apps_json,src=ci/apps-crm-uat.json \
  --secret type=env,id=github_token,src=GITHUB_BUILD_TOKEN \
  .
