output "resource_group" {
  description = "The resource group containing management resources"
  value       = module.alz_management.resource_group
}

output "log_analytics_workspace" {
  description = "Log Analytics workspace details"
  value       = module.alz_management.log_analytics_workspace
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace"
  value       = module.alz_management.resource_id
}

output "automation_account" {
  description = "Azure Automation account details"
  value       = module.alz_management.automation_account
}

output "data_collection_rule_ids" {
  description = "Data Collection Rule resource IDs"
  value       = module.alz_management.data_collection_rule_ids
}

output "user_assigned_identity_ids" {
  description = "User assigned identity IDs"
  value       = module.alz_management.user_assigned_identity_ids
}
