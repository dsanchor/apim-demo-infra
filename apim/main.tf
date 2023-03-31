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
    storage_account_name = "tfstategithub1328673397"
    key                  = "tfgithubactions.tfstate"
  }
}

# Constructed names of resources
locals {
  resourceGroupName = "${var.prefix}-${var.environment}-rg"
  apimName          = "${var.prefix}-${var.environment}-apim-${var.uniqueId}"
  sku_name          = "${var.apimSku}_${var.apimSkuCapacity}"         
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
  description           = "A subscription to this product will allow you to make 100 calls per hour. Rate limit applied: 10 calls per minute."
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
  description           = "A subscription to this product will allow you to make 10,000 calls per hour. Rate limit applied: 600 calls per minute."
  subscription_required = true
  approval_required     = true
  subscriptions_limit   = 1
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

#Add subscription to starter product
resource "azurerm_api_management_subscription" "starter" {
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  product_id            = azurerm_api_management_product.starter.product_id
  display_name          = "Starter"
  state                 = "active"
}

#Add subscription to premium product
resource "azurerm_api_management_subscription" "premium" {
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  product_id            = azurerm_api_management_product.premium.product_id
  display_name          = "Premium"
  state                 = "active"
}