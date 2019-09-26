
if ($systemconfiguration.ip){
    [string]$interfaceindex = (Get-NetIPConfiguration | Where-Object {$_.IPv4Address.ipaddress -eq $systemconfiguration.ip}).interfaceindex
    if (!($interfaceindex)){
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "IP Configuration is wrong. Interface not found."  
        exit 99}
    #[string]$dhcp = (Get-NetIPInterface | Where-Object {($_.ifIndex -eq $interfaceindex)} | Where-Object {($_.AddressFamily -eq "$($systemconfiguration.AddressFamily)")}).Dhcp
    #if ($dhcp -eq "Enabled"){exit 99}
    #Rename Adapter
    try {
        Write-Log -LogFile $logfile -Classification "Info" -Message "Rename Management NetworkInterface: ... "
        Get-NetAdapter -InterfaceIndex $interfaceindex | Rename-NetAdapter -newname $($systemconfiguration.NetworkName)
        Write-Log -LogFile $logfile -Classification "Success" -Message "Interface Renamed"
        }
    catch {
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Failed to rename Network Interface: $error[0]"  
        }
    try {
        Write-Log -LogFile $logfile -Classification "Info" -Message "Configure DNS Servers: ... "
        if ($($systemconfiguration.dns)){
            Set-DnsClientServerAddress -InterfaceIndex $interfaceindex -ServerAddresses $($systemconfiguration.dns)    
            }
        else {Set-DnsClientServerAddress -InterfaceIndex $interfaceindex -ServerAddresses $($systemconfiguration.ip),127.0.0.1}
        Write-Log -LogFile $logfile -Classification "SUCCESS" -Message "DNS Servers configured."
        }
    catch {
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Failed to Configure DNS: $error[0]"  
        }
    }

[array]$windowsfeatures = $systemconfiguration.windowsfeatures -split ";"

[string]$osversion = ((Get-WmiObject -class Win32_OperatingSystem).Caption).ToLower()

if ($osversion -match "server")
    {
    foreach ($windowsfeature in $windowsfeatures){
        if ($windowsfeature.Length -eq 0){continue}
        $installstate = (get-windowsfeature -name $windowsfeature).installstate
        if ($installstate -eq "Installed"){continue}
        try {
            Write-Log -LogFile $logfile -Classification "Info" -Message "Installing: .... $windowsfeature"
            $InstallStatus = Install-WindowsFeature -name $windowsfeature -IncludeManagementTools
            Write-Log -LogFile $logfile -Classification "Success" -Message "Feature Installed: $windowsfeature ExitCode: $($InstallStatus.ExitCode) RestartRequired: $($InstallStatus.RestartNeeded)"
            }
        catch {
            Write-Log -LogFile $logfile -Classification "ERROR" -Message "There was a problem to install the windows feature $windowsfeature please check windows logs!"    
            exit 99
            }
        }
    }

else {
    [array]$availablecapabilities
    $availablecapabilities = DISM.exe /Online /Get-Capabilities
    foreach ($windowsfeature in $windowsfeatures){
        if ($windowsfeature.Length -eq 0){continue}
        $InstallCapabilities = $availablecapabilities | where-object {$_ -match $windowsfeature}        
        foreach ($InstallCapability in $InstallCapabilities){
            try {
                $InstallCapability = $InstallCapability -replace ".*(\:\s)",""
                Write-Log -LogFile $logfile -Classification "Info" -Message "Installing: .... $InstallCapability"
                DISM.exe /Online /add-capability /CapabilityName:$InstallCapability
                #Write-Log -LogFile $logfile -Classification "Success" -Message "Feature Installed: $InstallCapability ExitCode: $($InstallStatus.ExitCode) RestartRequired: $($InstallStatus.RestartNeeded)"
                }
            catch {
                Write-Log -LogFile $logfile -Classification "ERROR" -Message "There was a problem to install the windows feature $InstallCapability please check windows logs!"    
                exit 99
                }    
            
            }
        
        }

    }


    if (!($systemconfiguration.Role -eq "ROOTDC") -or !($systemconfiguration.Role -eq "MEMBERDC")){
        try {
            if ((gwmi win32_computersystem).partofdomain -eq $False) {
            $password= ConvertTo-SecureString $($systemconfiguration.joindomain.password) -AsPlainText -Force
            $AdminCredentials = New-Object System.Management.Automation.PSCredential ($($systemconfiguration.joindomain.user),$password)
            Add-Computer -DomainName $systemconfiguration.joindomain.domain -OUPath $systemconfiguration.joindomain.OUPath -Credential $AdminCredentials
            }
        }
        catch {Write-Log -LogFile $logfile -Classification "INFO" -Message "Unable to determin Domain"}
        
        foreach ($disk in $systemconfiguration.disks.disk){
            $actualdisk = get-disk | Where-Object PartitionStyle -eq 'RAW' | Where-Object {($_.size/1gb -eq $disk.volsize )} | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $disk.driveletter -UseMaximumSize | Format-Volume -NewFileSystemLabel $disk.volname -FileSystem NTFS -Confirm:$false   
        }
        Restart-Computer -force
    }