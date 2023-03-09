# Configure Terraform
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

# Configure the Azure Active Directory Provider
provider "azuread" {
#  tenant_id = "16b3c013-d300-468d-ac64-7eda0820b6d3"
}

data "azuread_client_config" "current" {}

# Update an application
resource "azuread_application" "csa-apimdemo-app" {
  display_name    = "Cloud Solution Architect APIM Demo App"
  owners          = [data.azuread_client_config.current.object_id]
  identifier_uris = ["api://csa-apimdemo-appuri"]

}


