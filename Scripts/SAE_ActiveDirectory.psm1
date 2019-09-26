if ($systemconfiguration.Role -eq "ROOTDC"){
    $ADconfig = $systemconfiguration.ADConfig
    Write-Log -LogFile $logfile -Classification "Info" -Message "Promot Root Domain Controller: .... $($ADconfig.DomainName)"
    Import-Module ADDSDeployment
    try {
        if ((gwmi win32_computersystem).partofdomain -eq $true) {exit 99}
        }
    catch {Write-Log -LogFile $logfile -Classification "ERROR" -Message "Unable to determin Domain"}
    $CreateDnsDelegation = $([System.Convert]::ToBoolean($ADconfig.CreateDnsDelegation))
    $InstallDns = $([System.Convert]::ToBoolean($ADconfig.InstallDns))
    Install-ADDSForest -CreateDnsDelegation:$CreateDnsDelegation -DatabasePath $ADconfig.DatabasePath -DomainMode $ADconfig.DomainMode -DomainName $ADconfig.DomainName -DomainNetbiosName $ADconfig.DomainNetbiosName -ForestMode $ADconfig.ForestMode -InstallDns:$InstallDns -LogPath $ADconfig.LogPath -SafeModeAdministratorPassword $(ConvertTo-SecureString $($ADconfig.SafeModeAdministratorPassword) -AsPlainText -Force) -SysvolPath $ADconfig.SysvolPath -Force
    }

