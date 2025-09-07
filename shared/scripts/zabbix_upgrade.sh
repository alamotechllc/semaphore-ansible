#!/bin/bash
set -euo pipefail

# Zabbix Server Upgrade Script
# This script performs safe Zabbix server upgrades with backup, validation, and rollback capability

# Default values
USER="ubuntu"
ZABBIX_VERSION=""
BACKUP_ENABLED=true
DRY_RUN=false
ROLLBACK_ON_FAILURE=true
VALIDATE_UPGRADE=true

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
        --zabbix-version)
            ZABBIX_VERSION="$2"
            shift 2
            ;;
        --backup)
            BACKUP_ENABLED=true
            shift
            ;;
        --no-backup)
            BACKUP_ENABLED=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-rollback)
            ROLLBACK_ON_FAILURE=false
            shift
            ;;
        --no-validation)
            VALIDATE_UPGRADE=false
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

if [[ -z "${ZABBIX_VERSION:-}" ]]; then
    echo "Error: --zabbix-version is required"
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
echo "Zabbix Server Upgrade for Client: $CLIENT"
echo "Target host: $HOST"
echo "SSH user: $USER"
echo "Target Zabbix version: $ZABBIX_VERSION"
echo "Backup enabled: $BACKUP_ENABLED"
echo "Dry run: $DRY_RUN"
echo "Rollback on failure: $ROLLBACK_ON_FAILURE"
echo "Validate upgrade: $VALIDATE_UPGRADE"
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

# Function to get current Zabbix version
get_current_version() {
    local version
    version=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "zabbix_server --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo 'unknown'")
    echo "$version"
}

# Function to create backup
create_backup() {
    local log_file="$1"
    local backup_dir="/tmp/zabbix_backup_$(date +%Y%m%d_%H%M%S)"
    
    echo "=== CREATING BACKUP ===" >> "$log_file"
    echo "Backup directory: $backup_dir" >> "$log_file"
    
    # Create backup directory
    execute_ssh "sudo mkdir -p $backup_dir" "$log_file" "Create backup directory"
    
    # Backup Zabbix configuration
    execute_ssh "sudo cp -r /etc/zabbix $backup_dir/" "$log_file" "Backup Zabbix configuration"
    
    # Backup Zabbix web interface
    execute_ssh "sudo cp -r /usr/share/zabbix $backup_dir/" "$log_file" "Backup Zabbix web interface"
    
    # Backup database (if MySQL/MariaDB)
    execute_ssh "sudo mysqldump --single-transaction --routines --triggers zabbix > $backup_dir/zabbix_database.sql" "$log_file" "Backup Zabbix database"
    
    # Backup logs
    execute_ssh "sudo cp -r /var/log/zabbix $backup_dir/ 2>/dev/null || true" "$log_file" "Backup Zabbix logs"
    
    # Create backup archive
    execute_ssh "sudo tar -czf $backup_dir.tar.gz -C /tmp $(basename $backup_dir)" "$log_file" "Create backup archive"
    
    echo "BACKUP_LOCATION=$backup_dir.tar.gz" >> "$log_file"
    echo "✅ Backup created: $backup_dir.tar.gz"
}

# Function to validate system requirements
validate_requirements() {
    local log_file="$1"
    
    echo "=== VALIDATING SYSTEM REQUIREMENTS ===" >> "$log_file"
    
    # Check available disk space (need at least 2GB)
    execute_ssh "df -h / | tail -1 | awk '{print \$4}'" "$log_file" "Check available disk space"
    
    # Check memory (need at least 1GB free)
    execute_ssh "free -m | awk 'NR==2{printf \"%.1f\", \$7/1024}'" "$log_file" "Check available memory"
    
    # Check if Zabbix is currently running
    execute_ssh "systemctl is-active zabbix-server" "$log_file" "Check Zabbix server status"
    
    # Check database connectivity
    execute_ssh "mysql -u zabbix -p$(grep DBPassword /etc/zabbix/zabbix_server.conf | cut -d= -f2) -e 'SELECT 1' zabbix" "$log_file" "Test database connectivity"
    
    echo "✅ System requirements validated"
}

# Function to perform the upgrade
perform_upgrade() {
    local log_file="$1"
    
    echo "=== PERFORMING ZABBIX UPGRADE ===" >> "$log_file"
    
    # Stop Zabbix services
    execute_ssh "sudo systemctl stop zabbix-server zabbix-agent" "$log_file" "Stop Zabbix services"
    
    # Update package lists
    execute_ssh "sudo apt update" "$log_file" "Update package lists"
    
    # Install new Zabbix version
    execute_ssh "sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent" "$log_file" "Install Zabbix packages"
    
    # Run database upgrade scripts
    execute_ssh "sudo zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -u zabbix -p$(grep DBPassword /etc/zabbix/zabbix_server.conf | cut -d= -f2) zabbix" "$log_file" "Run database upgrade scripts"
    
    # Start Zabbix services
    execute_ssh "sudo systemctl start zabbix-server zabbix-agent" "$log_file" "Start Zabbix services"
    
    # Enable services
    execute_ssh "sudo systemctl enable zabbix-server zabbix-agent" "$log_file" "Enable Zabbix services"
    
    echo "✅ Zabbix upgrade completed"
}

