resource "azurerm_virtual_machine_extension" "MYDEPLOY" {
  depends_on = ["azurerm_virtual_machine.DC01"]
  name                 = "MYDEPLOY"
  location            = "${azurerm_resource_group.labRG.location}"
  resource_group_name  = "${azurerm_resource_group.labRG.name}"
  virtual_machine_name = "${azurerm_virtual_machine.DC01.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
  "fileUris": ["https://gist.githubusercontent.com/kevit/0cdea7324667ea2f87527f9663498795/raw/47a3e6018126d911a3cce5581606eaeafd88ddec/lab.ps1"],
  "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ./lab.ps1",
  "timestamp" : "13"
  }
SETTINGS

}
