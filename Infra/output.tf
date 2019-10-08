output "DC1_ip_addr" {
  value = "${azurerm_public_ip.Win10PublicIP.ip_address}"
}
output "location" {
  value = "${azurerm_resource_group.labRG.location}"
}
  
output "resource_group_name" {
  value  = "${azurerm_resource_group.labRG.name}"
}

output "win10client" {
  value = "${azurerm_virtual_machine.win10client.name}"
}