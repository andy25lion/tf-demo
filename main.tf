terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

variable "AZURE_TENANT_ID" {
  type = string
}
variable "AZURE_CLIENT_ID" {
  type = string
}
variable "AZURE_CLIENT_SECRET" {
  type = string
}
variable "AZURE_SUBSCRIPTION_ID" {
  type = string
}

provider "azurerm" {
  features {}

  tenant_id         = var.AZURE_TENANT_ID
  client_id         = var.AZURE_CLIENT_ID
  client_secret     = var.AZURE_CLIENT_SECRET
  subscription_id   = var.AZURE_SUBSCRIPTION_ID

}

resource "random_password" "vm_password" {
  count = 3
  length  = 16
  special = true
}


resource "azurerm_resource_group" "example" {
  name     = "tf-demo"
  location = "Germany West Central"
}