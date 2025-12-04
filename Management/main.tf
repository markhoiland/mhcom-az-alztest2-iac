# Deploy ALZ Management resources
module "alz_management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "~> 0.7"

  location                     = var.location
  resource_group_name          = var.resource_group_name
  log_analytics_workspace_name = var.log_analytics_workspace_name
  automation_account_name      = var.automation_account_name

  # Log Analytics settings
  log_analytics_workspace_retention_in_days = var.log_analytics_workspace_retention_in_days

  # Automation account settings
  linked_automation_account_creation_enabled = var.enable_automation_account

  # Telemetry
  enable_telemetry = var.enable_telemetry

  # Tags
  tags = var.tags
}
