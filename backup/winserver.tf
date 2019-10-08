locals {
  virtual_machine_name = "DC01"
}

resource "azurerm_network_interface" "internal_DC01" {
  name                    = "internal_DC01"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  internal_dns_name_label = "${local.virtual_machine_name}"

  ip_configuration {
    name                          = "internal_DC01"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.4"
    subnet_id                 = "${azurerm_subnet.gold_subnet.id}"
  }
}

resource "azurerm_virtual_machine" "DC01" {
  name                          = "DC01"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  network_interface_ids = ["${azurerm_network_interface.internal_DC01.id}"] 
  vm_size                       = "${var.vm_size}"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.virtual_machine_name}"
  admin_username            = "AdministratorLab"
  admin_password            = "labPassword2019"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
}
