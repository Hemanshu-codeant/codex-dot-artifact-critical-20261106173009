#!/usr/bin/env bash
set -euo pipefail

jq -n \
  --arg marker "SAFE_ARTIFACT_CONTROL" \
  '{marker: $marker}' > payload-control.json
