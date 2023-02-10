variable "location" {
    type = string
    default = "westeurope"
}

variable "region" {
    type = string
    default = "westeurope"
}

variable "prefix" {
    type = string
}

variable "environment" {
    type = string
}

variable "apimSku" {
    type = string
}

variable "apimSkuCapacity" {
    type = number
}

variable "apimPublisherName" {
    type = string
}

variable "apimPublisherEmail" {
    type = string
}

variable "storageAccountSku" {
    default = {
        tier = "Standard"
        type = "LRS"
    }
}