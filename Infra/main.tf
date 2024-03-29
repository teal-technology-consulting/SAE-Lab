
resource "azurerm_virtual_network" "client" {
  name                = "CLIENT"
  location            = "${azurerm_resource_group.labRG.location}"
  address_space       = ["${var.client_address_space}"]
  resource_group_name = "${azurerm_resource_group.labRG.name}"
}

resource "azurerm_subnet" "client_subnet" {
  name                 = "CLIENT_subnet"
  virtual_network_name = "${azurerm_virtual_network.client.name}"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  address_prefix       = "${var.client_subnet_prefix}"
}


resource "azurerm_network_security_group" "sg_client" {
  name                = "SG_Client"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
}

resource "azurerm_network_security_rule" "sg_Client_outbound" {
  name                        = "sg_Client_outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  network_security_group_name = "${azurerm_network_security_group.sg_client.name}"
}
resource "azurerm_network_security_rule" "sg_Client_inbound" {
  name                        = "sg_Client_inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  network_security_group_name = "${azurerm_network_security_group.sg_client.name}"
}
