#!/bin/bash
set -euo pipefail

# Default values
USER="ubuntu"
DEPLOYMENT_TYPE="standard"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --client)
            CLIENT="$2"
            shift 2
            ;;
        --client-dir)
            CLIENT_DIR="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_KEY="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --user)
            USER="$2"
            shift 2
            ;;
        --deployment-type)
            DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "${CLIENT:-}" ]]; then
    echo "Error: --client is required"
    exit 1
fi

if [[ -z "${CLIENT_DIR:-}" ]]; then
    echo "Error: --client-dir is required"
    exit 1
fi

if [[ -z "${SSH_KEY:-}" ]]; then
    echo "Error: --ssh-key is required"
    exit 1
fi

# Load host from targets.env if not provided
if [[ -z "${HOST:-}" ]]; then
    TARGETS_FILE="${CLIENT_DIR}/env/targets.env"
    if [[ -f "$TARGETS_FILE" ]]; then
        echo "Loading configuration from: $TARGETS_FILE"
        source "$TARGETS_FILE"
        if [[ -z "${HOST:-}" ]]; then
            echo "Error: HOST not found in $TARGETS_FILE"
            exit 1
        fi
    else
        echo "Error: --host is required and $TARGETS_FILE not found"
        exit 1
    fi
fi

echo "=========================================="
echo "Deploying to client: $CLIENT"
echo "Target host: $HOST"
echo "SSH user: $USER"
echo "Deployment type: $DEPLOYMENT_TYPE"
echo "=========================================="

# Create outputs directory
mkdir -p "outputs/$CLIENT"

# Execute deployment based on type
case "$DEPLOYMENT_TYPE" in
    "standard")
        echo "Running standard deployment..."
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "hostname && uptime" > "outputs/$CLIENT/deployment.log" 2>&1
        ;;
    "network")
        echo "Running network automation deployment..."
        if [[ -d "${CLIENT_DIR}/ansible" ]]; then
            cd "${CLIENT_DIR}/ansible"
            ansible-playbook -i inventories/production.yml playbooks/arista_discovery.yml --check > "../../outputs/$CLIENT/network_deployment.log" 2>&1
            cd - > /dev/null
        else
            echo "Warning: No ansible directory found for network deployment"
        fi
        ;;
    "azure")
        echo "Running Azure deployment..."
        if [[ -d "${CLIENT_DIR}/ansible" ]]; then
            cd "${CLIENT_DIR}/ansible"
            # Find the first available inventory file
            inventory_file=$(find inventories/ -name "*.yml" -o -name "*.yaml" | head -1)
            if [[ -n "$inventory_file" ]]; then
                ansible-playbook -i "$inventory_file" playbooks/azure_vm_provision.yml --check > "../../outputs/$CLIENT/azure_deployment.log" 2>&1
            else
                echo "Warning: No inventory file found for Azure deployment"
            fi
            cd - > /dev/null
        else
            echo "Warning: No ansible directory found for Azure deployment"
        fi
        ;;
    *)
        echo "Unknown deployment type: $DEPLOYMENT_TYPE"
        exit 1
        ;;
esac

echo "Deployment completed successfully!"
echo "Check outputs/$CLIENT/ directory for logs and results"