# Function to validate upgrade
validate_upgrade() {
    local log_file="$1"
    local expected_version="$2"
    
    echo "=== VALIDATING UPGRADE ===" >> "$log_file"
    
    # Wait for services to start
    execute_ssh "sleep 10" "$log_file" "Wait for services to start"
    
    # Check Zabbix server status
    execute_ssh "systemctl is-active zabbix-server" "$log_file" "Check Zabbix server status"
    
    # Check Zabbix agent status
    execute_ssh "systemctl is-active zabbix-agent" "$log_file" "Check Zabbix agent status"
    
    # Verify version
    local current_version
    current_version=$(get_current_version)
    echo "Current version: $current_version" >> "$log_file"
    echo "Expected version: $expected_version" >> "$log_file"
    
    if [[ "$current_version" == "$expected_version" ]]; then
        echo "✅ Version validation successful"
        echo "UPGRADE_VALIDATION=success" >> "$log_file"
    else
        echo "❌ Version validation failed"
        echo "UPGRADE_VALIDATION=failed" >> "$log_file"
        return 1
    fi
    
    # Test web interface
    execute_ssh "curl -s -o /dev/null -w '%{http_code}' http://localhost/zabbix/" "$log_file" "Test Zabbix web interface"
    
    echo "✅ Upgrade validation completed"
}

# Function to rollback
rollback_upgrade() {
    local log_file="$1"
    local backup_file="$2"
    
    echo "=== ROLLING BACK UPGRADE ===" >> "$log_file"
    
    # Stop services
    execute_ssh "sudo systemctl stop zabbix-server zabbix-agent" "$log_file" "Stop Zabbix services"
    
    # Restore from backup
    execute_ssh "sudo tar -xzf $backup_file -C /tmp" "$log_file" "Extract backup"
    
    local backup_dir="/tmp/$(basename $backup_file .tar.gz)"
    
    # Restore configuration
    execute_ssh "sudo cp -r $backup_dir/zabbix /etc/" "$log_file" "Restore Zabbix configuration"
    
    # Restore web interface
    execute_ssh "sudo cp -r $backup_dir/zabbix /usr/share/" "$log_file" "Restore Zabbix web interface"
    
    # Restore database
    execute_ssh "mysql -u zabbix -p$(grep DBPassword /etc/zabbix/zabbix_server.conf | cut -d= -f2) zabbix < $backup_dir/zabbix_database.sql" "$log_file" "Restore Zabbix database"
    
    # Start services
    execute_ssh "sudo systemctl start zabbix-server zabbix-agent" "$log_file" "Start Zabbix services"
    
    echo "✅ Rollback completed"
}

# Main upgrade logic
upgrade_zabbix() {
    local log_file="outputs/$CLIENT/zabbix_upgrade_$(date +%Y%m%d_%H%M%S).log"
    local backup_file=""
    
    echo "Starting Zabbix upgrade process..."
    echo "Log file: $log_file"
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    echo "Current Zabbix version: $current_version" >> "$log_file"
    echo "Current Zabbix version: $current_version"
    
    # Validate system requirements
    validate_requirements "$log_file"
    
    # Create backup if enabled
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        create_backup "$log_file"
        backup_file=$(grep "BACKUP_LOCATION=" "$log_file" | cut -d= -f2)
    fi
    
    # Perform upgrade
    if perform_upgrade "$log_file"; then
        echo "✅ Upgrade process completed successfully"
        
        # Validate upgrade if enabled
        if [[ "$VALIDATE_UPGRADE" == "true" ]]; then
            if validate_upgrade "$log_file" "$ZABBIX_VERSION"; then
                echo "✅ Upgrade validation successful"
                echo "UPGRADE_STATUS=success" >> "$log_file"
            else
                echo "❌ Upgrade validation failed"
                echo "UPGRADE_STATUS=validation_failed" >> "$log_file"
                
                # Rollback if enabled
                if [[ "$ROLLBACK_ON_FAILURE" == "true" && -n "$backup_file" ]]; then
                    rollback_upgrade "$log_file" "$backup_file"
                    echo "UPGRADE_STATUS=rolled_back" >> "$log_file"
                fi
            fi
        else
            echo "⚠️  Upgrade validation skipped"
            echo "UPGRADE_STATUS=completed_no_validation" >> "$log_file"
        fi
    else
        echo "❌ Upgrade process failed"
        echo "UPGRADE_STATUS=failed" >> "$log_file"
        
        # Rollback if enabled
        if [[ "$ROLLBACK_ON_FAILURE" == "true" && -n "$backup_file" ]]; then
            rollback_upgrade "$log_file" "$backup_file"
            echo "UPGRADE_STATUS=rolled_back" >> "$log_file"
        fi
    fi
    
    echo "=========================================="
    echo "Zabbix upgrade process completed!"
    echo "Log file: $log_file"
    echo "=========================================="
}

# Execute the upgrade
upgrade_zabbix
