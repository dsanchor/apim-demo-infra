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

# Configure the Azure Active Directory Provider
provider "azuread" {

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


data "azuread_client_config" "current" {}

# Create an application
resource "azuread_application" "csa-apimdemo-app" {
  display_name    = "Cloud Solution Architect APIM Demo App"
  owners          = [data.azuread_client_config.current.object_id]
  identifier_uris = ["api://csa-apimdemo-appuri"]

api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access example on behalf of the signed-in user."
      admin_consent_display_name = "Access example for admin consent"
      enabled                    = true
      id                         = "16183846-204b-4b43-82e1-5d2222eb4b9b"
      type                       = "User"
      user_consent_description   = "Allow the application to access example on your behalf."
      user_consent_display_name  = "Access example for user consent"
      value                      = "demo"
    }

    oauth2_permission_scope {
      admin_consent_description  = "Administer the example application"
      admin_consent_display_name = "Administer"
      enabled                    = true
      id                         = "be18fa3e-ab5b-4b11-83d9-04ba2b7946bc"
      type                       = "Admin"
      value                      = "administer"
    }

    oauth2_permission_scope {
      admin_consent_description  = "Secret scope the example application"
      admin_consent_display_name = "Secret scope"
      enabled                    = true
      id                         = "ee18fa3e-ab5b-4b11-83d9-04ba2b7946bc"
      type                       = "Admin"
      value                      = "secretscope"
    }
  }

    required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type = "Role"
    }

    resource_access {
      id   = "b4e74841-8e56-480b-be8b-910348b18b4c" # User.ReadWrite
      type = "Scope"
    }
  }

}


resource "azuread_application_pre_authorized" "example" {
  application_object_id = azuread_application.csa-apimdemo-app.object_id
  authorized_app_id     = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  permission_ids        = ["16183846-204b-4b43-82e1-5d2222eb4b9b", "be18fa3e-ab5b-4b11-83d9-04ba2b7946bc"]
}
