resource "azurerm_resource_group" "labRG" {
        name = "labResourceGroup"
        location = "${var.location}"
}

variable "location" {
  description = "The region."
  default     = "westeurope"
}
variable "client_address_space" {
  description = "The address space"
  default     = "10.0.1.0/24"
}

variable "client_subnet_prefix" {
  description = "The address prefix subnet."
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "Specifies size"
  default     = "Standard_B2s"
}
variable "win10_size" {
  description = "Specifies size"
  default     = "Standard_B2s"
}

#variable "subnet_id" {}
#variable "admin_username" {}
#variable "admin_password" {}
#variable "vm_name" {}
