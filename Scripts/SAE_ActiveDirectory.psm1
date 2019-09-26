function New-SAERootDomainController {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigCreateDnsDelegation,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigInstallDNS,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDatabasePath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDomainMode,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDomainName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDomainNetbiosName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigForestMode,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigLogPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigSafeModeAdministratorPassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigSysvolPath    
    )
    Import-Module ADDSDeployment
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Start step: ..." 
    try {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Verify system is not domain joined."
        if ((Get-WmiObject win32_computersystem).partofdomain -eq $true) {exit 99}
        }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "System already part of a Windows Domain. ..."
    }
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Promot system to Domain Controller ..."
    $CreateDnsDelegation = $([System.Convert]::ToBoolean($ADconfigCreateDnsDelegation))
    $InstallDns = $([System.Convert]::ToBoolean($ADconfigInstallDNS))
    try {
        Install-ADDSForest -CreateDnsDelegation:$CreateDnsDelegation -DatabasePath $ADconfigDatabasePath -DomainMode $ADconfigDomainMode -DomainName $ADconfigDomainName -DomainNetbiosName $ADconfigDomainNetbiosName -ForestMode $ADconfigForestMode -InstallDns:$InstallDns -LogPath $ADconfigLogPath -SafeModeAdministratorPassword $(ConvertTo-SecureString $($ADconfigSafeModeAdministratorPassword) -AsPlainText -Force) -SysvolPath $ADconfigSysvolPath -Force
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "... Finish step."
    }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "There was a problem during the domain controller promotion. $error[0]"
    }
        
}

function New-SAEMemberDomainController {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigAdminPassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigInstallDNS,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigSafeModeAdministratorPassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigAdminUser,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDomainName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDatabasePath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigLogPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigSysvolPath
    )

    try {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Import Module."
        Import-Module ADDSDeployment
    }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "Import Module failed."
    }
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Start step: ..."
    if (!(Test-NetConnection -computername $ADconfigDomainName -Port 389)) {
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Unable to connect to Domain by Port 389: $($ADconfigDomainName)"
        exit 99
    }
    if (!(Test-NetConnection -computername $ADconfigDomainName -Port 445)){
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Unable to connect to Domain by Port 445: $($ADconfigDomainName)"
        exit 99
    }
    try {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Verify system is not domain joined."
        if ((Get-WmiObject win32_computersystem).partofdomain -eq $true) {exit 99}
        }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "System already part of a Windows Domain. ..."
    }
    
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Start step: ..." 
    
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Promot system to Domain Controller ..."
    $password= ConvertTo-SecureString $($ADconfigAdminPassword) -AsPlainText -Force
    $AdminCredentials = New-Object System.Management.Automation.PSCredential ($($ADconfigAdminUser),$password)
    $InstallDns = $([System.Convert]::ToBoolean($ADconfigInstallDNS))
    Try {
        Install-ADDSDomainController -DatabasePath $ADconfigDatabasePath -Credential $AdminCredentials -DomainName $ADconfigDomainName -InstallDns:$InstallDns -LogPath $ADconfigLogPath -SafeModeAdministratorPassword $(ConvertTo-SecureString $($ADconfigSafeModeAdministratorPassword) -AsPlainText -Force) -SysvolPath $ADconfigSysvolPath -Force
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "... Finish step."
    }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "There was a problem during the domain controller promotion. $error[0]"
    }
}

function New-SAEOrganizationalUnit {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigOUPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigOURootPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigOUName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigOUServer,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigOUProtectedFromAccidentalDeletion
    )
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Start step ..."
    [string]$oupath = $null
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Get OU root path:"
    if ($ADconfigOUPath.Length -eq 0) { $oupath =  $ADconfigOURootPath}
    else {$oupath =  $($ADconfigOUPath + "," + $ADconfigOURootPath)}
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "OU root path: $oupath"
    Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Verify if OU exists if so skip creation and continue with next."
    if (([adsi]::Exists("LDAP://OU=" + $($ADconfigOUName) + "," + $($oupath)))){ continue }
    
    $HT_NewADOU = @{}
    $HT_NewADOU.Name = $ADconfigOUName
    $HT_NewADOU.Path = $oupath
    $HT_NewADOU.ProtectedFromAccidentalDeletion = $([System.Convert]::ToBoolean($ADconfigOUProtectedFromAccidentalDeletion))
    $HT_NewADOU.Server = $ADconfigOUServer
    
    try {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "Try to create the OU. $($HT_NewADOU.Name) in $($HT_NewADOU.Path)"
        New-ADOrganizationalUnit @HT_NewADOU
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Information" -LogText "OU created."
    }
    catch {
        Write-Log -Component $MyInvocation.MyCommand -ValidateSet "Error" -LogText "Failed to create OU: $error[0]"
    }
    
    Start-Sleep -Seconds 10

}

