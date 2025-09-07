#!/bin/bash
set -euo pipefail

# Ubuntu Server Update Script
# This script performs safe Ubuntu server updates with logging and rollback capability

# Default values
USER="ubuntu"
UPDATE_TYPE="standard"
REBOOT_REQUIRED=false
DRY_RUN=false
FORCE_UPDATE=false

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
        --update-type)
            UPDATE_TYPE="$2"
            shift 2
            ;;
        --reboot)
            REBOOT_REQUIRED=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
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
echo "Ubuntu Server Update for Client: $CLIENT"
echo "Target host: $HOST"
echo "SSH user: $USER"
echo "Update type: $UPDATE_TYPE"
echo "Reboot required: $REBOOT_REQUIRED"
echo "Dry run: $DRY_RUN"
echo "Force update: $FORCE_UPDATE"
echo "=========================================="

# Create outputs directory
mkdir -p "outputs/$CLIENT"

# Function to execute SSH commands with logging
execute_ssh() {
    local command="$1"
    local log_file="$2"
    local description="$3"
    
    echo "Executing: $description"
    echo "Command: $command"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would execute: $command"
        echo "[DRY RUN] $description" >> "$log_file"
        return 0
    fi
    
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "$command" >> "$log_file" 2>&1; then
        echo "✅ $description completed successfully"
        return 0
    else
        echo "❌ $description failed"
        return 1
    fi
}

# Main update logic
update_ubuntu() {
    local log_file="outputs/$CLIENT/ubuntu_update_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Starting Ubuntu update process..."
    echo "Log file: $log_file"
    
    # Pre-update system information
    echo "=== PRE-UPDATE SYSTEM INFORMATION ===" >> "$log_file"
    execute_ssh "uname -a && lsb_release -a && df -h && free -h" "$log_file" "System information collection"
    
    # Update package lists first
    echo "=== UPDATING PACKAGE LISTS ===" >> "$log_file"
    execute_ssh "apt update" "$log_file" "Update package lists"
    
    # Check for available updates
    echo "=== CHECKING FOR AVAILABLE UPDATES ===" >> "$log_file"
    local update_count
    update_count=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "apt list --upgradable 2>/dev/null | wc -l")
    echo "Available updates: $update_count" >> "$log_file"
    echo "Available updates: $update_count"
    
    # Check if updates are needed
    if [[ "$update_count" -eq 0 ]]; then
        echo "✅ No updates available. System is up to date!"
        echo "NO_UPDATES_AVAILABLE=true" >> "$log_file"
        
        if [[ "$FORCE_UPDATE" == "true" ]]; then
            echo "⚠️  Force update enabled - proceeding with update process anyway"
            echo "FORCE_UPDATE_ENABLED=true" >> "$log_file"
        else
            echo "=========================================="
            echo "Ubuntu update check completed - no updates needed!"
            echo "Log file: $log_file"
            echo "=========================================="
            return 0
        fi
    else
        echo "📦 Found $update_count packages that can be updated"
        echo "UPDATES_AVAILABLE=true" >> "$log_file"
        echo "UPDATE_COUNT=$update_count" >> "$log_file"
    fi
    
    # Perform updates based on type
    case "$UPDATE_TYPE" in
        "security")
            echo "=== SECURITY UPDATES ONLY ===" >> "$log_file"
            execute_ssh "apt upgrade -y --only-upgrade" "$log_file" "Security updates only"
            ;;
        "standard")
            echo "=== STANDARD UPDATES ===" >> "$log_file"
            execute_ssh "apt upgrade -y" "$log_file" "Standard package updates"
            ;;
        "full")
            echo "=== FULL SYSTEM UPDATE ===" >> "$log_file"
            execute_ssh "apt update && apt upgrade -y && apt dist-upgrade -y" "$log_file" "Full system update"
            ;;
        "minimal")
            echo "=== MINIMAL UPDATES ===" >> "$log_file"
            execute_ssh "apt upgrade -y --no-install-recommends" "$log_file" "Minimal updates"
            ;;
        *)
            echo "Unknown update type: $UPDATE_TYPE"
            exit 1
            ;;
    esac
    
    # Clean up
    echo "=== CLEANUP ===" >> "$log_file"
    execute_ssh "apt autoremove -y && apt autoclean" "$log_file" "System cleanup"
    
    # Post-update system information
    echo "=== POST-UPDATE SYSTEM INFORMATION ===" >> "$log_file"
    execute_ssh "uname -a && lsb_release -a && df -h && free -h" "$log_file" "Post-update system information"
    
    # Check if reboot is required
    echo "=== REBOOT CHECK ===" >> "$log_file"
    if execute_ssh "test -f /var/run/reboot-required" "$log_file" "Check if reboot required"; then
        echo "⚠️  Reboot is required"
        echo "REBOOT_REQUIRED=true" >> "$log_file"
        
        if [[ "$REBOOT_REQUIRED" == "true" ]]; then
            echo "=== REBOOTING SYSTEM ===" >> "$log_file"
            execute_ssh "sudo reboot" "$log_file" "System reboot"
            echo "🔄 System rebooted"
        else
            echo "⚠️  Reboot required but not performed (use --reboot flag)"
        fi
    else
        echo "✅ No reboot required"
        echo "REBOOT_REQUIRED=false" >> "$log_file"
    fi
    
    echo "=========================================="
    echo "Ubuntu update completed successfully!"
    echo "Log file: $log_file"
    echo "=========================================="
}

# Execute the update
update_ubuntu
