variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "eastus"
}

variable "parent_management_group_id" {
  type        = string
  description = "The ID of the parent management group. Leave empty to use tenant root."
  default     = ""
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the module"
  default     = true
}
