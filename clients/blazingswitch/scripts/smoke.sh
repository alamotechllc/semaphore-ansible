#!/usr/bin/env bash
set -xeuo pipefail
echo "Repo root: $(pwd)"
git rev-parse HEAD
ls -la
# Check required env without echoing secrets
for v in AZURE_CLIENT_ID AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID AZURE_CLIENT_SECRET; do
  if [ -n "${!v:-}" ]; then echo "OK: $v"; else echo "MISSING: $v" && exit 12; fi
done
echo "Smoke OK"
