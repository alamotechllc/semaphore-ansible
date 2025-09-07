#!/usr/bin/env bash
set -xeuo pipefail
: "${AZURE_CLIENT_ID:?}"; : "${AZURE_CLIENT_SECRET:?}"; : "${AZURE_TENANT_ID:?}"; : "${AZURE_SUBSCRIPTION_ID:?}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  python3 -m venv .venv && . .venv/bin/activate
  pip install --upgrade pip \
    "ansible>=9" ansible-lint jmespath pyyaml \
    "azure-identity>=1.15.0" "azure-mgmt-resource>=23.0.0" "azure-mgmt-network>=25.0.0"
fi

ansible-galaxy collection install -r requirements.yml || true

ansible-playbook -i inventories/dev/hosts.ini playbook/site.yml \
  -e @inventories/dev/group_vars/all.yml