function New-SAEADGroup {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupDisplayName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupSamAccountName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupCategory,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupScope,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupOrganisationalUnitPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupOURootpath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupDescription,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigGroupServer
    )
    [string]$GroupExists=$null
    try{
        $GroupExists = Get-ADGroup -server $domaincontroller -Identity $ADconfigGroupSamAccountName -ErrorAction SilentlyContinue
        if ($GroupExists.Length -ne 0) {
            return $true
        }
    }
    catch{
        $HT_NewADGroup = @{}
        $HT_NewADGroup.DisplayName = $ADconfigGroupDisplayName
        $HT_NewADGroup.Name = $ADconfigGroupName
        $HT_NewADGroup.SamAccountName = $ADconfigGroupSamAccountName
        $HT_NewADGroup.GroupCategory = $ADconfigGroupCategory
        $HT_NewADGroup.GroupScope = $ADconfigGroupScope
        $HT_NewADGroup.Path = $ADconfigGroupOrganisationalUnitPath + "," + $ADconfigGroupOURootpath
        $HT_NewADGroup.Description = $ADconfigGroupDescription
        $HT_NewADGroup.Server = $ADconfigGroupServer
        try {
            New-ADGroup @HT_NewADGroup -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 10
            return $true
        }
        catch{
            return $false
        }
        
    }
}

function New-SAEADUser {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserDisplayName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserServer,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserSamAccountName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserPassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserEnabled,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserPassworNeverExpires,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserChangePasswordAtLogon,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserGivenName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserSurname,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserCannotChangePassword,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserDescription,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigUserOU
    )

    [string]$CheckUserExists = $null
    try {
        $CheckUserExists = get-aduser -server $ADconfigUserServer -Identity $ADconfigUserSamAccountName -ErrorAction SilentlyContinue
        if ($CheckUserExists.Length -ne 0) {
            return $true
        }
    }
    catch {
        $pass= ConvertTo-SecureString -String $ADconfigUserPassword -AsPlainText -Force
        $HT_NewADUser = @{}
        $HT_NewADUser.AccountPassword = $pass
        $HT_NewADUser.Enabled = $([System.Convert]::ToBoolean($ADconfigUserEnabled))
        $HT_NewADUser.PasswordNeverExpires = $([System.Convert]::ToBoolean($ADconfigUserPassworNeverExpires))
        $HT_NewADUser.ChangePasswordAtLogon = $([System.Convert]::ToBoolean($ADconfigUserChangePasswordAtLogon))
        $HT_NewADUser.GivenName = $ADconfigUserGivenName
        $HT_NewADUser.Surname = $ADconfigUserSurname
        $HT_NewADUser.Name = $ADconfigUserName
        $HT_NewADUser.CannotChangePassword = $([System.Convert]::ToBoolean($ADconfigUserCannotChangePassword))
        $HT_NewADUser.Description = $ADconfigDescription
        $HT_NewADUser.SamAccountName = $ADconfigUserSamAccountName
        $HT_NewADUser.DisplayName = $ADconfigUserDisplayName
        $HT_NewADUser.UserPrincipalName = $ADconfigUserName + "@" + $env:USERDNSDOMAIN
        $HT_NewADUser.Server = $ADconfigUserServer
        new-aduser @HT_NewADUser
        Start-Sleep -Seconds 10
    }
    if (!([adsi]::Exists("LDAP://" + $($ADconfigUserOU) +"," + (get-addomain).DistinguishedName))){ continue }
    try {
        Move-ADObject -Server $domaincontroller -Identity (get-aduser -Identity $Account.SamAccountName).DistinguishedName -TargetPath $($Account.OrganisationalUnit + "," + (get-addomain).DistinguishedName) -ErrorAction SilentlyContinue
        }
    catch{}
}

function Set-SAEDomainJoinRights {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDJRNetbiosDomain,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDJRDomainJoinOU,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDJROURootPath,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDJRSamAccountName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADconfigDJRServer
    )
    $CheckUserExists = get-aduser -server $ADconfigDJRServer -Identity $ADconfigDJRSamAccountName -ErrorAction SilentlyContinue
    if ($CheckUserExists.Length -ne 0){
        $domainjoinuser = $ADconfigDJRNetbiosDomain + "\" + $ADconfigDJRSamAccountName
        $joindomainou = $ADconfigDJRDomainJoinOU + "," + $ADconfigDJROURootPath
        DSACLS $joindomainou /R $domainjoinuser
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):GR;;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):CA;Reset Password;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;pwdLastSet;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;Logon Information;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;description;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;displayName;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;sAMAccountName;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;DNS Host Name Attributes;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;Account Restrictions;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):WP;servicePrincipalName;computer"
        DSACLS $joindomainou /I:S /G "$($domainjoinuser):CC;computer;organizationalUnit"
    }
    
}