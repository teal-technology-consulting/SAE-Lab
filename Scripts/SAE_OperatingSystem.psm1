
function Get-SAENetworkAdapterInterfaceID{
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationIP
    )
    New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Get Interface index: ... "
    [string]$interfaceindex = $null
    $interfaceindex = (Get-NetIPConfiguration | Where-Object {$_.IPv4Address.ipaddress -eq $systemconfigurationIP}).interfaceindex
    if (!($interfaceindex)){
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "Network interface not found."  
        exit 99
    }
    New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Interface Index: $($interfaceindex)"
    return $interfaceindex
}
function Rename-SAENetworkAdapter {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationIP,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationNetworkName
    )
    [string]$interfaceindex = $null
    $interfaceindex = Get-SAENetworkAdapterInterfaceID -SystemconfigurationIP $SystemconfigurationIP
    

    try {New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Rename NetworkInterface: ... "
        Get-NetAdapter -InterfaceIndex $interfaceindex | Rename-NetAdapter -newname $SystemconfigurationNetworkName
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Interface Renamed"
    }
    
    catch {
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "error" -LogText"Failed to rename Network Interface: $error[0]"  
    }
}

function Set-SAEDNSClient {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationIP,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$systemconfigurationDNS
    )
    
    [string]$InterfaceIndex = $null
    $interfaceIndex = Get-SAENetworkAdapterInterfaceID -SystemconfigurationIP $SystemconfigurationIP

    try {
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Configure DNS Servers: ... "
        Set-DnsClientServerAddress -InterfaceIndex $interfaceindex -ServerAddresses $systemconfigurationDNS    
    }
    
    catch {
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "Failed to Configure DNS: $error[0]"  
    }
}

function get-saeinstalledwindowsfeatures {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationWindowsfeature
    )
    [string]$osversion = $null
    $osversion = ((Get-WmiObject -class Win32_OperatingSystem).Caption).ToLower()

    if ($osversion -match "server") {
        $installstate = $null
        try {
            New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Get Installation state for windows feature."
            $installstate = (get-windowsfeature -name $SystemconfigurationWindowsfeature).installstate
        }
        catch {
            New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "There was a problem getting the installed windows features."
        }
        
        if ($installstate -eq "Installed"){
            New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Windowsfeature installed"
            return $true
        } 
        else {
            New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Windowsfeature not installed."
            return $false
        }
    }

    else {

    }
}

function install-saewindowsfeatures {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$systemconfigurationWindowsfeatures
    )
    
    [array]$windowsfeatures
    $windowsfeatures= $systemconfigurationWindowsfeatures -split ";"
    [string]$osversion = $null
    $osversion = ((Get-WmiObject -class Win32_OperatingSystem).Caption).ToLower()

    if ($osversion -match "server") {
        foreach ($windowsfeature in $windowsfeatures){
            if ($windowsfeature.Length -eq 0){continue}
            $installstate = get-saeinstalledwindowsfeatures -SystemconfigurationWindowsfeature $windowsfeature
            if (!($installstate)){continue}
            try {
                New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Installing: .... $windowsfeature"
                $InstallStatus = Install-WindowsFeature -name $windowsfeature -IncludeManagementTools
                New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Feature Installed: $windowsfeature ExitCode: $($InstallStatus.ExitCode) RestartRequired: $($InstallStatus.RestartNeeded)"
                }
            catch {
                New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "There was a problem to install the windows feature $windowsfeature please check windows logs!"    
                exit 99
                }
        }
    }

    else {
        foreach ($windowsfeature in $windowsfeatures){
            if ($windowsfeature.Length -eq 0){continue}
            [array]$availablecapabilities
            $availablecapabilities = DISM.exe /Online /Get-Capabilities
            $InstallCapabilities = $availablecapabilities | where-object {$_ -match $windowsfeature}        
            foreach ($InstallCapability in $InstallCapabilities){
                try {
                    $InstallCapability = $InstallCapability -replace ".*(\:\s)",""
                    New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Installing: .... $InstallCapability"
                    DISM.exe /Online /add-capability /CapabilityName:$InstallCapability
                    }
                catch {
                    New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "There was a problem to install the windows feature $InstallCapability please check windows logs!"    
                    exit 99
                    }    
                }
            }
    }
}

function set-SAEConfigureNewDisks{
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$SystemconfigurationDiskVolsize,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$SystemconfigurationDiskDriveletter,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$SystemconfigurationDiskVolname
    )
    try {
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Start configure disk: ..."
        get-disk | Where-Object PartitionStyle -eq 'RAW' | Where-Object {($_.size/1gb -eq $SystemconfigurationDiskVolsize )} | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $SystemconfigurationDiskDriveletter -UseMaximumSize | Format-Volume -NewFileSystemLabel $SystemconfigurationDiskVolname -FileSystem NTFS -Confirm:$false
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Disk configured."
    }
    catch {
        New-LogLine -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "There was a problem configuring the disk .... : $error[0]"
    }
    
}

function Add-SAEJoinDomain {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring]$SystemconfigurationJoindomainPassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationJoindomainUser,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationJoindomainDomain,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SystemconfigurationJoindomainOUPath
    )
        try {
            if ((Get-WmiObject win32_computersystem).partofdomain -eq $False) {
            $AdminCredentials = New-Object System.Management.Automation.PSCredential ($($SystemconfigurationJoindomainUser),$SystemconfigurationJoindomainPassword)
            Add-Computer -DomainName $SystemconfigurationJoindomainDomain -OUPath $SystemconfigurationJoindomainOUPath -Credential $AdminCredentials
            }
        }
        catch {Write-Log -LogFile $logfile -Classification "INFO" -Message "Unable to determin Domain"}
}