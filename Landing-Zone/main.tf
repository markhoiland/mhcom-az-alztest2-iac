# Get current Azure context
data "azapi_client_config" "current" {}

# Deploy Azure Landing Zone with default ALZ architecture
module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.15"

  architecture_name  = "alz"
  location           = var.location
  parent_resource_id = var.parent_management_group_id != "" ? var.parent_management_group_id : data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
}