if ($systemconfiguration.Role -eq "MEMBERDC"){
    $ADconfig = $systemconfiguration.ADConfig
    Write-Log -LogFile $logfile -Classification "Info" -Message "Promot further Domain Controller: .... $($ADconfig.DomainName)"
    
    if (!(Test-NetConnection -computername $ADconfig.DomainName -Port 389)) {
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Unable to connect to Domain by Port 389: $($ADconfig.DomainName)"
        exit 99}
    if (!(Test-NetConnection -computername $ADconfig.DomainName -Port 445)){
        Write-Log -LogFile $logfile -Classification "ERROR" -Message "Unable to connect to Domain by Port 445: $($ADconfig.DomainName)"
        exit 99}
    Import-Module ADDSDeployment
    try {
        if ((gwmi win32_computersystem).partofdomain -eq $true) {exit 99}
        }
    catch {Write-Log -LogFile $logfile -Classification "INFO" -Message "Unable to determin Domain"}
    $password= ConvertTo-SecureString $($ADconfig.AdminPasswort) -AsPlainText -Force
    $AdminCredentials = New-Object System.Management.Automation.PSCredential ($($ADConfig.AdminUser),$password)
    $InstallDns = $([System.Convert]::ToBoolean($ADconfig.InstallDns))
    Install-ADDSDomainController -DatabasePath $ADconfig.DatabasePath -Credential $AdminCredentials -DomainName $ADconfig.DomainName -InstallDns:$InstallDns -LogPath $ADconfig.LogPath -SafeModeAdministratorPassword $(ConvertTo-SecureString $($ADconfig.SafeModeAdministratorPassword) -AsPlainText -Force) -SysvolPath $ADconfig.SysvolPath -Force -whatif
    }

    foreach ($ou in $OUs){
        if ($ou.OrganisationalUnitPath.Length -eq 0) { $oupath =  $OURootpath}
        else {$oupath =  $($ou.OrganisationalUnitPath + "," + $OURootpath)}
        if (([adsi]::Exists("LDAP://OU=" + $($ou.OUname) + "," + $($oupath)))){ continue }
        $HT_NewADOU = @{}
        $HT_NewADOU.Name = $ou.OUname
        $HT_NewADOU.Path = $oupath
        $HT_NewADOU.ProtectedFromAccidentalDeletion = $([System.Convert]::ToBoolean($ou.ProtectedFromAccidentalDeletion))
        $HT_NewADOU.Server = $domaincontroller
        New-ADOrganizationalUnit @HT_NewADOU
        sleep -Seconds 10
        }
    
    #Create AD Groups
    
    [array]$groups = $Configuration.configuration.groups.group
    
    foreach ($group in $groups){
        [string]$GroupExists=$null
        try{
            $GroupExists = Get-ADGroup -server $domaincontroller -Identity $groupmember -ErrorAction SilentlyContinue
            if ($GroupExists.Length -ne 0) {continue}
            }
        catch{}
        $HT_NewADGroup = @{}
        $HT_NewADGroup.DisplayName = $group.DisplayName
        $HT_NewADGroup.Name = $group.Name
        $HT_NewADGroup.SamAccountName = $group.SamAccountName
        $HT_NewADGroup.GroupCategory = $group.GroupCategory
        $HT_NewADGroup.GroupScope = $group.GroupScope
        $HT_NewADGroup.Path = $group.OrganisationalUnitPath + "," + $OURootpath
        $HT_NewADGroup.Description = $group.Description
        $HT_NewADGroup.Server = $domaincontroller
        try {
            $groupcreated = New-ADGroup @HT_NewADGroup -ErrorAction SilentlyContinue
            }
        catch{}
        sleep -Seconds 10
        foreach ($groupmember in $group.memberof.GroupMember){
            if ($groupmember.Length -eq 0) {continue}
            [string]$GroupExists=$null
            try{
                $GroupExists = Get-ADGroup -server $domaincontroller -Identity $groupmember -ErrorAction SilentlyContinue
                if ($GroupExists.Length -ne 0) {continue}
                }
            catch{}
            [array]$newgroup = $Configuration.configuration.groups.group | Where-Object {$_.name -eq $groupmember}
            $HT_NewADGroup = @{}
            $HT_NewADGroup.DisplayName = $newgroup.DisplayName
            $HT_NewADGroup.Name = $newgroup.Name
            $HT_NewADGroup.SamAccountName = $newgroup.SamAccountName
            $HT_NewADGroup.GroupCategory = $newgroup.GroupCategory
            $HT_NewADGroup.GroupScope = $newgroup.GroupScope
            $HT_NewADGroup.Path = $newgroup.OrganisationalUnitPath + "," + $OURootpath
            $HT_NewADGroup.Description = $newgroup.Description
            $HT_NewADGroup.Server = $domaincontroller
            New-ADGroup @HT_NewADGroup
            sleep -Seconds 10
            Add-ADGroupMember -Identity $group.SamAccountName -members $groupmember
            }
        
    }
    
    #Create AD User
    
    [array]$Accounts = $Configuration.configuration.Accounts.Account
    
    foreach ($Account in $Accounts){
        if ($null -eq $Account.SamAccountName) {exit 99}
        [string]$CheckUserExists = $null
        try {
            $CheckUserExists = get-aduser -server $domaincontroller -Identity $Account.SamAccountName -ErrorAction SilentlyContinue
            if ($CheckUserExists.Length -ne 0){
                try {
                    Move-ADObject -Server $domaincontroller -Identity (get-aduser -Identity $Account.SamAccountName).DistinguishedName -TargetPath $($Account.OrganisationalUnit + "," + (get-addomain).DistinguishedName) -ErrorAction SilentlyContinue
                    
                    if ($Account.type -eq "JoinDomain") {
                    #Join Domain Rights
            
                    $domainjoinuser = $netbiosdomain + "\" + $Account.SamAccountName
    
                    foreach ($joindomainou in $account.joindomainOUs){
                        $joindomainou = $joindomainou + "," + $OURootpath
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
    
                    }
                catch{}
                continue
                }
            }
        catch{}
        if ($CheckUserExists.Length -eq 0) {
            $PW=$Account.password
            $pass= ConvertTo-SecureString -String $pw -AsPlainText -Force
            $HT_NewADUser = @{}
            $HT_NewADUser.AccountPassword = $pass
            $HT_NewADUser.Enabled = $([System.Convert]::ToBoolean($Account.Enabled))
            $HT_NewADUser.PasswordNeverExpires = $([System.Convert]::ToBoolean($Account.PassworNeverExpires))
            $HT_NewADUser.ChangePasswordAtLogon = $([System.Convert]::ToBoolean($Account.ChangePasswordAtLogon))
            $HT_NewADUser.GivenName = $Account.GivenName
            $HT_NewADUser.Surname = $Account.Surname
            $HT_NewADUser.Name = $Account.Name
            $HT_NewADUser.CannotChangePassword = $([System.Convert]::ToBoolean($Account.CannotChangePassword))
            $HT_NewADUser.Description = $Account.Description
            $HT_NewADUser.SamAccountName = $Account.SamAccountName
            $HT_NewADUser.DisplayName = $Account.DisplayName
            $HT_NewADUser.UserPrincipalName = $Account.Name + "@" + $env:USERDNSDOMAIN
            $HT_NewADUser.Server = $domaincontroller
            new-aduser @HT_NewADUser
            sleep -Seconds 10
            }
        if ($Account.OrganisationalUnit){
            if (!([adsi]::Exists("LDAP://" + $($Account.OrganisationalUnit) +"," + (get-addomain).DistinguishedName))){ continue }
            try {
                Move-ADObject -Server $domaincontroller -Identity (get-aduser -Identity $Account.SamAccountName).DistinguishedName -TargetPath $($Account.OrganisationalUnit + "," + (get-addomain).DistinguishedName) -ErrorAction SilentlyContinue
                }
            catch{}
            }
        if ($Account.type -eq "JoinDomain") {
            #Join Domain Rights
            
            $domainjoinuser = $netbiosdomain + "\" + $Account.SamAccountName
    
            foreach ($joindomainou in $account.joindomainOUs){
                $joindomainou = $joindomainou + "," + $OURootpath
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
        }