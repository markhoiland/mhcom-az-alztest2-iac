# Landing-Zone

This folder contains the Terraform configuration for deploying the core Azure Landing Zone (ALZ) architecture.

## What Gets Deployed

This configuration uses the [Azure ALZ Terraform Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest) to deploy:

- **Management Group Hierarchy**: Complete ALZ management group structure
- **Azure Policy**: Policy definitions, initiatives, and assignments
- **Role Definitions**: Custom Azure role definitions
- **Role Assignments**: Azure RBAC role assignments
- **Subscription Placement**: Organization of subscriptions into management groups

## Architecture

The default `architecture_name = "alz"` deploys the standard Azure Landing Zone architecture with the following management groups:

```
Tenant Root Group
└── ALZ
    ├── Platform
    │   ├── Management
    │   ├── Connectivity
    │   └── Identity
    └── Landing Zones
        ├── Corp
        └── Online
```

## Configuration

### Required Variables

- `location`: Azure region for managed identities (default: "eastus")
- `parent_management_group_id`: Parent management group ID (default: tenant root)

### Optional Variables

- `enable_telemetry`: Enable module telemetry (default: true)

## Usage

### Local Development

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Preview changes:
   ```bash
   terraform plan
   ```

5. Apply changes:
   ```bash
   terraform apply
   ```

### CI/CD Pipeline

Changes to this folder automatically trigger the `landing-zone-terraform.yml` workflow when:
- Pushed to the `main` branch
- Pull requests are created/updated
- Manually triggered via workflow_dispatch

## Important Notes

### .alzlib Directory

The ALZ module downloads a library of policies and archetypes to a `.alzlib` directory. This is excluded from version control via `.gitignore` as it's auto-generated.

### State Management

For production use, uncomment and configure the `backend "azurerm"` block in `terraform.tf` to use remote state storage.

### Permissions Required

The service principal or user running this configuration needs:
- **Owner** or **Contributor** + **User Access Administrator** role at the target Management Group scope
- Permissions to create and manage Management Groups
- Permissions to assign Azure Policies

## Outputs

- `management_group_resource_ids`: Map of management group names to resource IDs
- `policy_assignment_resource_ids`: Map of policy assignments to resource IDs
- `policy_definition_resource_ids`: Map of policy definitions to resource IDs

## Customization

To customize the ALZ architecture:

1. Modify policy assignments using the `policy_assignments_to_modify` variable
2. Add custom libraries by configuring the `alz` provider
3. Adjust management group hierarchy settings

See the [module documentation](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest) for advanced configuration options.
