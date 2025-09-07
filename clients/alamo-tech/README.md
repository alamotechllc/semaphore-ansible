# Alamo Tech Client Configuration

## Overview
This directory contains all automation configurations and runbooks for Alamo Tech client deployments.

## Available Deployments

### 1. Ubuntu Server Updates
**Purpose**: Keep Ubuntu servers up to date with security patches and package updates

**Usage**:
```bash
# Via Semaphore
Deployment Type: ubuntu-update

# Manual execution
./shared/scripts/ubuntu_update.sh \
  --client "alamo-tech" \
  --client-dir "clients/alamo-tech" \
  --ssh-key "/path/to/ssh_key" \
  --host "100.106.25.78" \
  --user "root" \
  --update-type "standard"
```

**Features**:
- ✅ Intelligent update checking (only updates if needed)
- ✅ Multiple update types (standard, security, full, minimal)
- ✅ Comprehensive logging
- ✅ Force update option
- ✅ Dry run capability

### 2. Zabbix Server Upgrade
**Purpose**: Safely upgrade Zabbix monitoring server with backup and rollback capability

**Usage**:
```bash
# Via Semaphore
Deployment Type: zabbix-upgrade

# Manual execution
./shared/scripts/zabbix_upgrade.sh \
  --client "alamo-tech" \
  --client-dir "clients/alamo-tech" \
  --ssh-key "/path/to/ssh_key" \
  --host "100.106.25.78" \
  --user "root" \
  --zabbix-version "6.4" \
  --backup \
  --validate-upgrade
```

**Features**:
- ✅ Pre-upgrade system validation
- ✅ Automatic backup creation
- ✅ Safe upgrade process
- ✅ Post-upgrade validation
- ✅ Automatic rollback on failure
- ✅ Comprehensive logging

## Configuration Files

### `env/targets.env`
Main configuration file containing:
- Server connection details
- Deployment preferences
- Feature toggles
- Client-specific settings

### `ansible/playbooks/`
Ansible playbooks for orchestrated deployments:
- `ubuntu_update.yml` - Ubuntu server updates
- `zabbix_upgrade.yml` - Zabbix server upgrades

## Deployment Types

| Type | Description | Script | Playbook |
|------|-------------|--------|----------|
| `standard` | Basic connectivity test | `deploy_zabbix.sh` | N/A |
| `ubuntu-update` | Ubuntu package updates | `ubuntu_update.sh` | `ubuntu_update.yml` |
| `zabbix-upgrade` | Zabbix server upgrade | `zabbix_upgrade.sh` | `zabbix_upgrade.yml` |

## Semaphore Integration

### Required Secret Groups
- `alamo-vars`: Contains SSH key for server access

### Pipeline Configuration
- **Repository**: `https://github.com/alamotechllc/semaphore-ansible`
- **Branch**: `main`
- **Playbook**: `semaphore/deploy.sh`

### Usage Examples
```bash
# Ubuntu Update
./semaphore/deploy.sh alamo-tech ubuntu-update

# Zabbix Upgrade
./semaphore/deploy.sh alamo-tech zabbix-upgrade
```

## Logs and Outputs

All deployment logs are stored in:
- `outputs/alamo-tech/` - Local execution logs
- Semaphore build logs - CI/CD execution logs

## Safety Features

### Ubuntu Updates
- ✅ Update availability checking
- ✅ Dry run mode
- ✅ Comprehensive logging
- ✅ Rollback capability (manual)

### Zabbix Upgrades
- ✅ System requirement validation
- ✅ Automatic backup creation
- ✅ Version validation
- ✅ Automatic rollback on failure
- ✅ Service status verification

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key is correct
   - Check server accessibility
   - Confirm user permissions

2. **Update Script Skipped**
   - Check if updates are actually available
   - Use `--force` flag if needed
   - Verify script permissions

3. **Zabbix Upgrade Failed**
   - Check system requirements
   - Verify database connectivity
   - Review backup creation
   - Check service status

### Log Locations
- Ubuntu Updates: `outputs/alamo-tech/ubuntu_update_YYYYMMDD_HHMMSS.log`
- Zabbix Upgrades: `outputs/alamo-tech/zabbix_upgrade_YYYYMMDD_HHMMSS.log`

## Support

For issues or questions:
1. Check the logs in `outputs/alamo-tech/`
2. Review Semaphore build logs
3. Verify configuration in `env/targets.env`
4. Test connectivity manually

## Version History

- **v1.0**: Initial Ubuntu update automation
- **v1.1**: Added intelligent update checking
- **v2.0**: Added Zabbix upgrade automation with backup/rollback