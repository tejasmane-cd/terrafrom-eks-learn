#!/usr/bin/env bash
set -euo pipefail

cluster_name="${1:?EKS cluster name required}"
region="${2:?AWS region required}"
cidrs_json="${TF_VAR_endpoint_public_access_cidrs:?TF_VAR_endpoint_public_access_cidrs must be set}"

desired_sorted="$(echo "$cidrs_json" | jq -c 'sort')"
cidrs_csv="$(echo "$cidrs_json" | jq -r 'join(",")')"

wait_for_cluster_active() {
  aws eks wait cluster-active --region "$region" --name "$cluster_name"
}

wait_for_no_in_progress_updates() {
  local attempt=1
  local max_attempts=36

  while (( attempt <= max_attempts )); do
    local update_ids
    update_ids="$(aws eks list-updates \
      --region "$region" \
      --name "$cluster_name" \
      --query 'updateIds' \
      --output json)"

    local pending=0
    if [[ "$update_ids" != "[]" && "$update_ids" != "null" ]]; then
      while IFS= read -r update_id; do
        [[ -z "$update_id" ]] && continue
        local status
        status="$(aws eks describe-update \
          --region "$region" \
          --name "$cluster_name" \
          --update-id "$update_id" \
          --query 'update.status' \
          --output text)"
        if [[ "$status" == "InProgress" || "$status" == "Pending" ]]; then
          pending=1
          echo "EKS update ${update_id} is ${status}; waiting..."
          break
        fi
      done < <(echo "$update_ids" | jq -r '.[]')
    fi

    if (( pending == 0 )); then
      wait_for_cluster_active
      return 0
    fi

    sleep 15
    ((attempt++))
  done

  echo "Timed out waiting for in-progress EKS cluster updates to finish." >&2
  return 1
}

current_cidrs_json="$(aws eks describe-cluster \
  --region "$region" \
  --name "$cluster_name" \
  --query 'cluster.resourcesVpcConfig.publicAccessCidrs' \
  --output json)"
current_sorted="$(echo "$current_cidrs_json" | jq -c 'sort')"

if [[ "$current_sorted" == "$desired_sorted" ]]; then
  echo "EKS publicAccessCidrs already match desired values: ${cidrs_csv}"
  wait_for_no_in_progress_updates
  echo "EKS API endpoint is ready for this runner."
  exit 0
fi

echo "Updating ${cluster_name} publicAccessCidrs to: ${cidrs_csv}"

attempt=1
max_attempts=24
while (( attempt <= max_attempts )); do
  if update_out="$(aws eks update-cluster-config \
    --region "$region" \
    --name "$cluster_name" \
    --resources-vpc-config "endpointPublicAccess=true,publicAccessCidrs=${cidrs_csv}" 2>&1)"; then
    echo "$update_out"
    wait_for_no_in_progress_updates
    echo "EKS API endpoint is ready for this runner."
    exit 0
  fi

  if [[ "$update_out" == *ResourceInUseException* ]]; then
    echo "EKS endpoint access update already in progress (attempt ${attempt}/${max_attempts}); waiting..."
    wait_for_no_in_progress_updates || true

    current_sorted="$(aws eks describe-cluster \
      --region "$region" \
      --name "$cluster_name" \
      --query 'cluster.resourcesVpcConfig.publicAccessCidrs' \
      --output json | jq -c 'sort')"
    if [[ "$current_sorted" == "$desired_sorted" ]]; then
      echo "EKS publicAccessCidrs now match desired values after waiting."
      echo "EKS API endpoint is ready for this runner."
      exit 0
    fi

    sleep $((attempt * 5))
    ((attempt++))
    continue
  fi

  echo "$update_out" >&2
  exit 1
done

echo "Failed to update EKS publicAccessCidrs after ${max_attempts} attempts." >&2
exit 1
