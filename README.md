# Multi-Client Automation with Semaphore

A streamlined, multi-client automation system built for Semaphore CI/CD that supports different deployment types and client isolation.

## 🚀 Quick Start

### 1. List Available Clients
```bash
./semaphore/list-clients.sh
```

### 2. Deploy to a Client
```bash
# Standard deployment
./semaphore/deploy.sh kiker standard

# Network automation deployment
./semaphore/deploy.sh blazingswitch network

# Azure deployment
./semaphore/deploy.sh kiker azure
```

### 3. Check Results
```bash
# View deployment logs
ls -la outputs/<client-name>/
cat outputs/<client-name>/deployment.log
```

## 📁 Project Structure

```
semaphore-ansible/
├── clients/                    # Client-specific configurations
│   ├── kiker/                 # Kiker CPA client
│   │   ├── env/
│   │   │   └── targets.env    # Target configuration
│   │   ├── ansible/           # Azure automation
│   │   └── README.md          # Client documentation
│   ├── blazingswitch/         # Blazingswitch client
│   │   ├── env/
│   │   │   └── targets.env    # Network configuration
│   │   ├── ansible/           # Network automation
│   │   └── README.md          # Client documentation
│   ├── branchsix/             # Branchsix client
│   │   └── env/
│   │       └── targets.env    # Basic configuration
│   └── clearpick/             # Clearpick client
│       └── env/
│           └── targets.env    # Basic configuration
├── shared/
│   └── scripts/
│       └── deploy_zabbix.sh   # Unified deployment script
├── semaphore/
│   ├── deploy.sh              # Main deployment script
│   └── list-clients.sh        # Client listing utility
├── .semaphore/
│   └── semaphore.yml          # Semaphore configuration
├── outputs/                   # Deployment logs and results
└── README.md                  # This file
```

## 🎯 Deployment Types

### Standard Deployment
- **Purpose**: Basic server connectivity and health checks
- **Commands**: `hostname && uptime`
- **Output**: Simple connectivity verification
- **Use Case**: Basic monitoring and health checks

### Network Deployment
- **Purpose**: Network device automation and configuration
- **Commands**: Ansible playbooks for network devices
- **Output**: Network configuration and discovery results
- **Use Case**: Arista, Cisco, Extreme network devices

### Azure Deployment
- **Purpose**: Azure infrastructure provisioning and management
- **Commands**: Ansible playbooks for Azure resources
- **Output**: VM provisioning and infrastructure logs
- **Use Case**: Azure VM provisioning and management

## 🔧 Configuration

### Client Configuration
Each client has a `targets.env` file with:
```bash
# Basic configuration
HOST=your-server-ip-or-hostname
USER=ubuntu
ENVIRONMENT=production
PROJECT=client-name
REGION=us-east-1

# Deployment type
APPLICATION=zabbix
DEPLOYMENT_TYPE=standard
```

### Semaphore Secrets
Each client requires a secret group named `<client>-vars` containing:
- `ssh_key`: Private SSH key for target server access

## 🚀 Usage Examples

### List All Clients
```bash
./semaphore/list-clients.sh
```

### Deploy to Different Clients
```bash
# Standard deployment to Kiker
./semaphore/deploy.sh kiker standard

# Network automation for Blazingswitch
./semaphore/deploy.sh blazingswitch network

# Azure deployment for Kiker
./semaphore/deploy.sh kiker azure
```

### Check Deployment Results
```bash
# View all outputs
ls -la outputs/

# Check specific client logs
cat outputs/kiker/deployment.log
cat outputs/blazingswitch/network_deployment.log
```

## 🔒 Security

- **SSH Keys**: Managed through Semaphore secrets
- **Client Isolation**: Each client has separate configuration and secrets
- **Environment Variables**: Sensitive data stored in encrypted secrets
- **Output Logging**: All deployment logs saved to `outputs/` directory

## 📊 Monitoring

### Deployment Logs
All deployments create logs in the `outputs/` directory:
```
outputs/
├── kiker/
│   ├── deployment.log
│   └── azure_deployment.log
├── blazingswitch/
│   ├── deployment.log
│   └── network_deployment.log
└── branchsix/
    └── deployment.log
```

### Semaphore Integration
- **Pipeline**: Single pipeline handles all clients
- **Variables**: `CLIENT` environment variable selects target
- **Secrets**: Automatic secret group selection based on client
- **Promotions**: Production deployment promotion available

## 🛠️ Development

### Adding New Clients
1. Create client directory: `mkdir -p clients/new-client/env`
2. Add configuration: `clients/new-client/env/targets.env`
3. Configure Semaphore secret: `new-client-vars`
4. Test deployment: `./semaphore/deploy.sh new-client standard`

### Adding New Deployment Types
1. Update `shared/scripts/deploy_zabbix.sh`
2. Add new case in deployment type switch
3. Update `semaphore/deploy.sh` validation
4. Test with existing clients

## 📚 Documentation

- **Client Setup**: See `CLIENT_SETUP.md` for detailed setup instructions
- **Client Documentation**: Each client has its own `README.md`
- **Semaphore Configuration**: See `.semaphore/semaphore.yml`

## 🤝 Support

- **Issues**: Check deployment logs in `outputs/` directory
- **Client Configuration**: Verify `targets.env` files
- **Semaphore Secrets**: Ensure SSH keys are properly configured
- **Network Connectivity**: Test SSH access to target servers

---

**Multi-Client Automation** - Streamlined deployment for multiple clients! 🚀
