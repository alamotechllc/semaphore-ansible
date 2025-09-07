# Blazingswitch Client Configuration

This directory contains all Blazingswitch-specific configuration and automation files for network infrastructure management.

## Directory Structure

```
clients/blazingswitch/
├── env/
│   └── targets.env              # Target server configuration
├── ansible/
│   ├── ansible.cfg             # Ansible configuration
│   ├── inventories/
│   │   └── production.yml      # Network device inventory
│   ├── playbooks/
│   │   ├── arista_discovery.yml    # Network discovery
│   │   ├── bgp_cutover.yml         # BGP migration
│   │   └── rollback.yml            # Emergency rollback
│   └── group_vars/
│       └── all.yml             # Global variables
├── scripts/
│   ├── apply_dev.sh            # Development deployment
│   ├── plan_dev.sh             # Development planning
│   └── smoke.sh                # Smoke testing
├── roles/
│   └── azure_infra/            # Azure infrastructure role
├── site.yml                    # Main playbook
├── requirements.yml            # Ansible requirements
└── README.md                   # This file
```

## Configuration

### Environment Variables

The `env/targets.env` file contains:
- `HOST`: Target server IP or hostname
- `USER`: SSH user (defaults to admin)
- `ENVIRONMENT`: Environment type (production)
- `PROJECT`: Project name (blazingswitch)
- `REGION`: AWS region (us-east-1)

### Network Device Credentials
- `ARISTA_USERNAME` / `ARISTA_PASSWORD`: Arista EOS devices
- `CISCO_USERNAME` / `CISCO_PASSWORD`: Cisco IOS devices
- `EXTREME_USERNAME` / `EXTREME_PASSWORD`: Extreme EXOS devices

### Cloud Provider Configuration
- `AWS_VPC_ID` / `AWS_DEFAULT_REGION`: AWS configuration
- `AZURE_VNET_NAME` / `AZURE_RESOURCE_GROUP` / `AZURE_LOCATION`: Azure configuration
- `GCP_VPC_NAME` / `GCP_PROJECT_ID` / `GCP_REGION`: GCP configuration

### Network Configuration
- `BGP_GLOBAL_ASN`: BGP autonomous system number (65000)
- `MANAGEMENT_VLAN`: Management VLAN ID (100)
- `DATA_VLAN`: Data VLAN ID (200)
- `VOICE_VLAN`: Voice VLAN ID (300)

## Supported Network Devices

### Arista EOS
- **Core Routers**: arista-core-01, arista-core-02
- **BGP ASN**: 65001
- **Role**: Core routing and BGP peering

### Cisco IOS
- **Access Switches**: cisco-access-01, cisco-access-02
- **BGP ASN**: 65002
- **Role**: Access layer switching

### Extreme EXOS
- **Distribution Switches**: extreme-dist-01
- **BGP ASN**: 65003
- **Role**: Distribution layer switching

## Cloud Integration

### AWS VPC
- **VPC ID**: Configurable via environment
- **Region**: us-east-1 (default)
- **CIDR**: 10.0.0.0/16

### Azure VNet
- **VNet Name**: blazingswitch-vnet (default)
- **Resource Group**: blazingswitch-rg (default)
- **Location**: eastus (default)
- **CIDR**: 10.1.0.0/16

### GCP VPC
- **VPC Name**: blazingswitch-vpc (default)
- **Project ID**: Configurable via environment
- **Region**: us-central1 (default)
- **CIDR**: 10.2.0.0/16

## Deployment

To deploy to Blazingswitch:

1. **Set the client environment variable:**
   ```bash
   export CLIENT=blazingswitch
   ```

2. **Run the deployment:**
   ```bash
   ./semaphore/deploy.sh blazingswitch
   ```

3. **Or trigger via Semaphore:**
   - Set `CLIENT=blazingswitch` in the pipeline
   - The system will automatically use the `blazingswitch-vars` secret group

## Ansible Playbooks

### arista_discovery.yml
- **Purpose**: Discover network topology and current configuration
- **Tags**: `discovery`
- **Target**: All network devices
- **Output**: Saved to outputs directory

### bgp_cutover.yml
- **Purpose**: Migrate from static routes to BGP
- **Tags**: `cutover`
- **Safety**: Includes pre-flight checks and validation
- **Rollback**: Automatic rollback on failure

### rollback.yml
- **Purpose**: Emergency rollback to previous configuration
- **Tags**: `rollback`
- **Speed**: Optimized for rapid recovery
- **Scope**: All affected devices

## Scripts

### apply_dev.sh
- **Purpose**: Apply development configuration
- **Usage**: `./scripts/apply_dev.sh`
- **Environment**: Development

### plan_dev.sh
- **Purpose**: Plan development changes
- **Usage**: `./scripts/plan_dev.sh`
- **Output**: Shows planned changes without applying

### smoke.sh
- **Purpose**: Run smoke tests after deployment
- **Usage**: `./scripts/smoke.sh`
- **Tests**: Connectivity, BGP status, configuration validation

## Security

- SSH keys are managed through Semaphore secrets (`blazingswitch-vars`)
- All sensitive configuration is stored in environment files
- Network device credentials are encrypted and stored securely
- Cloud provider API keys are managed through environment variables

## Maintenance

- Update `targets.env` for configuration changes
- Modify playbooks in `ansible/playbooks/` for automation changes
- Update inventory in `ansible/inventories/` for device changes
- Modify scripts in `scripts/` for deployment process changes

## Output Management

All playbook outputs are automatically saved to:
```
outputs/blazingswitch/
├── discovery_results/
├── cutover_logs/
├── rollback_logs/
└── task_outputs/
```

## Troubleshooting

### Common Issues

1. **Network device connectivity**:
   - Verify SSH credentials in environment variables
   - Check network connectivity to devices
   - Validate device inventory configuration

2. **BGP configuration issues**:
   - Check BGP ASN configuration
   - Verify route reflector settings
   - Validate peer relationships

3. **Cloud integration problems**:
   - Verify cloud provider credentials
   - Check resource group/VPC configuration
   - Validate network peering settings

### Debug Commands

```bash
# Test network device connectivity
ansible-playbook -i ansible/inventories/production.yml ansible/playbooks/arista_discovery.yml --check

# Validate BGP configuration
ansible-playbook -i ansible/inventories/production.yml ansible/playbooks/bgp_cutover.yml --check

# Run smoke tests
./scripts/smoke.sh
```
