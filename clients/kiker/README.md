# Kiker CPA Client Configuration

This directory contains all Kiker CPA-specific configuration and automation files.

## Directory Structure

```
clients/kiker/
├── env/
│   └── targets.env          # Target server configuration
├── ansible/
│   ├── inventories/
│   │   └── azure_kiker_cpa.yml  # Azure inventory configuration
│   └── playbooks/
│       ├── azure_vm_provision.yml      # VM provisioning playbook
│       ├── azure_windows_vm_provision.yml  # Windows VM provisioning
│       └── azure_test_connection.yml   # Connection testing
└── README.md               # This file
```

## Configuration

### Environment Variables

The `env/targets.env` file contains:
- `HOST`: Target server IP or hostname
- `USER`: SSH user (defaults to azureuser)
- `ENVIRONMENT`: Environment type (production)
- `PROJECT`: Project name (kiker-cpa)
- `REGION`: Azure region (central-us)
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_RESOURCE_GROUP`: Azure resource group name

### Azure Configuration

- **Resource Group**: `kiker-cpa-rg`
- **Location**: Central US
- **VM Size**: Standard_B2s
- **Admin User**: azureuser
- **VM Count**: 2

## Deployment

To deploy to Kiker CPA:

1. **Set the client environment variable:**
   ```bash
   export CLIENT=kiker
   ```

2. **Run the deployment:**
   ```bash
   ./semaphore/deploy.sh kiker
   ```

3. **Or trigger via Semaphore:**
   - Set `CLIENT=kiker` in the pipeline
   - The system will automatically use the `kiker-vars` secret group

## Ansible Playbooks

### azure_vm_provision.yml
- Provisions Azure VMs for Kiker CPA
- Creates resource group, virtual network, and security groups
- Deploys 2 Ubuntu 18.04 LTS VMs

### azure_windows_vm_provision.yml
- Provisions Windows VMs if needed
- Similar infrastructure setup with Windows-specific configurations

### azure_test_connection.yml
- Tests connectivity to Azure resources
- Validates authentication and resource access

## Security

- SSH keys are managed through Semaphore secrets (`kiker-vars`)
- All sensitive configuration is stored in environment files
- Azure authentication uses CLI-based authentication

## Maintenance

- Update `targets.env` for configuration changes
- Modify playbooks in `ansible/playbooks/` for infrastructure changes
- Update inventory in `ansible/inventories/` for resource changes
