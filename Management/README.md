# Management

This folder contains the Terraform configuration for deploying Azure Landing Zone management resources.

## What Gets Deployed

This configuration uses the [Azure ALZ Management Module](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest) to deploy:

- **Log Analytics Workspace**: Central logging and monitoring
- **Azure Automation Account**: (Optional) For automated management tasks
- **Data Collection Rules**: For Azure Monitor Agent
  - Change Tracking DCR
  - VM Insights DCR
  - Defender for SQL DCR
- **User Assigned Managed Identity**: For Azure Monitor Agent
- **Log Analytics Solutions**: Container Insights, VM Insights, etc.

## Configuration

### Required Variables

- `location`: Azure region for resources (default: "eastus")
- `resource_group_name`: Resource group name (default: "rg-alz-management")
- `log_analytics_workspace_name`: Log Analytics workspace name (default: "law-alz-management")
- `automation_account_name`: Automation account name (default: "aa-alz-management")

### Optional Variables

- `log_analytics_workspace_retention_in_days`: Data retention period (default: 30)
- `enable_automation_account`: Deploy Automation Account (default: false)
- `enable_telemetry`: Enable module telemetry (default: true)
- `tags`: Resource tags

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

Changes to this folder automatically trigger the `management-terraform.yml` workflow when:
- Pushed to the `main` branch
- Pull requests are created/updated
- Manually triggered via workflow_dispatch

## Deployment Order

It's recommended to deploy the Management resources **after** the Landing-Zone infrastructure, as they may reference outputs from the Landing-Zone deployment.

## Resource Naming

All resources use the names specified in variables. For production deployments, ensure names comply with:
- Azure naming conventions
- Your organization's naming standards
- Character limits for each resource type

## State Management

For production use, uncomment and configure the `backend "azurerm"` block in `terraform.tf` to use remote state storage.

## Outputs

- `resource_group`: Resource group details
- `log_analytics_workspace`: Log Analytics workspace details
- `log_analytics_workspace_id`: Workspace resource ID
- `automation_account`: Automation account details
- `data_collection_rule_ids`: DCR resource IDs
- `user_assigned_identity_ids`: Managed identity IDs

## Integration with Landing-Zone

The Log Analytics workspace deployed here can be referenced by policy assignments in the Landing-Zone configuration for centralized logging and monitoring.

Example policy parameter configuration in Landing-Zone:

```hcl
policy_default_values = {
  logAnalytics = jsonencode({
    value = module.management.log_analytics_workspace_id
  })
}
```

## Monitoring and Logging

The deployed workspace includes:
- **Container Insights**: Monitor AKS clusters
- **VM Insights**: Monitor virtual machines
- **Data Collection Rules**: For Azure Monitor Agent
- **Retention Policies**: Configurable data retention

## Cost Considerations

Log Analytics costs are based on:
- Data ingestion volume (GB)
- Data retention period
- Additional features enabled

Use the `log_analytics_workspace_retention_in_days` variable to control costs through retention policies.

## Customization

Advanced customization options:
- Custom log analytics solutions
- Additional data collection rules
- Workspace configurations
- Automation account runbooks

See the [module documentation](https://registry.terraform.io/modules/Azure/avm-ptn-alz-management/azurerm/latest) for all available options.
