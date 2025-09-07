#!/usr/bin/env bash
set -euo pipefail

# Safe env check (doesn't echo secrets)
for v in AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID AZURE_SUBSCRIPTION_ID; do
  [ -n "${!v:-}" ] || { echo "Missing $v"; exit 1; }
done

# Ensure Ansible
if ! command -v ansible-playbook >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -m venv .venv && . .venv/bin/activate
    pip install --upgrade pip "ansible>=9" ansible-lint
  else
    echo "python3 not found on runner" >&2; exit 1
  fi
fi

ansible-galaxy collection install -r requirements.yml || true

INV="inventories/dev/hosts.ini"
VARS="inventories/dev/group_vars/all.yml"

# Auto-detect playbook location
if   [ -f playbook/site.yml   ]; then PLAYBOOK="playbook/site.yml"
elif [ -f playbooks/site.yml  ]; then PLAYBOOK="playbooks/site.yml"
elif [ -f site.yml            ]; then PLAYBOOK="site.yml"
else echo "No site.yml found" >&2; exit 2; fi

ansible-playbook -i "$INV" "$PLAYBOOK" --check --diff -e @"$VARS"
