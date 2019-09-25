resource "azurerm_resource_group" "labRG" {
        name = "labResourceGroup"
        location = "${var.location}"
}

variable "location" {
  description = "The region."
  default     = "centralus"
}
variable "client_address_space" {
  description = "The address space"
  default     = "10.0.1.0/24"
}
variable "gold_address_space" {
  description = "The address space"
  default     = "10.0.3.0/24"
}
variable "red_address_space" {
  description = "The address space"
  default     = "10.0.2.0/24"
}
variable "client_subnet_prefix" {
  description = "The address prefix subnet."
  default     = "10.0.1.0/24"
}

variable "gold_subnet_prefix" {
  description = "The address prefix subnet."
  default     = "10.0.3.0/24"
}
variable "red_subnet_prefix" {
  description = "The address prefix subnet."
  default     = "10.0.2.0/24"
}

variable "vm_size" {
  description = "Specifies size"
  default     = "Standard_A0"
}
variable "win10_size" {
  description = "Specifies size"
  default     = "Standard_A0"
}

#variable "subnet_id" {}
#variable "admin_username" {}
#variable "admin_password" {}
#variable "vm_name" {}
