#!/usr/bin/env bash
set -euo pipefail

base_cidrs="${1:?base CIDR JSON list required}"

runner_cidr="$(curl -sf https://checkip.amazonaws.com)/32"
merged="$(echo "$base_cidrs" | jq -c --arg cidr "$runner_cidr" 'if index($cidr) then . else . + [$cidr] end')"

echo "Appending GitHub Actions runner egress ${runner_cidr} to EKS public access CIDRs"
echo "TF_VAR_endpoint_public_access_cidrs=${merged}" >> "${GITHUB_ENV:?}"
