#!/bin/bash
set -euo pipefail

# Check if CLIENT argument is provided
if [[ $# -eq 0 ]]; then
    echo "Error: CLIENT argument is required"
    echo "Usage: $0 <CLIENT> [DEPLOYMENT_TYPE]"
    echo "Available deployment types: standard, network, azure"
    exit 1
fi

CLIENT="$1"
DEPLOYMENT_TYPE="${2:-standard}"
CLIENT_DIR="clients/$CLIENT"
SSH_KEY="$SEMAPHORE_SECRET_DIR/ssh_key"

# Validate client directory exists
if [[ ! -d "$CLIENT_DIR" ]]; then
    echo "Error: Client directory $CLIENT_DIR does not exist"
    echo "Available clients:"
    ls -1 clients/ 2>/dev/null || echo "No clients found"
    exit 1
fi

# Validate SSH key exists
if [[ ! -f "$SSH_KEY" ]]; then
    echo "Error: SSH key $SSH_KEY does not exist"
    exit 1
fi

# Validate deployment type
case "$DEPLOYMENT_TYPE" in
    "standard"|"network"|"azure")
        ;;
    *)
        echo "Error: Invalid deployment type '$DEPLOYMENT_TYPE'"
        echo "Available types: standard, network, azure"
        exit 1
        ;;
esac

echo "=========================================="
echo "Starting deployment for client: $CLIENT"
echo "Deployment type: $DEPLOYMENT_TYPE"
echo "Client directory: $CLIENT_DIR"
echo "SSH key: $SSH_KEY"
echo "=========================================="

# Call the shared deployment script
./shared/scripts/deploy_zabbix.sh \
    --client "$CLIENT" \
    --client-dir "$CLIENT_DIR" \
    --ssh-key "$SSH_KEY" \
    --deployment-type "$DEPLOYMENT_TYPE"
