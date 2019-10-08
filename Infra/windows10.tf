resource "azurerm_public_ip" "Win10PublicIP" {
  name                = "win10PublicIP"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name = "${azurerm_resource_group.labRG.name}"
  allocation_method   = "Static"
  }
 
 
#--- NIC
resource "azurerm_network_interface" "Win10NIC" {
  name                = "interface0"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name = "${azurerm_resource_group.labRG.name}"
network_security_group_id     = "${azurerm_network_security_group.sg_client.id}"
 
  ip_configuration {
    name                          = "Win10Client"
    subnet_id                     = "${azurerm_subnet.client_subnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = "${azurerm_public_ip.Win10PublicIP.id}"
  }
 
}
resource "azurerm_virtual_machine" "win10client" {
    name                           = "Win10"
    location            = "${azurerm_resource_group.labRG.location}"
    resource_group_name            = "${azurerm_resource_group.labRG.name}"
    network_interface_ids  = ["${azurerm_network_interface.Win10NIC.id}"]
    vm_size                        = "${var.win10_size}"
    delete_os_disk_on_termination  = "True"

#--- vm reference ---

   storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-entn"
    version   = "18362.356.1909091636"
  }

 
  storage_os_disk {
    name              = "disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type           = "Windows"
  }
 
  os_profile {
    computer_name  = "Windows10"
    admin_username = "lab"
    admin_password = "labPassword2019"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent = true
  }
 
}
