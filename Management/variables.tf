variable "location" {
  type        = string
  description = "The Azure region where management resources will be deployed"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for management resources"
  default     = "rg-alz-management"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the Log Analytics workspace"
  default     = "law-alz-management"
}

variable "automation_account_name" {
  type        = string
  description = "Name of the Azure Automation account"
  default     = "aa-alz-management"
}

variable "log_analytics_workspace_retention_in_days" {
  type        = number
  description = "Number of days to retain data in Log Analytics workspace"
  default     = 30
}

variable "enable_automation_account" {
  type        = bool
  description = "Enable deployment of Azure Automation account linked to Log Analytics"
  default     = false
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the module"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Environment = "Management"
    ManagedBy   = "Terraform"
  }
}
