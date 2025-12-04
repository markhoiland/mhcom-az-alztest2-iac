terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    alz = {
      source  = "Azure/alz"
      version = "~> 0.20"
    }
  }

  # Backend configuration - update with your storage account details
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstate"
  #   container_name       = "tfstate"
  #   key                  = "landing-zone.tfstate"
  # }
}

provider "azapi" {
  # Configuration options
  # When using OIDC, authentication is automatic
}

provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2025.09.0"
    }
  ]
}
