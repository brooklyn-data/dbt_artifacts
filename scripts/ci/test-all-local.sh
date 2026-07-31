#!/usr/bin/env bash
# Run integration tests against every local-runnable data warehouse.
# Convenience wrapper around test.sh — same script CI calls for Tier 1.
#
# Usage: scripts/ci/test-all-local.sh [<dbt_version>]
#
# Continues past a single warehouse's failure so you see the full picture
# rather than stopping at the first red. Aggregates exit codes at the end.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "${repo_root}"

dbt_version="${1:-}"

warehouses=(postgres trino sqlserver)
failed=()

for warehouse in "${warehouses[@]}"; do
  banner "=== ${warehouse} ==="
  if "${repo_root}/scripts/ci/test.sh" "${warehouse}" "${dbt_version}"; then
    log "${warehouse}: PASS"
  else
    log "${warehouse}: FAIL"
    failed+=("${warehouse}")
  fi
done

banner "Summary"
for warehouse in "${warehouses[@]}"; do
  status="PASS"
  for f in "${failed[@]:-}"; do
    [[ "${f}" == "${warehouse}" ]] && status="FAIL"
  done
  printf '  %-12s %s\n' "${warehouse}" "${status}"
done

if (( ${#failed[@]} > 0 )); then
  die "${#failed[@]} warehouse(s) failed: ${failed[*]}"
fi

log "all local warehouses passed"
