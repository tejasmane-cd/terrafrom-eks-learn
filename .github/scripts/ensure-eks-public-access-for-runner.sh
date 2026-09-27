#!/usr/bin/env bash
set -euo pipefail

cluster_name="${1:?EKS cluster name required}"
region="${2:?AWS region required}"
cidrs_json="${TF_VAR_endpoint_public_access_cidrs:?TF_VAR_endpoint_public_access_cidrs must be set}"

cidrs_csv="$(echo "$cidrs_json" | jq -r 'join(",")')"

echo "Updating ${cluster_name} publicAccessCidrs to: ${cidrs_csv}"
aws eks update-cluster-config \
  --region "$region" \
  --name "$cluster_name" \
  --resources-vpc-config "endpointPublicAccess=true,publicAccessCidrs=${cidrs_csv}"

aws eks wait cluster-active --region "$region" --name "$cluster_name"
echo "EKS API endpoint is ready for this runner."
