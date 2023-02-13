# Azure API Management demo main repository

## Overview

This repository contains the main infrastructure for the Azure API Management demo.

## Prerequisites

This demo requires the following prerequisites:
- An Azure subscription
- The Azure CLI
- A Service Principal with Contributor rights on the subscription
- Setup credentials in Github Secrets
- Create an storage account and a container for the Terraform state
- Fork this repository and clone it locally. 

### Azure subscription

You must have an Azure subscription to deploy this demo. If you don't have an Azure subscription, you can create a [free account](https://azure.microsoft.com/free).

### Azure CLI

We will create some prerequired resources with the [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli). 

### Service Principal

This demo needs a Service Principal to deploy the infrastructure. You can create a Service Principal with the following instructions:

- Log in to Azure:

```bash
az login
```

- List the available subscriptions:

```bash
az account list -o table
```

- Init the SUBSCRIPTION_ID variable with the subscription ID you want to use:

```bash
export SUBSCRIPTION_ID=<subscriptionID>
```

- Create the Service Principal with contributor rights on the subscription:
    
```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID"
```

Copy the output of the command and keep it safe for next step.

For details, see the instructions in the [Azure CLI documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) to create a Service Principal.

### Github Secrets

We will create the following secrets in Github Secrets, where all values are the ones you got from the previous step:

- TF_ARM_CLIENT_ID=<*appId*>
- TF_ARM_CLIENT_SECRET=<*password*>
- TENANT_ID=<*tenant*>
- SUBSCRIPTION_ID=<*subscriptionID*>

### Storage account and container

We will use a storage account and a container to store the Terraform state. You can create a storage account and a container with the following instructions:

- Init the RESORUCE_GROUP variable with the name of the resource group you want to use:

```bash
export RESOURCE_GROUP=terraform-global-rg
```

- Create the resource group:

```bash
az group create --name $RESOURCE_GROUP --location westeurope --subscription $SUBSCRIPTION_ID
```

- Init the STORAGE_ACCOUNT_NAME variable with the name of the storage account you want to use:

```bash
export STORAGE_ACCOUNT_NAME=tfstategithub$RANDOM
```

- Create the storage account:

```bash
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --location westeurope --sku Standard_LRS --subscription $SUBSCRIPTION_ID
```

- Under *apim* directory, find the *main.tf* file and modify the name of the *storage_account_name* variable with the value of the STORAGE_ACCOUNT_NAME variable. To get the value of the STORAGE_ACCOUNT_NAME variable, run the following command:

```bash
echo $STORAGE_ACCOUNT_NAME
```

- Create both containers for *dev* and *main* environments:

```bash
az storage container create --name dev-tfapim --account-name $STORAGE_ACCOUNT_NAME --subscription $SUBSCRIPTION_ID
az storage container create --name main-tfapim --account-name $STORAGE_ACCOUNT_NAME --subscription $SUBSCRIPTION_ID
```

### Fork and clone the repository

Fork this repository. Then clone it locally by running the following command in the directory where you want to have the repository:

```bash
git clone <your_repository>.git
```

Move to the *dev* branch:

```bash
git checkout dev
```

We will use the *dev* branch to make changes to the infrastructure which will be deployed as the Develpoment environment. The *main* branch will be used to deploy the Production environment after the changes have been tested in the Development environment, create a PR from the *dev* branch to the *main* branch and merge it.

# Run the automation

We have included a [GitHub Action](.github/workflows/apim-deployment.yaml) to run the Terraform automation.

This automation will create the following resources:
- Resource group
- API Management service
- Storage account for future use (to store the API Management APIs descriptors and the API Management policies. We will use this storage account in the next steps of the demo).

The storage account and the API Management service that we create in this automation have to be unique named. To make sure they are unique, modify the *apim.tfvars* file and change the value of the *uniqueId* variable. The final value of both names will be:
- storage account name: *"${var.prefix}${var.environment}apimsa${var.uniqueId}"*
- API Management service name: *"${var.prefix}${var.environment}-apim-${var.uniqueId}"*

To run the automation, push the changes to the *dev* branch. The automation will run automatically.

```bash	
git add .
git commit -m "Initial commit"
git push origin dev
```