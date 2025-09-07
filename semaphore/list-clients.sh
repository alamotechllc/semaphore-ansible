#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Available Clients"
echo "=========================================="

if [[ ! -d "clients" ]]; then
    echo "No clients directory found"
    exit 1
fi

for client_dir in clients/*/; do
    if [[ -d "$client_dir" ]]; then
        client_name=$(basename "$client_dir")
        echo "Client: $client_name"
        
        # Check if targets.env exists
        if [[ -f "$client_dir/env/targets.env" ]]; then
            echo "  ✓ Configuration: targets.env found"
            # Extract HOST from targets.env
            if grep -q "^HOST=" "$client_dir/env/targets.env"; then
                host=$(grep "^HOST=" "$client_dir/env/targets.env" | cut -d'=' -f2)
                echo "  ✓ Target Host: $host"
            else
                echo "  ⚠ Target Host: Not configured"
            fi
        else
            echo "  ⚠ Configuration: targets.env missing"
        fi
        
        # Check for ansible directory
        if [[ -d "$client_dir/ansible" ]]; then
            echo "  ✓ Ansible: Configuration found"
            if [[ -d "$client_dir/ansible/playbooks" ]]; then
                playbook_count=$(find "$client_dir/ansible/playbooks" -name "*.yml" | wc -l)
                echo "  ✓ Playbooks: $playbook_count found"
            fi
        else
            echo "  - Ansible: Not configured"
        fi
        
        echo ""
    fi
done

echo "=========================================="
echo "Usage Examples:"
echo "  ./semaphore/deploy.sh alamo-tech standard"
echo "  ./semaphore/deploy.sh alamo-tech ubuntu-update"
echo "  ./semaphore/deploy.sh blazingswitch network"
echo "  ./semaphore/deploy.sh kiker azure"
echo "=========================================="
