http://www.anniehedgie.com/terraform-and-winrm postcommand

https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure


Windows10
az vm image list --all --output table --publisher MicrosoftWindowsDesktop

export ARM_SUBSCRIPTION_ID=your_subscription_id
export ARM_CLIENT_ID=your_appId
export ARM_CLIENT_SECRET=your_password
export ARM_TENANT_ID=your_tenant_id

# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=public
