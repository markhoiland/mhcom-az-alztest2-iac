# Quick Reference Guide

This guide provides quick commands and procedures for common tasks.

## Table of Contents
- [Initial Setup](#initial-setup)
- [Local Development](#local-development)
- [GitHub Actions](#github-actions)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

## Initial Setup

### 1. Azure OIDC Configuration (One-time)

```bash
# Login and set subscription
az login
az account set --subscription "<subscription-id>"

# Create App Registration
APP_ID=$(az ad app create --display-name "GitHub-OIDC-ALZ-Terraform" --query appId -o tsv)
echo "Client ID: $APP_ID"

# Create Service Principal
az ad sp create --id $APP_ID
OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

# Set your repository details
GITHUB_ORG="your-org"
REPO_NAME="your-repo"

# Create federated credentials
az ad app federated-credential create --id $APP_ID --parameters "{
  \"name\": \"GitHub-OIDC-Main\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:$GITHUB_ORG/$REPO_NAME:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

az ad app federated-credential create --id $APP_ID --parameters "{
  \"name\": \"GitHub-OIDC-PR\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:$GITHUB_ORG/$REPO_NAME:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

# Assign permissions (adjust scope as needed)
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/<mg-id>"

# Get values for GitHub
echo "=== GitHub Secrets ==="
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id -o tsv)"
```

### 2. GitHub Configuration

Add these secrets in **Settings** → **Secrets and variables** → **Actions**:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### 3. Terraform State Backend (Recommended)

```bash
# Variables
RG_NAME="rg-terraform-state"
ST_NAME="sttfstate$(openssl rand -hex 4)"
CONTAINER="tfstate"
LOCATION="eastus"

# Create resources
az group create -n $RG_NAME -l $LOCATION
az storage account create -n $ST_NAME -g $RG_NAME -l $LOCATION --sku Standard_LRS
az storage container create -n $CONTAINER --account-name $ST_NAME --auth-mode login

echo "Storage Account: $ST_NAME"
```

Update `terraform.tf` in both folders with the storage account details.

## Local Development

### Initialize and Plan

```bash
# Landing-Zone
cd Landing-Zone
terraform init
terraform plan

# Management
cd ../Management
terraform init
terraform plan
```

### Format and Validate

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Apply Changes

```bash
# Interactive apply
terraform apply

# Auto-approve (use with caution)
terraform apply -auto-approve
```

### Destroy Resources

```bash
# Preview destroy
terraform plan -destroy

# Destroy (interactive)
terraform destroy
```

## GitHub Actions

### Trigger Workflow Manually

1. Go to **Actions** tab in GitHub
2. Select workflow (Landing-Zone or Management)
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### View Workflow Runs

```bash
# Using GitHub CLI
gh run list --workflow=landing-zone-terraform.yml
gh run view <run-id>
gh run view <run-id> --log
```

### Cancel Running Workflow

```bash
gh run cancel <run-id>
```

## Common Operations

### Update Module Versions

Edit the `version` constraint in `main.tf`:

```hcl
# Landing-Zone/main.tf
module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.16"  # Update version
  # ...
}

# Management/main.tf
module "alz_management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "~> 0.8"  # Update version
  # ...
}
```

Then run:
```bash
terraform init -upgrade
terraform plan
```

### Add Custom Policy Assignments

In `Landing-Zone/main.tf`, add to the module configuration:

```hcl
module "alz" {
  # ... existing config ...

  policy_assignments_to_modify = {
    alzroot = {
      policy_assignments = {
        "Deploy-MDFC-Config" = {
          parameters = {
            logAnalytics = jsonencode({
              value = "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/..."
            })
          }
        }
      }
    }
  }
}
```

### Check Terraform State

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show <resource-address>

# Remove resource from state (doesn't delete resource)
terraform state rm <resource-address>
```

### Import Existing Resources

```bash
# Import a resource
terraform import <resource-address> <azure-resource-id>

# Example: Import management group
terraform import module.alz.azapi_resource.management_groups_level_1[\"example\"] \
  /providers/Microsoft.Management/managementGroups/example
```

## Troubleshooting

### Clear Terraform State Lock

```bash
# If state is locked and no other operation is running
terraform force-unlock <lock-id>
```

### Refresh State

```bash
# Sync state with actual infrastructure
terraform refresh
```

### View Terraform Logs

```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan

# Disable logging
unset TF_LOG
```

### Reset Terraform Directory

```bash
# Remove Terraform files and start fresh
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Check Azure Credentials

```bash
# Verify Azure CLI login
az account show

# List role assignments
az role assignment list --assignee <service-principal-object-id>
```

### Validate OIDC Configuration

```bash
# List federated credentials
az ad app federated-credential list --id <app-id>

# Test GitHub Actions OIDC (in workflow)
# Check job logs for authentication details
```

## Best Practices

### Before Making Changes

1. Create a feature branch
2. Test locally with `terraform plan`
3. Create PR to trigger plan workflow
4. Review plan in PR comments
5. Merge to apply changes

### Regular Maintenance

```bash
# Update provider versions
terraform init -upgrade

# Clean up old state versions (if using remote backend)
# Configure versioning/lifecycle in storage account

# Review and update dependencies quarterly
```

### Backup State

```bash
# Manual backup
terraform state pull > terraform.tfstate.backup

# Automated backup (for local state)
# Add to .gitignore: *.tfstate.backup
```

### Security Checks

```bash
# Check for security issues
terraform validate

# Review access and permissions
az role assignment list --all

# Audit federated credentials
az ad app federated-credential list --id <app-id>
```

## Quick Commands Cheat Sheet

| Task | Command |
|------|---------|
| Format code | `terraform fmt -recursive` |
| Validate | `terraform validate` |
| Initialize | `terraform init` |
| Plan | `terraform plan` |
| Apply | `terraform apply` |
| Destroy | `terraform destroy` |
| Show state | `terraform show` |
| List resources | `terraform state list` |
| Refresh state | `terraform refresh` |
| Unlock state | `terraform force-unlock <id>` |
| Upgrade providers | `terraform init -upgrade` |

## Support

For issues or questions:
- Check the main [README.md](../README.md)
- Review module documentation:
  - [ALZ Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest)
  - [Management Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest)
- Open a GitHub issue
