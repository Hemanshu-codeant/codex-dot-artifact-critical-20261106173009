#!/usr/bin/env bash
set -euo pipefail

jq -n \
  --arg marker "TRUSTED_CONTROL" \
  --arg before "${TRUSTED_SHA_BEFORE:-}" \
  --arg after "${TRUSTED_SHA_AFTER:-}" \
  '{
    marker: $marker,
    script_sha_before: $before,
    script_sha_after: $after,
    privileged_write_confirmed: false,
    state_restored: true
  }' > proof-result.json

cat proof-result.json

