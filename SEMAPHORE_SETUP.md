# Semaphore Setup Guide

This guide walks you through setting up Semaphore to use the multi-client automation system with Ubuntu server updates.

## Prerequisites

- Semaphore instance running (local or cloud)
- Access to Semaphore admin interface
- SSH keys for target servers
- Target server access configured

## Step 1: Create Project

1. **Log into Semaphore**
   - Navigate to your Semaphore instance
   - Login with admin credentials

2. **Create New Project**
   - Click "New Project" or "+" button
   - **Project Name**: `Multi-Client Automation`
   - **Repository**: `https://github.com/alamotechllc/semaphore-ansible`
   - **Branch**: `main`
   - **Playbook**: `.semaphore/semaphore.yml`

## Step 2: Configure Secrets

For each client, you need to create a secret group with SSH keys:

### Alamo Tech Secrets
1. **Go to Project Settings** → **Secrets**
2. **Create New Secret**:
   - **Name**: `alamo-vars`
   - **Type**: File
   - **File Name**: `ssh_key`
   - **Content**: Upload your Alamo Tech server SSH private key

### Kiker Secrets
1. **Create New Secret**:
   - **Name**: `kiker-vars`
   - **Type**: File
   - **File Name**: `ssh_key`
   - **Content**: Upload your Kiker server SSH private key

### Blazingswitch Secrets
1. **Create New Secret**:
   - **Name**: `blazingswitch-vars`
   - **Type**: File
   - **File Name**: `ssh_key`
   - **Content**: Upload your Blazingswitch server SSH private key

### Branchsix Secrets
1. **Create New Secret**:
   - **Name**: `branchsix-vars`
   - **Type**: File
   - **File Name**: `ssh_key`
   - **Content**: Upload your Branchsix server SSH private key

### Clearpick Secrets
1. **Create New Secret**:
   - **Name**: `clearpick-vars`
   - **Type**: File
   - **File Name**: `ssh_key`
   - **Content**: Upload your Clearpick server SSH private key

## Step 3: Configure Environment Variables

1. **Go to Project Settings** → **Environment Variables**
2. **Add Variables**:
   - `CLIENT`: `alamo-tech` (or the client you want to deploy to)
   - `ENVIRONMENT`: `production`

## Step 4: Update Client Configurations

Before running deployments, update the target server information:

### Alamo Tech Configuration
Edit `clients/alamo-tech/env/targets.env`:
```bash
# Update with actual server details
HOST=your-actual-alamo-tech-server-ip
USER=ubuntu
ENVIRONMENT=production
PROJECT=alamo-tech
REGION=us-central-1

# Ubuntu Update Configuration
UBUNTU_UPDATE_TYPE=standard
AUTO_REBOOT=false
DRY_RUN=false
```

### Other Clients
Update similar files for other clients:
- `clients/kiker/env/targets.env`
- `clients/blazingswitch/env/targets.env`
- `clients/branchsix/env/targets.env`
- `clients/clearpick/env/targets.env`

## Step 5: Test Deployment

### Test Alamo Tech Ubuntu Update
1. **Set Environment Variable**:
   - In Semaphore, set `CLIENT=alamo-tech`
   - Or use Survey Variable in pipeline

2. **Run Pipeline**:
   - The pipeline will automatically use the `alamo-vars` secret group
   - Execute Ubuntu update deployment

3. **Check Results**:
   - View pipeline logs in Semaphore
   - Check `outputs/alamo-tech/` directory for detailed logs

## Step 6: Configure Survey Variables (Optional)

For easier client selection:

1. **Go to Project Settings** → **Survey Variables**
2. **Add Survey Variable**:
   - **Name**: `CLIENT`
   - **Type**: Select
   - **Options**:
     - `alamo-tech`
     - `kiker`
     - `blazingswitch`
     - `branchsix`
     - `clearpick`

## Deployment Types Available

### Standard Deployment
- **Purpose**: Basic connectivity and health checks
- **Command**: `./semaphore/deploy.sh $CLIENT standard`

### Ubuntu Update Deployment
- **Purpose**: Ubuntu server system updates
- **Command**: `./semaphore/deploy.sh $CLIENT ubuntu-update`
- **Features**: Comprehensive logging, reboot detection, multiple update types

### Network Deployment
- **Purpose**: Network device automation (Blazingswitch)
- **Command**: `./semaphore/deploy.sh $CLIENT network`

### Azure Deployment
- **Purpose**: Azure infrastructure (Kiker)
- **Command**: `./semaphore/deploy.sh $CLIENT azure`

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Verify SSH key is correctly uploaded to secret group
   - Check that target host is accessible
   - Ensure SSH key has proper permissions (600)

2. **Client Directory Not Found**:
   - Verify client directory exists in repository
   - Check that `env/targets.env` file is present

3. **Target Host Not Found**:
   - Update `targets.env` file with correct host information
   - Verify host is reachable from Semaphore agents

4. **Permission Denied**:
   - Ensure SSH key permissions are correct
   - Verify user has sudo access on target server

### Debug Commands

```bash
# Test SSH connection manually
ssh -i /path/to/ssh_key -o StrictHostKeyChecking=no ubuntu@your-server-ip "hostname && uptime"

# Check client configuration
cat clients/alamo-tech/env/targets.env

# List available clients
./semaphore/list-clients.sh
```

## Security Best Practices

1. **SSH Key Management**:
   - Use dedicated SSH keys for each client
   - Rotate keys regularly
   - Store keys securely in Semaphore secrets

2. **Access Control**:
   - Limit Semaphore user access to necessary projects
   - Use environment-specific configurations
   - Monitor deployment logs regularly

3. **Network Security**:
   - Ensure target servers are properly secured
   - Use VPN or private networks when possible
   - Implement firewall rules for SSH access

## Monitoring and Maintenance

1. **Regular Updates**:
   - Schedule regular Ubuntu updates via Semaphore
   - Monitor update logs for any issues
   - Test updates in staging environment first

2. **Log Management**:
   - Review deployment logs regularly
   - Archive old logs periodically
   - Set up alerts for failed deployments

3. **Backup and Recovery**:
   - Backup client configurations
   - Test recovery procedures
   - Document rollback procedures

---

**Next Steps**: After completing this setup, you can run Ubuntu updates for Alamo Tech using Semaphore with the `ubuntu-update` deployment type.
