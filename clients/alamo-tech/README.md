# Alamo Tech Client Configuration

This directory contains all Alamo Tech-specific configuration and automation files.

## Directory Structure

```
clients/alamo-tech/
├── env/
│   └── targets.env              # Target server configuration
└── README.md                   # This file
```

## Configuration

### Environment Variables

The `env/targets.env` file contains:
- `HOST`: Target server IP or hostname
- `USER`: SSH user (defaults to ubuntu)
- `ENVIRONMENT`: Environment type (production)
- `PROJECT`: Project name (alamo-tech)
- `REGION`: AWS region (us-central-1)

### Alamo Tech Specific Configuration
- `COMPANY_NAME`: Company name (Alamo Tech)
- `DEPLOYMENT_TIER`: Deployment tier (enterprise)
- `MONITORING_ENABLED`: Monitoring status (true)
- `BACKUP_ENABLED`: Backup status (true)

## Deployment

To deploy to Alamo Tech:

1. **Set the client environment variable:**
   ```bash
   export CLIENT=alamo-tech
   ```

2. **Run the deployment:**
   ```bash
   # Standard deployment
   ./semaphore/deploy.sh alamo-tech standard
   
   # Ubuntu server update
   ./semaphore/deploy.sh alamo-tech ubuntu-update
   ```

3. **Or trigger via Semaphore:**
   - Set `CLIENT=alamo-tech` in the pipeline
   - The system will automatically use the `alamo-vars` secret group

## Deployment Types

### Standard Deployment
- **Purpose**: Basic server connectivity and health checks
- **Commands**: `hostname && uptime`
- **Output**: Simple connectivity verification
- **Use Case**: Basic monitoring and health checks

### Ubuntu Update Deployment
- **Purpose**: Ubuntu server system updates and maintenance
- **Commands**: `apt update && apt upgrade -y`
- **Output**: Comprehensive update logs with system information
- **Use Case**: Regular server maintenance and security updates
- **Options**: 
  - `standard`: Regular package updates
  - `security`: Security updates only
  - `full`: Complete system update including dist-upgrade
  - `minimal`: Updates without recommended packages

### Future Expansion
Alamo Tech can be extended to support:
- **Network automation**: For network device management
- **Azure deployment**: For cloud infrastructure
- **Custom automation**: For specific Alamo Tech requirements

## Security

- SSH keys are managed through Semaphore secrets (`alamo-vars`)
- All sensitive configuration is stored in environment files
- Enterprise-grade security with monitoring and backup enabled

## Maintenance

- Update `targets.env` for configuration changes
- Add ansible directory for advanced automation if needed
- Modify deployment scripts for custom requirements

## Support

For Alamo Tech specific issues:
- Check deployment logs in `outputs/alamo-tech/`
- Verify SSH connectivity to target servers
- Ensure proper secret configuration in Semaphore
