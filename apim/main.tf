# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-global-rg"
    storage_account_name = "tfstategithub11184"
    key                  = "tfgithubactions.tfstate"
  }
}

# Constructed names of resources
locals {
  resourceGroupName = "${var.prefix}-${var.environment}-rg"
  apimName          = "${var.prefix}-${var.environment}-apim-${var.uniqueId}"
  sku_name          = "${var.apimSku}_${var.apimSkuCapacity}"         
  storageAccountName= "${var.prefix}${var.environment}apimsa${var.uniqueId}"

}

resource "azurerm_resource_group" "rg" {
  name     = local.resourceGroupName
  location = var.location
}

resource "azurerm_api_management" "apim" {
  name                = local.apimName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.apimPublisherName
  publisher_email     = var.apimPublisherEmail

  sku_name = local.sku_name
}

resource "azurerm_api_management_product" "starter" {
  product_id            = "starter"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Starter"
  subscription_required = true
  approval_required     = false
  published             = true
}


resource "azurerm_api_management_product_policy" "starter" {
  product_id          = azurerm_api_management_product.starter.product_id
  api_management_name = azurerm_api_management_product.starter.api_management_name
  resource_group_name = azurerm_api_management_product.starter.resource_group_name

  xml_content = <<XML
  <policies>
    <inbound>
      <base />
      <rate-limit calls="10" renewal-period="60"/>
      <quota calls="100" renewal-period="3600"/>
    </inbound>
  </policies>
  XML

}

resource "azurerm_api_management_product" "premium" {
  product_id            = "premium"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Premium"
  subscription_required = true
  approval_required     = true
  published             = true
}

resource "azurerm_api_management_product_policy" "premium" {
  product_id          = azurerm_api_management_product.premium.product_id
  api_management_name = azurerm_api_management_product.premium.api_management_name
  resource_group_name = azurerm_api_management_product.premium.resource_group_name

  xml_content = <<XML
  <policies>
    <inbound>
      <base />
      <rate-limit calls="600" renewal-period="60"/>
      <quota calls="10000" renewal-period="3600"/>
    </inbound>
  </policies>
  XML

}

# Create Storage Account
resource "azurerm_storage_account" "sa" {
  name                      = local.storageAccountName
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = var.storageAccountSku.tier
  account_replication_type  = var.storageAccountSku.type
  account_kind              = "StorageV2"
  enable_https_traffic_only = true
  allow_nested_items_to_be_public =  true
}