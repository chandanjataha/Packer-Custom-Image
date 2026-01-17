# Packer Custom Image Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Packer Version](https://img.shields.io/badge/Packer-%3E%3D1.10.0-blue)
![Status](https://img.shields.io/badge/Status-Production%20Ready-green)

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Security Best Practices](#security-best-practices)
- [Variables & Customization](#variables--customization)
- [Troubleshooting](#troubleshooting)
- [CI/CD Integration](#cicd-integration)
- [Maintenance & Versioning](#maintenance--versioning)
- [Contributing](#contributing)
- [Support](#support)

---

## Overview

**Packer Custom Image Builder** is an enterprise-grade Infrastructure as Code (IaC) solution using HashiCorp Packer to automate the creation of custom Azure VM images. This project enables organizations to:

- **Standardize Infrastructure**: Build consistent VM images with pre-configured software and security baselines
- **Reduce Deployment Time**: Eliminate post-deployment configuration and provisioning delays
- **Ensure Compliance**: Implement organization-wide security policies and configuration standards
- **Enable Scaling**: Rapidly deploy multiple VM instances from golden images
- **Audit & Track**: Maintain version control and audit trails for all image builds

### Key Features

- Automated Azure VM image generation using Packer
- Ubuntu 22.04 LTS base image with modern security standards
- Pre-installed application stack (nginx, custom applications)
- HCL2 configuration for IaC best practices
- Multi-region support capability
- Automated image tagging and resource management
- Integration-ready for CI/CD pipelines
- Azure Resource Group management

---

## Architecture

### Build Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│            Packer Build Orchestration                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │  Source Image    │      │  Provisioning    │       │
│  │  (Ubuntu 22.04)  │─────▶│  Scripts         │       │
│  └──────────────────┘      └──────────────────┘       │
│                                    │                    │
│                                    ▼                    │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │  Azure Provider  │      │  Build Instance  │       │
│  │  Credentials     │─────▶│  (VM with Agent) │       │
│  └──────────────────┘      └──────────────────┘       │
│                                    │                    │
│                                    ▼                    │
│            ┌──────────────────────────────┐            │
│            │  Managed Image Artifact      │            │
│            │  (packerdemo RG)             │            │
│            └──────────────────────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Component Breakdown

| Component | Purpose | Details |
|-----------|---------|---------|
| **Source** | Base VM definition | Ubuntu 22.04 LTS, Standard_D2s_v3 instance |
| **Provisioner** | Configuration automation | Shell scripts for package installation |
| **Artifact** | Output image | Managed image in Azure Resource Group |
| **Tags** | Metadata | Resource organization and cost tracking |

---

## Prerequisites

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| **Packer** | >= 1.10.0 | Image building orchestration |
| **Azure CLI** | >= 2.50.0 | Azure authentication and resource management |
| **PowerShell** | >= 7.0 (optional) | Windows native automation |
| **Git** | >= 2.40.0 | Version control and repository management |

### Azure Requirements

- **Azure Subscription**: Active Azure subscription with billing enabled
- **Service Principal**: Azure AD service principal with contributor permissions on target resource group
- **Resource Group**: Pre-created Azure resource group (e.g., `packerdemo`)
- **Network**: VNet configuration allowing outbound internet access for package downloads

### System Requirements

- **OS**: Windows 10+, macOS 10.14+, or Linux (Ubuntu 18.04+)
- **Storage**: Minimum 50GB free disk space for temporary build artifacts
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Network**: Stable internet connection with unrestricted access to Azure and package repositories

---

## Installation & Setup

### 1. Install Packer

#### Windows (PowerShell)
```powershell
# Using Chocolatey
choco install packer

# Or download directly from HashiCorp
# https://www.packer.io/downloads
```

#### macOS
```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/packer

# Or download directly
# https://www.packer.io/downloads
```

#### Linux (Ubuntu/Debian)
```bash
# Add HashiCorp repository
curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install
sudo apt-get update && sudo apt-get install packer
```

### 2. Verify Installation

```bash
packer version
# Expected output: Packer v1.10.x or higher
```

### 3. Clone Repository

```bash
git clone <repository-url>
cd Packer-Custom-Image
```

### 4. Azure CLI Authentication

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription <SUBSCRIPTION_ID>

# Verify authentication
az account show
```

### 5. Initialize Packer Plugins

```bash
# Initialize required plugins (Azure provider)
packer init custom_images.pkr.hcl
```

---

## Configuration

### Azure Service Principal Setup (Recommended)

For CI/CD and automated builds, use a service principal instead of personal credentials:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "packer-builder" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>

# Output will provide:
# - appId (client_id)
# - password (client_secret)
# - tenant (tenant_id)
```

### Environment Variables Setup

Create a `.env` file (do **NOT** commit to version control):

```bash
# Azure Credentials
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"

# Packer Variables
export PACKER_LOG=1  # Enable debug logging
export PACKER_LOG_PATH="./packer-build.log"
```

### Load Environment Variables

```bash
# PowerShell
Get-Content .env | ForEach-Object {
  if ($_ -like "*=*") {
    $key, $value = $_.Split('=')
    [Environment]::SetEnvironmentVariable($key, $value)
  }
}

# Bash/Shell
source .env
```

---

## Usage

### Basic Build

```bash
# Validate configuration
packer validate custom_images.pkr.hcl

# Build image
packer build custom_images.pkr.hcl

# Build with debug output
packer build -debug custom_images.pkr.hcl

# Build specific source only
packer build -only="azure-arm.basic-example" custom_images.pkr.hcl
```

### Build with Variables

```bash
# Using command-line variables
packer build \
  -var="resource_group_name=my-rg" \
  -var="location=East US" \
  custom_images.pkr.hcl

# Using variables file
packer build -var-file="variables.tfvars" custom_images.pkr.hcl
```

### Expected Output

```
azure-arm.basic-example: output will be in this color.

==> azure-arm.basic-example: Running builder ...
==> azure-arm.basic-example: Getting tokens using client secret
==> azure-arm.basic-example: Creating Azure client ...
==> azure-arm.basic-example: Creating virtual machine ...
...
Build 'azure-arm.basic-example' finished after 15 minutes 23 seconds.

==> Builds finished. The artifacts of successful builds are:

--> azure-arm.basic-example: Azure.ResourceManagement.VMImage:

OSType: Linux
ManagedImageId: /subscriptions/.../resourceGroups/packerdemo/providers/Microsoft.Compute/images/nginx-custom-image
```

### Build Outputs

After successful build, the managed image is created in Azure:
- **Location**: Resource Group `packerdemo`
- **Image Name**: `nginx-custom-image`
- **OS Type**: Linux (Ubuntu 22.04 LTS)

---

## Security Best Practices

### Credential Management

⚠️ **CRITICAL**: Never commit credentials to version control.

- **Use Azure Key Vault** for credential storage
- **Use environment variables** for temporary credential passing
- **Use Service Principals** instead of personal credentials
- **Implement MFA** on Azure accounts
- **Rotate credentials** regularly (every 90 days)

### Secrets Management

```hcl
# ❌ BAD - Never do this
source "azure-arm" "bad-example" {
  client_id     = "543c2581-dd7f-406f-b108-40a932c"
  client_secret = "Rtz8Q~v8LOE5OF5dzPJ4mjG6KiAssn"
}

# ✅ GOOD - Use environment variables
variable "azure_client_id" {
  type      = string
  sensitive = true
  default   = env("AZURE_CLIENT_ID")
}

variable "azure_client_secret" {
  type      = string
  sensitive = true
  default   = env("AZURE_CLIENT_SECRET")
}

source "azure-arm" "good-example" {
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
}
```

### Network Security

- **Restrict build VM access**: Use NSGs to limit outbound traffic
- **Use private endpoints** for Key Vault access
- **Enable VNet integration** for isolated builds
- **Implement Azure Firewall** rules for outbound filtering

### Image Security

- **Patch Management**: Run `apt-get upgrade` for latest security patches
- **Remove Sensitive Data**: Clean temporary files and credentials before image capture
- **Implement Azure Policies**: Enforce encryption and compliance
- **Enable Image Encryption**: Use Azure Disk Encryption (ADE)
- **Scan for Vulnerabilities**: Use Azure Container Registry scanning or third-party tools

### Compliance & Auditing

```bash
# Enable audit logging
packer build -var="enable_audit_logging=true" custom_images.pkr.hcl

# Monitor builds in Azure Activity Log
az monitor activity-log list --resource-group packerdemo
```

---

## Variables & Customization

### Default Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `image_publisher` | `Canonical` | Ubuntu image publisher |
| `image_offer` | `0001-com-ubuntu-server-jammy` | Ubuntu 22.04 LTS offer |
| `image_sku` | `22_04-lts` | Ubuntu 22.04 LTS SKU |
| `vm_size` | `Standard_D2s_v3` | Build instance size |
| `location` | `West US` | Azure region |
| `os_type` | `Linux` | Operating system type |

### Creating a Variables File

Create `variables.pkrvars.hcl`:

```hcl
# Resource Configuration
resource_group_name                = "packerdemo"
subscription_id                    = "d6648ae8-3690-454e-ab03-88b7483d3"
tenant_id                          = "964c8d5d-5d50-4ef0-8220-46a5be85e"
client_id                          = sensitive("YOUR_CLIENT_ID")
client_secret                      = sensitive("YOUR_CLIENT_SECRET")

# Image Configuration
managed_image_name                 = "nginx-custom-image"
managed_image_resource_group_name  = "packerdemo"
location                           = "West US"
vm_size                            = "Standard_D2s_v3"

# Source Image
image_publisher                    = "Canonical"
image_offer                        = "0001-com-ubuntu-server-jammy"
image_sku                          = "22_04-lts"

# Tagging
azure_tags = {
  environment = "production"
  managed_by  = "packer"
  team        = "platform-engineering"
  cost_center = "engineering"
}
```

### Customizing Provisioning

Modify shell provisioner inline commands:

```hcl
provisioner "shell" {
  inline = [
    "apt-get update",
    "apt-get upgrade -y",
    "apt-get install -y nginx curl wget git jq",
    "systemctl enable nginx",
    "git clone https://github.com/your-org/your-app.git /var/www/html",
    "chmod -R 755 /var/www/html"
  ]
}
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. Authentication Failures

**Error**: `Error authenticating to Azure: cannot parse json`

**Solution**:
```bash
# Verify credentials
az account show

# Re-authenticate
az login

# Set subscription
az account set --subscription <SUBSCRIPTION_ID>
```

#### 2. Plugin Version Issues

**Error**: `Unsupported plugin version`

**Solution**:
```bash
# Remove cached plugins
rm -rf ~/.packer.d/plugins

# Reinitialize
packer init custom_images.pkr.hcl
```

#### 3. Build Timeout

**Error**: `context deadline exceeded`

**Solution**:
```hcl
# Increase build timeout in source block
communicator_timeout = "15m"
```

#### 4. Insufficient Permissions

**Error**: `StatusCode=403 Unauthorized`

**Solution**:
```bash
# Verify service principal has contributor role
az role assignment create \
  --assignee <CLIENT_ID> \
  --role "Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
```

#### 5. Package Installation Failures

**Error**: `E: Unable to locate package nginx`

**Solution**:
```hcl
provisioner "shell" {
  inline = [
    "apt-get update",
    "apt-get install -y --no-install-recommends nginx"
  ]
}
```

### Debug Logging

```bash
# Enable detailed logging
export PACKER_LOG=1
export PACKER_LOG_PATH="./packer-debug.log"
packer build -debug custom_images.pkr.hcl

# View logs
tail -f packer-debug.log
```

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/packer-build.yml`:

```yaml
name: Packer Build

on:
  push:
    branches:
      - main
    paths:
      - 'custom_images.pkr.hcl'
      - '.github/workflows/packer-build.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: latest
      
      - name: Initialize Packer
        run: packer init custom_images.pkr.hcl
      
      - name: Validate Configuration
        run: packer validate custom_images.pkr.hcl
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build Image
        run: packer build custom_images.pkr.hcl
        env:
          PACKER_LOG: 1
```

### Azure DevOps Pipeline Example

Create `azure-pipelines.yml`:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  PACKER_VERSION: '1.10.0'

stages:
  - stage: Build
    jobs:
      - job: PackerBuild
        steps:
          - task: UsePythonVersion@0
            inputs:
              versionSpec: '3.11'
          
          - script: |
              wget https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
              unzip packer_$(PACKER_VERSION)_linux_amd64.zip
              chmod +x packer
            displayName: 'Install Packer'
          
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Azure Subscription'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                ./packer init custom_images.pkr.hcl
                ./packer validate custom_images.pkr.hcl
                ./packer build custom_images.pkr.hcl
```

---

## Maintenance & Versioning

### Versioning Strategy

Use semantic versioning for image releases:

```
Image Version: 1.0.0
├── Major: Breaking changes (OS version upgrade)
├── Minor: Feature additions (new packages)
└── Patch: Security patches
```

### Version Control Best Practices

```bash
# Create version tags
git tag -a v1.0.0 -m "Initial production release"
git push origin v1.0.0

# Document changes in CHANGELOG
# CHANGELOG.md format:
# ## [1.0.0] - 2024-01-18
# ### Added
# - Initial nginx custom image
# - StreamFlix application integration
# ### Security
# - Applied all security patches
```

### Regular Maintenance Tasks

- **Weekly**: Review Azure Activity Log for failed builds
- **Monthly**: Update base image to latest LTS patches
- **Quarterly**: Audit image contents and remove obsolete packages
- **Annually**: Review and update Packer version and plugins

### Automated Image Refresh

```bash
# Schedule daily rebuild (cron)
0 2 * * * cd /path/to/Packer-Custom-Image && packer build custom_images.pkr.hcl
```

---

## Contributing

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/add-python3
   ```

2. **Test Configuration**
   ```bash
   packer validate custom_images.pkr.hcl
   packer build -var="managed_image_name=test-image" custom_images.pkr.hcl
   ```

3. **Document Changes**
   ```bash
   # Update CHANGELOG.md
   git add CHANGELOG.md custom_images.pkr.hcl
   ```

4. **Create Pull Request**
   - Describe changes
   - Attach build logs
   - Request review from team leads

### Code Review Checklist

- [ ] Configuration validates without errors
- [ ] Security practices followed (no hardcoded secrets)
- [ ] Changes documented in CHANGELOG
- [ ] Build tested successfully
- [ ] Image size within acceptable limits
- [ ] All required packages installed
- [ ] Tagging strategy followed

---

## Support

### Getting Help

- **Documentation**: [HashiCorp Packer Official Docs](https://www.packer.io/docs)
- **Community**: [HashiCorp Discuss - Packer](https://discuss.hashicorp.com/c/packer/)
- **Issues**: Create GitHub issue with reproduction steps
- **Internal Team**: Contact Platform Engineering team

### Reporting Issues

Include the following information:

```
**Environment**:
- OS: [Windows/macOS/Linux]
- Packer Version: `packer version`
- Azure Region: [region]

**Reproduction Steps**:
1. ...
2. ...
3. ...

**Expected Behavior**: ...
**Actual Behavior**: ...

**Build Logs**:
```
[Attach packer-build.log]
```
```

### Performance Optimization

| Optimization | Impact | Implementation |
|--------------|--------|-----------------|
| Parallel builds | 3x faster | Use multiple sources |
| Caching | 50% faster | Cache package repositories |
| Spot instances | 70% cheaper | Use `spot_price = "0.05"` |
| Region selection | Network latency | Use closest Azure region |

---

## License

This project is licensed under the MIT License - see [LICENSE](./LICENSE) file for details.

---

## Project Metadata

- **Created**: January 2024
- **Last Updated**: January 2026
- **Maintained By**: Platform Engineering Team
- **Support SLA**: 24-hour response time for P1 issues

---

## Related Resources

- [Azure Best Practices](https://learn.microsoft.com/en-us/azure/best-practices-and-patterns)
- [Packer Azure Provider Documentation](https://www.packer.io/plugins/builders/azure)
- [Infrastructure as Code Best Practices](https://www.terraform.io/cloud-docs/state/best-practices)
- [Azure Security Baseline](https://learn.microsoft.com/en-us/security/benchmark/azure/)