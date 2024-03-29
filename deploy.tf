module "parent" {
  source = "./Infra"
}

resource "azurerm_virtual_machine_extension" "MYDEPLOY" {
  name                 = "MYDEPLOY"
  location             = "${module.parent.location}"
  resource_group_name  = "${module.parent.resource_group_name}"
  virtual_machine_name = "${module.parent.win10client}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
 {
  
  "commandToExecute": "Mkdir C:\\AppX; exit 0",
  "timestamp" : "15"
  
}
SETTINGS

}

 # "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -Command \"& {\"$(Get-Date) This is a test.\" | Out-File -FilePath C:\\Users\\Public\\TestFile.txt -Encoding utf8 -Append}; exit 0",