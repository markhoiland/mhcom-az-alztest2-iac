# Azure Landing Zone Infrastructure as Code

This repository contains Terraform configurations for deploying Azure Landing Zones (ALZ) using Azure Verified Modules (AVM) with secure GitHub Actions CI/CD pipelines using OpenID Connect (OIDC).

## Repository Structure

```
.
├── Landing-Zone/          # Core Azure Landing Zone deployment
│   ├── main.tf           # ALZ module configuration
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── terraform.tf      # Provider and backend configuration
│   └── terraform.tfvars.example
├── Management/            # ALZ Management resources
│   ├── main.tf           # Management module configuration
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── terraform.tf      # Provider and backend configuration
│   └── terraform.tfvars.example
└── .github/
    └── workflows/         # CI/CD workflows
        ├── landing-zone-terraform.yml
        └── management-terraform.yml
```

## Architecture Overview

### Landing-Zone
Deploys the core Azure Landing Zone architecture using the `Azure/terraform-azurerm-avm-ptn-alz` module with:
- Management group hierarchy
- Azure Policy definitions and assignments
- Role definitions and assignments
- Subscription placement

### Management
Deploys ALZ management resources using the `Azure/terraform-azurerm-avm-ptn-alz-management` module with:
- Log Analytics Workspace
- Azure Automation Account (optional)
- Data Collection Rules
- User Assigned Managed Identities
- Log Analytics Solutions

## Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository
- Azure CLI installed locally (for setup)
- Terraform >= 1.9.0 (for local development)

## Setup Instructions

### Part 1: Azure Entra ID Configuration for OIDC

#### 1.1 Create Azure AD Application Registration

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create the App Registration
az ad app create --display-name "GitHub-OIDC-ALZ-Terraform"

# Note the appId (Client ID) from the output
APP_ID="<appId-from-output>"
```

#### 1.2 Create Service Principal

```bash
# Create service principal
az ad sp create --id $APP_ID

# Get the Object ID of the service principal
OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)
echo "Service Principal Object ID: $OBJECT_ID"
```

#### 1.3 Configure Federated Credentials for OIDC

You need to create federated credentials for both the main branch and pull requests.

```bash
# Get your GitHub repository details
GITHUB_ORG="<your-github-org-or-username>"
REPO_NAME="<your-repo-name>"

# Create federated credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-OIDC-Main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$REPO_NAME':ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-OIDC-PR",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$REPO_NAME':pull_request",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### 1.4 Assign Azure Permissions

The service principal needs appropriate permissions to deploy Landing Zones:

```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign Owner role at Management Group level (required for Landing Zone deployment)
# Note: You may need to adjust the scope based on your requirements
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/<root-management-group-id>"

# Alternative: Assign at subscription level if you don't have management group permissions
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Owner" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

**Required Permissions:**
- **Owner** or **Contributor** + **User Access Administrator** at the target Management Group or Subscription
- Permissions to create and manage Management Groups
- Permissions to assign Azure Policies

#### 1.5 Record Configuration Values

Save these values for GitHub configuration:

```bash
echo "Azure Tenant ID: $(az account show --query tenantId -o tsv)"
echo "Azure Subscription ID: $SUBSCRIPTION_ID"
echo "Azure Client ID (App ID): $APP_ID"
```

### Part 2: GitHub Repository Configuration

#### 2.1 Configure GitHub Secrets

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add the following:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | `<appId from 1.1>` | Application (client) ID |
| `AZURE_TENANT_ID` | `<tenantId>` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `<subscriptionId>` | Azure subscription ID |

**Note:** With OIDC, you do NOT need to store client secrets or passwords. Authentication is handled through federated identity.

#### 2.2 Configure GitHub Environment (Optional but Recommended)

For additional security and deployment controls:

1. Go to **Settings** → **Environments**
2. Click **New environment** and name it `production`
3. Configure protection rules:
   - ✅ Required reviewers (add team members)
   - ✅ Wait timer (optional, e.g., 5 minutes)
   - ✅ Deployment branches: Selected branches → Add `main`

### Part 3: Terraform Backend Configuration (Optional)

For production deployments, configure remote state storage:

#### 3.1 Create Storage Account for Terraform State

```bash
# Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
```

#### 3.2 Update Terraform Backend Configuration

Uncomment and update the `backend "azurerm"` blocks in:
- `Landing-Zone/terraform.tf`
- `Management/terraform.tf`

Example:
```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "sttfstate<unique-id>"
  container_name       = "tfstate"
  key                  = "landing-zone.tfstate"  # or "management.tfstate"
}
```

### Part 4: Local Development Setup

#### 4.1 Clone Repository

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

#### 4.2 Configure Variables

```bash
# For Landing-Zone
cd Landing-Zone
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# For Management
cd ../Management
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

#### 4.3 Initialize and Validate

```bash
# Landing-Zone
cd Landing-Zone
terraform init
terraform validate
terraform plan

# Management
cd ../Management
terraform init
terraform validate
terraform plan
```

## CI/CD Workflow Overview

### Workflows

1. **landing-zone-terraform.yml** - Deploys core ALZ infrastructure
2. **management-terraform.yml** - Deploys management resources

### Workflow Triggers

- **Push to main**: Runs plan and apply
- **Pull Request**: Runs plan only and posts results as PR comment
- **Manual**: Can be triggered via workflow_dispatch

### Workflow Steps

1. **Terraform Plan Job**:
   - Checkout code
   - Authenticate to Azure using OIDC
   - Format check
   - Initialize Terraform
   - Validate configuration
   - Generate plan
   - Post plan to PR (if applicable)

2. **Terraform Apply Job** (main branch only):
   - Checkout code
   - Authenticate to Azure using OIDC
   - Initialize Terraform
   - Apply changes automatically

## Security Best Practices

### OIDC Benefits
✅ No long-lived credentials stored in GitHub  
✅ Automatic token rotation  
✅ Scoped to specific repository and branches  
✅ Audit trail through Azure AD  

### Additional Recommendations
- Use branch protection rules for main branch
- Require pull request reviews
- Enable GitHub Advanced Security features
- Regularly review federated credentials
- Use Azure Policy for governance
- Implement least-privilege access

## Deployment Workflow

### Standard Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make Changes**
   - Edit Terraform files in `Landing-Zone/` or `Management/`
   - Test locally with `terraform plan`

3. **Create Pull Request**
   - Push branch to GitHub
   - Open PR to main
   - Review Terraform plan in PR comments

4. **Merge to Main**
   - Approve and merge PR
   - Workflow automatically applies changes to Azure

## Troubleshooting

### OIDC Authentication Failures

**Error**: "Error: AADSTS70021: No matching federated identity record found"

**Solution**: Verify federated credentials are configured correctly
```bash
az ad app federated-credential list --id $APP_ID
```

### Permission Errors

**Error**: "AuthorizationFailed" or "Insufficient privileges"

**Solution**: Verify service principal has Owner or Contributor role at appropriate scope

### Terraform State Lock

**Error**: "Error acquiring the state lock"

**Solution**: 
- Ensure no other workflows are running
- Check Azure Storage for state lock
- If stuck, break lease: `az storage blob lease break --blob-url <url>`

## Module Documentation

- [Azure ALZ Terraform Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest)
- [Azure ALZ Management Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest)

## Support and Contributions

For issues or questions:
1. Check existing GitHub Issues
2. Review module documentation
3. Create new issue with detailed description

## License

This repository structure and configuration is provided as-is for deploying Azure Landing Zones.
