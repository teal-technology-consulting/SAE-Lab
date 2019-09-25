output "DC1_ip_addr" {
  value = "${azurerm_public_ip.Win10PublicIP.ip_address}"
}
