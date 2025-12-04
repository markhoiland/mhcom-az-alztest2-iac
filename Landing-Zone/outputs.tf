output "management_group_resource_ids" {
  description = "Map of management group names to resource IDs"
  value       = module.alz.management_group_resource_ids
}

output "policy_assignment_resource_ids" {
  description = "Map of policy assignment names to resource IDs"
  value       = module.alz.policy_assignment_resource_ids
}

output "policy_definition_resource_ids" {
  description = "Map of policy definition names to resource IDs"
  value       = module.alz.policy_definition_resource_ids
}
