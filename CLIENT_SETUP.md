# Client Setup Instructions

This document provides step-by-step instructions for setting up new clients in the multi-client automation system.

## Overview

The automation system supports multiple clients with isolated environments, secrets, and deployment targets. Each client has its own directory structure and configuration files.

## Directory Structure

```
clients/
├── <client-name>/
│   ├── env/
│   │   └── targets.env          # Client configuration
│   ├── ansible/                 # Optional: Ansible automation
│   │   ├── inventories/
│   │   ├── playbooks/
│   │   └── group_vars/
│   └── README.md               # Optional: Client documentation
shared/
└── scripts/
    └── deploy_zabbix.sh        # Unified deployment script
semaphore/
├── deploy.sh                   # Main deployment script
└── list-clients.sh            # Client listing utility
.semaphore/
└── semaphore.yml              # Semaphore configuration
outputs/                       # Deployment logs and results
```

## Adding a New Client

### 1. Create Client Directory Structure

```bash
# Create the client directory and environment folder
mkdir -p clients/<client-name>/env

# Example for a new client called "acme-corp"
mkdir -p clients/acme-corp/env
```

### 2. List Available Clients

```bash
# View all configured clients
./semaphore/list-clients.sh
```

### 3. Create Target Environment File

Create a `targets.env` file in the client's environment directory:

```bash
# Create the targets.env file
touch clients/<client-name>/env/targets.env
```

**Example `targets.env` content:**
```bash
# Target server configuration
HOST=192.168.1.100
# Optional: Override default SSH user (defaults to ubuntu)
# USER=admin
# Optional: Additional environment variables
# ENVIRONMENT=production
# REGION=us-east-1
```

### 4. Configure Semaphore Secrets

In your Semaphore project:

1. **Create a new Variable Group:**
   - Go to your Semaphore project settings
   - Navigate to "Secrets" section
   - Click "Create New Secret"
   - Name it `<client-name>-vars` (e.g., `acme-corp-vars`)

2. **Add SSH Key:**
   - In the secret configuration, add a file named `ssh_key`
   - Upload or paste your private SSH key content
   - Ensure the key has proper permissions (600) and is in OpenSSH format

3. **Update Semaphore Configuration:**
   - Edit `.semaphore/semaphore.yml`
   - Add the new client's secret to the `secrets` section:

```yaml
secrets:
  - name: branchsix-vars
    files:
      - path: ssh_key
        content: encrypted
  - name: kiker-vars
    files:
      - path: ssh_key
        content: encrypted
  - name: clearpick-vars
    files:
      - path: ssh_key
        content: encrypted
  - name: acme-corp-vars  # Add your new client here
    files:
      - path: ssh_key
        content: encrypted
```

### 5. Test the Setup

#### Local Testing

You can test the deployment script locally:

```bash
# Set environment variables
export SEMAPHORE_SECRET_DIR=/path/to/your/secrets
export CLIENT=acme-corp

# Run the deployment script with different deployment types
./semaphore/deploy.sh acme-corp standard    # Standard deployment
./semaphore/deploy.sh acme-corp network     # Network automation
./semaphore/deploy.sh acme-corp azure       # Azure deployment
```

#### Semaphore Testing

1. **Trigger a deployment:**
   - Go to your Semaphore project
   - Start a new pipeline
   - Set the `CLIENT` environment variable to your new client name
   - The pipeline will automatically use the corresponding secret group

2. **Monitor the deployment:**
   - Check the pipeline logs for successful SSH connection
   - Verify that `hostname` and `uptime` commands execute successfully

## Client Configuration Examples

### Example 1: Basic Setup
```bash
# clients/acme-corp/env/targets.env
HOST=10.0.1.50
```

### Example 2: Custom SSH User
```bash
# clients/acme-corp/env/targets.env
HOST=10.0.1.50
USER=admin
```

### Example 3: Multiple Environment Variables
```bash
# clients/acme-corp/env/targets.env
HOST=10.0.1.50
USER=admin
ENVIRONMENT=production
REGION=us-east-1
APPLICATION=zabbix
```

## Security Best Practices

### SSH Key Management

1. **Generate dedicated SSH keys for each client:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/<client-name>-key -C "automation@<client-name>"
   ```

2. **Restrict key permissions:**
   ```bash
   chmod 600 ~/.ssh/<client-name>-key
   ```

3. **Add public key to target server:**
   ```bash
   ssh-copy-id -i ~/.ssh/<client-name>-key.pub <user>@<host>
   ```

### Environment File Security

- Never commit `targets.env` files to version control
- Use `.gitignore` to exclude sensitive configuration files
- Consider using encrypted configuration files for production environments

## Troubleshooting

### Common Issues

1. **SSH Connection Failed:**
   - Verify SSH key is correctly uploaded to Semaphore secrets
   - Check that the target host is accessible from Semaphore agents
   - Ensure SSH key has proper permissions (600)

2. **Client Directory Not Found:**
   - Verify the client directory exists: `clients/<client-name>/`
   - Check that the `env/` subdirectory is present

3. **Target Host Not Found:**
   - Verify `targets.env` file exists and contains `HOST` variable
   - Check that the file is in the correct location: `clients/<client-name>/env/targets.env`

4. **Permission Denied:**
   - Ensure deployment scripts are executable: `chmod +x semaphore/deploy.sh`
   - Verify SSH key permissions and format

### Debug Commands

```bash
# Test SSH connection manually
ssh -i /path/to/ssh_key -o StrictHostKeyChecking=no <user>@<host> "hostname && uptime"

# Check file permissions
ls -la clients/<client-name>/env/targets.env
ls -la semaphore/deploy.sh
ls -la shared/scripts/deploy_zabbix.sh

# Validate environment file
cat clients/<client-name>/env/targets.env
```

## Maintenance

### Updating Client Configuration

1. **Modify target environment:**
   - Edit `clients/<client-name>/env/targets.env`
   - Update host, user, or other environment variables as needed

2. **Update SSH keys:**
   - Generate new SSH key if needed
   - Update the key in Semaphore secrets
   - Deploy new public key to target servers

### Removing a Client

1. **Remove client directory:**
   ```bash
   rm -rf clients/<client-name>/
   ```

2. **Remove Semaphore secret:**
   - Delete the corresponding variable group in Semaphore
   - Remove the secret reference from `.semaphore/semaphore.yml`

3. **Clean up SSH keys:**
   - Remove the SSH key from target servers
   - Delete local SSH key files

## Support

For issues or questions regarding client setup:

1. Check the troubleshooting section above
2. Review Semaphore pipeline logs for detailed error messages
3. Verify all configuration files and permissions
4. Test SSH connectivity manually before running automated deployments
